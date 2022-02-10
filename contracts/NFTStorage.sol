pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./weapons.sol";
import "./characters.sol";
import "./shields.sol";
import "./NFTMarket.sol";
import "./Promos.sol";
import "./WeaponRenameTagConsumables.sol";
import "./CharacterRenameTagConsumables.sol";
import "./WeaponCosmetics.sol";
import "./CharacterCosmetics.sol";
import "./interfaces/IBridgeProxy.sol";

contract NFTStorage is IERC721ReceiverUpgradeable, Initializable, AccessControlUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    Weapons weapons;
    Characters characters;
    NFTMarket nftMarket;
    WeaponRenameTagConsumables weaponRenameTagConsumables;
    CharacterRenameTagConsumables characterRenameTagConsumables;
    WeaponCosmetics weaponCosmetics;
    CharacterCosmetics characterCosmetics;

    bool storageEnabled;
    // sender + token address => ids
    mapping(address => mapping(address => EnumerableSet.UintSet)) private storedItems;
    // token address + id => owner who stored
    mapping(address => mapping(uint256 => address)) private storedItemsOwners;
    // All stored items
    mapping(address => EnumerableSet.UintSet) private allStoredItems;
    // Ideally this would be put in weapons / chars etc.. but hit contract limit on weapons so putting this here for now
    mapping(address => mapping(uint256 => string)) private nftChainIds;

    // Keeping thing in check
    // A player can only have one pending request at a time

    uint8 public constant TRANSFER_OUT_STATUS_NONE = 0;
    uint8 public constant TRANSFER_OUT_STATUS_PENDING = 1;
    uint8 public constant TRANSFER_OUT_STATUS_PROCESSING = 2;
    uint8 public constant TRANSFER_OUT_STATUS_DONE = 3;
    uint8 public constant TRANSFER_OUT_STATUS_ERROR = 4;
    uint8 public constant TRANSFER_OUT_STATUS_RESTORED = 5;

    struct TransferOut {
        address owner;
        address nftAddress;

        uint256 requestBlock; // For tracking. Requested on block x
        uint256 lastUpdateBlock; // For tracking. Last Update on block y
        uint256 nftId;

        uint256 chainId;
        uint8 status; // enumeration. 0 => nothing, 1 => transfer requested, 2 => moved   
    }

    // Bot stuff
    uint256 private _transfersOutAt;
    uint256 private _transfersOutCount;
    mapping(uint256 => bool) private _bridgeEnabled; // Which chain can we go to from here?
    mapping(uint256 => string) private _chainPrefix; // Prefix to prepend to chainId
    bool private _botEnabled;
    mapping(uint256 => TransferOut) private transferOuts;

    // Player stuff
    // Player => bridgeTransferId
    mapping(address => uint256) private transferOutOfPlayers;

    // NFT stuff, an NFT should at most have one BridgeTransfer
    // NFT => id => bridgeTransferId
    mapping(address => mapping(uint256 => uint256)) private transferOutOfNFTs;

    // address is IERC721
    EnumerableSet.AddressSet private supportedTokenTypes; 

    uint8 public constant TRANSFER_IN_STATUS_AVAILABLE = 1;
    uint8 public constant TRANSFER_IN_STATUS_WITHDRAWN = 2;

    // Bot deposited items to be extracted by player
    uint8 public constant NFT_TYPE_WEAPON = 1;
    uint8 public constant NFT_TYPE_CHARACTER = 2;
    uint8 public constant NFT_TYPE_SHIELD = 3;

    mapping(uint8 => address) private nftTypeToAddress;

    // Struct to hold data that will always be needed + rename because it can't be packed.
    // transferInsMeta will hold actual NFT data packed
    struct TransferIn {
        address owner;

        uint8 nftType;
        uint256 sourceChain;
        uint256 sourceId;
        
        string rename;

        uint256 arrivedAt; // For tracking. Arrived on block x
        uint256 lastUpdateBlock; // For tracking. Last Update on block y

        uint8 status; // enumeration. 0 => waiting, 1 => claimed 
    }
    
    // Player address => items to be extracted
    mapping(address => EnumerableSet.UintSet) private receivedNFTs;

    uint256 private _transferInsAt;
    mapping(uint256 => TransferIn) private transferIns;
    mapping(uint256 => uint256) private transferInsMeta;
    mapping(uint256 => uint256) private transferInSeeds;


    EnumerableSet.UintSet private _supportedChains;

    // Source chain => NFT Type => NFTId of source chain => transfer id
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _transferInsLog;
    // Transfer id => minted item Id; no need for NFT type; we can get that from trasnfer in info
    mapping(uint256 => uint256) private _withdrawFromBridgeLog;

    CryptoBlades public game;
    uint256 private _bridgeFee;
    
    // global chainid => local mint id
    mapping(address => mapping(string => uint256)) private nftChainIdsToMintId;

    mapping(uint256 => string) private transferInChainId;

    Promos public promos;

    string private _localChainPrefix;

    Shields shields;

    // Bot 2.0
    // Proxy contracts
    mapping(address => address) private nftProxyContract;
    // Source chain => transfer out id of source chain => mintid (mint id 0 doesn't exist...)
    mapping(uint256 => mapping(uint256 => uint256)) private bot2p0Log;
    // NFT => allowed networks to bridge into
    mapping(address => EnumerableSet.UintSet) private nftAllowedChains;
    // Target network => allowed nfts
    mapping(uint256 => EnumerableSet.AddressSet) private targetChainAllowedNFTs;

    event NFTStored(address indexed owner, IERC721 indexed nftAddress, uint256 indexed nftID);
    event NFTWithdrawn(address indexed owner, IERC721 indexed nftAddress, uint256 indexed nftID);
    event NFTTransferOutRequest(address indexed owner, IERC721 indexed nftAddress, uint256 indexed nftID);
    event NFTTransferOutCanceled(address indexed owner);
    event NFTTransferUpdate(uint256 indexed requestId, uint8 status, bool forced);
    event TransferedIn(address indexed receiver, uint8 nftType, uint256 sourceChain, uint256 indexed sourceId);
    event NFTWithdrawnFromBridge(address indexed receiver, uint256 indexed bridgedId, uint8 nftType, uint256 indexed mintedId);

    function initialize(address _weaponsAddress, address _charactersAddress, WeaponRenameTagConsumables _weaponRenameTagConsumables, CharacterRenameTagConsumables _characterRenameTagConsumables,
     WeaponCosmetics _weaponCosmetics, CharacterCosmetics _characterCosmetics, NFTMarket _nftMarket)
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        weapons = Weapons(_weaponsAddress);
        nftTypeToAddress[NFT_TYPE_WEAPON] = _weaponsAddress;

        characters = Characters(_charactersAddress);
        nftTypeToAddress[NFT_TYPE_CHARACTER] =_charactersAddress;

        weaponRenameTagConsumables = _weaponRenameTagConsumables;
        characterRenameTagConsumables = _characterRenameTagConsumables;

        weaponCosmetics = _weaponCosmetics;
        characterCosmetics = _characterCosmetics;

        nftMarket = _nftMarket;
    }

    function migrateTo_56837f7(CryptoBlades _game) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        game = _game;
    }

    function migrateTo_98bf302(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        promos = _promos;
    }

    function migrateTo_3f597dc(address _shieldsAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        shields = Shields(_shieldsAddress);
        nftTypeToAddress[NFT_TYPE_SHIELD] =_shieldsAddress;
    }

    modifier restricted() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AO");
        _;
    }

    modifier gameAdminRestricted() {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NGA");
        _;
    }

    modifier isStored(IERC721 _tokenAddress, uint256 id) {
        require(
            supportedTokenTypes.contains(address(_tokenAddress)) &&
                storedItems[msg.sender][address(_tokenAddress)].contains(id),
            "Not listed"
        );
        _;
    }

    modifier isNotStored(IERC721 _tokenAddress, uint256 id) {
        require(
            !supportedTokenTypes.contains(address(_tokenAddress)) ||
                !storedItems[msg.sender][address(_tokenAddress)].contains(id),
            "Already listed"
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
            "Error"
        );
        _;
    }

    modifier notBridged(IERC721 _tokenAddress, uint256 id) {
         require(
            transferOuts[transferOutOfNFTs[address(_tokenAddress)][id]].status == TRANSFER_OUT_STATUS_NONE
            || transferOuts[transferOutOfNFTs[address(_tokenAddress)][id]].status == TRANSFER_OUT_STATUS_RESTORED,
            "Pending bridge"
        );
        _;
    }

     modifier canStore() {
         require(
            storageEnabled && promos.getBit(msg.sender, promos.BIT_BAD_ACTOR()) == false,
            "storage disabled"
        );
        _;
    }

     modifier bridgeEnabled(uint256 targetChain) {
         require(
            _bridgeEnabled[targetChain],
            "bridging disabled"
        );
        _;
    }

    modifier noPendingBridge() {
         require(
            transferOuts[transferOutOfPlayers[msg.sender]].status == TRANSFER_OUT_STATUS_NONE
            || transferOuts[transferOutOfPlayers[msg.sender]].status == TRANSFER_OUT_STATUS_DONE
            || transferOuts[transferOutOfPlayers[msg.sender]].status == TRANSFER_OUT_STATUS_RESTORED,
            "Cannot request a bridge"
        );
        _;
    }
    
    modifier ownsBridgedNFT(uint256 bridgedNFT) {
         require( transferIns[bridgedNFT].owner == msg.sender, "not bridged NFT owner" );
        _;
    }

    modifier bridgeSupported(IERC721 _tokenAddress, uint256 _id, uint256 targetChain) {
        require(_id != 0, "BNS1"); // avoid sanity issues with mappings; just dont support 0
        require(nftAllowedChains[address(_tokenAddress)].contains(targetChain), "BNS2"); // We support bridging from this chain to that chain
        _;
    }
    
    // fail safes
    modifier canWithdrawBridgedNFT(uint256 bridgedNFT) {
         require( transferIns[bridgedNFT].status == TRANSFER_IN_STATUS_AVAILABLE, "not available" );
         require( nftTypeToAddress[transferIns[bridgedNFT].nftType] != address(0), "NFT not defined" );
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

    // Get # of stored items of player for NFT
    function getNumberOfStoragedItems(
        IERC721 _tokenAddress
    ) public view returns (uint256) {
        return storedItems[msg.sender][address(_tokenAddress)].length();
    }

    // Get stored items of player for NFT
    function getStorageItemIds(
        IERC721 _tokenAddress
    ) public view  returns (uint256[] memory tokens) {

        uint256 amount = getNumberOfStoragedItems(_tokenAddress);
        tokens = new uint256[](amount);

        EnumerableSet.UintSet storage storedTokens = storedItems[msg.sender][address(_tokenAddress)];

        for (uint256 i = 0; i < storedTokens.length(); i++) {
            uint256 id = storedTokens.at(i);
                tokens[i] = id;
        }
    }

    // Player adds NFT to storage
    function storeItem(
        IERC721 _tokenAddress,
        uint256 _id
    )
        public
        tokenNotBanned(_tokenAddress)
        isNotStored(_tokenAddress, _id)
        canStore()
    {
        storedItems[msg.sender][address(_tokenAddress)].add(_id);
        allStoredItems[address(_tokenAddress)].add(_id);
        storedItemsOwners[address(_tokenAddress)][_id] = msg.sender;

        _tokenAddress.safeTransferFrom(msg.sender, address(this), _id);

        emit NFTStored(msg.sender, _tokenAddress, _id);
    }

    // Player withdraws NFT from storage.
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

        emit NFTWithdrawn(msg.sender, _tokenAddress, _id);
    }

    function allowToken(IERC721 _tokenAddress) public restricted {
        supportedTokenTypes.add(address(_tokenAddress));
    }

    function disallowToken(IERC721 _tokenAddress) public restricted {
        supportedTokenTypes.remove(address(_tokenAddress));
    }

    // something
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


    function storageIsEnabled() public view returns (bool) {
        return storageEnabled;
    }

    function setStorageEnabled(bool enabled) public restricted {
        storageEnabled = enabled;
    }

    // bridge stuff
    function chainBridgeEnabled(uint256 chainId) public view returns (bool) {
        return _bridgeEnabled[chainId];
    }

    function getEnabledChainsForBridging() public view  returns (uint256[] memory chainIds) {
        uint256 amount = _supportedChains.length();
        chainIds = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 id = _supportedChains.at(i);
                chainIds[i] = id;
        }
    }

    
    function toggleChainBridgeEnabled(uint256 chainId, string memory prefix, bool enable) public restricted {
        _bridgeEnabled[chainId] = enable;
        _chainPrefix[chainId] = prefix;

        if(enable) {
            _supportedChains.add(chainId);
        } else {
            _supportedChains.remove(chainId);
        }
    }

    // Player requests to bridge an item
    function bridgeItem(
        IERC721 _tokenAddress,
        uint256 _id,
        uint256 targetChain
    )
        public
        tokenNotBanned(_tokenAddress)
        isStored(_tokenAddress, _id)
        isOwner(_tokenAddress, _id) // isStored built in but why not
        bridgeSupported(_tokenAddress, _id, targetChain)
        bridgeEnabled(targetChain)
        noPendingBridge()
        canStore()
    {
        game.payContractTokenOnly(msg.sender, _bridgeFee);
        transferOuts[++_transfersOutCount] = TransferOut(msg.sender, address(_tokenAddress), block.number, 0, _id, targetChain, 1);
        transferOutOfPlayers[msg.sender] = _transfersOutCount;
        transferOutOfNFTs[address(_tokenAddress)][_id] = _transfersOutCount;

        // Set the chainid if none is set already
        // Not set => this is a local mint that was not bridged in
        // Set it to LocalPrefixMintId (Example BSC123, HECO456)
        if(bytes(nftChainIds[address(_tokenAddress)][_id]).length == 0){
            string memory chainId = buildChainId(_id);
            nftChainIds[address(_tokenAddress)][_id] = chainId;
            nftChainIdsToMintId[address(_tokenAddress)][chainId] = _id;
        }
        
        emit NFTTransferOutRequest(msg.sender, _tokenAddress, _id);
    }

    // Player cancels bridge request. Can only happen if it's pending.
    function cancelBridge() public
    {
        TransferOut storage transferOut = transferOuts[transferOutOfPlayers[msg.sender]];

        require(transferOut.status == TRANSFER_OUT_STATUS_PENDING, 'no pending bridge');
        transferOut.status = TRANSFER_OUT_STATUS_NONE;
        transferOut.lastUpdateBlock = block.number;

        emit NFTTransferOutCanceled(msg.sender);
    }

    // Player received NFTs waiting to be converted to NFTs
    function getReceivedNFTs() public view  returns (uint256[] memory tokens) {
        uint256 amount = receivedNFTs[msg.sender].length();
        tokens = new uint256[](amount);

        EnumerableSet.UintSet storage storedTokens = receivedNFTs[msg.sender];

        for (uint256 i = 0; i < storedTokens.length(); i++) {
            uint256 id = storedTokens.at(i);
                tokens[i] = id;
        }
    }

    function getReceivedNFT(uint256 receivedNFT) public view  returns (address, uint8, uint256, uint256, uint8, uint256) {
        TransferIn storage transferIn = transferIns[receivedNFT];
        return (transferIn.owner, transferIn.nftType, transferIn.sourceChain, transferIn.sourceId, transferIn.status, transferInsMeta[receivedNFT]);
    }

    // to be removed eventually; bot will now mint into storage
    function withdrawFromBridge(uint256 bridgedNFT) ownsBridgedNFT(bridgedNFT) canWithdrawBridgedNFT(bridgedNFT) canStore() public {
        uint256 mintedItem;
        TransferIn storage transferIn = transferIns[bridgedNFT];
        uint256 seed = transferInSeeds[bridgedNFT]; 

        if(transferIn.nftType == NFT_TYPE_WEAPON) {
            mintedItem = _withdrawWeaponFromBridge(bridgedNFT, transferIn.sourceChain, transferIn.sourceId);   
            require(weapons.ownerOf(mintedItem) == address(this), "NAW"); // The minted item, if already existed, should be in storage
            if(bytes(transferIn.rename).length > 0) {
                weaponRenameTagConsumables.setName(mintedItem, transferIn.rename);
            }
        }
        else if(transferIn.nftType == NFT_TYPE_CHARACTER) {
            mintedItem = _withdrawCharacterFromBridge(bridgedNFT, transferInsMeta[bridgedNFT], seed);
            require(characters.ownerOf(mintedItem) == address(this), "NAC"); // The minted item, if already existed, should be in storage
            if(bytes(transferIn.rename).length > 0) {
                characterRenameTagConsumables.setName(mintedItem, transferIn.rename);
            }
        }
        else if(transferIn.nftType == NFT_TYPE_SHIELD) {
            mintedItem = _withdrawShieldFromBridge(bridgedNFT, transferIn.sourceChain, transferIn.sourceId);   
            require(shields.ownerOf(mintedItem) == address(this), "NAS"); // The minted item, if already existed, should be in storage
        }

        if(transferOuts[transferOutOfNFTs[nftTypeToAddress[transferIn.nftType]][mintedItem]].status == TRANSFER_OUT_STATUS_DONE) {
            transferOuts[transferOutOfNFTs[nftTypeToAddress[transferIn.nftType]][mintedItem]].status = TRANSFER_OUT_STATUS_RESTORED;
        }

        address nftAddress = nftTypeToAddress[transferIn.nftType];
        allStoredItems[nftAddress].add(mintedItem);
        storedItemsOwners[nftAddress][mintedItem] = transferIn.owner;
        storedItems[transferIn.owner][nftAddress].add(mintedItem);

        receivedNFTs[msg.sender].remove(bridgedNFT);
        transferIns[bridgedNFT].status = TRANSFER_IN_STATUS_WITHDRAWN;
        transferIns[bridgedNFT].lastUpdateBlock = block.number;

        // local mint id => global chain id
        nftChainIds[nftTypeToAddress[transferIn.nftType]][mintedItem] = transferInChainId[bridgedNFT];
        // global chain id => local mint id (to restore)
        nftChainIdsToMintId[nftTypeToAddress[transferIn.nftType]][transferInChainId[bridgedNFT]] = mintedItem;
        _withdrawFromBridgeLog[bridgedNFT] = mintedItem;

        emit NFTWithdrawnFromBridge(transferIn.owner, bridgedNFT, transferIn.nftType, mintedItem);
    }

    // to be removed eventually; bot will now mint into storage
    function _withdrawWeaponFromBridge(uint256 bridgedNFT, uint256 chainId, uint256 sourceId) internal returns (uint256 mintedId) {
        // Get any existing mint that has this global id
        mintedId = nftChainIdsToMintId[nftTypeToAddress[NFT_TYPE_WEAPON]][transferInChainId[bridgedNFT]];

        uint256 seed = transferInSeeds[bridgedNFT];

        uint256 meta = transferInsMeta[bridgedNFT];

        uint32 appliedCosmetic = uint32((meta >> 96) & 0xFFFFFFFF);

         mintedId = 
            weapons.performMintWeaponDetailed(address(this), meta, seed, mintedId);

        if(appliedCosmetic > 0) {
            weaponCosmetics.setWeaponCosmetic(mintedId, appliedCosmetic);
         }
    }

    // to be removed eventually; bot will now mint into storage
    function _withdrawCharacterFromBridge(uint256 bridgedNFT, uint256 metaData, uint256 seed) internal returns (uint256 mintedId) {
        (uint32 appliedCosmetic, uint16 xp, uint8 level, uint8 trait, uint24 bonusPower)  = unpackCharactersData(metaData); 
        
        mintedId = nftChainIdsToMintId[nftTypeToAddress[NFT_TYPE_CHARACTER]][transferInChainId[bridgedNFT]];

        mintedId = 
            characters.customMint(address(this), xp, 
            level, trait, seed, mintedId, bonusPower);

            if(appliedCosmetic > 0) {
                characterCosmetics.setCharacterCosmetic(mintedId, appliedCosmetic);
            }
    }

    // to be removed eventually; bot will now mint into storage
    function _withdrawShieldFromBridge(uint256 bridgedNFT, uint256 chainId, uint256 sourceId) internal returns (uint256 mintedId) {
        mintedId = nftChainIdsToMintId[nftTypeToAddress[NFT_TYPE_SHIELD]][transferInChainId[bridgedNFT]];

        uint256 seed = transferInSeeds[bridgedNFT];

        uint256 meta = transferInsMeta[bridgedNFT];

        uint32 appliedCosmetic = uint32((meta >> 96) & 0xFFFFFFFF);

         mintedId = 
            shields.performMintShieldDetailed(address(this), meta, seed, mintedId);
    }

    function getNFTChainId(address nftAddress, uint256 nftId) public view returns (string memory chainId) {
        chainId = nftChainIds[nftAddress][nftId];
    }

    function setNFTChainId(address nftAddress, uint256 nftId, string calldata chainId, bool forced) external gameAdminRestricted {
        require(forced || (bytes(nftChainIds[nftAddress][nftId]).length == 0 && nftChainIdsToMintId[nftAddress][chainId] == 0), "NA");
        nftChainIds[nftAddress][nftId] = chainId;
        nftChainIdsToMintId[nftAddress][chainId] = nftId;
    }

    function setLocalChainPrefix(string calldata prefix) external restricted {
        _localChainPrefix = prefix;
    }

    function getLocalChainPrefix() public view returns (string memory) {
        return _localChainPrefix;
    }

    function setBridgeFee(uint256 newFee) external restricted {
        _bridgeFee = newFee;
    }

     function getBridgeFee() public view returns (uint256){
        return _bridgeFee;
    }

    // Bot stuff
    function botEnabled() public view returns (bool) {
        return _botEnabled;
    }

    function toggleBotEnabled(bool enable) public restricted {
        _botEnabled = enable;
    }

    function getBridgeTransferAt() public view returns (uint256) {
        return _transfersOutAt;
    }

    function setBridgeTransferAt(uint256 transfersOutAt) public gameAdminRestricted {
        _transfersOutAt = transfersOutAt;
    }

    function getBridgeTransfers() public view returns (uint256) {
        return _transfersOutCount;
    }

    // Transfer request of a player if any (only active one). Not bot... will move up
    function getBridgeTransfer() public view returns (uint256) {
        return getBridgeTransferOfPlayer(msg.sender);
    }

     function getBridgeTransferOfPlayer(address player) public view returns (uint256) {
        return transferOutOfPlayers[player];
    }

    function getBridgeTransfer(uint256 bridgeTransferId) public view returns (address, address, uint256, uint256, uint256, uint256, uint8) {
        TransferOut storage transferOut = transferOuts[bridgeTransferId];
        return (transferOut.owner,
                transferOut.nftAddress,
                transferOut.nftId,
                transferOut.requestBlock,
                transferOut.lastUpdateBlock,
                transferOut.chainId,
                transferOut.status);
    }

    // Bot to update status of a transfer request (this chain => outside chain)
    function updateBridgeTransferStatus(uint256 bridgeTransferId, uint8 status, bool forced) public gameAdminRestricted {
        TransferOut storage transferOut = transferOuts[bridgeTransferId];
        require(forced || 
        (transferOut.status == TRANSFER_OUT_STATUS_PENDING && status == TRANSFER_OUT_STATUS_PROCESSING)
        || (transferOut.status == TRANSFER_OUT_STATUS_PROCESSING && status == TRANSFER_OUT_STATUS_DONE)
        || status == TRANSFER_OUT_STATUS_ERROR, 'Invalid status change');
        transferOut.status = status;
        transferOut.lastUpdateBlock = block.number;

        if(status == TRANSFER_OUT_STATUS_DONE) {
            transferOut = transferOuts[bridgeTransferId];
            storedItems[transferOut.owner][transferOut.nftAddress].remove(transferOut.nftId);
            allStoredItems[transferOut.nftAddress].remove(transferOut.nftId);
            delete storedItemsOwners[transferOut.nftAddress][transferOut.nftId];
        }

        emit NFTTransferUpdate(bridgeTransferId, status, forced);
    }

    // To know if it actually made it
    function getTransferInFromLog(uint256 sourceChain, uint8 nftType, uint256 sourceId) public view returns (uint256) {
        return  _transferInsLog[sourceChain][nftType][sourceId];
    }

    // mint 0 wont be supported in bridging => if != 0 => it got here => transfer was made
     function getTransferInFromLogV2(uint256 sourceChain, uint256 sourceTransferId) public view returns (uint256) {
        return bot2p0Log[sourceChain][sourceTransferId];
    }

    function collectNFTData(address nftAddress, uint256 tokenId) external view returns (uint256[] memory uintVars, string memory stringVar) {
        return IBridgeProxy(nftProxyContract[nftAddress]).collectData(tokenId);
    }

    function mintOrUpdate(address receiver, uint256 sourceChain, uint256 sourceTransfer, address nftAddress, string calldata chainId, uint256[] calldata uintVars, string calldata stringVar) external gameAdminRestricted {
        require(bot2p0Log[sourceChain][sourceTransfer] == 0, "NA");
        uint256 mintedId = nftChainIdsToMintId[nftAddress][chainId];

        mintedId = IBridgeProxy(nftProxyContract[nftAddress]).mintOrUpdate(mintedId, uintVars, stringVar);

        // Whether minted or updated, the bridge owns the NFT
        require(IERC721(nftAddress).ownerOf(mintedId) == address(this), "NA2");
        _logMintOrUpdate(sourceChain, sourceTransfer, nftAddress, mintedId, chainId);
        _attachToWallet(receiver, nftAddress, mintedId);
    }

    function _logMintOrUpdate(uint256 sourceChain, uint256 sourceTransfer, address nftAddress, uint256 tokenId, string memory chainId) internal {
        bot2p0Log[sourceChain][sourceTransfer] = tokenId;
        nftChainIds[nftAddress][tokenId] = chainId;
        nftChainIdsToMintId[nftAddress][chainId] = tokenId;
    }

    function _attachToWallet(address owner, address nftAddress, uint256 tokenId) internal {
        allStoredItems[nftAddress].add(tokenId);
        storedItemsOwners[nftAddress][tokenId] = owner;
        storedItems[owner][nftAddress].add(tokenId);
    }

    function setProxyContract(address nft, address proxy, bool forced) external restricted {
        require(forced || nftProxyContract[nft] == address(0), "NA");
        nftProxyContract[nft] = proxy;
    }

    function getProxyContract(address nft) public view returns (address) {
        return nftProxyContract[nft];
    }

    function setChainSupportedForNFT(address nft, uint256[] calldata chainIds, bool support) external restricted {
        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256 chainId = chainIds[i];
            if(support) {
                require(!nftAllowedChains[nft].contains(chainId), "NA");
                nftAllowedChains[nft].add(chainId);
                targetChainAllowedNFTs[chainId].add(nft);
            } else {
                require(nftAllowedChains[nft].contains(chainId), "NA2");
                nftAllowedChains[nft].remove(chainId);
                targetChainAllowedNFTs[chainId].remove(nft);
            }
        }
    }

    function getChainsSupportingNFT(address nft) public view returns (uint256[] memory chains) {
        chains = new uint256[](nftAllowedChains[nft].length());

        for (uint256 i = 0; i < nftAllowedChains[nft].length(); i++) {
            uint256 id = nftAllowedChains[nft].at(i);
                chains[i] = id;
        }
    }

    function getNFTsSupportedByChain(uint256 chain) public view returns (address[] memory nfts) {
        nfts = new address[](targetChainAllowedNFTs[chain].length());

        for (uint256 i = 0; i < targetChainAllowedNFTs[chain].length(); i++) {
            address nft = targetChainAllowedNFTs[chain].at(i);
                nfts[i] = nft;
        }
    }

    function unpackCharactersData(uint256 metaData) public pure returns (uint32 appliedCosmetic, uint16 xp, uint8 level, uint8 trait, uint24 bonusPower) {
        trait = uint8((metaData) & 0xFF);
        level = uint8((metaData >> 8) & 0xFF);
        xp = uint16(metaData  >> 16 & 0xFFFF);
        appliedCosmetic = uint32((metaData >> 32) & 0xFFFFFFFF);
        bonusPower = uint24((metaData >> 64) & 0xFFFFFF);
    }

    function buildChainId(uint256 sourceId) internal view returns (string memory) {
        return string(abi.encodePacked(_localChainPrefix, uint2str(sourceId)));
    }

    function uint2str(uint i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }
}
