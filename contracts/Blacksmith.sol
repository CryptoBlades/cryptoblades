pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IRandoms.sol";
import "./shields.sol";
import "./WeaponRenameTagConsumables.sol";
import "./CharacterRenameTagConsumables.sol";
import "./CharacterFireTraitChangeConsumables.sol";
import "./CharacterEarthTraitChangeConsumables.sol";
import "./CharacterWaterTraitChangeConsumables.sol";
import "./CharacterLightningTraitChangeConsumables.sol";
import "./weapons.sol";
import "./cryptoblades.sol";

contract Blacksmith is Initializable, AccessControlUpgradeable {
    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME = keccak256("GAME");

    uint256 public constant SHIELD_SKILL_FEE = 5 ether;
    uint256 public constant ONE_SKILL_FEE = 1 ether;

    uint256 private _characterRenamePrice;
    uint256 private _weaponRenamePrice;
    uint256 private _characterTraitChangePrice;

    /* ========== STATE VARIABLES ========== */

    Weapons public weapons;
    IRandoms public randoms;

    mapping(address => uint32) public tickets;

    Shields public shields;
    CryptoBlades public game;
    CharacterRenameTagConsumables public characterRename;
    WeaponRenameTagConsumables public weaponRename;
    CharacterFireTraitChangeConsumables public characterFireTraitChangeConsumables;
    CharacterEarthTraitChangeConsumables public characterEarthTraitChangeConsumables;
    CharacterWaterTraitChangeConsumables public characterWaterTraitChangeConsumables;
    CharacterLightningTraitChangeConsumables public characterLightningTraitChangeConsumables;

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

     function migrateTo_16884dd(CharacterRenameTagConsumables _characterRename,
     WeaponRenameTagConsumables _weaponRename,
     CharacterFireTraitChangeConsumables _charFireTraitChange,
     CharacterEarthTraitChangeConsumables _charEarthTraitChange,
     CharacterWaterTraitChangeConsumables _charWaterTraitChange,
     CharacterLightningTraitChangeConsumables _charLightningTraitChange
     ) external {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
         characterRename = _characterRename;
         weaponRename = _weaponRename;
         characterFireTraitChangeConsumables = _charFireTraitChange;
         characterEarthTraitChangeConsumables = _charEarthTraitChange;
         characterWaterTraitChangeConsumables = _charWaterTraitChange;
         characterLightningTraitChangeConsumables = _charLightningTraitChange;

         _characterRenamePrice = 1 ether;
         _weaponRenamePrice = 1 ether;
         _characterTraitChangePrice = 1 ether;
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
        uint256 BIT_FOUNDER_SHIELD = promos.BIT_FOUNDER_SHIELD();

        require(!promos.getBit(msg.sender, BIT_FOUNDER_SHIELD), "Limit 1");
        promos.setBit(msg.sender, BIT_FOUNDER_SHIELD);
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

    /* ========== Character Rename ========== */
    
    function setCharacterRenamePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        _characterRenamePrice = newPrice;
    }

    function characterRenamePrice() public view returns (uint256){
        return _characterRenamePrice;
    }

    function purchaseCharacterRenameTag(uint256 paying) public {
        require(paying == _characterRenamePrice, 'Invalid price');
        game.payContractTokenOnly(msg.sender, _characterRenamePrice);
        characterRename.giveItem(msg.sender);
    }
    
    /* ========== Weapon Rename ========== */

    function setWeaponRenamePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        _weaponRenamePrice = newPrice;
    }

    function weaponRenamePrice() public view returns (uint256){
        return _weaponRenamePrice;
    }

    function purchaseWeaponRenameTag(uint256 paying) public {
        require(paying == _weaponRenamePrice, 'Invalid price');
        game.payContractTokenOnly(msg.sender, _weaponRenamePrice);
        weaponRename.giveItem(msg.sender);
    }

     /* ========== Character Trait Change ========== */

     function setCharacterTraitChangePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        _characterTraitChangePrice = newPrice;
    }

     function characterTraitChangePrice() public view returns (uint256){
        return _characterTraitChangePrice;
    }

    function purchaseCharacterFireTraitChange(uint256 paying) public {
        require(paying == _characterTraitChangePrice, 'Invalid price');
        game.payContractTokenOnly(msg.sender, _characterTraitChangePrice);
        characterFireTraitChangeConsumables.giveItem(msg.sender);
    }

    function purchaseCharacterEarthTraitChange(uint256 paying) public {
        require(paying == _characterTraitChangePrice, 'Invalid price');
        game.payContractTokenOnly(msg.sender, _characterTraitChangePrice);
        characterEarthTraitChangeConsumables.giveItem(msg.sender);
    }

    function purchaseCharacterWaterTraitChange(uint256 paying) public {
        require(paying == _characterTraitChangePrice, 'Invalid price');
        game.payContractTokenOnly(msg.sender, _characterTraitChangePrice);
        characterWaterTraitChangeConsumables.giveItem(msg.sender);
    }

    function purchaseCharacterLightningTraitChange(uint256 paying) public {
        require(paying == _characterTraitChangePrice, 'Invalid price');
        game.payContractTokenOnly(msg.sender, _characterTraitChangePrice);
        characterLightningTraitChangeConsumables.giveItem(msg.sender);
    }
}
