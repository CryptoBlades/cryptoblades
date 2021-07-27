pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./multiAccessUpgradeable.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./skillToken.sol";

contract Arena is Initializable, MultiAccessUpgradeable {

    struct Gladiator {
        address owner;
        uint256 stake;
        uint256 charID;
        uint256 wepID;
        uint24 power;
    }

    // Events
    event EmptyArena();
    event GladiatorJoined(address owner, uint256 stake, uint256 character, uint256 weapon, uint24 power);
    event GladiatorLeft(address owner);

    // Needs to be granted access to NFT contracts to interact with them
    CryptoBlades internal game;
    Characters internal characters;
    Weapons internal weapons;
    IERC20 internal skillToken;
    address [] internal addresses;
    mapping(address => Gladiator) internal gladiators;

    
    modifier isWeaponOwner(uint256 weapon) {
        require(weapons.ownerOf(weapon) == msg.sender, "Not the weapon owner");
        _;
    }

    modifier isCharacterOwner(uint256 character) {
        require(characters.ownerOf(character) == msg.sender, "Not the character owner");
        _;
    }

    function initialize(address gameContract)
        public
        initializer
    {
        MultiAccessUpgradeable.initialize();
        grantAccess(gameContract);
        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
        skillToken = game.skillToken();
    }

    function emptyArena()
        public
    {
        for(uint256 i = 0; i < addresses.length; i++) {
            delete gladiators[addresses[i]]; 
        }
        delete addresses;
        emit EmptyArena();
    }

    function enterArena(uint256 charID, uint256 weaponID, uint256 stake)
        public
        isWeaponOwner(weaponID)
        isCharacterOwner(charID)
    {
        require (stake > 0, "You must stake some skill.");
        require (gladiators[msg.sender].stake == 0, "You can only stake one character.");
        require (skillToken.balanceOf(msg.sender) >= stake, "Not enough skill.");

        // TODO: Unclear at the moment what's the amount of skill to stake and what to do with it.
        // TODO: Use the already existing code for skill transfer in cryptoblades.sol
        // TODO: This will need user spend approval.
        // Transfer staked SKILL to this contract.
        skillToken.transferFrom(msg.sender, address(this), stake);

        // TODO: Calc power
        uint24 power = 0;

        gladiators[msg.sender] = Gladiator({
            owner: msg.sender,
            stake: stake,
            charID: charID,
            wepID: weaponID,
            power: power
        });

        emit GladiatorJoined(msg.sender, stake, charID, weaponID, power);
    }

    function leaveArena()
        public
    {
        require (gladiators[msg.sender].stake > 0, "You don't have a character staked.");

        // TODO: Use existing code.
        // Return remaining stake to the player.
        if (gladiators[msg.sender].stake > 0) {
            // TODO: Where does this go?
            //skillToken.transferFrom(address(this), msg.sender, gladiators[msg.sender].stake);
        }

        // Remove gladiator
        for(uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == msg.sender) {
                delete addresses[i];
            }
        }
        delete gladiators[msg.sender];

        emit GladiatorLeft(msg.sender);
    }

    // TODO: Match players, fight, etc...
}