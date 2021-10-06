pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTStorage is IERC721ReceiverUpgradeable, Initializable, AccessControlUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize()
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // sender + token address => ids
    mapping(address => mapping(address => EnumerableSet.UintSet)) private storedItems;
    // token address + id => owner who stored
    mapping(address => mapping(uint256 => address)) private storedItemsOwners;
    // All stored items
    mapping(address => EnumerableSet.UintSet) private allStoredItems;

    // address is IERC721
    EnumerableSet.AddressSet private supportedTokenTypes; 

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not game admin");
        _;
    }

    modifier isStored(IERC721 _tokenAddress, uint256 id) {
        require(
            supportedTokenTypes.contains(address(_tokenAddress)) &&
                storedItems[msg.sender][address(_tokenAddress)].contains(id),
            "Token ID not listed"
        );
        _;
    }

    modifier isNotStored(IERC721 _tokenAddress, uint256 id) {
        require(
            !supportedTokenTypes.contains(address(_tokenAddress)) ||
                !storedItems[msg.sender][address(_tokenAddress)].contains(id),
            "Token ID must not be listed"
        );
        _;
    }

    modifier isOwner(IERC721 _tokenAddress, uint256 id) {
        require(
            storedItemsOwners[address(_tokenAddress)][id] == msg.sender,
            "Access denied"
        );
        _;
    }

    modifier tokenNotBanned(IERC721 _tokenAddress) {
        require(
            isTokenSupported(_tokenAddress),
            "This type of NFT may not be stored"
        );
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

    function isTokenSupported(IERC721 _tokenAddress) public view returns (bool) {
        return supportedTokenTypes.contains(address(_tokenAddress));
    }

    function getSupportedTokenTypes() public view returns (IERC721[] memory) {
        EnumerableSet.AddressSet storage set = supportedTokenTypes;
        IERC721[] memory tokens = new IERC721[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = IERC721(set.at(i));
        }
        return tokens;
    }

    function getNumberOfStoragedItems(
        IERC721 _tokenAddress
    ) public view returns (uint256) {
        return storedItems[msg.sender][address(_tokenAddress)].length();
    }

    function getStorageItemIds(
        IERC721 _tokenAddress
    ) public view  returns (uint256[] memory tokens) {

        uint256 amount = getNumberOfStoragedItems(_tokenAddress);
        tokens = new uint256[](amount);

        EnumerableSet.UintSet storage storedTokens = storedItems[msg.sender][address(_tokenAddress)];

        uint256 index = 0;
        for (uint256 i = 0; i < storedTokens.length(); i++) {
            uint256 id = storedTokens.at(i);
                tokens[index++] = id;
        }
    }

    function storeItem(
        IERC721 _tokenAddress,
        uint256 _id
    )
        public
        tokenNotBanned(_tokenAddress)
        isValidERC721(_tokenAddress)
        isNotStored(_tokenAddress, _id)
    {
        storedItems[msg.sender][address(_tokenAddress)].add(_id);
        allStoredItems[address(_tokenAddress)].add(_id);
        storedItemsOwners[address(_tokenAddress)][_id] = msg.sender;

        _tokenAddress.safeTransferFrom(msg.sender, address(this), _id);
    }

    function withdrawFromStorage(IERC721 _tokenAddress, uint256 _id)
        public
        isStored(_tokenAddress, _id)
        isOwner(_tokenAddress, _id)
    {
        storedItems[msg.sender][address(_tokenAddress)].remove(_id);
        allStoredItems[address(_tokenAddress)].remove(_id);
        delete storedItemsOwners[address(_tokenAddress)][_id];

        _tokenAddress.safeTransferFrom(address(this), msg.sender, _id);
    }

    function allowToken(IERC721 _tokenAddress) public restricted isValidERC721(_tokenAddress) {
        supportedTokenTypes.add(address(_tokenAddress));
    }

    function disallowToken(IERC721 _tokenAddress) public restricted {
        supportedTokenTypes.remove(address(_tokenAddress));
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
            supportedTokenTypes.contains(_tokenAddress) &&
                allStoredItems[_tokenAddress].contains(_id),
            "Token ID not listed"
        );

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}
