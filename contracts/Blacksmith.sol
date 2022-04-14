pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IRandoms.sol";
import "./shields.sol";
import "./Consumables.sol";
import "./Cosmetics.sol";
import "./weapons.sol";
import "./cryptoblades.sol";
import "./CBKLandSale.sol";

contract Blacksmith is Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME = keccak256("GAME");

    uint256 public constant ITEM_WEAPON_RENAME = 1;
    uint256 public constant ITEM_CHARACTER_RENAME = 2;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_FIRE = 3;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_EARTH = 4;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_WATER = 5;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_LIGHTNING = 6;
    uint256 public constant ITEM_COSMETIC_WEAPON = 7; // series
    uint256 public constant ITEM_COSMETIC_CHARACTER = 8; // series
    uint256 public constant ITEM_SHIELD = 9;

    uint256 public constant VAR_PURCHASE_SHIELD_TYPE = 1;
    uint256 public constant VAR_PURCHASE_SHIELD_SUPPLY = 2; // only for non-0 type shields

    uint256 public constant LINK_SKILL_ORACLE_2 = 1; // technically second skill oracle (it's separate)
    uint256 public constant LINK_KING_ORACLE = 2;

    /* ========== STATE VARIABLES ========== */

    Weapons public weapons;
    IRandoms public randoms;

    mapping(address => uint32) public tickets;

    Shields public shields;
    CryptoBlades public game;


    // keys: ITEM_ constant
    mapping(uint256 => address) public itemAddresses;
    mapping(uint256 => uint256) public itemFlatPrices;

    mapping(uint256 => uint256) public numberParameters; // AKA "vars"

    mapping(uint256 => mapping(uint256 => uint256)) public itemSeriesFlatPrices;
    CBKLandSale public cbkLandSale;
    // ERC20 => tier => price
    mapping(uint256 => mapping(uint256 => uint256)) public landPrices;
    mapping(uint256 => address) currencies;

    mapping(uint256 => address) public links;

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

    function migrateTo_bcdf4c(CBKLandSale _cbkLandSale) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        cbkLandSale = _cbkLandSale;
    }

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverToken(address tokenAddress, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function purchaseShield() public {
        require(itemFlatPrices[ITEM_SHIELD] > 0);

        uint256 shieldType = numberParameters[VAR_PURCHASE_SHIELD_TYPE];
        if(shieldType != 0) {
            require(numberParameters[VAR_PURCHASE_SHIELD_SUPPLY] > 0);
            numberParameters[VAR_PURCHASE_SHIELD_SUPPLY] -= 1;
        }
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_SHIELD]);
        shields.mint(msg.sender, shieldType,
            uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1)))));
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGame() {
        require(hasRole(GAME, msg.sender), "Only game");
        _;
    }

    modifier isAdmin() {
         _isAdmin();
        _;
    }
    
    function _isAdmin() internal view {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
    }

    /* ========== Generic Getters ========== */

    function getAddressOfItem(uint256 itemIndex) public view returns(address) {
        return itemAddresses[itemIndex];
    }

    function getFlatPriceOfItem(uint256 itemIndex) public view returns(uint256) {
        return itemFlatPrices[itemIndex];
    }

    function getFlatPriceOfSeriesItem(uint256 itemIndex, uint256 seriesIndex) public view returns(uint256) {
        return itemSeriesFlatPrices[itemIndex][seriesIndex];
    }

    function getCurrency(uint256 currency) public view returns (address) {
        return currencies[currency];
    }

    function getLink(uint256 linkId) public view returns (address) {
        return links[linkId];
    }

    function vars(uint256 varField) public view returns (uint256) {
        return numberParameters[varField];
    }

    /* ========== Generic Setters ========== */

    function setAddressOfItem(uint256 itemIndex, address to) external isAdmin {
        itemAddresses[itemIndex] = to;
    }

    function setFlatPriceOfItem(uint256 itemIndex, uint256 flatWeiPrice) external isAdmin {
        itemFlatPrices[itemIndex] = flatWeiPrice;
    }

    function setFlatPriceOfItemSeries(uint256 itemIndex,
        uint256[] calldata seriesIndices,
        uint256[] calldata seriesPrices
    ) external isAdmin {
        for(uint i = 0; i < seriesIndices.length; i++) {
            itemSeriesFlatPrices[itemIndex][seriesIndices[i]] = seriesPrices[i];
        }
    }

    function setCurrency(uint256 currency, address currencyAddress, bool forced) external isAdmin {
        require(currency > 0 && (forced || currencies[currency] == address(0)), 'used');
        currencies[currency] = currencyAddress;
    }

    function setLink(uint256 linkId, address linkAddress) external isAdmin {
        links[linkId] = linkAddress;
    }

    function setVar(uint256 varField, uint256 value) external isAdmin {
        numberParameters[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external isAdmin {
        for(uint i = 0; i < varFields.length; i++) {
            numberParameters[varFields[i]] = values[i];
        }
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
        itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic] = newPrice;
    }

     function getWeaponCosmeticPrice(uint32 cosmetic) public view returns (uint256){
        return itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic];
    }

    function purchaseWeaponCosmetic(uint32 cosmetic, uint256 paying) public {
        require(paying > 0 && paying == itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic]);
        Cosmetics(itemAddresses[ITEM_COSMETIC_WEAPON]).giveCosmetic(msg.sender, cosmetic, 1);
    }

    /* ========== Character cosmetics ========== */
    function setCharacterCosmeticPrice(uint32 cosmetic, uint256 newPrice) external isAdmin {
        require(cosmetic > 0 && newPrice > 0, 'invalid request');
        itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic] = newPrice;
    }

     function getCharacterCosmeticPrice(uint32 cosmetic) public view returns (uint256){
        return itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic];
    }

    function purchaseCharacterCosmetic(uint32 cosmetic, uint256 paying) public {
        require(paying > 0 && paying == itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic]);
        Cosmetics(itemAddresses[ITEM_COSMETIC_CHARACTER]).giveCosmetic(msg.sender, cosmetic, 1);
    }

    /* ========== CBK Land sale ========== */

    event CBKLandPurchased(address indexed owner, uint256 tier, uint256 price, uint256 currency);

    function purchaseT1CBKLand(uint256 paying, uint256 currency) public {
        uint256 price = getCBKLandPrice(cbkLandSale.TIER_ONE(), currency);
        require(paying > 0 && price == paying, 'Invalid price');
        payCurrency(msg.sender, price, currency);
        cbkLandSale.giveT1Land(msg.sender);
        emit CBKLandPurchased(msg.sender, cbkLandSale.TIER_ONE(), price, currency);
    }

    function purchaseT2CBKLand(uint256 paying, uint256 chunkId, uint256 currency) public {
        uint256 price = getCBKLandPrice(cbkLandSale.TIER_TWO(), currency);
        require(paying > 0 && price == paying,  'Invalid price');
        payCurrency(msg.sender, price, currency);
        cbkLandSale.giveT2Land(msg.sender, chunkId);
        emit CBKLandPurchased(msg.sender, cbkLandSale.TIER_TWO(), price, currency);
    }

    function purchaseT3CBKLand(uint256 paying, uint256 chunkId, uint256 currency) public {
        uint256 price = getCBKLandPrice(cbkLandSale.TIER_THREE(), currency);
        require(paying > 0 && price == paying, 'Invalid price');
        payCurrency(msg.sender, price, currency);
        cbkLandSale.giveT3Land(msg.sender, chunkId);
        emit CBKLandPurchased(msg.sender, cbkLandSale.TIER_THREE(), price, currency);
    }

    function getCBKLandPrice(uint256 tier, uint256 currency) public view returns (uint256){
        return landPrices[currency][tier] * getOracledTokenPerUSD(currency);
    }

    function getOracledTokenPerUSD(uint256 currency) public view returns (uint256) {
        if(currency == 0) {
            return IPriceOracle(links[LINK_SKILL_ORACLE_2]).currentPrice();
        }
        else {
            return IPriceOracle(links[LINK_KING_ORACLE]).currentPrice();
        }
    }

    function setCBKLandPrice(uint256 tier, uint256 newPrice, uint256 currency) external isAdmin {
        require(newPrice > 0, 'invalid price');
        require(tier >= cbkLandSale.TIER_ONE() && tier <= cbkLandSale.TIER_THREE(), "Invalid tier");
        landPrices[currency][tier] = newPrice;
    }

    function payCurrency(address payer, uint256 paying, uint256 currency) internal {
        if(currency == 0){
             game.payContractTokenOnly(payer, paying, true);
        }
        else {
            IERC20(currencies[currency]).transferFrom(payer, address(this), paying);
        }
    }
}
