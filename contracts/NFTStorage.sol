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

        _chainPrefix[56] = "BSC";
        _chainPrefix[128] = "HECO";
        _chainPrefix[66] = "OKEX";

        storageEnabled = false;
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

    // Convert data stored by bot into an actual NFT and move it to storage
    // Bot can't mint on its own because some NFTs will have constraints (example max 4 chars)
    // Storage concept makes it a lot easier
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
            // if(bytes(transferIn.rename).length > 0) { // later
            //     characterRenameTagConsumables.setName(mintedItem, transferIn.rename);
            // }
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

    // Takes bridgedNFT not meta to avoid stack too deep
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

    function _withdrawCharacterFromBridge(uint256 bridgedNFT, uint256 metaData, uint256 seed) internal returns (uint256 mintedId) {
        (uint32 appliedCosmetic, uint16 xp, uint8 level, uint8 trait)  = unpackCharactersData(metaData); 
        
        mintedId = nftChainIdsToMintId[nftTypeToAddress[NFT_TYPE_CHARACTER]][transferInChainId[bridgedNFT]];

        mintedId = 
            characters.customMint(address(this), xp, 
            level, trait, seed, mintedId);

            if(appliedCosmetic > 0) {
                characterCosmetics.setCharacterCosmetic(mintedId, appliedCosmetic);
            }
    }

    function _withdrawShieldFromBridge(uint256 bridgedNFT, uint256 chainId, uint256 sourceId) internal returns (uint256 mintedId) {
        mintedId = nftChainIdsToMintId[nftTypeToAddress[NFT_TYPE_SHIELD]][transferInChainId[bridgedNFT]];

        uint256 seed = transferInSeeds[bridgedNFT];

        uint256 meta = transferInsMeta[bridgedNFT];

        uint32 appliedCosmetic = uint32((meta >> 96) & 0xFFFFFFFF);

         mintedId = 
            shields.performMintShieldDetailed(address(this), meta, seed, mintedId);

        // if(appliedCosmetic > 0) { later
        //     weaponCosmetics.setWeaponCosmetic(mintedId, appliedCosmetic);
        //  }
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

    // Bot to transfer in an NFT (outside chain => this chain)
    function transferIn(address receiver, uint8 nftType, uint256 sourceChain, uint256 sourceId, 
    string memory rename, uint256 metaData, uint256 seed, string memory chainId) public gameAdminRestricted {
        transferIns[++_transferInsAt] = TransferIn(receiver, nftType, sourceChain, sourceId,
        rename, block.number, 0, TRANSFER_IN_STATUS_AVAILABLE);
        receivedNFTs[receiver].add(_transferInsAt);
        transferInsMeta[_transferInsAt] = metaData;
        transferInSeeds[_transferInsAt] = seed;
        transferInChainId[_transferInsAt] = chainId;

        _transferInsLog[sourceChain][nftType][sourceId] = _transferInsAt;
        emit TransferedIn(receiver, nftType, sourceChain, sourceId);
    }

    // To know if it actually made it
    function getTransferInFromLog(uint256 sourceChain, uint8 nftType, uint256 sourceId) public view returns (uint256) {
        return  _transferInsLog[sourceChain][nftType][sourceId];
    }

    function packedWeaponsData(uint256 weaponId) public view returns (uint256 packedData, uint256 seed3dCosmetics, string memory rename) {
        (uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level,,,,, uint24 _burnPoints,) = weapons.get(weaponId);
        uint32 appliedCosmetic = weaponCosmetics.getWeaponCosmetic(weaponId);
        rename = weaponRenameTagConsumables.getWeaponRename(weaponId);
        seed3dCosmetics = weapons.getCosmeticsSeed(weaponId);
        packedData = packWeaponsData(appliedCosmetic, _properties, _stat1, _stat2, _stat3, _level, uint8(_burnPoints & 0xFF), uint8((_burnPoints >> 8) & 0xFF), uint8((_burnPoints >> 16) & 0xFF));
    }

    // Applied cosmetic 32 bits is too much but will just put it as MSB for now. Can change later when something else is added.
    function packWeaponsData(uint32 appliedCosmetic, uint16 properties, uint16 stat1, uint16 stat2, uint16 stat3, uint8 weaponLevel, uint8 lowStarBurnPoints, uint8 fourStarBurnPoints, uint8 fiveStarBurnPoints) public pure returns (uint256) {
        return  uint256(fiveStarBurnPoints | (uint256(fourStarBurnPoints) << 8) | (uint256(lowStarBurnPoints) << 16) | (uint256(weaponLevel) << 24) | (uint256(stat3) << 32) | (uint256(stat2) << 48) | (uint256(stat1) << 64) | (uint256(properties) << 80) | (uint256(appliedCosmetic) << 96));
    }

    function unpackWeaponsData(uint256 metaData) public pure returns (uint32 appliedCosmetic, uint16 properties, uint16 stat1, uint16 stat2, uint16 stat3, uint8 weaponLevel, uint8 lowStarBurnPoints, uint8 fourStarBurnPoints, uint8 fiveStarBurnPoints) {
        fiveStarBurnPoints = uint8(metaData & 0xFF);
        fourStarBurnPoints = uint8((metaData >> 8) & 0xFF);
        lowStarBurnPoints = uint8((metaData >> 16) & 0xFF);
        weaponLevel = uint8((metaData >> 24) & 0xFF);
        stat3 = uint16((metaData >> 32) & 0xFFFF);
        stat2 = uint16((metaData >> 48) & 0xFFFF);
        stat1 = uint16((metaData >> 64) & 0xFFFF);
        properties = uint16((metaData >> 80) & 0xFFFF);
        appliedCosmetic = uint32((metaData >> 96) & 0xFFFFFFFF);
    }

    function packedCharacterData(uint256 characterId) public view returns (uint256 packedData, uint256 seed3dCosmetics, string memory rename) {
        (uint16 xp, uint8 level, uint8 trait,,,,,,, ) = characters.get(characterId);
        uint32 appliedCosmetic = characterCosmetics.getCharacterCosmetic(characterId);
        rename = characterRenameTagConsumables.getCharacterRename(characterId);
        seed3dCosmetics = characters.getCosmeticsSeed(characterId);
        packedData = packCharactersData(appliedCosmetic, xp, level, trait);
    }

    // Applied cosmetic 32 bits is too much but will just put it as MSB for now. Can change later when something else is added.
    function packCharactersData(uint32 appliedCosmetic, uint16 xp, uint8 level, uint8 trait) public pure returns (uint256) {
        return  uint256(uint256(trait) | (uint256(level) << 8) | (uint256(xp) << 16) | (uint256(appliedCosmetic) << 32));
    }

    function unpackCharactersData(uint256 metaData) public pure returns (uint32 appliedCosmetic, uint16 xp, uint8 level, uint8 trait) {
        trait = uint8((metaData) & 0xFF);
        level = uint8((metaData >> 8) & 0xFF);
        xp = uint16(metaData  >> 16 & 0xFFFF);
        appliedCosmetic = uint32((metaData >> 32) & 0xFFFFFFFF);
    }

    function packedShieldsData(uint256 shieldid) public view returns (uint256 packedData, uint256 seed3dCosmetics, string memory rename) {
        (uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3) = shields.get(shieldid);
        uint8 _type = uint8(shields.getNftVar(shieldid, 2)); // 2 => shield type
        uint32 appliedCosmetic = 0; // to add later
        rename = ""; // to add later
        seed3dCosmetics = shields.getCosmeticsSeed(shieldid);
        packedData = packShieldsData(appliedCosmetic, _properties, _stat1, _stat2, _stat3, _type);
    }

    
    function packShieldsData(uint32 appliedCosmetic, uint16 properties, uint16 stat1, uint16 stat2, uint16 stat3, uint8 shieldType) public pure returns (uint256) {
        return  uint256(uint256(shieldType) | uint256(stat3) << 16| (uint256(stat2) << 32) | (uint256(stat1) << 48) | (uint256(properties) << 64) | (uint256(appliedCosmetic) << 80));
    }

    function unpackShieldsData(uint256 metaData) public pure returns (uint32 appliedCosmetic, uint16 properties, uint16 stat1, uint16 stat2, uint16 stat3, uint8 shieldType) {
        // 16 bits reserved for the type (only using 8)
        shieldType = uint8(metaData & 0xFF); 
        stat3 = uint16((metaData >> 16) & 0xFFFF);
        stat2 = uint16((metaData >> 32) & 0xFFFF);
        stat1 = uint16((metaData >> 48) & 0xFFFF);
        properties = uint16((metaData >> 64) & 0xFFFF);
        appliedCosmetic = uint32((metaData >> 80) & 0xFFFFFFFF);
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
