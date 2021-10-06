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

    // sender + token address => ids
    mapping(address => mapping(address => EnumerableSet.UintSet)) private storedItems;
    // token address + id => owner who stored
    mapping(address => mapping(uint256 => address)) private storedItemsOwners;
    // All stored items
    mapping(address => EnumerableSet.UintSet) private allStoredItems;

    // Keeping thing in check
    // A player can only have one pending request at a time

    uint8 public constant BRIDGE_STATUS_NONE = 0;
    uint8 public constant BRIDGE_STATUS_PENDING = 1;
    uint8 public constant BRIDGE_STATUS_DONE = 2;

    struct BridgeTransfer {
        address owner;
        address nftAddress;

        uint256 requestBlock; // For tracking. Requested on block x
        uint256 lastUpdateBlock; // For tracking. Last Update on block y
        uint256 nftId;

        uint8 chainId; // uint 8 should be enough
        uint8 status; // enumeration. 0 => nothing, 1 => transfer requested, 2 => moved   
    }

    // Bot stuff
    uint256 private _bridgeTransfersAt;
    uint256 private _bridgeTransfers;
    mapping(uint8 => bool) private _bridgeEnabled; // Which chain can we go to from here?
    bool private _botEnabled;
    mapping(uint256 => BridgeTransfer) private bridgeTransfers;

    // Player stuff
    // Player => bridgeTransferId
    mapping(address => uint256) private bridgeTransfersOfPlayers;

    // NFT stuff, an NFT should at most have one BridgeTransfer
    // NFT => id => bridgeTransferId
    mapping(address => mapping(uint256 => uint256)) private bridgeTransfersOfNFTs;

    // address is IERC721
    EnumerableSet.AddressSet private supportedTokenTypes; 


    function initialize()
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // make our lives easier and just void the first one...
        bridgeTransfers[0] = BridgeTransfer(address(0), address(0), 0, 0, 0, 0, 0);
    }


    modifier restricted() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Admin only");
        _;
    }

    modifier gameAdminRestricted() {
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

    modifier notBridged(IERC721 _tokenAddress, uint256 id) {
         require(
            bridgeTransfers[bridgeTransfersOfNFTs[address(_tokenAddress)][id]].status == BRIDGE_STATUS_NONE,
            "Pending bridge"
        );
        _;
    }

     modifier bridgeEnabled(uint8 targetChain) {
         require(
            _bridgeEnabled[targetChain],
            "bridging disabled"
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

    modifier noPendingBridge(){
         require(
            bridgeTransfers[bridgeTransfersOfPlayers[msg.sender]].status == BRIDGE_STATUS_NONE
            || bridgeTransfers[bridgeTransfersOfPlayers[msg.sender]].status == BRIDGE_STATUS_DONE,
            "Cannot request a bridge"
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
        notBridged(_tokenAddress, _id)
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

    // bridge stuff
    function chainBridgeEnabled(uint8 chainId) public view returns (bool) {
        return _bridgeEnabled[chainId];
    }

    function toggleChainBridgeEnabled(uint8 chainId, bool enable) public restricted {
        _bridgeEnabled[chainId] = enable;
    }

    function bridgeItem(
        IERC721 _tokenAddress,
        uint256 _id,
        uint8 targetChain
    )
        public
        tokenNotBanned(_tokenAddress)
        isValidERC721(_tokenAddress)
        isStored(_tokenAddress, _id)
        isOwner(_tokenAddress, _id) // isStored built in but why not
        bridgeEnabled(targetChain)
        noPendingBridge()
    {
        bridgeTransfers[++_bridgeTransfers] = BridgeTransfer(msg.sender, address(_tokenAddress), block.number, 0, _id, targetChain, 1);
        bridgeTransfersOfPlayers[msg.sender] = _bridgeTransfers;
        bridgeTransfersOfNFTs[address(_tokenAddress)][_id] = _bridgeTransfers;
    }

    function cancelBridge() public
    {
        require(bridgeTransfers[bridgeTransfersOfPlayers[msg.sender]].status == BRIDGE_STATUS_PENDING, 'no pending bridge');
        bridgeTransfers[bridgeTransfersOfPlayers[msg.sender]].status = BRIDGE_STATUS_NONE;
        bridgeTransfers[bridgeTransfersOfPlayers[msg.sender]].lastUpdateBlock = block.number;
    }

    // Bot stuff
    function botEnabled() public view returns (bool){
        return _botEnabled;
    }

    function toggleBotEnabled(bool enable) public restricted {
        _botEnabled = enable;
    }

    function getBridgeTransferAt() public view returns (uint256){
        return _bridgeTransfersAt;
    }

    function setBridgeTransferAt(uint256 bridgeTransfersAt) public gameAdminRestricted {
        _bridgeTransfersAt = bridgeTransfersAt;
    }

    function getBridgeTransfers() public view returns (uint256){
        return _bridgeTransfers;
    }

    function getBridgeTransfer() public view returns (uint256){
        return bridgeTransfersOfPlayers[msg.sender];
    }

    function getBridgeTransfer(uint256 bridgeTransfer) public returns (address, address, uint256, uint256, uint256, uint8, uint8) {
        return (bridgeTransfers[bridgeTransfer].owner,
                bridgeTransfers[bridgeTransfer].nftAddress,
                bridgeTransfers[bridgeTransfer].nftId,
                bridgeTransfers[bridgeTransfer].requestBlock,
                bridgeTransfers[bridgeTransfer].lastUpdateBlock,
                bridgeTransfers[bridgeTransfer].chainId,
                bridgeTransfers[bridgeTransfer].status);
    }

    function updateBridgeTransferStatus(uint256 bridgeTransfer, uint8 status, bool forced) public gameAdminRestricted {
        require(forced || bridgeTransfers[bridgeTransfer].status == BRIDGE_STATUS_PENDING, 'Not pending transfer');
        bridgeTransfers[bridgeTransfer].status = status;
        bridgeTransfers[bridgeTransfer].lastUpdateBlock = block.number;
    }
}
