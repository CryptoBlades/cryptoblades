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
            weapons.drainDurability(itemID, uint8(vars[VAR_WEAPON_EQUIP_DURABILITY]), false);
        }
    }

    function calculateCharacterVars(uint256 onID) internal {
        Characters characters = Characters(links[LINK_CHARACTERS]);
        require(characters.getNftVar(onID, 1) == 0, "Busy");

        // equipped weapon is required for anything to be calculated
        if(hasSlotEquipped(LINK_CHARACTERS, onID, SLOT_CHARACTER_WEAPON)) {
            // assume weapon slot is using weapon address for now, will revert anyway if not
            
            uint256 powerData = getPowerData(onID);

            uint256[] memory fields = new uint256[](2);
            fields[0] = 4;
            fields[1] = 5;
            uint256[] memory values = new uint256[](2);
            values[0] = characters.vars(1/*equip version*/);
            values[1] = powerData;
        
            characters.setNFTVars(onID, fields, values );
        }
        else {
            // no weapon equipped, we null out the equipment version
            characters.setNftVar(onID, 4/*nft equipment version*/, 0);
        }
    }

    function getPowerData(uint256 onID) internal view returns (uint256) {
        Characters characters = Characters(links[LINK_CHARACTERS]);
        uint8 charTrait = characters.getTrait(onID);
        (int128 weaponMultBase, // does not contain stat trait benefits
            int128 weaponMultFight, // contains stat benefits (not wep-char trait match yet though!)
            uint24 weaponBonusPower,
            uint8 weaponTrait) = Weapons(links[LINK_WEAPONS])
                .getFightData(equippedSlotID[links[LINK_CHARACTERS]][onID][SLOT_CHARACTER_WEAPON],
                                    charTrait);
        
        uint24 souledBasePower = uint24(characters.getTotalPower(onID));
        uint256 souledPower = Common.getPlayerPower(souledBasePower, weaponMultFight, weaponBonusPower);
        // pve, 24 bits each
        return (getPveTraitBonus(charTrait, weaponTrait, 0).mulu(souledPower))//v fire
            | (getPveTraitBonus(charTrait, weaponTrait, 1).mulu(souledPower) << 24)//v earth
            | (getPveTraitBonus(charTrait, weaponTrait, 2).mulu(souledPower) << 48)//v lightning
            | (getPveTraitBonus(charTrait, weaponTrait, 3).mulu(souledPower) << 72)//v water
            | (Common.getPlayerPower(souledBasePower, weaponMultBase, weaponBonusPower) << 96)//base(target)

            | getPvpPowerData(onID, charTrait, weaponTrait, weaponMultFight, weaponBonusPower)
            
            //extra info in case the calling feature uses them (lvl, traits)
            | (uint256(charTrait) << 240)
            | (uint256(weaponTrait) << 242)
        ;
    }

    function getPvpPowerData(uint256 onID, uint8 charTrait, uint8 weaponTrait,
        int128 weaponMultFight, uint24 weaponBonusPower
    ) internal view returns (uint256) {
        Characters characters = Characters(links[LINK_CHARACTERS]);
        Shields shields = Shields(links[LINK_SHIELDS]);
        int128 shieldMult = 0;
        uint8 shieldTrait = 4; // signifies no shield
        if(hasSlotEquipped(LINK_CHARACTERS, onID, SLOT_CHARACTER_SHIELD)) {
            shieldMult = shields.getDefenseMultiplierForTrait(equippedSlotID[links[LINK_CHARACTERS]][onID][SLOT_CHARACTER_SHIELD], charTrait)
                .sub(mathOneFrac()).mul(2).div(10); // 20% multiplier contribution vs weapons
            shieldTrait = shields.getTrait(equippedSlotID[links[LINK_CHARACTERS]][onID][SLOT_CHARACTER_SHIELD]);
        }

        uint8 level = characters.getLevel(onID);
        uint256 pvpPower = Common.getPlayerPowerBase100(characters.getPowerAtLevel(level), weaponMultFight, weaponBonusPower);
        uint256 ffaPower = Common.getPlayerPowerBase100(characters.getPowerAtLevel(34), weaponMultFight, weaponBonusPower);

        //pvp, 14 bits each, tiered
        return (getPvpTraitBonus(charTrait, weaponTrait, shieldTrait, 0).mulu(pvpPower) << 120)//v fire
            | (getPvpTraitBonus(charTrait, weaponTrait, shieldTrait, 1).mulu(pvpPower) << 134)//v earth
            | (getPvpTraitBonus(charTrait, weaponTrait, shieldTrait, 2).mulu(pvpPower) << 148)//v lightning
            | (getPvpTraitBonus(charTrait, weaponTrait, shieldTrait, 3).mulu(pvpPower) << 162)//v water
            // pvp, 14 bits each, ffa
            | (getPvpTraitBonus(charTrait, weaponTrait, shieldTrait, 0).mulu(ffaPower) << 176)//v fire
            | (getPvpTraitBonus(charTrait, weaponTrait, shieldTrait, 1).mulu(ffaPower) << 190)//v earth
            | (getPvpTraitBonus(charTrait, weaponTrait, shieldTrait, 2).mulu(ffaPower) << 204)//v lightning
            | (getPvpTraitBonus(charTrait, weaponTrait, shieldTrait, 3).mulu(ffaPower) << 218)//v water
            
            | (uint256(level) << 232)
            | (uint256(shieldTrait) << 244);
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

    function getPowerDataDebug(uint256 charID) external view returns (
        uint24[5] memory pvePower,
        /*uint24 firePower,
        uint24 earthPower,
        uint24 lightningPower,
        uint24 waterPower,
        uint24 basePower,*/

        uint16[4] memory pvpTierPower,
        /*uint16 fireTierPower,
        uint16 earthTierPower,
        uint16 lightningTierPower,
        uint16 waterTierPower,*/

        uint16[4] memory pvpFfaPower,
        /*uint16 fireFFAPower,
        uint16 earthFFAPower,
        uint16 lightningFFAPower,
        uint16 waterFFAPower,*/

        uint8 level,
        uint8 charTrait,
        uint8 wepTrait,
        uint8 shieldTrait
        ) {
        uint256 powerData = Characters(links[LINK_CHARACTERS]).getNftVar(charID, 5);
        //pvePower = new uint24[](5);
        pvePower[0] = uint24(powerData & 0xFFFFFF);
        pvePower[1] = uint24((powerData >> 24) & 0xFFFFFF);
        pvePower[2] = uint24((powerData >> 48) & 0xFFFFFF);
        pvePower[3] = uint24((powerData >> 72) & 0xFFFFFF);
        pvePower[4] = uint24((powerData >> 96) & 0xFFFFFF);
        /*firePower = uint24(powerData & 0xFFFFFF);
        earthPower = uint24((powerData >> 24) & 0xFFFFFF);
        lightningPower = uint24((powerData >> 48) & 0xFFFFFF);
        waterPower = uint24((powerData >> 72) & 0xFFFFFF);
        basePower = uint24((powerData >> 96) & 0xFFFFFF);*/

        //pvpTierPower = new uint16[](4);
        pvpTierPower[0] = uint16((powerData >> 120) & 0xFFFF);
        pvpTierPower[1] = uint16((powerData >> 134) & 0xFFFF);
        pvpTierPower[2] = uint16((powerData >> 148) & 0xFFFF);
        pvpTierPower[3] = uint16((powerData >> 162) & 0xFFFF);
        /*fireTierPower = uint16((powerData >> 120) & 0xFFFF);
        earthTierPower = uint16((powerData >> 134) & 0xFFFF);
        lightningTierPower = uint16((powerData >> 148) & 0xFFFF);
        waterTierPower = uint16((powerData >> 162) & 0xFFFF);*/
        
        //pvpFfaPower = new uint16[](4);
        pvpFfaPower[0] = uint16((powerData >> 176) & 0xFFFF);
        pvpFfaPower[1] = uint16((powerData >> 190) & 0xFFFF);
        pvpFfaPower[2] = uint16((powerData >> 204) & 0xFFFF);
        pvpFfaPower[3] = uint16((powerData >> 218) & 0xFFFF);
        /*fireFFAPower = uint16((powerData >> 176) & 0xFFFF);
        earthFFAPower = uint16((powerData >> 190) & 0xFFFF);
        lightningFFAPower = uint16((powerData >> 204) & 0xFFFF);
        waterFFAPower = uint16((powerData >> 218) & 0xFFFF);*/

        level = uint8((powerData >> 232) & 0xFF);
        charTrait = uint8((powerData >> 240) & 0x3);
        wepTrait = uint8((powerData >> 242) & 0x3);
        shieldTrait = uint8((powerData >> 244) & 0x3);
    }

    // Read-only

    function isEquippable(address onAddr, uint256 slot, address itemAddr) public view returns (bool) {
        return equippableInSlot[onAddr][slot].contains(itemAddr);
    }

    function hasSlotEquipped(uint256 link, uint256 onID, uint256 slot) public view returns (bool) {
        return equippedSlotAddress[links[link]][onID][slot] != address(0);
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