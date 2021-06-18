pragma solidity ^0.6.5;

// ERC165 Interface ID: 0xe62e6974
interface ITransferCooldownable {
    // Views
    function lastTransferTimestamp(uint256 tokenId) external view returns (uint256);

    function transferCooldownEnd(uint256 tokenId)
        external
        view
        returns (uint256);

    function transferCooldownLeft(uint256 tokenId)
        external
        view
        returns (uint256);
}

library TransferCooldownableInterfaceId {
    function interfaceId() internal pure returns (bytes4) {
        return
            ITransferCooldownable.lastTransferTimestamp.selector ^
            ITransferCooldownable.transferCooldownEnd.selector ^
            ITransferCooldownable.transferCooldownLeft.selector;
    }
}
