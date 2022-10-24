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

    uint256 public constant USERVAR_ = 10001;

    // Misc

    uint256 public constant SLOT_CHARACTER_WEAPON = 1;
    uint256 public constant SLOT_CHARACTER_SHIELD = 2;

    //////////
    // GENERAL
    //////////

    event Equipped(address indexed onAddr, uint256 indexed onID, uint256 indexed slot, address itemAddr, uint256 itemID);
    event Unequipped(address indexed onAddr, uint256 indexed onID, uint256 indexed slot, address itemAddr, uint256 itemID);
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

        equippedSlotAddress[onAddr][onID][slot] = itemAddr;
        equippedSlotID[onAddr][onID][slot] = itemID;
        processEquippedItem(onAddr, onID, slot, itemAddr, itemID);
        IERC721(itemAddr).safeTransferFrom(msg.sender, address(this), itemID);

        recalculate(onAddr, onID);
    }

    function unequipNFT(address onAddr, uint256 onID, uint256 slot) external {
        require(IERC721(onAddr).ownerOf(onID) == msg.sender);//item owner check done on transfer

        IERC721(equippedSlotAddress[onAddr][onID][slot])
            .safeTransferFrom(address(this), msg.sender, equippedSlotID[onAddr][onID][slot]);

        equippedSlotAddress[onAddr][onID][slot] = address(0);
        equippedSlotID[onAddr][onID][slot] = 0;

        recalculate(onAddr, onID);
    }

    function recalculate(address onAddr, uint256 onID) public {
        // will use proxy later, for now we assume all items use the manager directly for chars
        if(onAddr == links[LINK_CHARACTERS])
            calculateCharacterVars(onID);
        else
            revert("Not implemented");
    }

    function processEquippedItem(address onAddr, uint256 onID, uint256 slot, address itemAddr, uint256 itemID) internal {
        if(itemAddr == links[LINK_WEAPONS]) {
            Weapons weapons = Weapons(links[LINK_WEAPONS]);
            weapons.drainDurability(itemID, vars[VAR_WEAPON_EQUIP_DURABILITY], false);
        }
    }

    function calculateCharacterVars(uint256 onID) internal {
        Characters characters = Characters(links[LINK_CHARACTERS]);
        Weapons weapons = Weapons(links[LINK_WEAPONS]);
        require(characters.getNftVar(characterID, 1) == 0, "Busy");

        if(equippedSlotAddress[characters][onID][SLOT_CHARACTER_WEAPON] != 0) {
            // assume weapon slot is using weapon address for now, will revert anyway if not
            uint8 charTrait = charcters.getTrait(onID);
            (int128 weaponMultTarget,
                int128 weaponMultFight,
                uint24 weaponBonusPower,
                uint8 weaponTrait) = weapons.getFightData(equippedSlotID[characters][onID][SLOT_CHARACTER_WEAPON],
                                        charTrait);
            
            uint256 basePower// WIP

            characters.setNFTVars(
                [4/*equipment version*/, ],
                [characters.vars(1/*equip version*/), ]
            );
        }
        else {
            // no weapon equipped, we null out the equipment version
            characters.setNFTVar(4/*nft equipment version*/, 0);
        }
    }

    // Read-only

    function isEquippable(address onAddr, uint256 slot, address itemAddr) public returns (bool) {
        return equippableInSlot[onAddr][slot].contains(itemAddr);
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