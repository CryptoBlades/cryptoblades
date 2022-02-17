pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./util.sol";

contract PartnerVault is Initializable, AccessControlUpgradeable, IERC721ReceiverUpgradeable {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    mapping(address => uint256[]) public nfts;
    mapping(address => uint256) public currencies;

    function initialize() public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NA");
    }

    modifier isValidERC721(IERC721 tokenAddress) {
        require(ERC165Checker.supportsInterface(address(tokenAddress), _INTERFACE_ID_ERC721), "Not IERC721");
        _;
    }

    function onERC721Received(address, address, uint256 _id, bytes calldata) external override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }


    // FUNCTIONS

    //what about approval? is the check if owner necessary here?
    //maybe a general function for both actions? idk
    function storeNfts(IERC721 tokenAddress, uint256[] memory tokenIds) public restricted isValidERC721(tokenAddress) {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            tokenAddress.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            nfts[address(tokenAddress)].push(tokenIds[i]);
        }
    }

    function transferNfts(address tokenAddress, address to, uint256 amount) public restricted {
        require(amount < nfts[tokenAddress].length, "Not enough NFTs");
        IERC721 nft = IERC721(tokenAddress);
        for (uint8 i = 0; i < amount; i++) {
            uint256 tokenId = nfts[tokenAddress][nfts[tokenAddress].length - 1];
            nft.safeTransferFrom(address(this), to, tokenId);
            nfts[tokenAddress].pop();
        }
    }

    function isNftOwner(address tokenAddress, address user, uint256 tokenId) public view returns (bool) {
        IERC721 nft = IERC721(tokenAddress);
        return nft.ownerOf(tokenId) == user;
    }

    function storeCurrency(IERC20 tokenAddress, uint256 amount) public restricted {
        tokenAddress.transferFrom(msg.sender, address(this), amount);
        currencies[address(tokenAddress)] += amount;
    }

    //            require(index < questTemplates[tier].length, "Index out of bounds");
    //        questTemplates[tier][index] = questTemplates[tier][questTemplates[tier].length - 1];
    //        questTemplates[tier].pop();

    //    //what about approval? is the check if owner necessary here?
    //    function storeERC20(address tokenAddress, uint256 amount) public restricted {
    //        IERC20 token = IERC20(tokenAddress);
    //        token.safeTransfer(this, amount);
    //    }

    // VIEWS

    function getNftsInVault(address tokenAddress) public view returns (uint256[] memory) {
        return nfts[tokenAddress];
    }
}
