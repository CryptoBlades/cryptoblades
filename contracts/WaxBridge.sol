pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract WaxBridge is Initializable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using SafeMath for uint256;

    bytes32 public constant WAX_BRIDGE = keccak256("WAX_BRIDGE");

    uint256 public constant LIMIT_PERIOD = 1 days;

    function initialize() public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        latestWaxChainBlockNumberProcessed = 0;
        totalOwedBnb = 0;
        bnbLimitPerPeriod = 35779455436688300;// 0.03577 or about $10
    }

    uint256 public latestWaxChainBlockNumberProcessed;
    uint256 public totalOwedBnb;
    uint256 public bnbLimitPerPeriod;
    mapping(address => uint256) public bnbLimitTimestamp;
    mapping(address => uint256) public withdrawableBnb;
    mapping(address => uint256) private withdrawnBnbDuringPeriod;

    function getWithdrawnBnbDuringPeriod() public view returns (uint256) {
        if(bnbLimitTimestamp[msg.sender] + LIMIT_PERIOD < block.timestamp) {
            return 0;
        }

        return withdrawnBnbDuringPeriod[msg.sender];
    }

    function getRemainingWithdrawableBnbDuringPeriod() external view returns(uint256) {
        return bnbLimitPerPeriod.sub(getWithdrawnBnbDuringPeriod());
    }

    function getTimeUntilLimitExpires() external view returns(uint256) {
        uint256 limitExpirationTime = bnbLimitTimestamp[msg.sender] + LIMIT_PERIOD;
        (, uint256 result) = limitExpirationTime.trySub(block.timestamp);
        return result;
    }

    function setDailyBnbWeiLimit(uint256 _dailyBnbWeiLimit) external restricted {
        bnbLimitPerPeriod = _dailyBnbWeiLimit;
    }

    receive() external payable restricted {
    }

    function processWaxConversions(uint256 _latestWaxChainBlockNumberProcessed, address[] calldata _to, uint256[] calldata _value) external payable {
        require(hasRole(WAX_BRIDGE, msg.sender), "Missing WAX_BRIDGE role");
        require(_latestWaxChainBlockNumberProcessed > latestWaxChainBlockNumberProcessed, "WAX chain block num must be gt");
        require(_to.length == _value.length, "Mismatched array lengths");
        require(_to.length < 3000, "Too many recipients");

        // assume they're holding enough skill (bot will check through main contract)

        latestWaxChainBlockNumberProcessed = _latestWaxChainBlockNumberProcessed;

        uint256 _totalOwedBnb = 0;
        for (uint256 i = 0; i < _to.length; i++) {
            _totalOwedBnb = _totalOwedBnb.add(_value[i]);
            withdrawableBnb[_to[i]] = withdrawableBnb[_to[i]].add(_value[i]);
        }

        totalOwedBnb = totalOwedBnb.add(_totalOwedBnb);
    }

    function withdraw(uint256 _maxAmount) external returns (uint256) {
        if(bnbLimitTimestamp[msg.sender] + LIMIT_PERIOD < block.timestamp) {
            bnbLimitTimestamp[msg.sender] = block.timestamp;
            withdrawnBnbDuringPeriod[msg.sender] = 0;
        }

        uint256 withdrawableBnbDuringPeriod = bnbLimitPerPeriod.sub(withdrawnBnbDuringPeriod[msg.sender]);

        uint256 bnbToSend = _maxAmount;
        if(bnbToSend > withdrawableBnb[msg.sender]) {
            bnbToSend = withdrawableBnb[msg.sender];
        }
        if(bnbToSend > withdrawableBnbDuringPeriod) {
            bnbToSend = withdrawableBnbDuringPeriod;
        }

        // because of if statement above, 'bnbToSend' is guaranteed to be lte 'withdrawableBnb[msg.sender]'
        // this saves gas
        withdrawableBnb[msg.sender] -= bnbToSend;
        totalOwedBnb -= bnbToSend;
        withdrawnBnbDuringPeriod[msg.sender] = withdrawnBnbDuringPeriod[msg.sender].add(bnbToSend);

        // supposedly, send and transfer are discouraged since ether istanbul update
        (bool sent,) = msg.sender.call{value: bnbToSend}("");
        require(sent, "Failed to send BNB");
    }

    modifier restricted() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Missing DEFAULT_ADMIN_ROLE role");
        _;
    }

}