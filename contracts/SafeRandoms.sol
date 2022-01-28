pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract SafeRandoms is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    /* Security
    *   Seeds are more secure the faster they are resolved
    *   Resolution every block = 100% security
    *   Optionally, publicResolutionBlocks can be set to 0 to force admin resolution
    */

    /* Usage:
    *   
    *   Transaction #1: Have the user pay costs (if applicable) and request the seed
    *   Transaction #2: Pop the seed (will revert if not ready, use check if necessary)
    *   
    *   After popping, you can use one seed for multiple outcomes (ie 10 weapon seeds)
    *   Just make sure to re-encode with keccak256(abi.encodePacked(seed,value...))
    *   ONLY with values that won't change over time:
    *   ie. block.number: NO
    *   1,2,3 etc: YES, IF seeds aren't shared under the same action identifier
    *    (so 1x weapons produce different requestIDs than 10x weapons)
    *   
    *   You can use the requestNext boolean for pop calls to request the next seed already,
    *   This allows you to have a new secure seed ready for every transaction (except the first)
    *   
    *   Resolve booleans of functions contribute to seed resolution,
    *   (sending false can be used to save gas if necessary)
    *    Check costs ~2k gas, resolution costs 35k (+3.1k for event + 1.7k for event check)
    */

    /* Seed Types
    *
    *   Single (One-at-a-time) seeds:
    *    Only one request possible per user for this type at a time
    *    The seed must be used before another one can be requested
    *    Can be used for actions that don't have up-front cost (besides gas)
    *     But! Consider possibility that the user may transfer NFT to another wallet or bridge networks
    *    These seeds can be salted after without popping to produce expectable results if tolerable
    *     (this saves gas if the initial action needed security but the following ones don't)
    *     ! Salted seeds are stored separately, the original one-at-a-time seed will be available raw
    *   
    *   Queued seeds:
    *    More than one seed request can be piled up (costs ~15-20k more gas than single seeds)
    *    Example use: Ordering multiple batches of weapons without requiring the first batch to complete
    *    MUST HAVE a full upfront cost to avoid abuse! (ie skill cost to mint an NFT)
    *   
    *   !!! IMPORTANT !!!!
    *    Seed types are not to be mixed for the same action type!
    *    Requesting a queued seed and popping a one-timer won't work, and vice versa
    */

    /* RequestIDs
    *   
    *   Request ID is a unique value to identify the exact action a random seed is requested for.
    *   A seed requested for 1x weapon mint must be different than for 10x weapon mints etc.
    *   
    *   Produce clean looking request IDs for two properties:
    *    RandomUtil.combineSeeds(SEED_WEAPON_MINT, amount)
    *   
    *   Or dirtier / for many properties: (you can slap arrays into encodePacked directly)
    *    uint(keccak256(abi.encodePacked(SEED_WEAPON_MINT, amount, special_weapon_series)))
    *   
    *   !!! DO NOT USE SIMPLE CONSTANT VALUES FOR THE ACTION IDENTIFIER (1,2,3) !!!
    *   USE ENCODED STRING CONSTANTS FOR EXAMPLE:
    *   uint256 public constant SEED_WEAPON_MINT = uint(keccak256("SEED_WEAPON_MINT"));
    */

    uint256 public currentSeedIndex; // new requests pile up under this index
    uint256 public seedIndexBlockNumber; // the block number "currentSeedIndex" was reached on
    uint256 public firstRequestBlockNumber; // first request block for the latest seed index
    mapping(uint256 => bytes32) public seedHashes; // key: seedIndex

    // keys: user, requestID / value: seedIndex
    mapping(address => mapping(uint256 => uint256)) public singleSeedRequests; // one-at-a-time (saltable)
    mapping(address => mapping(uint256 => uint256)) public singleSeedSalts; // optional, ONLY for single seeds
    mapping(address => mapping(uint256 => uint256[])) public queuedSeedRequests; // arbitrary in/out LIFO

    bool public publicResolutionLimited;
    uint256 public publicResolutionBlocks; // max number of blocks to resolve if limited

    bool public emitResolutionEvent;
    bool public emitRequestEvent;
    bool public emitPopEvent;

    event SeedResolved(address indexed resolver, uint256 indexed seedIndex);
    event SeedRequested(address indexed requester, uint256 indexed requestId);
    event SeedPopped(address indexed popper, uint256 indexed requestId);

    function initialize () public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        currentSeedIndex = 1; // one-at-a-time seeds have a 0 check
        seedIndexBlockNumber = block.number;
        firstRequestBlockNumber = block.number-1; // save 15k gas for very first user
    }
    
    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not admin");
    }

    // SINGLE SEED REQUESTS

    function requestSingleSeed(address user, uint256 requestID) public restricted {
        _resolveSeedPublic(user);
        _requestSingleSeed(user, requestID);
    }

    function _requestSingleSeed(address user, uint256 requestID) internal {
        require(singleSeedRequests[user][requestID] == 0);
        singleSeedRequests[user][requestID] = currentSeedIndex;
        if(firstRequestBlockNumber < seedIndexBlockNumber)
            firstRequestBlockNumber = block.number;

        if(emitRequestEvent)
            emit SeedRequested(user, requestID);
    }

    // QUEUED SEED REQUESTS

    function requestQueuedSeed(address user, uint256 requestID) public restricted {
        _resolveSeedPublic(user);
        _requestQueuedSeed(user, requestID);
    }

    function _requestQueuedSeed(address user, uint256 requestID) internal {
        queuedSeedRequests[user][requestID].push(currentSeedIndex);
        if(firstRequestBlockNumber < seedIndexBlockNumber)
            firstRequestBlockNumber = block.number;

        if(emitRequestEvent)
            emit SeedRequested(user, requestID);
    }

    // SEED RESOLUTIONS

    function resolveSeedPublic() public {
       _resolveSeedPublic(msg.sender);
    }

    function _resolveSeedPublic(address resolver) internal {
        if(!publicResolutionLimited || block.number < firstRequestBlockNumber + publicResolutionBlocks)
            _resolveSeed(resolver);
    }

    function resolveSeedAdmin() public restricted {
        _resolveSeed(msg.sender);
    }

    function _resolveSeed(address resolver) internal {
        if(block.number > firstRequestBlockNumber && firstRequestBlockNumber >= seedIndexBlockNumber) {
            seedHashes[currentSeedIndex++] = blockhash(block.number - 1);
            seedIndexBlockNumber = block.number;
            if(emitResolutionEvent)
                emit SeedResolved(resolver, currentSeedIndex);
        }
    }

    // SINGLE SEED FULFILLMENT

    function popSingleSeed(address user, uint256 requestID, bool resolve, bool requestNext) public restricted returns (uint256 seed) {
        if(resolve)
            _resolveSeedPublic(user);

        seed = readSingleSeed(user, requestID, false);
        require(seed != 0);
        delete singleSeedRequests[user][requestID];

        if(emitPopEvent)
            emit SeedPopped(user, requestID);

        if(requestNext)
            _requestSingleSeed(user, requestID);
    }

    function readSingleSeed(address user, uint256 requestID, bool allowZero) public view returns (uint256 seed) {
        seed = uint(seedHashes[singleSeedRequests[user][requestID]]);
        require(allowZero || seed != 0);
    }

    function saltSingleSeed(address user, uint256 requestID, bool resolve) public restricted returns (uint256 seed) {
        if(resolve)
            _resolveSeedPublic(user);

        require(seedHashes[singleSeedRequests[user][requestID]] != 0);
        seed = uint(keccak256(abi.encodePacked(
            seedHashes[singleSeedRequests[user][requestID]]
            ,singleSeedSalts[user][requestID]
        )));
        singleSeedSalts[user][requestID] = seed;
        return seed;
    }

    // QUEUED SEED FULFILLMENT

    function popQueuedSeed(address user, uint256 requestID, bool resolve, bool requestNext) public restricted returns (uint256 seed) {
        if(resolve)
            _resolveSeedPublic(user);

        // will revert on empty queue due to pop()
        seed = readQueuedSeed(user, requestID, false);
        queuedSeedRequests[user][requestID].pop();

        if(emitPopEvent)
            emit SeedPopped(user, requestID);

        if(requestNext)
            _requestQueuedSeed(user, requestID);

        return seed;
    }

    function readQueuedSeed(address user, uint256 requestID, bool allowZero) public view returns (uint256 seed) {
        uint256 lastIndex = queuedSeedRequests[user][requestID].length-1;
        seed = uint256(keccak256(abi.encodePacked(
            seedHashes[queuedSeedRequests[user][requestID][lastIndex]],
            user, requestID, lastIndex
        )));
        require(allowZero || seed != 0);
    }

    // HELPER VIEWS

    function hasSingleSeedRequest(address user, uint256 requestID) public view returns (bool) {
        return singleSeedRequests[user][requestID] != 0;
    }

    function getQueuedRequestCount(uint256 requestID) public view returns (uint256) {
        return queuedSeedRequests[msg.sender][requestID].length;
    }
    
    function encode(uint256[] calldata requestData) external pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(requestData)));
    }

    // ADMIN FUNCTIONS (excluding resolveSeedAdmin)

    function setPublicResolutionLimited(bool to) public restricted {
        publicResolutionLimited = to;
    }

    function setPublicResolutionBlocks(uint256 to) public restricted {
        publicResolutionBlocks = to;
    }

    function setEmitResolutionEvent(bool to) public restricted {
        emitResolutionEvent = to;
    }

    function setEmitRequestEvent(bool to) public restricted {
        emitRequestEvent = to;
    }

    function setEmitPopEvent(bool to) public restricted {
        emitPopEvent = to;
    }

}