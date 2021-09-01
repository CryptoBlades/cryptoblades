pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IRandoms.sol";
import "./shields.sol";
import "./Consumables.sol";
import "./Cosmetics.sol";
import "./weapons.sol";
import "./cryptoblades.sol";

contract Blacksmith is Initializable, AccessControlUpgradeable {
    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME = keccak256("GAME");

    uint256 public constant SHIELD_SKILL_FEE = 3 ether;

    uint256 public constant ITEM_WEAPON_RENAME = 1;
    uint256 public constant ITEM_CHARACTER_RENAME = 2;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_FIRE = 3;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_EARTH = 4;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_WATER = 5;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_LIGHTNING = 6;


    uint256 public constant COSMETIC_ADDRESS_WEAPON = 1;
    uint256 public constant COSMETIC_ADDRESS_CHARACTER = 2;

    /* ========== STATE VARIABLES ========== */

    Weapons public weapons;
    IRandoms public randoms;

    mapping(address => uint32) public tickets;

    Shields public shields;
    CryptoBlades public game;

    // keys: ITEM_ constant
    mapping(uint256 => address) public itemAddresses;
    mapping(uint256 => uint256) public itemFlatPrices;

    mapping(uint256 => address) public cosmeticAddresses;
    mapping(uint32 => uint256) public cosmeticWeaponFlatPrices;
    mapping(uint32 => uint256) public cosmeticCharacterFlatPrices;

    /* ========== INITIALIZERS AND MIGRATORS ========== */

    function initialize(Weapons _weapons, IRandoms _randoms)
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        weapons = _weapons;
        randoms = _randoms;
    }

    function migrateRandoms(IRandoms _newRandoms) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        randoms = _newRandoms;
    }

    function migrateTo_61c10da(Shields _shields, CryptoBlades _game) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        shields = _shields;
        game = _game;
    }

    function migrateTo_16884dd(
        address _characterRename,
        address _weaponRename,
        address _charFireTraitChange,
        address _charEarthTraitChange,
        address _charWaterTraitChange,
        address _charLightningTraitChange
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        itemAddresses[ITEM_WEAPON_RENAME] = _weaponRename;
        itemAddresses[ITEM_CHARACTER_RENAME] = _characterRename;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_FIRE] = _charFireTraitChange;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_EARTH] = _charEarthTraitChange;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_WATER] = _charWaterTraitChange;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING] = _charLightningTraitChange;

        itemFlatPrices[ITEM_WEAPON_RENAME] = 0.1 ether;
        itemFlatPrices[ITEM_CHARACTER_RENAME] = 0.1 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE] = 0.2 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH] = 0.2 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER] = 0.2 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING] = 0.2 ether;
    }

    function migrateTo_eefb9b1(
        address _weaponCosmetic,
        address _characterCosmetic
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        cosmeticAddresses[COSMETIC_ADDRESS_WEAPON] = _weaponCosmetic;
        cosmeticAddresses[COSMETIC_ADDRESS_CHARACTER] = _characterCosmetic;      
       
       // basic effects
       for(uint32 i = 1; i < 6; i++) {
            cosmeticWeaponFlatPrices[i] = 0.1 ether;
            cosmeticCharacterFlatPrices[i] = 0.1 ether;
        }
        
        // premium effects weapons
        for(uint32 i = 6; i < 16; i++) {
            cosmeticWeaponFlatPrices[i] = 0.5 ether;
        }
        // plain borders weapons
        cosmeticWeaponFlatPrices[16] = 0.4 ether;
        cosmeticWeaponFlatPrices[17] = 0.3 ether;
        cosmeticWeaponFlatPrices[18] = 0.2 ether;
        cosmeticWeaponFlatPrices[19] = 0.1 ether;

        // premium effects characters
        for(uint32 i = 6; i < 15; i++) {
            cosmeticCharacterFlatPrices[i] = 0.5 ether;
        }        
        // plain borders characters
        cosmeticCharacterFlatPrices[15] = 0.4 ether;
        cosmeticCharacterFlatPrices[16] = 0.3 ether;
        cosmeticCharacterFlatPrices[17] = 0.2 ether;
        cosmeticCharacterFlatPrices[18] = 0.1 ether;
    }

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    // function spendTicket(uint32 _num) external {
    //     require(_num > 0);
    //     require(tickets[msg.sender] >= _num, "Not enough tickets");
    //     tickets[msg.sender] -= _num;

    //     for (uint256 i = 0; i < _num; i++) {
    //         weapons.mint(
    //             msg.sender,
    //             // TODO: Do the thing we do in cryptoblades.sol to "lock in" the user into a given blockhash
    //         );
    //     }
    // }

    function giveTicket(address _player, uint32 _num) external onlyGame {
        tickets[_player] += _num;
    }

    function purchaseShield() public {
        Promos promos = game.promos();
        uint256 BIT_LEGENDARY_DEFENDER = promos.BIT_LEGENDARY_DEFENDER();

        require(!promos.getBit(msg.sender, BIT_LEGENDARY_DEFENDER), "Limit 1");
        promos.setBit(msg.sender, BIT_LEGENDARY_DEFENDER);
        game.payContractTokenOnly(msg.sender, SHIELD_SKILL_FEE);
        shields.mintForPurchase(msg.sender);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGame() {
        require(hasRole(GAME, msg.sender), "Only game");
        _;
    }

     modifier isAdmin() {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    /* ========== Generic Getters ========== */

    function getAddressOfItem(uint256 itemIndex) public view returns(address) {
        return itemAddresses[itemIndex];
    }

    function getFlatPriceOfItem(uint256 itemIndex) public view returns(uint256) {
        return itemFlatPrices[itemIndex];
    }

    function getAddressOfCosmetic(uint256 cosmeticIndex) public view returns(address) {
        return cosmeticAddresses[cosmeticIndex];
    }
    /* ========== Character Rename ========== */
    
    function setCharacterRenamePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        itemFlatPrices[ITEM_CHARACTER_RENAME] = newPrice;
    }

    function characterRenamePrice() public view returns (uint256){
        return itemFlatPrices[ITEM_CHARACTER_RENAME];
    }

    function purchaseCharacterRenameTag(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_RENAME], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_RENAME]);
        Consumables(itemAddresses[ITEM_CHARACTER_RENAME]).giveItem(msg.sender, 1);
    }
    
    function purchaseCharacterRenameTagDeal(uint256 paying) public { // 4 for the price of 3
        require(paying == itemFlatPrices[ITEM_CHARACTER_RENAME] * 3, 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_RENAME] * 3);
        Consumables(itemAddresses[ITEM_CHARACTER_RENAME]).giveItem(msg.sender, 4);
    }
    
    /* ========== Weapon Rename ========== */

    function setWeaponRenamePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        itemFlatPrices[ITEM_WEAPON_RENAME] = newPrice;
    }

    function weaponRenamePrice() public view returns (uint256){
        return itemFlatPrices[ITEM_WEAPON_RENAME];
    }

    function purchaseWeaponRenameTag(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_WEAPON_RENAME], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_WEAPON_RENAME]);
        Consumables(itemAddresses[ITEM_WEAPON_RENAME]).giveItem(msg.sender, 1);
    }

    function purchaseWeaponRenameTagDeal(uint256 paying) public { // 4 for the price of 3
        require(paying == itemFlatPrices[ITEM_WEAPON_RENAME] * 3, 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_WEAPON_RENAME] * 3);
        Consumables(itemAddresses[ITEM_WEAPON_RENAME]).giveItem(msg.sender, 4);
    }

     /* ========== Character Trait Change ========== */

     function setCharacterTraitChangePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE] = newPrice;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH] = newPrice;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER] = newPrice;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING] = newPrice;
    }

     function characterTraitChangePrice() public view returns (uint256){
        return itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE];
    }

    function purchaseCharacterFireTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE]);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_FIRE]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterEarthTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH]);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_EARTH]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterWaterTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER]);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_WATER]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterLightningTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING]);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING]).giveItem(msg.sender, 1);
    }


    /* ========== Weapon cosmetics ========== */
    function setWeaponCosmeticPrice(uint32 cosmetic, uint256 newPrice) external isAdmin {
        require(cosmetic > 0 && newPrice > 0, 'invalid request');
        cosmeticWeaponFlatPrices[cosmetic] = newPrice;
    }

     function getWeaponCosmeticPrice(uint32 cosmetic) public view returns (uint256){
        return cosmeticWeaponFlatPrices[cosmetic];
    }

    function purchaseWeaponCosmetic(uint32 cosmetic, uint256 paying) public {
        require(paying > 0 && paying == cosmeticWeaponFlatPrices[cosmetic], 'Invalid price');
        game.payContractTokenOnly(msg.sender, cosmeticWeaponFlatPrices[cosmetic]);
        Cosmetics(cosmeticAddresses[COSMETIC_ADDRESS_WEAPON]).giveCosmetic(msg.sender, cosmetic, 1);
    }

    /* ========== Character cosmetics ========== */
    function setCharacterCosmeticPrice(uint32 cosmetic, uint256 newPrice) external isAdmin {
        require(cosmetic > 0 && newPrice > 0, 'invalid request');
        cosmeticCharacterFlatPrices[cosmetic] = newPrice;
    }

     function getCharacterCosmeticPrice(uint32 cosmetic) public view returns (uint256){
        return cosmeticCharacterFlatPrices[cosmetic];
    }

    function purchaseCharacterCosmetic(uint32 cosmetic, uint256 paying) public {
        require(paying > 0 && paying == cosmeticCharacterFlatPrices[cosmetic], 'Invalid price');
        game.payContractTokenOnly(msg.sender, cosmeticCharacterFlatPrices[cosmetic]);
        Cosmetics(cosmeticAddresses[COSMETIC_ADDRESS_CHARACTER]).giveCosmetic(msg.sender, cosmetic, 1);
    }
}
