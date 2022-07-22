pragma solidity ^0.6.2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./util.sol";
import "./characters.sol";
import "./weapons.sol";
import "./shields.sol";

contract EquipmentManager is Initializable, ReentrancyGuard, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    // STATE
    Characters public characters;
    Weapons public weapons;
    Shields public shields;

    EnumerableSet.AddressSet private allowedNFTs;

    mapping(IERC721 => uint256) nftSlots; // 0 = weapon, 1 = shield
    mapping(uint256 => mapping(uint256 => uint256[])) public charEquipments;
    mapping(uint256 => uint24) public charPower;
    mapping(IERC721 => uint256) public maxSlots;

    event ItemEquipped(address indexed owner, uint256 characterId, IERC721 nftAddress, uint256 nftId);
    event ItemUnequipped(address indexed owner, uint256 characterId, IERC721 nftAddress, uint256 nftId);

    function initialize(Characters _characters, Weapons _weapons, Shields _shields)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        characters = _characters;
        weapons = _weapons;
        shields = _shields;

        _registerNftAddress(IERC721(address(weapons)));
        _registerNftAddress(IERC721(address(shields)));
    }

    // MODIFIERS

    modifier isCharacterOwner(uint256 characterId) {
        _isCharacterOwner(characterId);
        _;
    }

    modifier isNftOwner(IERC721 nftAddress, uint256 nftId) {
        _isNftOwner(nftAddress, nftId);
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    // PRIVATE FUNCTIONS

    function _isCharacterOwner(uint256 characterId) private view {
        require(characters.ownerOf(characterId) == msg.sender, 'Not owner');
    }

    function _isNftOwner(IERC721 nftAddress, uint256 nftId) private view {
        require(nftAddress.ownerOf(nftId) == msg.sender, 'Not nft owner');
    }

    function _restricted() private view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    function _registerNftAddress(IERC721 nftAddress) private {
        if (!allowedNFTs.contains(address(nftAddress))) {
            nftSlots[nftAddress] = allowedNFTs.length();
            allowedNFTs.add(address(nftAddress));
        }
    }

    function _unregisterNftAddress(IERC721 nftAddress) private {
        if (allowedNFTs.contains(address(nftAddress))) {
            allowedNFTs.remove(address(nftAddress));
        }
    }

    function _getShieldStats(uint256 characterId, uint256 shieldId) private view returns (int128) {
        uint8 trait = characters.getTrait(characterId);
        int128 shieldMultFight = shields.getDefenseMultiplierForTrait(shieldId, trait);
        return (shieldMultFight);
    }

    // VIEWS

    function characterEquipmentIds(IERC721 nftAddress, uint256 characterId) public view returns (uint256[] memory) {
        uint256 nftSlot = nftSlots[nftAddress];
        return charEquipments[characterId][nftSlot];
    }

    function getAllowedNFTs() public view returns (IERC721[] memory) {
        EnumerableSet.AddressSet storage set = allowedNFTs;
        IERC721[] memory nfts = new IERC721[](set.length());

        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = IERC721(set.at(i));
        }
        return nfts;
    }

    function calculatePower(uint256 characterId) public view returns (uint24) {
        uint256 weaponId;
        uint256 shieldId;
        int128 bonusShieldStats = 0;
        uint24 power = 0;
        if (characterEquipmentIds(IERC721(address(weapons)), characterId).length > 0) {
            weaponId = characterEquipmentIds(IERC721(address(weapons)), characterId)[0];
            if (characterEquipmentIds(IERC721(address(shields)), characterId).length > 0) {
                shieldId = characterEquipmentIds(IERC721(address(shields)), characterId)[0];
                bonusShieldStats = _getShieldStats(characterId, shieldId).sub(1).mul(20).div(100);
            }
            int128 weaponMult = weapons.getPowerMultiplierForTrait(
                    weapons.getProperties(weaponId),
                    weapons.getStat1(weaponId),
                    weapons.getStat2(weaponId),
                    weapons.getStat3(weaponId),
                    characters.getTrait(characterId)
                );
            power = Common.getPlayerPowerBase100(
                    Common.getPowerAtLevel(characters.getLevel(characterId)),
                    (weaponMult.add(bonusShieldStats)),
                    weapons.getBonusPower(weaponId)
                );
        }
        return power;
    }

    // PUBLIC FUNCTIONS

    function setEquipment(IERC721 nftAddress, uint256 characterId, uint256 nftId) external nonReentrant isCharacterOwner(characterId) isNftOwner(nftAddress, nftId) {
        require(address(characters) != address(nftAddress), 'CEC'); // can't equip character
        uint256 nftSlot = nftSlots[nftAddress];
        uint256 nftCount = charEquipments[characterId][nftSlot].length;
        require(nftCount <= maxSlots[nftAddress], 'MCR'); // max nft count reached
        if (address(weapons) == address(nftAddress) || address(shields) == address(nftAddress)) {
            if (address(weapons) == address(nftAddress)) {
                require(weapons.getNftVar(nftId, weapons.NFTVAR_BUSY()) == 0, 'WIB'); // weapon is busy
                weapons.setNftVar(nftId, weapons.NFTVAR_BUSY(), 3);
            } else {
                require(shields.getNftVar(nftId, shields.NFTVAR_BUSY()) == 0, 'SIB'); // shield is busy
                shields.setNftVar(nftId, shields.NFTVAR_BUSY(), 3);
            }
        } else {
            nftAddress.safeTransferFrom(msg.sender, address(this), nftId);
        }
        charEquipments[characterId][nftSlot].push(nftId);
        charPower[characterId] = calculatePower(characterId);
        emit ItemEquipped(msg.sender, characterId, nftAddress, nftId);
    }

    function removeEquipment(IERC721 nftAddress, uint256 characterId, uint256 nftId) external nonReentrant isCharacterOwner(characterId)  {
        require(address(characters) != address(nftAddress), 'CRC'); // can't remove character
        uint256 nftSlot = nftSlots[nftAddress];
        require(Common.numArrayIncludes(charEquipments[characterId][nftSlot], nftId), 'NNE'); // nft not equipped
        if (address(weapons) == address(nftAddress) || address(shields) == address(nftAddress)) {
            if (address(weapons) == address(nftAddress)) {
                require(weapons.getNftVar(nftId, weapons.NFTVAR_BUSY()) != 0, 'WNB'); // weapon is not busy
                weapons.setNftVar(nftId, weapons.NFTVAR_BUSY(), 0);
            } else {
                require(shields.getNftVar(nftId, shields.NFTVAR_BUSY()) != 0, 'SNB'); // shield is not busy
                shields.setNftVar(nftId, shields.NFTVAR_BUSY(), 0);
            }
        } else {
            nftAddress.safeTransferFrom(address(this), msg.sender, nftId);
        }
        charEquipments[characterId][nftSlot] = Common.numArraySplice(charEquipments[characterId][nftSlot], nftId);
        charPower[characterId] = calculatePower(characterId);
        emit ItemUnequipped(msg.sender, characterId, nftAddress, nftId);
    }

    function setSlotMaxCount(IERC721 nftAddress, uint256 value) external restricted {
        require(value > 0, 'VMZ'); // value must be more than zero
        maxSlots[nftAddress] = value;
    }

    function registerNFTAddress(IERC721 nftAddress) external restricted {
        require(
            address(nftAddress) != address(characters) &&
            address(nftAddress) != address(weapons) &&
            address(nftAddress) != address(shields)
        , 'CRC'); // cant register cryptoblades nft
        _registerNftAddress(nftAddress);
    }

    function unRegisterNFTAddress(IERC721 nftAddress) external restricted {
        require(
            address(nftAddress) != address(characters) &&
            address(nftAddress) != address(weapons) &&
            address(nftAddress) != address(shields)
        , 'CUC'); // cant unregister cryptoblades nft
        _unregisterNftAddress(nftAddress);
    }
}
