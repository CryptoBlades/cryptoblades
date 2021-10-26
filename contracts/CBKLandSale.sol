pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./CBKLand.sol";

contract CBKLandSale is Initializable, AccessControlUpgradeable {

    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CBKLand public cbkLand;
     /* ========== EVENTS ========== */
    event T1Given(address indexed owner, uint256 stamp);
    event T2Given(address indexed owner, uint256 chunkId);
    event T3Given(address indexed owner, uint256 chunkId);
    event T1GivenFree(address indexed owner, uint256 stamp);
    event T2GivenFree(address indexed owner, uint256 chunkId);
    event T3GivenFree(address indexed owner, uint256 chunkId);
    event T1GivenReserved(address indexed reseller, address indexed owner, uint256 chunkId);
    event T2GivenReserved(address indexed reseller, address indexed owner, uint256 chunkId);
    event T3GivenReserved(address indexed reseller, address indexed owner, uint256 chunkId);
    event LandTokenGiven(address indexed reseller, address indexed owner, uint256 tier);

    event ReservedLandClaimed(uint256 indexed reservation, address indexed reseller, address indexed owner, uint256 tier, uint256 chunkId);

    /* ========== LAND SALE INFO ========== */
    uint256 private constant NO_LAND = 0;
    uint256 public constant TIER_ONE = 1;
    uint256 public constant TIER_TWO = 2;
    uint256 public constant TIER_THREE = 3;
    uint256 private constant MAX_CHUNK_ID = 9999; // 100 x 100

    struct purchaseInfo {
        address buyer;
        uint256 purchasedTier;
        uint256 stamp; // chunkId or roundrobin stamp
        bool free;
    }

    uint256 private totalSales;
    mapping(uint256 => purchaseInfo) public sales; // Put all sales in an mapping for easier tracking
    mapping(address => purchaseInfo) public purchaseAddressMapping;
    mapping(uint256 => uint256) public availableLand; // Land that is up for sale. 
    mapping(uint256 => uint256) public chunkZoneLandSales;

    /* ========== T1 LAND SALE INFO ========== */
    // T1 land is sold with no exact coordinates commitment and assigned based on round robin
    // once minting is done. For now the player gets a stamp which can reflect PROJECTED land coordinates
    // should it need be.
    uint256 private t1LandsSold;



    /* ========== T2 LAND SALE INFO ========== */
    uint256 private t2LandsSold;
    uint256 private chunksWithT2Land;

    uint256 private _allowedLandSalePerChunk;
    uint256 private _allowedLandOffset; // Max allowed deviation allowed from theoretical average

    // T2 sold per chunk
    mapping(uint256 => uint256) public chunkT2LandSales;


    /* ========== T3 LAND SALE INFO ========== */
    uint256 private t3LandsSold;
    mapping(uint256 => address) public chunkT3LandSoldTo;


    /* ========== RESERVED CHUNKS SALE INFO ========== */
    EnumerableSet.UintSet private reservedChunkIds;

    bool internal _enabled;
    bool internal _reservedEnabled;
    
    mapping(address => EnumerableSet.UintSet) private reservedChunks;
    mapping(address => uint256) private reservedChunksCounter;
    mapping(uint256 => address) private chunksReservedFor;

    // reseller address => land tier => budget
    mapping(address => mapping(uint256 => uint256)) private resellerLandBudget;

    // player reserved land
    uint256 private playerReservedLandAt;
    mapping(address => EnumerableSet.UintSet) private playerReservedLands;
    mapping(uint256 => uint256) private playerReservedLandTier;
    mapping(uint256 => address) private playerReservedLandReseller;
    mapping(uint256 => address) private playerReservedLandForPlayer;
    mapping(uint256 => bool) private playerReservedLandClaimed;
    
    EnumerableSet.UintSet private takenT3Chunks;

    function initialize(CBKLand _cbkLand)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = false;

        _allowedLandOffset = 2;
        _allowedLandSalePerChunk = 99; // At least 1 reserved for T3
        availableLand[TIER_ONE] = 1000; // Placeholder value
        availableLand[TIER_TWO] = 100; // Placeholder value
        availableLand[TIER_THREE] = 10; // Placeholder value

        cbkLand = _cbkLand;
    }

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier saleAllowed() {
        require(_enabled, "Sales disabled");
        _;
    }

    modifier reservedSaleAllowed() {
        require(_reservedEnabled, "Sales disabled");
        _;
    }

    modifier canPurchase(address buyer) {
        require(purchaseAddressMapping[buyer].purchasedTier == 0, "Already purchased");
        _;
    }

    modifier chunkAvailable(uint256 chunkId) {
        require(chunkId <= MAX_CHUNK_ID, "Chunk not valid");
        require(!reservedChunkIds.contains(chunkId), "Chunk reserved");
        require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "Chunk not available");
        require(_chunkAvailableForT2(chunkId), "Chunk overpopulated");
        _;
    }

    // modifier reservedChunkAvailable(uint256 chunkId) {
    //     require(chunkId <= MAX_CHUNK_ID, "Chunk not valid");
    //     require(reservedChunks[msg.sender].contains(chunkId), "Chunk not reserved");
    //     require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "Chunk not available");
    //     _;
    // }

    // Will not overcomplicate the math on this one. Keeping it simple on purpose for gas cost.
    // Limited to t2 because T3 not many and T1 round robins
    function _chunkAvailableForT2(uint256 chunkId) internal view returns (bool) {
        return chunksWithT2Land == 0 ||
            (chunkT2LandSales[chunkId] + 1 < _allowedLandOffset + t2LandsSold / chunksWithT2Land);
    }

    modifier t3Available(uint256 chunkId) {
        require(_chunkAvailableForT3(chunkId), "T3 not available");
        _;
    }

    function _chunkAvailableForT3(uint256 chunkId) internal view returns (bool) {
        return chunkT3LandSoldTo[chunkId] == address(0);
    }

    modifier tierAvailable(uint256 tier) {
        require(availableLand[tier] > 0, "Tier not available");
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    function giveT1Land(address buyer) public saleAllowed canPurchase(buyer) tierAvailable(TIER_ONE) restricted {
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_ONE, t1LandsSold, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        emit T1Given(buyer, t1LandsSold);
        t1LandsSold++;
        availableLand[TIER_ONE]--;
        cbkLand.mint(buyer, TIER_ONE, 0);
    }

    function giveT2Land(address buyer, uint256 chunkId) public saleAllowed canPurchase(buyer) tierAvailable(TIER_TWO) chunkAvailable(chunkId) restricted {
        // First t2 sale
        if(chunkT2LandSales[chunkId] == 0){
            chunksWithT2Land++;
        }

        t2LandsSold++;
        chunkT2LandSales[chunkId]++;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_TWO, chunkId, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_TWO]--;

        emit T2Given(buyer, chunkId);
        cbkLand.mint(buyer, TIER_TWO, chunkId);
    }

    function giveT3Land(address buyer, uint256 chunkId) public saleAllowed canPurchase(buyer) tierAvailable(TIER_THREE) chunkAvailable(chunkId) t3Available(chunkId) restricted {
        t3LandsSold++;
        
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_THREE, chunkId, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_THREE]--;
        chunkT3LandSoldTo[chunkId] = buyer;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        takenT3Chunks.add(chunkId);
        emit T3Given(buyer, chunkId);
        cbkLand.mint(buyer, TIER_THREE, chunkId);
    }

    function giveT1LandFree(address buyer) public tierAvailable(TIER_ONE) restricted {
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_ONE, t1LandsSold, true);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        emit T1GivenFree(buyer, t1LandsSold);
        t1LandsSold++;
        availableLand[TIER_ONE]--;
        cbkLand.mint(buyer, TIER_ONE, 0);
    }

    function giveT2LandFree(address buyer, uint256 chunkId) public tierAvailable(TIER_TWO) chunkAvailable(chunkId) restricted {
        // First t2 sale
        if(chunkT2LandSales[chunkId] == 0){
            chunksWithT2Land++;
        }

        t2LandsSold++;
        chunkT2LandSales[chunkId]++;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_TWO, chunkId, true);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_TWO]--;

        emit T2GivenFree(buyer, chunkId);
        cbkLand.mint(buyer, TIER_TWO, chunkId);
    }

    function giveT3LandFree(address buyer, uint256 chunkId) public tierAvailable(TIER_THREE) chunkAvailable(chunkId) t3Available(chunkId) restricted {
        t3LandsSold++;
        
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_THREE, chunkId, true);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_THREE]--;
        chunkT3LandSoldTo[chunkId] = buyer;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;
        takenT3Chunks.add(chunkId);
        emit T3GivenFree(buyer, chunkId);
        cbkLand.mint(buyer, TIER_THREE, chunkId);
    }

    // function giveLandToken(address buyer, uint256 tier) public reservedSaleAllowed() {
    //     require(resellerLandBudget[msg.sender][tier] > 0); // will protect against invalid tiers
    //     resellerLandBudget[msg.sender][tier]--;
    //     cbkLand.mintLandToken(msg.sender, buyer, tier);
    //     emit LandTokenGiven(msg.sender, buyer, tier);
    // }

    // function getResellerBudget(address reseller) public view returns (uint256 t1, uint256 t2, uint256 t3) {
    //     t1 = resellerLandBudget[reseller][TIER_ONE];
    //     t2 = resellerLandBudget[reseller][TIER_TWO];
    //     t3 = resellerLandBudget[reseller][TIER_THREE];
    // }

    // function setResellerBudget(address reseller, uint256 t1, uint256 t2, uint256 t3) public restricted {
    //     resellerLandBudget[reseller][TIER_ONE] = t1;
    //     resellerLandBudget[reseller][TIER_TWO] = t2;
    //     resellerLandBudget[reseller][TIER_THREE] = t3;
    // }

    // Solidity hates polymorphism for this particular function
    function giveT1LandReservedBulk(address[] memory players, address reseller) public restricted {
        for (uint256 i = 0; i < players.length; i++) {
            giveT1LandReserved(players[i], reseller);
        }
    }

    function giveT1LandReserved(address player, address reseller) public restricted {
        uint256 rcLength = reservedChunks[reseller].length();
        require(rcLength > 0, "no reserved chunks");
        uint256 counter = reservedChunksCounter[reseller];
        for(uint256 i = counter; i < counter + rcLength; i++){
            uint256 cId = reservedChunks[reseller].at(uint256(i % rcLength));
            // it's actually a T1, but we will play on the T2 because population is shared
            if(chunkT2LandSales[cId] < _allowedLandSalePerChunk) {
                if(chunkT2LandSales[cId] == 0){
                    chunksWithT2Land++;
                }
                chunkT2LandSales[cId]++;
                chunkZoneLandSales[chunkIdToZoneId(cId)]++;
                cbkLand.mint(player, TIER_ONE, cId, reseller);
                emit T1GivenReserved(reseller, player, cId);
                reservedChunksCounter[reseller] = uint256(i + 1);
                return;
            }
        }

        // Could not find a land
        revert();
    }

    function giveT1LandReservedBulk(address[] memory players, address reseller, uint256 chunkId) public restricted {
        require(reservedChunks[reseller].contains(chunkId), "not reserved");
        for (uint256 i = 0; i < players.length; i++) {
            giveT1LandReserved(players[i], reseller, chunkId);
        }
    }

    function giveT1LandReserved(address player, address reseller, uint256 chunkId) public restricted {
        require(reservedChunks[reseller].contains(chunkId), "not reserved");
        if(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk) {
            if(chunkT2LandSales[chunkId] == 0){
                chunksWithT2Land++;
            }
            chunkT2LandSales[chunkId]++;
            chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;
            cbkLand.mint(player, TIER_ONE, chunkId, reseller);
            emit T1GivenReserved(reseller, player, chunkId);
             return;
        }
        // Could not find a land
        revert();
    }

    // function giveT2LandReserved(address buyer, uint256 chunkId) public reservedChunkAvailable(chunkId) reservedSaleAllowed() {
    //      if(chunkT2LandSales[chunkId] == 0){
    //         chunksWithT2Land++;
    //     }

    //     chunkT2LandSales[chunkId]++;
    //     chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

    //     emit T2GivenReserved(msg.sender, buyer, chunkId);
    //     cbkLand.mint(buyer, TIER_TWO, chunkId);
    // }

    // function giveT3LandReserved(address buyer, uint256 chunkId) public reservedChunkAvailable(chunkId) t3Available(chunkId) reservedSaleAllowed() {
    //     chunkT3LandSoldTo[chunkId] = buyer;
    //     chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

    //     emit T3GivenReserved(msg.sender, buyer, chunkId);
    //     cbkLand.mint(buyer, TIER_THREE, chunkId);
    // }

    // Will leave this commented
    // function setLandURI(uint256 landId, string memory uri) public {
    //     (, uint256 chunkId,,) = cbkLand.get(landId);
    //     require(reservedChunks[msg.sender].contains(chunkId), "no access");
    //     cbkLand.setURI(landId, uri);
    // }

    function chunkIdToZoneId(uint256 chunkId) internal pure returns (uint256){
        return 10 * (chunkId / 1000) + (chunkId % 100) / 10;
    }

    function salesAllowed() public view returns (bool){
        return _enabled;
    }

    function reservedSalesAllowed() public view returns (bool){
        return _reservedEnabled;
    }

    function getAllowedLandOffset()  public view returns (uint256){
        return _allowedLandOffset;
    }

    function checkIfChunkAvailable(uint256 tier, uint256 chunkId) public view returns (bool){
        if(reservedChunkIds.contains(chunkId)){
            return false;
        }

        if(chunkId > MAX_CHUNK_ID){
            return false;
        }

        if(tier == TIER_ONE){
            return availableLand[TIER_ONE] > 0;
        }

        if(tier == TIER_TWO){
            return availableLand[TIER_TWO] > 0
                    && chunkT2LandSales[TIER_TWO] < _allowedLandSalePerChunk
                    && _chunkAvailableForT2(chunkId);
        }

        if(tier == TIER_THREE){
            return availableLand[TIER_THREE] > 0
                    && _chunkAvailableForT3(chunkId);
        }

        return false;
    }

    function checkChunkReserved(uint256 chunkId) public view returns (bool){
        return reservedChunkIds.contains(chunkId);
    }

    function getAllZonesPopulation() public view returns (uint256[] memory) {
        uint256[] memory toReturn = new uint256[](100);

        for (uint256 i = 0; i < 100; i++) {
            toReturn[i] = chunkZoneLandSales[i];
        }

        return toReturn;
    }

    function getZonePopulation(uint256[] memory zoneIds) public view returns (uint256[] memory) {
        require(zoneIds.length > 0 && zoneIds.length <= 100, "invalid request");
        uint256[] memory toReturn = new uint256[](zoneIds.length);

        for (uint256 i = 0; i < zoneIds.length; i++) {
            toReturn[i] = chunkZoneLandSales[zoneIds[i]];
        }

        return toReturn;
    }

    function getZoneChunkPopulation(uint256 zoneId) public view returns (uint256[] memory) {
        require(zoneId < 100, "invalid request");
        uint256 zoneX = zoneId % 10;
        uint256 zoneY = zoneId / 10;

        uint256[] memory toReturn = new uint256[](100);
        uint256 counter = 0;

        for(uint256 j = zoneY * 1000; j < zoneY * 1000 + 1000; j += 100) {
            for(uint256 i = zoneX * 10; i < zoneX * 10 + 10; i++) {
                uint256 projectedId = i + j;
                toReturn[counter++] = chunkT2LandSales[projectedId] + (chunkT3LandSoldTo[projectedId] != address(0) ? 1 : 0);
            }
        }

        return toReturn;
    }

    function getChunkPopulation(uint256[] memory chunkIds) public view returns (uint256[] memory) {
        require(chunkIds.length > 0 && chunkIds.length <= 100, "invalid request");
        uint256[] memory toReturn = new uint256[](chunkIds.length);

        for (uint256 i = 0; i < chunkIds.length; i++) {
            toReturn[i] = chunkT2LandSales[chunkIds[i]] + (chunkT3LandSoldTo[chunkIds[i]] != address(0) ? 1 : 0);
        }

        return toReturn;
    }

    function getAvailableLand()  public view returns (uint256, uint256, uint256) {
        return (availableLand[TIER_ONE], availableLand[TIER_TWO], availableLand[TIER_THREE]);
    }

    function getAvailableLandPerChunk()  public view returns (uint256) {
        return _allowedLandSalePerChunk;
    }

    function getSoldLand()  public view returns (uint256, uint256, uint256) {
        return (t1LandsSold, t2LandsSold, t3LandsSold);
    }

    function getPopulatedT2Chunks()  public view returns (uint256) {
        return chunksWithT2Land;
    }

    function getPurchase()  public view returns (uint256, uint256) {
        return (purchaseAddressMapping[msg.sender].purchasedTier, purchaseAddressMapping[msg.sender].stamp);
    }

    function getPurchaseOf(address owner)  public view returns (uint256, uint256) {
        return (purchaseAddressMapping[owner].purchasedTier, purchaseAddressMapping[owner].stamp);
    }

    function getSalesCount() public view returns (uint256){
        return totalSales;
    }

    function getPurchaseBySale(uint256 sale)  public view returns (address, uint256, uint256) {
        return (sales[sale].buyer, sales[sale].purchasedTier, sales[sale].stamp);
    }

    function setSaleAllowed(bool allowed) external isAdmin {
        _enabled = allowed;
    }

    function setReservedSaleAllowed(bool allowed) external isAdmin {
        _reservedEnabled = allowed;
    }

    // do NOT use this for reserve false unless really needed. This doesn't update reseller data
    // the purpose of this function is to provide a cheap way to bulk reserve blocks that don't have resellers
    function setChunksReservation(uint256[] calldata chunkIds, bool reserved) external isAdmin {
        for (uint256 i = 0; i < chunkIds.length; i++) {
            
            if(reserved && !reservedChunkIds.contains(chunkIds[i])) {
                reservedChunkIds.add(chunkIds[i]);
            }

            if(!reserved) {
                reservedChunkIds.remove(chunkIds[i]);
            }
        }
    }

    // be careful with forced, a chunkId may still remain attached to an existing reseller
    // forced should not be used unless something is really wrong
    function setChunksReservationInfo(uint256[] calldata chunkIds, address reserveFor, bool reserved, bool forced) external isAdmin {
        for (uint256 i = 0; i < chunkIds.length; i++) {
            require (chunkIds[i] != 0, "0 NA"); // chunk id 0 shouldn't be reserved
            require(!reserved || (forced || chunksReservedFor[chunkIds[i]] == address(0)), "AS"); // already reserved, request has to be forced to avoid issues
            
            if(reserved && !reservedChunkIds.contains(chunkIds[i])) {
                reservedChunkIds.add(chunkIds[i]);
            }

            if(!reserved) {
                reservedChunkIds.remove(chunkIds[i]);
                chunksReservedFor[chunkIds[i]] = address(0);
                 reservedChunks[reserveFor].remove(chunkIds[i]);
            }

            if(reserved && !reservedChunks[reserveFor].contains(chunkIds[i])) {
                reservedChunks[reserveFor].add(chunkIds[i]);
                chunksReservedFor[chunkIds[i]] = reserveFor;
            }
        }
    }

    function givePlayersReservedLand(address[] calldata players, address reseller, uint256 tier) external isAdmin {
        for (uint256 i = 0; i < players.length; i++) {
            playerReservedLands[players[i]].add(++playerReservedLandAt);
            playerReservedLandTier[playerReservedLandAt] = tier;
            playerReservedLandReseller[playerReservedLandAt] = reseller;
            playerReservedLandForPlayer[playerReservedLandAt] = players[i];
        }
    }

    function getPlayerReservedLand(address player) public view returns(uint256[] memory t2Reservations, uint256[] memory t3Reservations) {
        uint256 amount = playerReservedLands[player].length();
        uint256 t2Count = 0;
        uint256 t3Count = 0;
         for (uint256 i = 0; i < amount; i++) {
            uint256 reservation = playerReservedLands[player].at(i);
            uint256 reservedTier = playerReservedLandTier[reservation];
           if(reservedTier == 2) {
               t2Count++;
           }
           else if(reservedTier == 3) {
               t3Count++;
           }
        }

        if(t2Count == 0 && t3Count == 0) {
            return (new uint256[](0), new uint256[](0));
        }

        t2Reservations = new uint256[](t2Count); 
        t3Reservations = new uint256[](t3Count); 
        t2Count = 0;
        t3Count = 0;

        for (uint256 i = 0; i < amount; i++) {
            uint256 reservation = playerReservedLands[player].at(i);
            uint256 reservedTier = playerReservedLandTier[reservation];
           if(reservedTier == 2) {
               t2Reservations[t2Count++] = reservation;
           }
           else if(reservedTier == 3) {
               t3Reservations[t3Count++] = reservation;
           }
        }
    }

    function getChunksOfReservations(uint256 reservationId) public view returns (uint256[] memory chunkIds) {
        address reseller = playerReservedLandReseller[reservationId];
        return getChunksOfReseller(reseller);
    }

    function getInfoOfReservation(uint256 reservationId) public view returns (address player, address reseller, uint256 tier, bool claimed) {
        return (playerReservedLandForPlayer[reservationId], playerReservedLandReseller[reservationId], playerReservedLandTier[reservationId], playerReservedLandClaimed[reservationId]);
    }

    function getChunksOfReseller(address reservedFor) public view  returns (uint256[] memory chunkIds) {
        uint256 amount = reservedChunks[reservedFor].length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = reservedChunks[reservedFor].at(i);
                chunkIds[index++] = id;
        }
    }

    function claimPlayerReservedLand(uint256 reservation, uint256 chunkId, uint256 tier) public reservedSaleAllowed {
        require(tier != 1, "NT1");
        require(playerReservedLandClaimed[reservation] == false, "AC"); // already claimed
        require(playerReservedLands[msg.sender].contains(reservation), "IR"); // invalid reservation
        require(playerReservedLandTier[reservation] == tier, "IT"); // invalid tier
        address reseller = playerReservedLandReseller[reservation];
        require(reservedChunks[reseller].contains(chunkId), "IR2"); // invalid reseller

        if(tier == 3) {
            require(_chunkAvailableForT3(chunkId), "T3 NA"); 
            chunkT3LandSoldTo[chunkId] = msg.sender;
            takenT3Chunks.add(chunkId);
        }

        if(tier == 2) {
            require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "T2 NA");
            if(chunkT2LandSales[chunkId] == 0){
                chunksWithT2Land++;
            }
            chunkT2LandSales[chunkId]++;
        }
        
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;
        playerReservedLands[msg.sender].remove(reservation);
        playerReservedLandClaimed[reservation] = true;
        cbkLand.mint(msg.sender, tier, chunkId, reseller);
        emit ReservedLandClaimed(reservation, reseller, msg.sender, tier, chunkId);
    }

    function getResellerOfChunk(uint256 chunkId) public view  returns (address reservedFor) {
        reservedFor = chunksReservedFor[chunkId];
    }

    function getReservedChunksIds() public view  returns (uint256[] memory chunkIds) {
        uint256 amount = reservedChunkIds.length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = reservedChunkIds.at(i);
                chunkIds[index++] = id;
        }
    }

    function getTakenT3Chunks() public view  returns (uint256[] memory chunkIds) {
        uint256 amount = takenT3Chunks.length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = takenT3Chunks.at(i);
                chunkIds[index++] = id;
        }
    }

    function setAllowedLandOffset(uint256 allowedOffset) external isAdmin {
        _allowedLandOffset = allowedOffset;
    }

    function setAllowedLandPerChunk(uint256 allowedLandSalePerChunk) external isAdmin {
        _allowedLandSalePerChunk = allowedLandSalePerChunk;
    }

    function setAvailableLand(uint256 tier, uint256 available) external isAdmin {
        require(tier >= TIER_ONE && tier <= TIER_THREE, "Invalid tier");
        availableLand[tier] = available;
    }
}