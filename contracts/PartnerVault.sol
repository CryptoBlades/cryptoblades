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
    using SafeMath for uint256;

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

    function storeNfts(IERC721 tokenAddress, uint256[] memory tokenIds) public restricted isValidERC721(tokenAddress) {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            tokenAddress.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            nfts[address(tokenAddress)].push(tokenIds[i]);
        }
    }

    function storeCurrency(IERC20 tokenAddress, uint256 amount) public restricted {
        tokenAddress.transferFrom(msg.sender, address(this), amount);
        currencies[address(tokenAddress)] = currencies[address(tokenAddress)].add(amount);
    }

    function transferReward(address tokenAddress, address to, uint256 amount, uint256 seed) external restricted {
        require(amount <= nfts[tokenAddress].length || amount <= currencies[tokenAddress], "Not enough NFTs or currency");
        if (amount < currencies[tokenAddress]) {
            IERC20 currency = IERC20(tokenAddress);
            currency.transfer(to, amount);
            currencies[tokenAddress] = currencies[tokenAddress].sub(amount);
        } else {
            IERC721 nft = IERC721(tokenAddress);
            for (uint8 i = 0; i < amount; i++) {
                uint256 index = RandomUtil.randomSeededMinMax(0, nfts[tokenAddress].length - 1, seed);
                uint256 tokenId = nfts[tokenAddress][index];
                nft.safeTransferFrom(address(this), to, tokenId);
                deleteNft(nft, index);
                seed = RandomUtil.combineSeeds(seed, i);
            }
        }
    }

    function deleteNft(IERC721 tokenAddress, uint256 index) internal {
        require(index < nfts[address(tokenAddress)].length, "Index out of bounds");
        nfts[address(tokenAddress)][index] = nfts[address(tokenAddress)][nfts[address(tokenAddress)].length - 1];
        nfts[address(tokenAddress)].pop();
    }

    function isNftOwner(IERC721 tokenAddress, address user, uint256 tokenId) public view returns (bool) {
        return tokenAddress.ownerOf(tokenId) == user;
    }


    // VIEWS

    function getNftsInVault(address tokenAddress) public view returns (uint256[] memory) {
        return nfts[tokenAddress];
    }
}
