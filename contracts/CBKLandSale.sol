pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./CBKLand.sol";

contract CBKLandSale is Initializable, AccessControlUpgradeable {

    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CBKLand cbkLand;
     /* ========== EVENTS ========== */
    event T1Given(address indexed owner, uint256 stamp);
    event T2Given(address indexed owner, uint256 chunkId);
    event T3Given(address indexed owner, uint256 chunkId);
    event T1GivenFree(address indexed owner, uint256 stamp);
    event T2GivenFree(address indexed owner, uint256 chunkId);
    event T3GivenFree(address indexed owner, uint256 chunkId);


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

    uint256 private constant MAX_LAND = 100;
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

    modifier chunkAvailable(uint256 chunkId) {
        require(chunkId <= MAX_CHUNK_ID, "Chunk not valid");
        require(!reservedChunkIds.contains(chunkId), "Chunk reserved");
        require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "Chunk not available");
        require(_chunkAvailableForT2(chunkId), "Chunk overpopulated");
        _;
    }

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

    function giveT1Land(address buyer) public saleAllowed tierAvailable(TIER_ONE) restricted {
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_ONE, t1LandsSold, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        emit T1Given(buyer, t1LandsSold);
        t1LandsSold++;
        availableLand[TIER_ONE]--;
        cbkLand.mint(buyer, TIER_ONE, 0);
    }

    function giveT2Land(address buyer, uint256 chunkId) public saleAllowed tierAvailable(TIER_TWO) chunkAvailable(chunkId) restricted {
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

    function giveT3Land(address buyer, uint256 chunkId) public saleAllowed tierAvailable(TIER_THREE) chunkAvailable(chunkId) t3Available(chunkId) restricted {
        t3LandsSold++;
        
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_THREE, chunkId, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_THREE]--;
        chunkT3LandSoldTo[chunkId] = buyer;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

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

        emit T3GivenFree(buyer, chunkId);
        cbkLand.mint(buyer, TIER_THREE, chunkId);
    }

    function chunkIdToZoneId(uint256 chunkId) internal pure returns (uint256){
        return 10 * (chunkId / 1000) + (chunkId % 100) / 10;
    }

    function salesAllowed() public view returns (bool){
        return _enabled;
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

    function reserveChunks(uint256[] calldata chunkIds, bool reserve) external isAdmin {
        for (uint256 i = 0; i < chunkIds.length; i++) {
            if(reserve && !reservedChunkIds.contains(chunkIds[i])) {
                reservedChunkIds.add(chunkIds[i]);
            }

            if(!reserve) {
                reservedChunkIds.remove(chunkIds[i]);
            }
        }
    }

    function getReservedChunksIds() public view  returns (uint256[] memory chunkIds) {

        uint256 amount = reservedChunkIds.length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < reservedChunkIds.length(); i++) {
            uint256 id = reservedChunkIds.at(i);
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