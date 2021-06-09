// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./interfaces/IPriceOracle.sol";

// *****************************************************************************
// *** NOTE: almost all uses of _tokenAddress in this contract are UNSAFE!!! ***
// *****************************************************************************
contract NFTMarket is
    IERC721ReceiverUpgradeable,
    Initializable,
    AccessControlUpgradeable
{
    //using SafeMath for uint256;
    using ABDKMath64x64 for int128; // kroge beware
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    // ############
    // Initializer
    // ############
    function initialize(IERC20 _skillToken, address _taxRecipient)
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        skillToken = _skillToken;

        taxRecipient = _taxRecipient;
        defaultTax = ABDKMath64x64.divu(1, 10); // 10%
    }

    // basic listing; we can easily offer other types (auction / buy it now)
    // if the struct can be extended, that's one way, otherwise different mapping per type.
    struct Listing {
        address seller;
        uint256 price;
        //int128 usdTether; // this would be to "tether" price dynamically to our oracle
    }

    // ############
    // State
    // ############
    IERC20 public skillToken; //0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab;
    address public taxRecipient; //game contract
    //IPriceOracle public priceOracleSkillPerUsd; // we may want this for dynamic pricing

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => mapping(uint256 => Listing)) private listings;
    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => EnumerableSet.UintSet) private listedTokenIDs;
    // address is IERC721
    EnumerableSet.AddressSet private listedTokenTypes; // stored for a way to know the types we have on offer

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => bool) public isTokenBanned;
    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => bool) public isUserBanned;

    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => int128) public tax; // per NFT type tax
    // address is IERC721 -- kept like this because of OpenZeppelin upgrade plugin bug
    mapping(address => bool) private freeTax; // since tax is 0-default, this specifies it to fix an exploit
    int128 public defaultTax; // fallback in case we haven't specified it

    // ############
    // Events
    // ############
    event NewListing(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        uint256 price
    );
    event ListingPriceChange(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        uint256 newPrice
    );
    event CancelledListing(
        address indexed seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID
    );
    event PurchasedListing(
        address indexed buyer,
        address seller,
        IERC721 indexed nftAddress,
        uint256 indexed nftID,
        uint256 price
    );

    // ############
    // Modifiers
    // ############
    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    modifier isListed(IERC721 _tokenAddress, uint256 id) {
        require(
            listedTokenTypes.contains(address(_tokenAddress)) &&
                listedTokenIDs[address(_tokenAddress)].contains(id),
            "Token ID not listed"
        );
        _;
    }

    modifier isNotListed(IERC721 _tokenAddress, uint256 id) {
        require(
            !listedTokenTypes.contains(address(_tokenAddress)) ||
                !listedTokenIDs[address(_tokenAddress)].contains(id),
            "Token ID must not be listed"
        );
        _;
    }

    modifier isSeller(IERC721 _tokenAddress, uint256 id) {
        require(
            listings[address(_tokenAddress)][id].seller == msg.sender,
            "Access denied"
        );
        _;
    }

    modifier isSellerOrAdmin(IERC721 _tokenAddress, uint256 id) {
        require(
            listings[address(_tokenAddress)][id].seller == msg.sender ||
                hasRole(GAME_ADMIN, msg.sender),
            "Access denied"
        );
        _;
    }

    modifier tokenNotBanned(IERC721 _tokenAddress) {
        require(
            isTokenBanned[address(_tokenAddress)] == false,
            "This type of NFT may not be traded here"
        );
        _;
    }

    modifier userNotBanned() {
        require(isUserBanned[msg.sender] == false, "Forbidden access");
        _;
    }

    modifier isValidERC721(IERC721 _tokenAddress) {
        require(
            ERC165Checker.supportsInterface(
                address(_tokenAddress),
                _INTERFACE_ID_ERC721
            )
        );
        _;
    }

    // ############
    // Views
    // ############
    function defaultTaxAsRoundedPercentRoughEstimate() public view returns (uint256) {
        return defaultTax.mulu(100);
    }

    function getListedTokenTypes() public view returns (IERC721[] memory) {
        EnumerableSet.AddressSet storage set = listedTokenTypes;
        IERC721[] memory tokens = new IERC721[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = IERC721(set.at(i));
        }
        return tokens;
    }

    function getListingIDs(IERC721 _tokenAddress)
        public
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage set = listedTokenIDs[address(_tokenAddress)];
        uint256[] memory tokens = new uint256[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = set.at(i);
        }
        return tokens;
    }

    function getNumberOfListingsBySeller(
        IERC721 _tokenAddress,
        address _seller
    ) public view returns (uint256) {
        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[address(_tokenAddress)];

        uint256 amount = 0;
        for (uint256 i = 0; i < listedTokens.length(); i++) {
            if (
                listings[address(_tokenAddress)][listedTokens.at(i)].seller == _seller
            ) amount++;
        }

        return amount;
    }

    function getListingIDsBySeller(IERC721 _tokenAddress, address _seller)
        public
        view
        returns (uint256[] memory tokens)
    {
        // NOTE: listedTokens is enumerated twice (once for length calc, once for getting token IDs)
        uint256 amount = getNumberOfListingsBySeller(_tokenAddress, _seller);
        tokens = new uint256[](amount);

        EnumerableSet.UintSet storage listedTokens = listedTokenIDs[address(_tokenAddress)];

        uint256 index = 0;
        for (uint256 i = 0; i < listedTokens.length(); i++) {
            uint256 id = listedTokens.at(i);
            if (listings[address(_tokenAddress)][id].seller == _seller)
                tokens[index++] = id;
        }
    }

    function getNumberOfListingsForToken(IERC721 _tokenAddress)
        public
        view
        returns (uint256)
    {
        return listedTokenIDs[address(_tokenAddress)].length();
    }

    function getSellerPrice(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return listings[address(_tokenAddress)][_id].price;
    }

    function getFinalPrice(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return
            getSellerPrice(_tokenAddress, _id) + (getTaxOnListing(_tokenAddress, _id));
    }

    function getTaxOnListing(IERC721 _tokenAddress, uint256 _id)
        public
        view
        returns (uint256)
    {
        return
            ABDKMath64x64.mulu(
                tax[address(_tokenAddress)],
                getSellerPrice(_tokenAddress, _id)
            );
    }

    // ############
    // Mutative
    // ############
    function addListing(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _price
    )
        public
        userNotBanned
        tokenNotBanned(_tokenAddress)
        isValidERC721(_tokenAddress)
        isNotListed(_tokenAddress, _id)
    {
        listings[address(_tokenAddress)][_id] = Listing(msg.sender, _price);
        listedTokenIDs[address(_tokenAddress)].add(_id);

        _updateListedTokenTypes(_tokenAddress);

        // in theory the transfer and required approval already test non-owner operations
        _tokenAddress.safeTransferFrom(msg.sender, address(this), _id);

        emit NewListing(msg.sender, _tokenAddress, _id, _price);
    }

    function changeListingPrice(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _newPrice
    )
        public
        userNotBanned
        isListed(_tokenAddress, _id)
        isSeller(_tokenAddress, _id)
    {
        listings[address(_tokenAddress)][_id].price = _newPrice;
        emit ListingPriceChange(
            msg.sender,
            _tokenAddress,
            _id,
            _newPrice
        );
    }

    function cancelListing(IERC721 _tokenAddress, uint256 _id)
        public
        userNotBanned
        isListed(_tokenAddress, _id)
        isSellerOrAdmin(_tokenAddress, _id)
    {
        delete listings[address(_tokenAddress)][_id];
        listedTokenIDs[address(_tokenAddress)].remove(_id);

        _updateListedTokenTypes(_tokenAddress);

        _tokenAddress.safeTransferFrom(address(this), msg.sender, _id);

        emit CancelledListing(msg.sender, _tokenAddress, _id);
    }

    function purchaseListing(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 _maxPrice
    ) public userNotBanned isListed(_tokenAddress, _id) {
        uint256 finalPrice = getFinalPrice(_tokenAddress, _id);
        require(finalPrice <= _maxPrice, "Buying price too low");

        Listing memory listing = listings[address(_tokenAddress)][_id];
        uint256 taxAmount = getTaxOnListing(_tokenAddress, _id);

        delete listings[address(_tokenAddress)][_id];
        listedTokenIDs[address(_tokenAddress)].remove(_id);
        _updateListedTokenTypes(_tokenAddress);

        skillToken.transferFrom(msg.sender, taxRecipient, taxAmount);
        skillToken.transferFrom(
            msg.sender,
            listing.seller,
            finalPrice - taxAmount
        );
        _tokenAddress.safeTransferFrom(address(this), msg.sender, _id);

        emit PurchasedListing(
            msg.sender,
            listing.seller,
            _tokenAddress,
            _id,
            finalPrice
        );
    }

    function setTaxRecipient(address _taxRecipient) public restricted {
        taxRecipient = _taxRecipient;
    }

    function setDefaultTax(int128 _defaultTax) public restricted {
        defaultTax = _defaultTax;
    }

    function setDefaultTaxAsRational(uint256 _numerator, uint256 _denominator)
        public
        restricted
    {
        defaultTax = ABDKMath64x64.divu(_numerator, _denominator);
    }

    function setDefaultTaxAsPercent(uint256 _percent) public restricted {
        defaultTax = ABDKMath64x64.divu(_percent, 100);
    }

    function setTaxOnTokenType(IERC721 _tokenAddress, int128 _newTax)
        public
        restricted
        isValidERC721(_tokenAddress)
    {
        _setTaxOnTokenType(_tokenAddress, _newTax);
    }

    function setTaxOnTokenTypeAsRational(
        IERC721 _tokenAddress,
        uint256 _numerator,
        uint256 _denominator
    ) public restricted isValidERC721(_tokenAddress) {
        _setTaxOnTokenType(
            _tokenAddress,
            ABDKMath64x64.divu(_numerator, _denominator)
        );
    }

    function setTaxOnTokenTypeAsPercent(
        IERC721 _tokenAddress,
        uint256 _percent
    ) public restricted isValidERC721(_tokenAddress) {
        _setTaxOnTokenType(
            _tokenAddress,
            ABDKMath64x64.divu(_percent, 100)
        );
    }

    function setUserBan(address user, bool to) public restricted {
        isUserBanned[user] = to;
    }

    function setTokenBan(IERC721 token, bool to) public restricted {
        isTokenBanned[address(token)] = to;
    }

    function recoverSkill(uint256 amount) public restricted {
        skillToken.transfer(msg.sender, amount); // dont expect we'll hold tokens here but might as well
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 _id,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        // NOTE: The contract address is always the message sender.
        address _tokenAddress = msg.sender;

        require(
            listedTokenTypes.contains(_tokenAddress) &&
                listedTokenIDs[_tokenAddress].contains(_id),
            "Token ID not listed"
        );

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    // ############
    // Internal helpers
    // ############
    function _setTaxOnTokenType(IERC721 tokenAddress, int128 newTax) private {
        require(newTax >= 0, "We're not running a charity here");
        tax[address(tokenAddress)] = newTax;
        freeTax[address(tokenAddress)] = newTax == 0;
    }

    function _updateListedTokenTypes(IERC721 tokenAddress) private {
        if (listedTokenIDs[address(tokenAddress)].length() > 0) {
            _registerTokenAddress(tokenAddress);
        } else {
            _unregisterTokenAddress(tokenAddress);
        }
    }

    function _registerTokenAddress(IERC721 tokenAddress) private {
        if (!listedTokenTypes.contains(address(tokenAddress))) {
            listedTokenTypes.add(address(tokenAddress));

            // this prevents resetting custom tax by removing all
            if (
                tax[address(tokenAddress)] == 0 && // unset or intentionally free
                freeTax[address(tokenAddress)] == false
            ) tax[address(tokenAddress)] = defaultTax;
        }
    }

    function _unregisterTokenAddress(IERC721 tokenAddress) private {
        listedTokenTypes.remove(address(tokenAddress));
    }
}
