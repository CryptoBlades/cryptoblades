pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./util.sol";
import "./Garrison.sol";
import "./common.sol";

contract Characters is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using SafeMath for uint16;
    using SafeMath for uint8;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Copied from promos.sol, to avoid paying 5k gas to query a constant.
    uint256 private constant BIT_FIRST_CHARACTER = 1;

    function initialize () public initializer {
        __ERC721_init("CryptoBlades character", "CBC");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function migrateTo_1ee400a(uint256[255] memory _experienceTable) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        experienceTable = _experienceTable;
    }

    function migrateTo_951a020() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        // Apparently ERC165 interfaces cannot be removed in this version of the OpenZeppelin library.
        // But if we remove the registration, then while local deployments would not register the interface ID,
        // existing deployments on both testnet and mainnet would still be registered to handle it.
        // That sort of inconsistency is a good way to attract bugs that only happens on some environments.
        // Hence, we keep registering the interface despite not actually implementing the interface.
        _registerInterface(0xe62e6974); // TransferCooldownableInterfaceId.interfaceId()
    }

    function migrateTo_ef994e2(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        promos = _promos;
    }

    function migrateTo_b627f23() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        characterLimit = 4;
    }

    function migrateTo_1a19cbb(Garrison _garrison) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        garrison = _garrison;
    }

    /*
        visual numbers start at 0, increment values by 1
        levels: 1-256
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
    */

    struct Character {
        uint16 xp; // xp to next level
        uint8 level; // up to 256 cap
        uint8 trait; // 2b trait, TBD
        uint64 staminaTimestamp; // standard timestamp in seconds-resolution marking regen start from 0
    }
    struct CharacterCosmetics {
        uint8 version;
        uint256 seed;
    }

    Character[] private tokens;
    CharacterCosmetics[] private cosmetics;

    uint256 public constant maxStamina = 200;
    uint256 public constant secondsPerStamina = 300; //5 * 60

    uint256[256] private experienceTable; // fastest lookup in the west

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(uint256 => uint256) public lastTransferTimestamp;

    Promos public promos;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    uint256 public characterLimit;

    mapping(uint256 => uint256) public raidsDone;
    mapping(uint256 => uint256) public raidsWon;

    uint256 public constant NFTVAR_SIMPLEQUEST_PROGRESS = 101;
    uint256 public constant NFTVAR_SIMPLEQUEST_TYPE = 102;
    uint256 public constant NFTVAR_REPUTATION = 103;

    uint256 public constant SIMPLEQUEST_TYPE_RAID = 8;

    mapping(uint256 => mapping(uint256 => uint256)) public nftVars; // nftID, fieldID, value
    uint256 public constant NFTVAR_BUSY = 1; // value bitflags: 1 (pvp) | 2 (raid) | 4 (TBD)..

    Garrison public garrison;

    uint256 public constant NFTVAR_BONUS_POWER = 2;

    event NewCharacter(uint256 indexed character, address indexed minter);
    event LevelUp(address indexed owner, uint256 indexed character, uint16 level);
    event Burned(address indexed owner, uint256 indexed id);

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NA");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    modifier minterOnly() {
        _minterOnly();
        _;
    }

    function _minterOnly() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(MINTER_ROLE, msg.sender), 'no access');
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "Too fresh for lookup");
    }

    function get(uint256 id) public view noFreshLookup(id) returns (uint16, uint8, uint8, uint64, uint16, uint16, uint16, uint16, uint16, uint16) {
        Character memory c = tokens[id];
        CharacterCosmetics memory cc = cosmetics[id];
        return (c.xp, c.level, c.trait, c.staminaTimestamp,
            getRandomCosmetic(cc.seed, 1, 13), // head
            getRandomCosmetic(cc.seed, 2, 45), // arms
            getRandomCosmetic(cc.seed, 3, 61), // torso
            getRandomCosmetic(cc.seed, 4, 41), // legs
            getRandomCosmetic(cc.seed, 5, 22), // boots
            getRandomCosmetic(cc.seed, 6, 2) // race
        );
    }

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint16 limit) private pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function getCosmeticsSeed(uint256 id) public view noFreshLookup(id) returns (uint256) {
        CharacterCosmetics memory cc = cosmetics[id];
        return cc.seed;
    }

    function getSoulForBurns(uint256[] calldata burnIds) external view returns (uint256) {
        uint256 soulAmount = 0;
        for(uint i = 0; i < burnIds.length; i++) {
            soulAmount += getTotalPower(burnIds[i]).div(10);
        }
        return soulAmount;
    }

    function mint(address minter, uint256 seed) public restricted {
        uint256 tokenID = tokens.length;

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        uint16 xp = 0;
        uint8 level = 0; // 1
        uint8 trait = uint8(RandomUtil.randomSeededMinMax(0,3,seed));
        uint64 staminaTimestamp = uint64(now.sub(getStaminaMaxWait()));

        tokens.push(Character(xp, level, trait, staminaTimestamp));
        cosmetics.push(CharacterCosmetics(0, RandomUtil.combineSeeds(seed, 1)));
        address receiver = minter;
        if(minter != address(0) && minter != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, minter) && balanceOf(minter) >= characterLimit) {
            receiver = address(garrison);
            garrison.redirectToGarrison(minter, tokenID);
            _mint(address(garrison), tokenID);
        }
        else {
            _mint(minter, tokenID);
        }
        emit NewCharacter(tokenID, receiver);
    }

    function customMint(address minter, uint16 xp, uint8 level, uint8 trait, uint256 seed, uint256 tokenID, uint24 bonusPower, uint16 reputation) minterOnly public returns (uint256) {
        uint64 staminaTimestamp = uint64(now); // 0 on purpose to avoid chain jumping abuse

        if(tokenID == 0){
            tokenID = tokens.length;

            if(block.number != lastMintedBlock)
                firstMintedOfLastBlock = tokenID;
            lastMintedBlock = block.number;

            tokens.push(Character(xp, level, trait, staminaTimestamp));
            cosmetics.push(CharacterCosmetics(0, RandomUtil.combineSeeds(seed, 1)));
            address receiver = minter;
            if(minter != address(0) && minter != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, minter) && balanceOf(minter) >= characterLimit) {
                receiver = address(garrison);
                garrison.redirectToGarrison(minter, tokenID);
                _mint(address(garrison), tokenID);
            }
            else {
                _mint(minter, tokenID);
            }
            emit NewCharacter(tokenID, receiver);
        }
        else {
            Character storage ch = tokens[tokenID];
            ch.xp = xp;
            ch.level = level;
            ch.trait = trait;
            ch.staminaTimestamp = staminaTimestamp;

            CharacterCosmetics storage cc = cosmetics[tokenID];
            cc.seed = seed;
        }

        nftVars[tokenID][NFTVAR_BONUS_POWER] = bonusPower;
        nftVars[tokenID][NFTVAR_REPUTATION] = reputation;

        return tokenID;
    }

    function burnIntoCharacter(uint256[] calldata burnIds, uint256 targetCharId, uint256 burnPowerMultiplier) external restricted {
        uint256 burnPower = 0;
        for(uint i = 0; i < burnIds.length; i++) {
            burnPower += nftVars[burnIds[i]][NFTVAR_BONUS_POWER].add(getPowerAtLevel(tokens[burnIds[i]].level));
            address burnOwner = ownerOf(burnIds[i]);
            if(burnOwner == address(garrison)) {
                burnOwner = garrison.characterOwner(burnIds[i]);
                garrison.updateOnBurn(burnOwner, burnIds[i]);
            }
            _burn(burnIds[i]);

            emit Burned(
                burnOwner,
                burnIds[i]
            );
        }
        require(uint(4).mul(getPowerAtLevel(tokens[targetCharId].level)) >= getTotalPower(targetCharId).add(burnPower), "Power limit");
        nftVars[targetCharId][NFTVAR_BONUS_POWER] = burnPower.mul(burnPowerMultiplier).div(1e18).add(nftVars[targetCharId][NFTVAR_BONUS_POWER]);
    }

    function burnIntoSoul(uint256[] calldata burnIds) external restricted {
        for(uint i = 0; i < burnIds.length; i++) {
            address burnOwner = ownerOf(burnIds[i]);
            if(burnOwner == address(garrison)) {
                burnOwner = garrison.characterOwner(burnIds[i]);
                garrison.updateOnBurn(burnOwner, burnIds[i]);
            }
            _burn(burnIds[i]);

            emit Burned(
                burnOwner,
                burnIds[i]
            );
        }
    }

    function upgradeWithSoul(uint256 targetCharId, uint256 soulAmount) external restricted {
        uint256 burnPower = soulAmount.mul(10);
        require(uint(4).mul(getPowerAtLevel(tokens[targetCharId].level)) >= getTotalPower(targetCharId).add(burnPower), "Power limit");
        nftVars[targetCharId][NFTVAR_BONUS_POWER] = burnPower.add(nftVars[targetCharId][NFTVAR_BONUS_POWER]);
    }

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].level; // this is used by dataminers and it benefits us
    }

    function getRequiredXpForNextLevel(uint8 currentLevel) public view returns (uint16) {
        return uint16(experienceTable[currentLevel]); // this is helpful to users as the array is private
    }

    function getPower(uint256 id) public view noFreshLookup(id) returns (uint24) {
        return getPowerAtLevel(tokens[id].level);
    }

    function getTotalPower(uint256 id) public view noFreshLookup(id) returns (uint256) {
        return nftVars[id][NFTVAR_BONUS_POWER].add(getPowerAtLevel(tokens[id].level));
    }

    function getPowerAtLevel(uint8 level) public pure returns (uint24) {
        return Common.getPowerAtLevel(level);
    }

    function getTrait(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].trait;
    }

    function setTrait(uint256 id, uint8 trait) public restricted {
        tokens[id].trait = trait;
    }

    function getXp(uint256 id) public view noFreshLookup(id) returns (uint32) {
        return tokens[id].xp;
    }

    function gainXp(uint256 id, uint16 xp) public restricted {
        _gainXp(id, xp);
    }

    function _gainXp(uint256 id, uint256 xp) internal {
        Character storage char = tokens[id];
        if (char.level < 255) {
            uint newXp = char.xp.add(xp);
            uint requiredToLevel = experienceTable[char.level]; // technically next level
            while (newXp >= requiredToLevel) {
                newXp = newXp - requiredToLevel;
                char.level += 1;
                emit LevelUp(ownerOf(id), id, char.level);
                if (char.level < 255)
                    requiredToLevel = experienceTable[char.level];
                else newXp = 0;
            }
            char.xp = uint16(newXp);
        }
    }

    function gainXpAll(uint256[] calldata chars, uint256[] calldata xps) external restricted {
        for(uint i = 0; i < chars.length; i++)
            _gainXp(chars[i], xps[i]);
    }

    function getStaminaTimestamp(uint256 id) public view noFreshLookup(id) returns (uint64) {
        return tokens[id].staminaTimestamp;
    }

    function setStaminaTimestamp(uint256 id, uint64 timestamp) public restricted {
        tokens[id].staminaTimestamp = timestamp;
    }

    function getStaminaPoints(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStaminaPointsFromTimestamp(tokens[id].staminaTimestamp);
    }

    function getStaminaPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerStamina;
        if(points > maxStamina) {
            points = maxStamina;
        }
        return uint8(points);
    }

    function isStaminaFull(uint256 id) public view noFreshLookup(id) returns (bool) {
        return getStaminaPoints(id) >= maxStamina;
    }

    function getStaminaMaxWait() public pure returns (uint64) {
        return uint64(maxStamina * secondsPerStamina);
    }

    function getFightDataAndDrainStamina(address fighter,
        uint256 id, uint8 amount, bool allowNegativeStamina, uint256 busyFlag) public restricted returns(uint96) {
        require(fighter == ownerOf(id) && nftVars[id][NFTVAR_BUSY] == 0);
        nftVars[id][NFTVAR_BUSY] |= busyFlag;

        Character storage char = tokens[id];
        uint8 staminaPoints = getStaminaPointsFromTimestamp(char.staminaTimestamp);
        require((staminaPoints > 0 && allowNegativeStamina) // we allow going into negative, but not starting negative
            || staminaPoints >= amount, "Not enough stamina!");

        uint64 drainTime = uint64(amount * secondsPerStamina);
        uint64 preTimestamp = char.staminaTimestamp;
        if(staminaPoints >= maxStamina) { // if stamina full, we reset timestamp and drain from that
            char.staminaTimestamp = uint64(now - getStaminaMaxWait() + drainTime);
        }
        else {
            char.staminaTimestamp = uint64(char.staminaTimestamp + drainTime);
        }
        // bitwise magic to avoid stacking limitations later on
        return uint96(char.trait | (getTotalPower(id) << 8) | (preTimestamp << 32));
    }

    function processRaidParticipation(uint256 id, bool won, uint16 xp) public restricted {
        raidsDone[id] = raidsDone[id] + 1;
        raidsWon[id] = won ? (raidsWon[id] + 1) : (raidsWon[id]);
        require(nftVars[id][NFTVAR_BUSY] == 0); // raids do not apply busy flag for now
        //nftVars[id][NFTVAR_BUSY] = 0;
        _gainXp(id, xp);
        if (getNftVar(id, NFTVAR_SIMPLEQUEST_TYPE) == SIMPLEQUEST_TYPE_RAID) {
            uint currentProgress = getNftVar(id, NFTVAR_SIMPLEQUEST_PROGRESS);
            setNftVar(id, NFTVAR_SIMPLEQUEST_PROGRESS, ++currentProgress);
        }
    }

    function getCharactersOwnedBy(address wallet) public view returns(uint256[] memory chars) {
        uint256 count = balanceOf(wallet);
        chars = new uint256[](count);
        for(uint256 i = 0; i < count; i++)
            chars[i] = tokenOfOwnerByIndex(wallet, i);
    }

    function getReadyCharacters(address wallet) public view returns(uint256[] memory chars) {
        uint256[] memory owned = getCharactersOwnedBy(wallet);
        uint256 ready = 0;
        for(uint i = 0; i < owned.length; i++)
            if(nftVars[owned[i]][NFTVAR_BUSY] == 0)
                ready++;
        chars = new uint[](ready);
        for(uint i = 0; i < owned.length; i++)
            if(nftVars[owned[i]][NFTVAR_BUSY] == 0)
                chars[--ready] = owned[i];
    }

    function setNFTVars(uint256 id, uint256[] memory fields, uint256[] memory values) public restricted {
        for(uint i = 0; i < fields.length; i++)
            nftVars[id][fields[i]] = values[i];
    }

    function getNFTVars(uint256 id, uint256[] memory fields) public view returns(uint256[] memory values) {
        values = new uint256[](fields.length);
        for(uint i = 0; i < fields.length; i++)
            values[i] = nftVars[id][fields[i]];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(nftVars[tokenId][NFTVAR_BUSY] == 0);
        address[] memory users = new address[](2);
        users[0] = from;
        users[1] = to;
        promos.setBits(users, BIT_FIRST_CHARACTER);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) override public {
        if(to != address(0) && to != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, to) && balanceOf(to) >= characterLimit) {
            garrison.redirectToGarrison(to, tokenId);
            super.safeTransferFrom(from, address(garrison), tokenId);
        }
        else {
            super.safeTransferFrom(from, to, tokenId);
        }
    }

    function setCharacterLimit(uint256 max) public restricted {
        characterLimit = max;
    }

    function getNftVar(uint256 characterID, uint256 nftVar) public view returns(uint256) {
        return nftVars[characterID][nftVar];
    }
    function setNftVar(uint256 characterID, uint256 nftVar, uint256 value) public restricted {
        nftVars[characterID][nftVar] = value;
    }
}
