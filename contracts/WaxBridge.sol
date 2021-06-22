pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";

contract CryptoBlades is Initializable, AccessControlUpgradeable {
    
    using ABDKMath64x64 for int128;

    function initialize() public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        waxWeiPerBnb = 2668232029457282000000;//2668.232029457282000000
        dailyBnbWeiLimit = 35779455436688300;// 0.03577 or about $10
    }

    uint256 public waxWeiPerBnb;
    uint256 public dailyBnbWeiLimit;
    mapping(address => uint256) bnbPaidTowardsLimit;
    mapping(address => uint256) bnbLimitTimestamp; // time of first exchange after 24h expired

    function setDailyBnbWeiLimit(uint256 _dailyBnbWeiLimit) public restricted {
        dailyBnbWeiLimit = _dailyBnbWeiLimit;
    }

    function setWaxWeiPerBnb(uint256 _waxWeiPerBnb) public restricted {
        waxWeiPerBnb = _waxWeiPerBnb;
    }

    function updateValues(uint256 _dailyBnbWeiLimit, uint256 _waxWeiPerBnb) public restricted {
        dailyBnbWeiLimit = _dailyBnbWeiLimit;
        waxWeiPerBnb = _waxWeiPerBnb;
    }

    function getBnbForWax(uint256 waxInWei) public view returns(uint256) {
        return ABDKMath64x64.divu(waxInWei,waxWeiPerBnb).mulu(1 ether);
    }

    function getRemainingBnbToday() public view returns(uint256) {
        if(bnbPaidTowardsLimit[msg.sender] >= dailyBnbWeiLimit)
            return 0;
        return dailyBnbWeiLimit - bnbPaidTowardsLimit[msg.sender];
    }

    function timeUntilLimitExpires() public view returns(uint256) {
        uint256 time = bnbLimitTimestamp[msg.sender] + 1 days;
        if(time < now)
            return 0;
        return time - now;
    }

    function onWaxReceived(address payable from, uint256 waxInWei) public restricted {
        // at this point we assume they're holding enough skill (bot will check through main contract)
        // and that the parameter here won't exceed their daily limit (bot will check ahead of time)
        // bot should track any extra it received and let the user claim the next day
        // so the argument passed should always be <= dailyLimit
        uint256 amount = ABDKMath64x64.divu(waxInWei, waxWeiPerBnb).mulu(1 ether);

        if(bnbLimitTimestamp[from] < now - 1 days) {
            bnbLimitTimestamp[from] = now;
            bnbPaidTowardsLimit[from] = amount;
        }
        else {
            bnbPaidTowardsLimit[from] += amount;
        }
        // supposedly, send and transfer are discouraged since ether istanbul update
        from.call{value: amount}("");
    }

    modifier restricted() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Missing DEFAULT_ADMIN_ROLE role");
        _;
    }

}