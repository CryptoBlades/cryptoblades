pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../SpecialWeaponsManager.sol";

contract PartnerGiveaways is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    
    mapping(uint256 => uint256) vars;
    uint256 public constant VAR_SHARDS_REWARD = 1;

    SpecialWeaponsManager public specialWeaponsManager;

    mapping(address => mapping(uint256 => bool)) public userClaimedAtGiveaway;
    mapping(uint256 => mapping(uint256 => bool)) public nftClaimedAtGiveaway;

    mapping(uint256 => address) public giveawayIdToAddress;
    mapping(uint256 => uint256) giveawayIdToSpecialEventId;
    mapping(uint256 => uint256) public giveawayEndTime;

    uint256 public nextGiveawayId;

    function initialize(SpecialWeaponsManager _specialWeaponsManager)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        specialWeaponsManager = _specialWeaponsManager;
        vars[VAR_SHARDS_REWARD] = 125;
    }

    // MODIFIERS

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    // VIEWS

    function getGiveawayClaimInfoForUser(uint256 giveawayId, uint256 nftId) external view returns(bool didUserClaim, bool didNftClaim){
        didUserClaim = userClaimedAtGiveaway[msg.sender][giveawayId];
        didNftClaim = nftClaimedAtGiveaway[giveawayId][nftId];
    }

    // FUNCTIONS
    
    function createGiveawayForNft(address requiredNftAddress, uint256 specialEventId, uint256 giveawayPeriod) external restricted {
        giveawayIdToAddress[nextGiveawayId] = requiredNftAddress;
        giveawayIdToSpecialEventId[nextGiveawayId] = specialEventId;
        giveawayEndTime[nextGiveawayId] = block.timestamp + giveawayPeriod;
        nextGiveawayId++; 
    }

    function claimReward(uint256 giveawayId, uint256 nftId) external {
        require(msg.sender == IERC721(giveawayIdToAddress[giveawayId]).ownerOf(nftId), "Nft not owned");
        require(!userClaimedAtGiveaway[msg.sender][giveawayId], "Reward for this wallet already claimed");
        require(!nftClaimedAtGiveaway[giveawayId][nftId], "Reward for this NFT already claimed");
        require(block.timestamp <= giveawayEndTime[giveawayId], "Giveaway ended");
        userClaimedAtGiveaway[msg.sender][giveawayId] = true;
        nftClaimedAtGiveaway[giveawayId][nftId] = true;
        specialWeaponsManager.addShards(msg.sender, giveawayIdToSpecialEventId[giveawayId], vars[VAR_SHARDS_REWARD]);
    }

    // VAR SETTER
    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for(uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }
}
