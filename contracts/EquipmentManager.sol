pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./characters.sol";
import "./weapons.sol";
import "./shields.sol";
import "./util.sol";

contract EquipmentManager is Initializable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    ////////////
    // CONSTANTS
    ////////////

    // Permissions

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    // Contract Vars

    uint256 public constant VAR_WEAPON_EQUIP_DURABILITY = 101;

    // Contract links

    uint256 public constant LINK_CHARACTERS = 1;
    uint256 public constant LINK_WEAPONS = 2;
    uint256 public constant LINK_SHIELDS = 3;

    // User vars

    //uint256 public constant USERVAR_ = 10001;

    // NFT vars

    uint256 public constant NFTVAR_EQUIPPED_SLOTS = 1;//each bit corresponding to its slot

    // Misc

    uint256 public constant SLOT_CHARACTER_WEAPON = 1;
    uint256 public constant SLOT_CHARACTER_SHIELD = 2;


    //////////
    // GENERAL
    //////////
    struct PowerData {
        uint256 onID;
        uint256 souledPower;
        uint256 pvpPower;
        uint256 ffaPower;
        int128 weaponMultBase;
        int128 weaponMultFight;
        uint24 souledBasePower;
        uint24 weaponBonusPower;
        uint8 level;
        uint8 charTrait;
        uint8 weaponTrait;
        uint8 shieldTrait;
    }

    event Equipped(address indexed onAddr, uint256 indexed onID, uint256 indexed slot, address itemAddr, uint256 itemID);
    event Unequipped(address indexed onAddr, uint256 indexed onID, uint256 indexed slot);
    event Recalculated(address indexed onAddr, uint256 indexed onID, uint256 indexed calculationID);

    function initialize () public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NA");
    }


    //////////////////
    // STATE VARIABLES
    //////////////////

    mapping(uint256 => uint256) public vars;
    mapping(uint256 => address) public links;
    mapping(address => mapping(uint256 => uint256)) public userVars;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public nftVars;//contract>id>field>value

    // equipper address, ID, slot, equipped item address
    mapping(address => mapping(uint256 => mapping(uint256 => address))) public equippedSlotAddress;
    // equipper address, ID, slot, equipped item ID(/amount?)
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public equippedSlotID;

    // equipper address, calculation identifier (future use), proxy address (default = this)
    mapping(address => mapping(uint256 => address)) calculatorProxy;
    // equipper address, slot, set of addresses supported
    mapping(address => mapping(uint256 => EnumerableSet.AddressSet)) private equippableInSlot;


    ////////////
    // FUNCTIONS
    ////////////

    // Mutative

    function equipNFT(address onAddr, uint256 onID, uint256 slot, address itemAddr, uint256 itemID) external {
        require(isEquippable(onAddr, slot, itemAddr), "Invalid item");
        require(IERC721(onAddr).ownerOf(onID) == msg.sender);//item owner check done on transfer
        require(equippedSlotAddress[onAddr][onID][slot] != address(0), "Slot taken");

        equippedSlotAddress[onAddr][onID][slot] = itemAddr;
        equippedSlotID[onAddr][onID][slot] = itemID;
        nftVars[onAddr][onID][NFTVAR_EQUIPPED_SLOTS] |= (0x1 << slot);//turn slot bit on

        processEquippedItem(onAddr, onID, slot, itemAddr, itemID);
        IERC721(itemAddr).transferFrom(msg.sender, address(this), itemID);

        recalculate(onAddr, onID);
        emit Equipped(onAddr, onID, slot, itemAddr, itemID);
    }

    function unequipNFT(address onAddr, uint256 onID, uint256 slot) external {
        require(IERC721(onAddr).ownerOf(onID) == msg.sender);

        IERC721(equippedSlotAddress[onAddr][onID][slot])
            .transferFrom(address(this), msg.sender, equippedSlotID[onAddr][onID][slot]);

        equippedSlotAddress[onAddr][onID][slot] = address(0);
        equippedSlotID[onAddr][onID][slot] = 0;
        nftVars[onAddr][onID][NFTVAR_EQUIPPED_SLOTS] &= ~(0x1 << slot);//turns the slot bit off

        recalculate(onAddr, onID);
        emit Unequipped(onAddr, onID, slot);
    }

    function recalculate(address onAddr, uint256 onID) public {
        // will use proxy later, for now we assume all items use the manager directly for chars
        if(onAddr == links[LINK_CHARACTERS])
            calculateCharacterVars(onID);
        else
            revert("Not implemented");
        emit Recalculated(onAddr, onID, 0);
    }

    function processEquippedItem(address onAddr, uint256 onID, uint256 slot, address itemAddr, uint256 itemID) internal {
        if(itemAddr == links[LINK_WEAPONS]) {
            Weapons weapons = Weapons(links[LINK_WEAPONS]);
            // Limit sharing by draining durability on equip
            weapons.drainDurability(itemID, uint8(vars[VAR_WEAPON_EQUIP_DURABILITY]), false);
        }
    }

    // Would-be proxy functions

    function calculateCharacterVars(uint256 onID) internal {
        Characters characters = Characters(links[LINK_CHARACTERS]);
        require(characters.getNftVar(onID, 1) == 0, "Busy");//don't let them switcharoo while in arena etc

        // equipped weapon is required for anything to be calculated
        if(_hasSlotEquipped(LINK_CHARACTERS, onID, SLOT_CHARACTER_WEAPON)) {
            uint256[] memory fields = new uint256[](2);
            fields[0] = 4;
            fields[1] = 5;
            uint256[] memory values = new uint256[](2);
            values[0] = characters.vars(1/*equip version*/);
            values[1] = getPowerData(onID);
        
            characters.setNFTVars(onID, fields, values );
        }
        else {
            // no weapon equipped, we null out the equipment version
            characters.setNftVar(onID, 4/*nft equipment version*/, 0);
        }
    }

    function getPowerData(uint256 onID) public view returns (uint256) {
        // May be called from frontend to check if a refresh is required/advised
        // Compare with characters.getNftVar(NFTVAR_POWER_DATA)

        Characters characters = Characters(links[LINK_CHARACTERS]);
        // Some values are set later
        PowerData memory pd = PowerData(
            onID,
            0,0,0,0,0,//souledPower,pvpPower,ffaPower,weaponMultBase,weaponMultFight
            uint24(characters.getTotalPower(onID)),//souledBasePower
            0,//weaponBonusPower
            characters.getLevel(onID),
            characters.getTrait(onID),
            0,0//weaponTrait, shieldTrait
        );

        // assume weapon slot is using weapon address for now, will revert anyway if not
        (int128 weaponMultBase, // does not contain stat trait benefits
            int128 weaponMultFight, // contains stat benefits (not wep-char trait match yet though!)
            uint24 weaponBonusPower,
            uint8 weaponTrait) = Weapons(links[LINK_WEAPONS])
                .getFightData(equippedSlotID[links[LINK_CHARACTERS]][onID][SLOT_CHARACTER_WEAPON],
                                    pd.charTrait);
        pd.weaponMultBase = weaponMultBase;
        pd.weaponMultFight = weaponMultFight;
        pd.weaponBonusPower = weaponBonusPower;
        pd.weaponTrait = weaponTrait;
        pd.souledPower = Common.getPlayerPower(pd.souledBasePower, pd.weaponMultFight, pd.weaponBonusPower);
        cachePvpData(pd);
        return getPvePowerData(pd) | getPvpPowerData(pd);
    }

    function getPvePowerData(PowerData memory pd) internal pure returns(uint256) {
        // pve, 24 bits each
        return (getPveTraitBonus(pd.charTrait, pd.weaponTrait, 0).mulu(pd.souledPower) & 0xFFFFFF)//v fire
            | ((getPveTraitBonus(pd.charTrait, pd.weaponTrait, 1).mulu(pd.souledPower) & 0xFFFFFF) << 24)//v earth
            | ((getPveTraitBonus(pd.charTrait, pd.weaponTrait, 2).mulu(pd.souledPower) & 0xFFFFFF) << 48)//v lightning
            | ((getPveTraitBonus(pd.charTrait, pd.weaponTrait, 3).mulu(pd.souledPower) & 0xFFFFFF) << 72)//v water
            | (uint256(Common.getPlayerPower(pd.souledBasePower, pd.weaponMultBase, pd.weaponBonusPower)) << 96)//base(target)
            // some extra info to save on calls, if necessary
            | (uint256(pd.level) << 232)
            | (uint256(pd.charTrait) << 240)
            | (uint256(pd.weaponTrait) << 242)
        ;
    }

    function cachePvpData(PowerData memory pd) internal view returns (PowerData memory) {
        Shields shields = Shields(links[LINK_SHIELDS]);
        int128 shieldMult = 0;
        uint8 shieldTrait = 4; // signifies no shield
        if(_hasSlotEquipped(LINK_CHARACTERS, pd.onID, SLOT_CHARACTER_SHIELD)) {
            shieldMult = shields.getDefenseMultiplierForTrait(
                equippedSlotID[links[LINK_CHARACTERS]][pd.onID][SLOT_CHARACTER_SHIELD],
                pd.charTrait)
                .sub(mathOneFrac()).mul(2).div(10); // 20% multiplier contribution vs weapons
            shieldTrait = shields.getTrait(equippedSlotID[links[LINK_CHARACTERS]][pd.onID][SLOT_CHARACTER_SHIELD]);
        }

        pd.pvpPower = Common.getPlayerPowerBase100(Common.getPowerAtLevel(pd.level),
            pd.weaponMultFight.add(shieldMult), pd.weaponBonusPower);
        pd.ffaPower = Common.getPlayerPowerBase100(Common.getPowerAtLevel(34),
            pd.weaponMultFight.add(shieldMult), pd.weaponBonusPower);
        pd.shieldTrait = shieldTrait == 4 ? 0 : shieldTrait;
        return pd;
    }

    function getPvpPowerData(PowerData memory pd) internal pure returns (uint256) {
        //pvp, 14 bits each, tiered
        return ((getPvpTraitBonus(pd.charTrait, pd.weaponTrait, pd.shieldTrait, 0).mulu(pd.pvpPower) & 0x3FFF) << 120)//v fire
            | ((getPvpTraitBonus(pd.charTrait, pd.weaponTrait, pd.shieldTrait, 1).mulu(pd.pvpPower) & 0x3FFF) << 134)//v earth
            | ((getPvpTraitBonus(pd.charTrait, pd.weaponTrait, pd.shieldTrait, 2).mulu(pd.pvpPower) & 0x3FFF) << 148)//v lightning
            | ((getPvpTraitBonus(pd.charTrait, pd.weaponTrait, pd.shieldTrait, 3).mulu(pd.pvpPower) & 0x3FFF) << 162)//v water
            // pvp, 14 bits each, ffa
            | ((getPvpTraitBonus(pd.charTrait, pd.weaponTrait, pd.shieldTrait, 0).mulu(pd.ffaPower) & 0x3FFF) << 176)//v fire
            | ((getPvpTraitBonus(pd.charTrait, pd.weaponTrait, pd.shieldTrait, 1).mulu(pd.ffaPower) & 0x3FFF) << 190)//v earth
            | ((getPvpTraitBonus(pd.charTrait, pd.weaponTrait, pd.shieldTrait, 2).mulu(pd.ffaPower) & 0x3FFF) << 204)//v lightning
            | ((getPvpTraitBonus(pd.charTrait, pd.weaponTrait, pd.shieldTrait, 3).mulu(pd.ffaPower) & 0x3FFF) << 218)//v water
            
            | (uint256(pd.shieldTrait) << 244);
    }

    function getPveTraitBonus(uint8 char, uint8 wep, uint8 enemy) internal pure returns (int128) {
        int128 traitBonus = mathOneFrac();
        if(char == wep)
            traitBonus = traitBonus.add(mathTraitBonus());
        
        if(Common.isTraitEffectiveAgainst(char, enemy))
            traitBonus = traitBonus.add(mathTraitBonus());
        else if(Common.isTraitEffectiveAgainst(enemy, char))
            traitBonus = traitBonus.sub(mathTraitBonus());
        
        return traitBonus;
    }

    function getPvpTraitBonus(uint8 char, uint8 wep, uint8 shield, uint8 enemy) internal pure returns (int128) {
        int128 traitBonus = getPveTraitBonus(char, wep, enemy);
        if(char == wep)
            traitBonus = traitBonus.add(mathTraitBonus().mul(2));//for a total of 3x weapon trait boost

        //4 or higher means no shield
        if(shield < 4) {
            if(Common.isTraitEffectiveAgainst(shield, enemy))
                traitBonus = traitBonus.mul(11).div(10); //+10% power for shield vs enemy
            else
                traitBonus = traitBonus.mul(103).div(100); //+3% power just for having a shield
        }
        
        return traitBonus;
    }

    function getPowerData(uint256 charID) external view returns (
        uint24[5] memory pvePower,
        uint16[4] memory pvpTierPower,
        uint16[4] memory pvpFfaPower,
        uint8 level,
        uint8 charTrait,
        uint8 wepTrait,
        uint8 shieldTrait,
        uint256 powerData
        ) {
        powerData = Characters(links[LINK_CHARACTERS]).getNftVar(charID, 5);

        pvePower[0] = uint24(powerData & 0xFFFFFF);
        pvePower[1] = uint24((powerData >> 24) & 0xFFFFFF);
        pvePower[2] = uint24((powerData >> 48) & 0xFFFFFF);
        pvePower[3] = uint24((powerData >> 72) & 0xFFFFFF);
        pvePower[4] = uint24((powerData >> 96) & 0xFFFFFF);

        pvpTierPower[0] = uint16((powerData >> 120) & 0x3FFF);
        pvpTierPower[1] = uint16((powerData >> 134) & 0x3FFF);
        pvpTierPower[2] = uint16((powerData >> 148) & 0x3FFF);
        pvpTierPower[3] = uint16((powerData >> 162) & 0x3FFF);
        
        pvpFfaPower[0] = uint16((powerData >> 176) & 0x3FFF);
        pvpFfaPower[1] = uint16((powerData >> 190) & 0x3FFF);
        pvpFfaPower[2] = uint16((powerData >> 204) & 0x3FFF);
        pvpFfaPower[3] = uint16((powerData >> 218) & 0x3FFF);

        level = uint8((powerData >> 232) & 0xFF);
        charTrait = uint8((powerData >> 240) & 0x3);
        wepTrait = uint8((powerData >> 242) & 0x3);
        shieldTrait = uint8((powerData >> 244) & 0x3);
    }

    function getPowerDataBytes(uint charID) external view returns (uint8[32] memory data) {
        uint256 powerData = Characters(links[LINK_CHARACTERS]).getNftVar(charID, 5);
        for(uint i = 0; i < 32; i++) {
            data[i] = uint8(powerData >> i*8);
        }
    }

    // Read-only

    function isEquippable(address onAddr, uint256 slot, address itemAddr) public view returns (bool) {
        return equippableInSlot[onAddr][slot].contains(itemAddr);
    }

    function getEquippedItem(address onAddr, uint256 slot) public view returns(address, uint256) {
        return (equippedSlotAddress[onAddr][onID][slot], equippedSlotID[onAddr][onID][slot]);
    }

    function _hasSlotEquipped(uint256 link, uint256 onID, uint256 slot) internal view returns (bool) {
        return equippedSlotAddress[links[link]][onID][slot] != address(0);
    }

    function hasSlotEquipped(address onAddr, uint256 onID, uint256 slot) public view returns (bool) {
        return equippedSlotAddress[onAddr][onID][slot] != address(0);
    }

    function mathOneFrac() internal pure returns (int128) {
        return ABDKMath64x64.fromUInt(1);
    }

    function mathTraitBonus() internal pure returns (int128) {
        return ABDKMath64x64.divu(75, 1000);
    }

    // Admin

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for(uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    function getNftVar(address onAddr, uint256 onID, uint256 nftVar) public view returns(uint256) {
        return nftVars[onAddr][onID][nftVar];
    }
    function setNftVar(address onAddr, uint256 onID, uint256 nftVar, uint256 value) public restricted {
        nftVars[onAddr][onID][nftVar] = value;
    }

    function setLink(uint256 linkId, address linkAddress) external restricted {
        links[linkId] = linkAddress;
    }

    function setEquippable(address onAddr, uint256 slot, address itemAddr, bool equippable) external restricted {
        if(equippable)
            equippableInSlot[onAddr][slot].add(itemAddr);
        else
            equippableInSlot[onAddr][slot].remove(itemAddr);
    }

}