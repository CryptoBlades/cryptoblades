pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";
import "./interfaces/IPriceOracle.sol";

contract NFTMarket is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using ABDKMath64x64 for int128; // kroge beware
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize (IERC20 _skillToken, address _taxAddress) public initializer {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        skillToken = _skillToken;

        taxAddress = _taxAddress;
        defaultTax = ABDKMath64x64.divu(1, 10); // 10%
    }

    // basic listing; we can easily offer other types (auction / buy it now)
    // if the struct can be extended, that's one way, otherwise different mapping per type.
    struct Listing {
        address seller;
        uint256 price;
        //int128 usdTether; // this would be to "tether" price dynamically to our oracle
    }

    IERC20 public skillToken;//0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab;
    address public taxAddress;//game contract
    //IPriceOracle public priceOracleSkillPerUsd; // we may want this for dynamic pricing

    IERC721[] public listedTokenTypes; // stored for a way to know the types we have on offer
    mapping(IERC721 => uint256) private tokenTypeIndex;

    mapping(IERC721 => bool) public tokenBans;
    mapping(address => bool) public userBans;

    mapping(IERC721 => int128) public tax; // per NFT type tax
    mapping(IERC721 => bool) private freeTax; // since tax is 0-default, this specifies it to fix an exploit
    int128 public defaultTax; // fallback in case we haven't specified it

    mapping(IERC721 => uint256) private listingCounts; // helps with registering new types
    mapping(IERC721 => mapping(uint256/*ID*/ => Listing)) private listings;
    mapping(IERC721 => EnumerableSet.UintSet) private listedTokenIDs;

    event NewListing(address indexed seller, IERC721 indexed nftAddress, uint256 indexed nftID, uint256 price);
    event ListingPriceChange(address indexed seller, IERC721 indexed nftAddress, uint256 indexed nftID, uint256 newPrice);
    event CancelledListing(address indexed seller, IERC721 indexed nftAddress, uint256 indexed nftID);
    event PurchasedListing(address indexed buyer, address seller, IERC721 indexed nftAddress, uint256 indexed nftID, uint256 price);

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    modifier isSeller(IERC721 tokenAddress, uint256 id) {
        require(listings[tokenAddress][id].seller == msg.sender, "Access denied");
        _;
    }

    modifier isSellerOrAdmin(IERC721 tokenAddress, uint256 id) {
        require(listings[tokenAddress][id].seller == msg.sender
            || hasRole(GAME_ADMIN, msg.sender), "Access denied");
        _;
    }

    modifier tokenNotBanned(IERC721 tokenAddress) {
        require(tokenBans[tokenAddress] == false, "This type of NFT may not be traded here");
        _;
    }

    modifier userNotBanned() {
        require(userBans[msg.sender] == false, "Forbidden access");
        _;
    }

    function recoverSkill(uint256 amount) public restricted {
        skillToken.transfer(msg.sender, amount); // dont expect we'll hold tokens here but might as well
    }

    function getListingIDs(IERC721 tokenAddress) public view returns (uint256[] memory) {
        EnumerableSet.UintSet storage set = listedTokenIDs[tokenAddress];
        uint256[] memory tokens = new uint256[](set.length());

        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = set.at(i);
        }
        return tokens;
    }

    function getNumberOfListingsBySeller(IERC721 tokenAddress, address seller) public view returns (uint256) {
        return getListingIDsBySeller(tokenAddress, seller).length;
    }

    function getListingIDsBySeller(IERC721 tokenAddress, address seller) public view returns (uint256[] memory) {
        uint256[] memory listedTokens = getListingIDs(tokenAddress);

        // correct me if I'm wrong but we cant have dynamic arrays in memory?
        // so we gotta do this double take?
        uint256 amount = 0;
        for(uint256 i = 0; i < listedTokens.length; i++) {
            if(listings[tokenAddress][listedTokens[i]].seller == seller)
                amount = amount.add(1);
        }

        uint256[] memory tokens = new uint256[](amount);

        uint256 index = 0;
        for(uint256 i = 0; i < tokens.length; i++) {
            uint256 id = listedTokens[i];
            if(listings[tokenAddress][id].seller == seller)
                tokens[index++] = id;
        }
    }

    function getNumberOfListingsForToken(IERC721 tokenAddress) public view returns (uint256) {
        return listingCounts[tokenAddress];
    }

    function getSellerPrice(IERC721 tokenAddress, uint256 id) public view returns (uint256) {
        return listings[tokenAddress][id].price;
    }

    function getFinalPrice(IERC721 tokenAddress, uint256 id) public view returns (uint256) {
        return getSellerPrice(tokenAddress, id).add(getTaxOnListing(tokenAddress, id));
    }

    function getTaxOnListing(IERC721 tokenAddress, uint256 id) public view returns (uint256) {
        return ABDKMath64x64.mulu(tax[tokenAddress], getSellerPrice(tokenAddress, id));
    }

    function setTaxOnTokenType(IERC721 tokenAddress, int128 newTax) public restricted {
        require(newTax >= 0, "We're not running a charity here");
        tax[tokenAddress] = newTax;
        freeTax[tokenAddress] = newTax == 0;
    }

    function addListing(IERC721 tokenAddress, uint256 id, uint256 price) public
            userNotBanned
            tokenNotBanned(tokenAddress) {

        // in theory the transfer and required approval already test non-owner operations
        tokenAddress.safeTransferFrom(msg.sender, address(this), id);
        listings[tokenAddress][id] = Listing(msg.sender, price);
        listedTokenIDs[tokenAddress].add(id);

        // if this is the first listing of its kind, we jot down the address for later use
        if(listingCounts[tokenAddress] == 0)
            registerTokenAddress(tokenAddress);
        listingCounts[tokenAddress] = listingCounts[tokenAddress].add(1);

        emit NewListing(msg.sender, tokenAddress, id, price);
    }

    function changeListingPrice(IERC721 tokenAddress, uint256 id, uint256 newPrice) public
            userNotBanned
            isSeller(tokenAddress, id) {

        listings[tokenAddress][id].price = newPrice;
        emit ListingPriceChange(msg.sender, tokenAddress, id, newPrice);
    }

    function cancelListing(IERC721 tokenAddress, uint256 id) public
            userNotBanned
            isSellerOrAdmin(tokenAddress, id) {
        tokenAddress.safeTransferFrom(address(this), msg.sender, id);
        delete listings[tokenAddress][id];
        listedTokenIDs[tokenAddress].remove(id);

        // if this is the last listing of its kind, we forget the address
        if(listingCounts[tokenAddress] == 1)
            unregisterTokenAddress(tokenAddress);
        listingCounts[tokenAddress] = listingCounts[tokenAddress].sub(1);

        emit CancelledListing(msg.sender, tokenAddress, id);
    }

    function purchaseListing(IERC721 tokenAddress, uint256 id, uint256 maxPrice) public
            userNotBanned
            tokenNotBanned(tokenAddress) {
        uint256 finalPrice = getFinalPrice(tokenAddress, id);
        require(finalPrice <= maxPrice, "Buying price too low");

        Listing memory listing = listings[tokenAddress][id];
        IERC721 tokenType = IERC721(tokenAddress);

        uint256 taxAmount = getTaxOnListing(tokenAddress, id);
        skillToken.transferFrom(msg.sender, taxAddress, taxAmount);
        skillToken.transferFrom(msg.sender, listing.seller, finalPrice.sub(taxAmount));
        tokenType.safeTransferFrom(address(this), msg.sender, id);
        delete listings[tokenAddress][id];
        listedTokenIDs[tokenAddress].remove(id);

        // if this is the last listing of its kind, we forget the address
        if(listingCounts[tokenAddress] == 1)
            unregisterTokenAddress(tokenAddress);
        listingCounts[tokenAddress] = listingCounts[tokenAddress].sub(1);

        emit PurchasedListing(msg.sender, listing.seller, tokenAddress, id, finalPrice);
    }

    function registerTokenAddress(IERC721 tokenAddress) private {
        tokenTypeIndex[tokenAddress] = listedTokenTypes.length;
        listedTokenTypes.push(tokenAddress);

        // this prevents resetting custom tax by removing all
        if(tax[tokenAddress] == 0 // unset or intentionally free
            && freeTax[tokenAddress] == false)
            tax[tokenAddress] = defaultTax;
    }

    function unregisterTokenAddress(IERC721 tokenAddress) private {
        uint256 lastIndex = listedTokenTypes.length.sub(1);
        IERC721 movedTokenType = listedTokenTypes[lastIndex];
        uint256 movingIndex = tokenTypeIndex[tokenAddress];

        listedTokenTypes[movingIndex] = movedTokenType;
        tokenTypeIndex[movedTokenType] = movingIndex;

        delete listedTokenTypes[lastIndex];
        delete tokenTypeIndex[tokenAddress];
    }

    function setTaxAddress(address newAddress) public restricted {
        taxAddress = newAddress;
    }

    function setDefaultTax(int128 newDefaultTax) public restricted {
        defaultTax = newDefaultTax;
    }

    function setUserBan(address user, bool to) public restricted {
        userBans[user] = to;
    }

    function setTokenBan(IERC721 token, bool to) public restricted {
        tokenBans[token] = to;
    }
}