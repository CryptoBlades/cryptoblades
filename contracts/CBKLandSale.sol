pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract CBKLandSale is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

     /* ========== EVENTS ========== */
    event T1Given(address indexed owner, uint32 stamp);
    event T2Given(address indexed owner, uint16 chunkId);
    event T3Given(address indexed owner, uint16 chunkId);


    /* ========== LAND SALE INFO ========== */
    uint8 private constant NO_LAND = 0;
    uint8 public constant TIER_ONE = 1;
    uint8 public constant TIER_TWO = 2;
    uint8 public constant TIER_THREE = 3;
    uint16 private constant MAX_CHUNK_ID = 9999; // 100 x 100

    struct purchaseInfo {
        address buyer;
        uint8 purchasedTier;
        uint32 stamp; // chunkId or roundrobin stamp
    }

    uint256 private totalSales;
    mapping(uint256 => purchaseInfo) public sales; // Put all sales in an mapping for easier tracking
    mapping(address => purchaseInfo) public purchaseAddressMapping;
    mapping(uint8 => uint32) public availableLand; // Land that is up for sale. 
    mapping(uint16 => uint16) public chunkZoneLandSales;

    /* ========== T1 LAND SALE INFO ========== */
    // T1 land is sold with no exact coordinates commitment and assigned based on round robin
    // once minting is done. For now the player gets a stamp which can reflect PROJECTED land coordinates
    // should it need be.
    uint32 private t1LandsSold;



    /* ========== T2 LAND SALE INFO ========== */
    uint32 private t2LandsSold;
    uint16 private chunksWithT2Land;

    uint8 private constant MAX_LAND = 100;
    uint8 private _allowedLandSalePerChunk;
    uint8 private _allowedLandOffset; // Max allowed deviation allowed from theoretical average

    // T2 sold per chunk
    mapping(uint16 => uint8) public chunkT2LandSales;


    /* ========== T3 LAND SALE INFO ========== */
    uint32 private t3LandsSold;
    mapping(uint16 => address) public chunkT3LandSoldTo;


    /* ========== RESERVED CHUNKS SALE INFO ========== */
    mapping(uint16 => bool) public chunkReserved;
    
    bool internal _enabled;

    function initialize()
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = true;

        _allowedLandOffset = 2;
        _allowedLandSalePerChunk = 99; // At least 1 reserved for T3
        availableLand[TIER_ONE] = 1000; // Placeholder value
        availableLand[TIER_TWO] = 100; // Placeholder value
        availableLand[TIER_THREE] = 10; // Placeholder value
    }

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier saleAllowed() {
        require(_enabled, "Sales disabled");
        _;
    }

    modifier chunkAvailable(uint16 chunkId) {
        require(chunkId <= MAX_CHUNK_ID, "Chunk not valid");
        require(!chunkReserved[chunkId], "Chunk reserved");
        require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "Chunk not available");
        require(_chunkAvailableForT2(chunkId), "Chunk overpopulated");
        _;
    }

    // Will not overcomplicate the math on this one. Keeping it simple on purpose for gas cost.
    // Limited to t2 because T3 not many and T1 round robins
    function _chunkAvailableForT2(uint16 chunkId) internal view returns (bool) {
        return chunksWithT2Land == 0 ||
            (chunkT2LandSales[chunkId] + 1 < _allowedLandOffset + t2LandsSold / chunksWithT2Land);
    }

    modifier t3Available(uint16 chunkId) {
        require(_chunkAvailableForT3(chunkId), "T3 not available");
        _;
    }

    function _chunkAvailableForT3(uint16 chunkId) internal view returns (bool) {
        return chunkT3LandSoldTo[chunkId] == address(0);
    }

    modifier tierAvailable(uint8 tier) {
        require(availableLand[tier] > 0, "Tier not available");
        _;
    }

    modifier canPurchase(address buyer) {
        require(purchaseAddressMapping[buyer].purchasedTier == NO_LAND, "Cannot purchase more than one land");
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    function giveT1Land(address buyer) public saleAllowed tierAvailable(TIER_ONE) canPurchase(buyer) restricted {
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_ONE, t1LandsSold);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        emit T1Given(buyer, t1LandsSold);
        t1LandsSold++;
        availableLand[TIER_ONE]--;
    }

    function giveT2Land(address buyer, uint16 chunkId) public saleAllowed tierAvailable(TIER_TWO) canPurchase(buyer) chunkAvailable(chunkId) restricted {
        // First t2 sale
        if(chunkT2LandSales[chunkId] == 0){
            chunksWithT2Land++;
        }

        t2LandsSold++;
        chunkT2LandSales[chunkId]++;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_TWO, uint32(chunkId));
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_TWO]--;

        emit T2Given(buyer, chunkId);
    }

    function giveT3Land(address buyer, uint16 chunkId) public saleAllowed tierAvailable(TIER_THREE) canPurchase(buyer) chunkAvailable(chunkId) t3Available(chunkId) restricted {
        t3LandsSold++;
        
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_THREE, chunkId);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_THREE]--;
        chunkT3LandSoldTo[chunkId] = buyer;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        emit T3Given(buyer, chunkId);
    }

    function chunkIdToZoneId(uint32 chunkId) internal pure returns (uint8){
        return uint8(10 * (chunkId / 1000) + (chunkId % 100) / 10);
    }

    function salesAllowed() public view returns (bool){
        return _enabled;
    }

    function getAllowedLandOffset()  public view returns (uint8){
        return _allowedLandOffset;
    }

    function checkIfChunkAvailable(uint8 tier, uint16 chunkId) public view returns (bool){
        if(chunkReserved[chunkId]){
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
                    && chunkT2LandSales[TIER_TWO] < _allowedLandSalePerChunk
                    && _chunkAvailableForT3(chunkId);
        }

        return false;
    }

    function checkChunkReserved(uint16 chunkId) public view returns (bool){
        return chunkReserved[chunkId];
    }

    function getAllZonesPopulation() public view returns (uint16[] memory) {
        uint16[] memory toReturn = new uint16[](100);

        for (uint8 i = 0; i < 100; i++) {
            toReturn[i] = chunkZoneLandSales[i];
        }

        return toReturn;
    }

    function getZonePopulation(uint16[] memory zoneIds) public view returns (uint16[] memory) {
        require(zoneIds.length > 0 && zoneIds.length <= 100, "invalid request");
        uint16[] memory toReturn = new uint16[](zoneIds.length);

        for (uint8 i = 0; i < zoneIds.length; i++) {
            toReturn[i] = chunkZoneLandSales[zoneIds[i]];
        }

        return toReturn;
    }

    function getZoneChunkPopulation(uint8 zoneId) public view returns (uint8[] memory) {
        require(zoneId < 100, "invalid request");
        uint8 zoneX = zoneId % 10;
        uint8 zoneY = zoneId / 10;

        uint8[] memory toReturn = new uint8[](100);
        uint8 counter = 0;

        for(uint16 j = zoneY * 1000; j < zoneY * 1000 + 1000; j += 100) {
            for(uint16 i = zoneX * 10; i < zoneX * 10 + 10; i++) {
                uint16 projectedId = i + j;
                toReturn[counter++] = chunkT2LandSales[projectedId] + (chunkT3LandSoldTo[projectedId] != address(0) ? 1 : 0);
            }
        }

        return toReturn;
    }

    function getChunkPopulation(uint16[] memory chunkIds) public view returns (uint8[] memory) {
        require(chunkIds.length > 0 && chunkIds.length <= 100, "invalid request");
        uint8[] memory toReturn = new uint8[](chunkIds.length);

        for (uint8 i = 0; i < chunkIds.length; i++) {
            toReturn[i] = chunkT2LandSales[chunkIds[i]] + (chunkT3LandSoldTo[chunkIds[i]] != address(0) ? 1 : 0);
        }

        return toReturn;
    }

    function getAvailableLand()  public view returns (uint32, uint32, uint32) {
        return (availableLand[TIER_ONE], availableLand[TIER_TWO], availableLand[TIER_THREE]);
    }

    function getAvailableLandPerChunk()  public view returns (uint8) {
        return _allowedLandSalePerChunk;
    }

    function getSoldLand()  public view returns (uint32, uint32, uint32) {
        return (t1LandsSold, t2LandsSold, t3LandsSold);
    }

    function getPopulatedT2Chunks()  public view returns (uint16) {
        return chunksWithT2Land;
    }

    function getPurchase()  public view returns (uint8, uint32) {
        return (purchaseAddressMapping[msg.sender].purchasedTier, purchaseAddressMapping[msg.sender].stamp);
    }

    function getPurchaseOf(address owner)  public view returns (uint8, uint32) {
        return (purchaseAddressMapping[owner].purchasedTier, purchaseAddressMapping[owner].stamp);
    }

    function getSalesCount() public view returns (uint256){
        return totalSales;
    }

    function getPurchaseBySale(uint256 sale)  public view returns (address, uint8, uint32) {
        return (sales[sale].buyer, sales[sale].purchasedTier, sales[sale].stamp);
    }

    function toggleSaleAllowed(bool allowed) external isAdmin {
        _enabled = allowed;
    }

    function reserveChunks(uint16[] calldata chunkIds, bool reserve) external isAdmin {
        for (uint256 i = 0; i < chunkIds.length; i++) {
            chunkReserved[chunkIds[i]] = reserve;
        }
    }

    function setAllowedLandOffset(uint8 allowedOffset) external isAdmin {
        _allowedLandOffset = allowedOffset;
    }

    function setAllowedLandPerChunk(uint8 allowedLandSalePerChunk) external isAdmin {
        _allowedLandSalePerChunk = allowedLandSalePerChunk;
    }

    function setAvailableLand(uint8 tier, uint8 available) external isAdmin {
        require(tier >= TIER_ONE && tier <= TIER_THREE, "Invalid tier");
        availableLand[tier] = available;
    }
}