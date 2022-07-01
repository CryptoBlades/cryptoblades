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
   
    bool private _erc20BridgeEnabled;

    uint8 public constant BRIDGE_TOKEN_VAR_MIN_AMOUNT_INDEX = 0; // can't request bridge less than this value; value is in wei
    uint8 public constant BRIDGE_TOKEN_VAR_FEE_INDEX = 1;
    uint8 public constant BRIDGE_TOKEN_VAR_MAX_AMOUNT_INDEX = 2; // can't request bridge greater than this value; value is in wei

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

        uint256 blockNumber;
    }

    struct ERC20BridgeReceivedTokens {
        address owner;
        address erc20Address;
        uint256 amount;

        uint256 sourceChain;
        uint256 sourceTransferId;

        uint256 blockNumber;
    }


    uint256 private _transfersOutCount;
    mapping(uint256 => bool) private _bridgeEnabled; // Which chain can we go to from here?
    mapping(uint256 => ERC20BridgeOutRequests) private _transferOuts;

    uint256 private _transferInsCount;
    mapping(uint256 => ERC20BridgeReceivedTokens) private _transferIns;

    // Player stuff
    // Player => bridgeTransferId
    mapping(address => uint256) private _transferOutOfPlayers;
    mapping(address => EnumerableSet.UintSet) private _transferOutOfPlayersHistory;
    mapping(address => EnumerableSet.UintSet) private _transferInOfPlayersHistory;

    // address is IERC20
    EnumerableSet.AddressSet private _supportedTokenTypes;
    EnumerableSet.UintSet private _supportedChains;

    CryptoBlades public game;

    // Proxy contracts
    mapping(address => address) private _erc20ProxyContract;
    // Source chain => transfer out id of source chain => transfer in id
    mapping(uint256 => mapping(uint256 => uint256)) private _botLog;
    // ERC20 => allowed networks to bridge into
    mapping(address => EnumerableSet.UintSet) private _erc20AllowedChains;
    // Target network => allowed ERC20s
    mapping(uint256 => EnumerableSet.AddressSet) private _targetChainAllowedERC20s;

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
            _erc20BridgeEnabled == true,
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
            _transferOuts[_transferOutOfPlayers[msg.sender]].status == TRANSFER_OUT_STATUS_NONE
            || _transferOuts[_transferOutOfPlayers[msg.sender]].status == TRANSFER_OUT_STATUS_DONE,
            "Cannot request a bridge"
        );
        _;
    }

    modifier bridgeSupported(IERC20 _tokenAddress, uint256 targetChain) {
        require(_erc20AllowedChains[address(_tokenAddress)].contains(targetChain), "BNS1"); // We support bridging from this chain to that chain
        require(IERC20BridgeProxy(_erc20ProxyContract[address(_tokenAddress)]).isEnabled(), "BNS2");
        _;
    }
    
    function isTokenSupported(IERC20 _tokenAddress) public view returns (bool) {
        return _supportedTokenTypes.contains(address(_tokenAddress));
    }

    function getSupportedTokenTypes() public view returns (IERC20[] memory) {
        EnumerableSet.AddressSet storage set = _supportedTokenTypes;
        IERC20[] memory tokens = new IERC20[](set.length());

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = IERC20(set.at(i));
        }
        return tokens;
    }

    function allowToken(IERC20 _tokenAddress) public restricted {
        _supportedTokenTypes.add(address(_tokenAddress));
    }

    function disallowToken(IERC20 _tokenAddress) public restricted {
        _supportedTokenTypes.remove(address(_tokenAddress));
    }

    function bridgeIsEnabled() public view returns (bool) {
        return _erc20BridgeEnabled;
    }

    function setBridgeEnabled(bool enabled) public restricted {
        _erc20BridgeEnabled = enabled;
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
        require(_amount <= _bridgeTokenVars[_tokenAddress][BRIDGE_TOKEN_VAR_MAX_AMOUNT_INDEX], "NA2");
        require(IERC20BridgeProxy(_erc20ProxyContract[_tokenAddress]).canBridge(msg.sender, _amount, targetChain), "NA3");

        game.payContractTokenOnly(msg.sender, _bridgeTokenVars[_tokenAddress][BRIDGE_TOKEN_VAR_FEE_INDEX]);
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        
        _transferOuts[++_transfersOutCount] = ERC20BridgeOutRequests(msg.sender, _tokenAddress, _amount, targetChain, TRANSFER_OUT_STATUS_PENDING, block.number);
        _transferOutOfPlayers[msg.sender] = _transfersOutCount;
        _transferOutOfPlayersHistory[msg.sender].add(_transfersOutCount);

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
        require(_botLog[sourceChain][sourceTransferId] == 0, "Already Processed");
        IERC20(_tokenAddress).transfer(receiver, _amount);
        _transferIns[++_transferInsCount] = ERC20BridgeReceivedTokens(receiver, _tokenAddress, _amount, sourceChain, sourceTransferId, block.number);
        _transferInOfPlayersHistory[receiver].add(_transferInsCount);
        _botLog[sourceChain][sourceTransferId] = _transferInsCount;
        emit BridgeIn(receiver, _tokenAddress, sourceChain, sourceTransferId, _amount);
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
        return _transferOutOfPlayers[player];
    }

    function getBridgeOutTransferOfPlayerHistory(address player)  public view returns (uint256[] memory history) {
        history = new uint256[](_transferOutOfPlayersHistory[player].length());

        for (uint256 i = 0; i < _transferOutOfPlayersHistory[player].length(); i++) {
            uint256 id = _transferOutOfPlayersHistory[player].at(i);
                history[i] = id;
        }
    }

    function getBridgeInTransferOfPlayerHistory(address player)  public view returns (uint256[] memory history) {
        history = new uint256[](_transferInOfPlayersHistory[player].length());

        for (uint256 i = 0; i < _transferInOfPlayersHistory[player].length(); i++) {
            uint256 id = _transferInOfPlayersHistory[player].at(i);
                history[i] = id;
        }
    }

    function getBridgeOutTransfer(uint256 bridgeTransferId) public view returns (address, address, uint256, uint256, uint8, uint256) {
        ERC20BridgeOutRequests storage transferOut = _transferOuts[bridgeTransferId];
        return (transferOut.owner,
                transferOut.erc20Address,
                transferOut.amount,
                transferOut.chainId,
                transferOut.status,
                transferOut.blockNumber);
    }

    function getBridgeInTransfer(uint256 bridgeTransferId) public view returns (address, address, uint256, uint256, uint256, uint256) {
        ERC20BridgeReceivedTokens storage transferIn = _transferIns[bridgeTransferId];
        return (transferIn.owner,
                transferIn.erc20Address,
                transferIn.amount,
                transferIn.sourceChain,
                transferIn.sourceTransferId,
                transferIn.blockNumber);
    }

    // Bot to update status of a transfer request (this chain => outside chain)
    function updateBridgeTransferStatus(uint256 bridgeTransferId, uint8 status, bool forced) public gameAdminRestricted {
        ERC20BridgeOutRequests storage transferOut = _transferOuts[bridgeTransferId];
        require(forced ||
        (transferOut.status == TRANSFER_OUT_STATUS_PENDING && status == TRANSFER_OUT_STATUS_PROCESSING)
        || (transferOut.status == TRANSFER_OUT_STATUS_PROCESSING && status == TRANSFER_OUT_STATUS_DONE)
        || status == TRANSFER_OUT_STATUS_ERROR, 'Invalid status change');
        transferOut.status = status;
    }

     function getTransferInFromLog(uint256 sourceChain, uint256 sourceTransferId) public view returns (uint256) {
        return _botLog[sourceChain][sourceTransferId];
    }

    function setProxyContract(address token, address proxy, bool forced) external restricted {
        require(forced || _erc20ProxyContract[token] == address(0), "NA");
        _erc20ProxyContract[token] = proxy;
    }

    function getProxyContract(address token) public view returns (address) {
        return _erc20ProxyContract[token];
    }

    function setChainSupportedForERC20(address token, uint256[] calldata chainIds, bool support) external restricted {
        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256 chainId = chainIds[i];
            if(support) {
                require(!_erc20AllowedChains[token].contains(chainId), "NA");
                _erc20AllowedChains[token].add(chainId);
                _targetChainAllowedERC20s[chainId].add(token);
            } else {
                require(_erc20AllowedChains[token].contains(chainId), "NA2");
                _erc20AllowedChains[token].remove(chainId);
                _targetChainAllowedERC20s[chainId].remove(token);
            }
        }
    }

    function getChainsSupportingERCs(address token) public view returns (uint256[] memory chains) {
        chains = new uint256[](_erc20AllowedChains[token].length());

        for (uint256 i = 0; i < _erc20AllowedChains[token].length(); i++) {
            uint256 id = _erc20AllowedChains[token].at(i);
                chains[i] = id;
        }
    }

    function getERCsSupportedByChain(uint256 chain) public view returns (address[] memory tokens) {
        tokens = new address[](_targetChainAllowedERC20s[chain].length());

        for (uint256 i = 0; i < _targetChainAllowedERC20s[chain].length(); i++) {
            address token = _targetChainAllowedERC20s[chain].at(i);
                tokens[i] = token;
        }
    }

    function recoverToken(address token, uint256 amount) public restricted {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
