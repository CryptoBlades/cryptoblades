pragma solidity ^0.6.5;

interface IBridgeProxy {
    function collectData(uint256 tokenId) external view returns (uint256[] memory uintVars, bool[] memory boolVars, address[] memory addressVars,  string memory stringVar);

    function mintOrUpdate(uint256 tokenId, uint256[] calldata uintVars, bool[] calldata boolVars, address[] calldata addressVars,  string calldata stringVar) external returns (uint256);

    function isEnabled() external view returns (bool);
}
