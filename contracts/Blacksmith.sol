pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IRandoms.sol";
import "./weapons.sol";

contract Blacksmith is Initializable, AccessControlUpgradeable {
    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME = keccak256("GAME");

    /* ========== STATE VARIABLES ========== */

    Weapons public weapons;
    IRandoms public randoms;

    mapping(address => uint32) public tickets;

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

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    function spendTicket(uint32 _num) external {
        require(_num > 0);
        require(tickets[msg.sender] >= _num, "Not enough tickets");
        tickets[msg.sender] -= _num;

        for (uint256 i = 0; i < _num; i++) {
            weapons.mint(
                msg.sender,
                uint256(
                    keccak256(
                        abi.encodePacked(randoms.getRandomSeed(msg.sender), i)
                    )
                )
            );
        }
    }

    function giveTicket(address _player, uint32 _num) external onlyGame {
        tickets[_player] += _num;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGame() {
        require(hasRole(GAME, msg.sender), "Only game");
        _;
    }
}
