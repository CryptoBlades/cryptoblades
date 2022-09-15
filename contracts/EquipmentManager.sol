pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./util.sol";

contract EquipmentManager is Initializable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

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

    /*struct Item {
        address link;
        uint id;
    }*/

    // STATE VARIABLES

    //mapping(uint256 => Item) public itemDefinitions;
    mapping(uint256 => address) public itemDefinitionsAddr;
    mapping(uint256 => uint) public itemDefinitionsID;
    /*mapping(address => mapping(uint => uint)) public itemDefinitionReverse; // only read from frontend!
    mapping(address => mapping(uint256 => mapping(uint256 => Item))) public equippedItems;//nftaddr, nftid, slotid, item
    mapping(address => mapping(uint256 => mapping(uint256 => address))) public equippedItems2;//nftaddr, nftid, slotid, item
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public equippedItems3;//nftaddr, nftid, slotid, item
    mapping(address => mapping(uint256 => uint256)) public equippedOnDefinition; //nftaddr, nftid, itemdef
    mapping(address => mapping(uint256 => uint256)) public equippedOnID; //nftaddr, nftid, id*/

    // FUNCTIONS

    /*function setDef(uint defid, address addr, uint id) public {
        itemDefinitions[defid] = Item(addr, id);
    }*/

    function setDef(uint defid, address addr, uint id) public {
        itemDefinitionsAddr[defid] = addr;
        itemDefinitionsID[defid] = id;
    }

    function seedTest1(uint num1, uint num2) public view returns (uint) {
        return RandomUtil.combineSeeds(RandomUtil.combineSeeds(uint(GAME_ADMIN), num1), num2);
    }

    function seedTest2(uint num1, uint num2) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(uint(GAME_ADMIN), num1, num2)));
    }
    
    function seedTest3(uint num1, uint num2) public view returns (uint) {
        uint[] memory seeds = new uint[](3);
        seeds[0] = uint(GAME_ADMIN);
        seeds[1] = num1;
        seeds[2] = num2;
        return RandomUtil.combineSeeds(seeds);
    }
    /*function hasEquipment(address nft) public view returns(bool) {
        
    }

    function setDef(uint256 defid, address link, uint id) public {
        itemDefinitions[defid] = Item(link,id);
        itemDefinitionReverse[link][id] = defid;
    }

// checking efficiency storing a struct vs storing multiple
// 1: struct store direct
// 2: data store separate
    function set1(address addr, uint nftid, uint slot, address item, uint itemid) public {
        equippedItems[addr][nftid][slot] = Item(item, itemid);
    }

    function set2(address addr, uint nftid, uint slot, address item, uint itemid) public {
        equippedItems2[addr][nftid][slot] = item;
        equippedItems3[addr][nftid][slot] = itemid;
    }

    function get1(address addr, uint nftid, uint slot) public view returns (address item, uint id) {
        Item memory i = equippedItems[addr][nftid][slot];
        return (i.link, i.id);
    }

    function get2(address addr, uint nftid, uint slot) public view returns (address item, uint id) {
        return (equippedItems2[addr][nftid][slot], equippedItems3[addr][nftid][slot]);
    }

//
    function sete(address addr, uint nftid, uint defid, uint equipee) public {
        equippedOnDefinition[addr][nftid] = defid;
        equippedOnID[addr][nftid] = equipee;
    }

    function gete(address addr, uint nftid) public view returns(address onaddr, uint onslot, uint onid) {
        Item memory i = itemDefinitions[equippedOnDefinition[addr][nftid]];
        return (i.link, i.id, equippedOnID[addr][nftid]);
    }*/

}