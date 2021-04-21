pragma solidity >=0.6.0;

import "../node_modules/abdk-libraries-solidity/ABDKMath64x64.sol";

contract DummyPriceService {
  // hardcoded for $5 per SKILL

  using ABDKMath64x64 for uint256;
  using ABDKMath64x64 for int128;

  function decimals() external pure returns (uint8) {
      return 18;
  }
  function description() external pure returns (string memory) {
      return "";
  }
  function version() external pure returns (uint256) {
      return 1;
  }

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    pure
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        return (_roundId, uint256(5 * 10000).divu(10000).to128x128(), 0, 0, 0); // 5 usd
  }

  function latestRoundData()
    external
    pure
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
    return (0, uint256(5 * 10000).divu(10000).to128x128(), 0, 0, 0); // 5 usd
  }

}
