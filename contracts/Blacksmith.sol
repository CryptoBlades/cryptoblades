pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IRandoms.sol";
import "./shields.sol";
import "./WeaponRenameTagConsumables.sol";
import "./CharacterRenameTagConsumables.sol";
import "./weapons.sol";
import "./cryptoblades.sol";

contract Blacksmith is Initializable, AccessControlUpgradeable {
    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME = keccak256("GAME");

    uint256 public constant SHIELD_SKILL_FEE = 5 ether;
    uint256 public constant ONE_SKILL_FEE = 1 ether;

    /* ========== STATE VARIABLES ========== */

    Weapons public weapons;
    IRandoms public randoms;

    mapping(address => uint32) public tickets;

    Shields public shields;
    CryptoBlades public game;
    CharacterRenameTagConsumables public characterRename;
    WeaponRenameTagConsumables public weaponRename;

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

     function migrateTo_Something(CharacterRenameTagConsumables _characterRename,
     WeaponRenameTagConsumables _weaponRename) external {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
         characterRename = _characterRename;
         weaponRename = _weaponRename;
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

    function purchaseCharacterRenameTag() public {
        game.payContractTokenOnly(msg.sender, ONE_SKILL_FEE);
        characterRename.giveItem(msg.sender);
    }

    function purchaseWeaponRenameTag() public {
        game.payContractTokenOnly(msg.sender, ONE_SKILL_FEE);
        weaponRename.giveItem(msg.sender);
    }
}
