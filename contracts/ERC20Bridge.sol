pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./cryptoblades.sol";
import "./interfaces/IERC20BridgeProxy.sol";

contract ERC20Bridge is Initializable, AccessControlUpgradeable
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
   
    bool erc20BridgeEnabled;

    uint8 public constant BRIDGE_TOKEN_VAR_MIN_AMOUNT_INDEX = 0; // can't request bridge less than this value; value is in wei
    uint8 public constant BRIDGE_TOKEN_VAR_FEE_INDEX = 1;

    mapping(uint256 => uint256) private _bridgeVars;
    mapping(address => mapping(uint256 => uint256)) private _bridgeTokenVars;

    uint8 public constant TRANSFER_OUT_STATUS_NONE = 0;
    uint8 public constant TRANSFER_OUT_STATUS_PENDING = 1;
    uint8 public constant TRANSFER_OUT_STATUS_PROCESSING = 2;
    uint8 public constant TRANSFER_OUT_STATUS_DONE = 3;
    uint8 public constant TRANSFER_OUT_STATUS_ERROR = 4;

    struct ERC20BridgeOutRequests {
        address owner;
        address erc20Address;
        uint256 amount;

        uint256 chainId;
        uint8 status; // enumeration. 0 => nothing, 1 => transfer requested, 2 => processing, 3 => done
    }

    struct ERC20BridgeReceivedTokens {
        address owner;
        address erc20Address;
        uint256 amount;

        uint256 sourceChain;
        uint256 sourceTransferId;
    }


    uint256 private _transfersOutCount;
    mapping(uint256 => bool) private _bridgeEnabled; // Which chain can we go to from here?
    mapping(uint256 => ERC20BridgeOutRequests) private transferOuts;

    uint256 private _transferInsCount;
    mapping(uint256 => ERC20BridgeReceivedTokens) private transferIns;

    // Player stuff
    // Player => bridgeTransferId
    mapping(address => uint256) private transferOutOfPlayers;
    mapping(address => EnumerableSet.UintSet) private transferOutOfPlayersHistory;
    mapping(address => EnumerableSet.UintSet) private transferInOfPlayersHistory;

    // address is IERC20
    EnumerableSet.AddressSet private supportedTokenTypes;
    EnumerableSet.UintSet private _supportedChains;

    CryptoBlades public game;

    // Proxy contracts
    mapping(address => address) private erc20ProxyContract;
    // Source chain => transfer out id of source chain => transfer in id
    mapping(uint256 => mapping(uint256 => uint256)) private botLog;
    // ERC20 => allowed networks to bridge into
    mapping(address => EnumerableSet.UintSet) private erc20AllowedChains;
    // Target network => allowed ERC20s
    mapping(uint256 => EnumerableSet.AddressSet) private targetChainAllowedERC20s;

    event BridgeIn(address indexed receiver, address indexed erc20, uint256 indexed sourceChain, uint256 sourceId, uint256 amount);
    event BridgeOut(address indexed sender, address indexed erc20, uint256 indexed destinationChain, uint256 requestId, uint256 amount);

    function initialize(CryptoBlades _game)
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = _game;
    }

    modifier restricted() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AO");
        _;
    }

    modifier gameAdminRestricted() {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NGA");
        _;
    }

    modifier tokenNotBanned(IERC20 _tokenAddress) {
        require(
            isTokenSupported(_tokenAddress),
            "Error"
        );
        _;
    }

     modifier canBridge() {
         require(
            erc20BridgeEnabled == true,
            "bridge disabled"
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
            || transferOuts[transferOutOfPlayers[msg.sender]].status == TRANSFER_OUT_STATUS_DONE,
            "Cannot request a bridge"
        );
        _;
    }

    modifier bridgeSupported(IERC20 _tokenAddress, uint256 targetChain) {
        require(erc20AllowedChains[address(_tokenAddress)].contains(targetChain), "BNS1"); // We support bridging from this chain to that chain
        require(IERC20BridgeProxy(erc20ProxyContract[address(_tokenAddress)]).isEnabled(), "BNS2");
        _;
    }
    
    function isTokenSupported(IERC20 _tokenAddress) public view returns (bool) {
        return supportedTokenTypes.contains(address(_tokenAddress));
    }

    function getSupportedTokenTypes() public view returns (IERC20[] memory) {
        EnumerableSet.AddressSet storage set = supportedTokenTypes;
        IERC20[] memory tokens = new IERC20[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = IERC20(set.at(i));
        }
        return tokens;
    }

    function allowToken(IERC20 _tokenAddress) public restricted {
        supportedTokenTypes.add(address(_tokenAddress));
    }

    function disallowToken(IERC20 _tokenAddress) public restricted {
        supportedTokenTypes.remove(address(_tokenAddress));
    }

    function bridgeIsEnabled() public view returns (bool) {
        return erc20BridgeEnabled;
    }

    function setBridgeEnabled(bool enabled) public restricted {
        erc20BridgeEnabled = enabled;
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


    function toggleChainBridgeEnabled(uint256 chainId, bool enable) public restricted {
        _bridgeEnabled[chainId] = enable;

        if(enable) {
            _supportedChains.add(chainId);
        } else {
            _supportedChains.remove(chainId);
        }
    }

    // Player requests to bridge an erc20
    function bridgeOutToken(
        address _tokenAddress,
        uint256 _amount,
        uint256 targetChain
    )
        public
        tokenNotBanned(IERC20(_tokenAddress))
        bridgeSupported(IERC20(_tokenAddress), targetChain)
        bridgeEnabled(targetChain)
        noPendingBridge()
        canBridge()
    {
        require(_amount >= _bridgeTokenVars[_tokenAddress][BRIDGE_TOKEN_VAR_MIN_AMOUNT_INDEX], "NA1");
        require(IERC20BridgeProxy(erc20ProxyContract[_tokenAddress]).canBridge(msg.sender, _amount, targetChain), "NA2");

        game.payContractTokenOnly(msg.sender, _bridgeTokenVars[_tokenAddress][BRIDGE_TOKEN_VAR_FEE_INDEX]);
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        
        transferOuts[++_transfersOutCount] = ERC20BridgeOutRequests(msg.sender, _tokenAddress, _amount, targetChain, TRANSFER_OUT_STATUS_PENDING);
        transferOutOfPlayers[msg.sender] = _transfersOutCount;
        transferOutOfPlayersHistory[msg.sender].add(_transfersOutCount);

        emit BridgeOut(msg.sender, _tokenAddress, targetChain, _transfersOutCount, _amount);
    }

    function bridgeInToken(
        address receiver,
        address _tokenAddress,
        uint256 _amount,
        uint256 sourceChain,
        uint256 sourceTransferId
    ) public gameAdminRestricted
    {
        IERC20(_tokenAddress).transfer(receiver, _amount);
        transferIns[++_transferInsCount] = ERC20BridgeReceivedTokens(receiver, _tokenAddress, _amount, sourceChain, sourceTransferId);
        transferInOfPlayersHistory[receiver].add(_transferInsCount);
        emit BridgeIn(receiver, _tokenAddress, sourceChain, sourceTransferId, _amount);
    }
    
    function erc20BridgeIsEnabled() public view returns (bool) {
        return erc20BridgeEnabled;
    }

    function setErc20BridgeIsEnabled(bool enabled) public restricted {
        erc20BridgeEnabled = enabled;
    }

    function getBridgeTransfers() public view returns (uint256) {
        return _transfersOutCount;
    }

    function getBridgeVal(uint256 index) public view returns (uint256) {
        return  _bridgeVars[index];
    }

    function setBridgeVal(uint256 index, uint256 value) public restricted {
        _bridgeVars[index] = value;
    }

    function getTokenBridgeVal(IERC20 token, uint256 index) public view returns (uint256) {
        return  _bridgeTokenVars[address(token)][index];
    }

    function setTokenBridgeVal(IERC20 token, uint256 index, uint256 value) public restricted {
        _bridgeTokenVars[address(token)][index] = value;
    }

    function getBridgeTransferOfPlayer(address player) public view returns (uint256) {
        return transferOutOfPlayers[player];
    }

    function getBridgeOutTransferOfPlayerHistory(address player)  public view returns (uint256[] memory history) {
        history = new uint256[](transferOutOfPlayersHistory[player].length());

        for (uint256 i = 0; i < transferOutOfPlayersHistory[player].length(); i++) {
            uint256 id = transferOutOfPlayersHistory[player].at(i);
                history[i] = id;
        }
    }

    function getBridgeInTransferOfPlayerHistory(address player)  public view returns (uint256[] memory history) {
        history = new uint256[](transferInOfPlayersHistory[player].length());

        for (uint256 i = 0; i < transferInOfPlayersHistory[player].length(); i++) {
            uint256 id = transferInOfPlayersHistory[player].at(i);
                history[i] = id;
        }
    }

    function getBridgeOutTransfer(uint256 bridgeTransferId) public view returns (address, address, uint256, uint256, uint8) {
        ERC20BridgeOutRequests storage transferOut = transferOuts[bridgeTransferId];
        return (transferOut.owner,
                transferOut.erc20Address,
                transferOut.amount,
                transferOut.chainId,
                transferOut.status);
    }

    function getBridgeInTransfer(uint256 bridgeTransferId) public view returns (address, address, uint256, uint256, uint256) {
        ERC20BridgeReceivedTokens storage transferIn = transferIns[bridgeTransferId];
        return (transferIn.owner,
                transferIn.erc20Address,
                transferIn.amount,
                transferIn.sourceChain,
                transferIn.sourceTransferId);
    }

    // Bot to update status of a transfer request (this chain => outside chain)
    function updateBridgeTransferStatus(uint256 bridgeTransferId, uint8 status, bool forced) public gameAdminRestricted {
        ERC20BridgeOutRequests storage transferOut = transferOuts[bridgeTransferId];
        require(forced ||
        (transferOut.status == TRANSFER_OUT_STATUS_PENDING && status == TRANSFER_OUT_STATUS_PROCESSING)
        || (transferOut.status == TRANSFER_OUT_STATUS_PROCESSING && status == TRANSFER_OUT_STATUS_DONE)
        || status == TRANSFER_OUT_STATUS_ERROR, 'Invalid status change');
        transferOut.status = status;
    }

     function getTransferInFromLogV2(uint256 sourceChain, uint256 sourceTransferId) public view returns (uint256) {
        return botLog[sourceChain][sourceTransferId];
    }

    function setProxyContract(address token, address proxy, bool forced) external restricted {
        require(forced || erc20ProxyContract[token] == address(0), "NA");
        erc20ProxyContract[token] = proxy;
    }

    function getProxyContract(address token) public view returns (address) {
        return erc20ProxyContract[token];
    }

    function setChainSupportedForERC20(address token, uint256[] calldata chainIds, bool support) external restricted {
        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256 chainId = chainIds[i];
            if(support) {
                require(!erc20AllowedChains[token].contains(chainId), "NA");
                erc20AllowedChains[token].add(chainId);
                targetChainAllowedERC20s[chainId].add(token);
            } else {
                require(erc20AllowedChains[token].contains(chainId), "NA2");
                erc20AllowedChains[token].remove(chainId);
                targetChainAllowedERC20s[chainId].remove(token);
            }
        }
    }

    function getChainsSupportingERCs(address token) public view returns (uint256[] memory chains) {
        chains = new uint256[](erc20AllowedChains[token].length());

        for (uint256 i = 0; i < erc20AllowedChains[token].length(); i++) {
            uint256 id = erc20AllowedChains[token].at(i);
                chains[i] = id;
        }
    }

    function getERCsSupportedByChain(uint256 chain) public view returns (address[] memory tokens) {
        tokens = new address[](targetChainAllowedERC20s[chain].length());

        for (uint256 i = 0; i < targetChainAllowedERC20s[chain].length(); i++) {
            address token = targetChainAllowedERC20s[chain].at(i);
                tokens[i] = token;
        }
    }
}
