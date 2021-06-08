const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const _ = require('lodash');
const BigNumber = require('bignumber.js');

function toBN(n) {
  return new BigNumber(n);
}

const SkillToken = artifacts.require('SkillToken');
SkillToken.numberFormat = 'String';
const Characters = artifacts.require('Characters');
Characters.numberFormat = 'String';
const NFTMarket = artifacts.require('NFTMarket');
NFTMarket.numberFormat = 'String';

contract('NFTMarket', accounts => {
  let market, skill, characters;
  beforeEach(async () => {
    skill = await SkillToken.deployed();
    characters = await Characters.deployed();

    market = await NFTMarket.new();

    await market.initialize(skill.address, accounts[2]);

    const GAME_ADMIN = await market.GAME_ADMIN();

    await characters.grantRole(GAME_ADMIN, accounts[0]);
    await market.grantRole(GAME_ADMIN, accounts[0]);

    await skill.transferFrom(skill.address, accounts[1], web3.utils.toWei('10', 'ether'));
  });

  async function createCharacter() {
    const { tx: mintCharaTx } = await characters.mint(accounts[0], '123');

    const newCharaEvt = await expectEvent.inTransaction(mintCharaTx, characters, 'NewCharacter', { minter: accounts[0] });
    return newCharaEvt.args.character;
  }

  it('prevents token transfers if they are not listed', async () => {
    const charaId = await createCharacter();

    expectRevert(characters.safeTransferFrom(accounts[0], market.address, charaId), "Token ID not listed");
  });

  it('supports adding listing', async () => {
    const charaId = await createCharacter();

    await characters.approve(market.address, charaId);

    const { tx } = await market.addListing(characters.address, charaId, web3.utils.toWei('5', 'ether'));

    await expectEvent.inTransaction(tx, market, 'NewListing', {
      seller: accounts[0],
      nftAddress: characters.address,
      nftID: charaId,
      price: web3.utils.toWei('5', 'ether')
    });

    const tokenOwner = await characters.ownerOf(charaId);
    assert.strictEqual(tokenOwner, market.address, 'Expected token to be owned by market');

    const listingIds = await market.getListingIDs(characters.address);
    assert.deepEqual(listingIds, [charaId], 'Expected all listings to include token');

    const listingIdsBySellerNum = await market.getNumberOfListingsBySeller(characters.address, accounts[0]);
    assert.strictEqual(listingIdsBySellerNum, '1', 'Expected listing count for self to be 1');

    const listingIdsBySeller = await market.getListingIDsBySeller(characters.address, accounts[0]);
    assert.deepEqual(listingIdsBySeller, [charaId], 'Expected listings-by-seller to include token');
  });

  it('supports buying', async () => {
    const charaId = await createCharacter();

    await characters.approve(market.address, charaId);

    await market.addListing(characters.address, charaId, web3.utils.toWei('5', 'ether'));

    const accountSkillBalancesPre = await Promise.all(
      accounts.map(acc => skill.balanceOf(acc).then(toBN))
    );

    await skill.approve(market.address, web3.utils.toWei('6', 'ether'), { from: accounts[1] });

    const { tx } = await market.purchaseListing(characters.address, charaId, web3.utils.toWei('6', 'ether'), { from: accounts[1] });

    const evt = await expectEvent.inTransaction(tx, market, 'PurchasedListing', {
      buyer: accounts[1],
      seller: accounts[0],
      nftAddress: characters.address,
      nftID: charaId
    });
    assert.strictEqual(
      toBN(evt.args.price).div(web3.utils.unitMap['ether']).toFixed(1),
      '5.5'
    );

    const accountSkillBalancesPost = await Promise.all(
      accounts.map(acc => skill.balanceOf(acc).then(toBN))
    );

    const accountSkillBalanceDiffs = accountSkillBalancesPost.map((bn, i) =>
      bn.minus(accountSkillBalancesPre[i]).div(web3.utils.unitMap['ether'])
    );

    assert.strictEqual(
      accountSkillBalanceDiffs[0].toFixed(1),
      '5.0',
      'Expected seller to recieve original price'
    );
    assert.strictEqual(
      accountSkillBalanceDiffs[1].toFixed(1),
      '-5.5',
      'Expected buyer to spend original price plus tax'
    );
    assert.strictEqual(
      accountSkillBalanceDiffs[2].toFixed(1),
      '0.5',
      'Expected tax recipient to receive tax on purchase'
    );

    const tokenOwner = await characters.ownerOf(charaId);
    assert.strictEqual(tokenOwner, accounts[1], 'Expected token to have right owner');

    const listingIds = await market.getListingIDs(characters.address);
    assert.deepEqual(listingIds, [], 'Expected there to be no listings');

    const listingIdsBySeller = await market.getListingIDsBySeller(characters.address, accounts[0]);
    assert.deepEqual(listingIdsBySeller, [], 'Expected there to be no listings by seller');
  });

  it('supports canceling listing', async () => {
    const charaId = await createCharacter();

    await characters.approve(market.address, charaId);

    await market.addListing(characters.address, charaId, web3.utils.toWei('5', 'ether'));

    const { tx } = await market.cancelListing(characters.address, charaId);

    await expectEvent.inTransaction(tx, market, 'CancelledListing', {
      seller: accounts[0],
      nftAddress: characters.address,
      nftID: charaId
    });

    const tokenOwner = await characters.ownerOf(charaId);
    assert.strictEqual(tokenOwner, accounts[0], 'Expected token to have right owner');

    const listingIds = await market.getListingIDs(characters.address);
    assert.deepEqual(listingIds, [], 'Expected there to be no listings');

    const listingIdsBySeller = await market.getListingIDsBySeller(characters.address, accounts[0]);
    assert.deepEqual(listingIdsBySeller, [], 'Expected there to be no listings by seller');
  });
});
