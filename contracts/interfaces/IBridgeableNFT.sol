pragma solidity ^0.6.5;

interface IBridgeableNFT {
    function collectData(uint256 tokenId) external view returns (uint256[] memory uintVars, bool[] memory boolVars, address[] memory addressVars,  string[] memory stringVars);

    function mintOrUpdate(uint256 tokenId, uint256[] calldata uintVars, bool[] calldata boolVars, address[] calldata addressVars,  string[] calldata stringVars) external returns (uint256);
}
