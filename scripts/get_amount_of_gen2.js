const Characters = artifacts.require('Characters');
const NFTStorage = artifacts.require('NFTStorage');
const retry = require('async-retry');

module.exports = async (callback) => {
  const currentBlock = await web3.eth.getBlockNumber();
  const startingBlock = 0;

  const blockRange = 2000;
  const blocksToCheck = currentBlock - startingBlock;
  const intervals = Math.floor(blocksToCheck / blockRange);
  const c = await Characters.deployed();
  let eventsCount = 0;
  for(let i = 1; i < intervals; i++) {
    try {
      await retry(async () => {
        const events = await c.getPastEvents('NewCharacter', {
          fromBlock: Math.max(currentBlock - (blockRange * i), startingBlock),
          toBlock: currentBlock - (blockRange * (i - 1))
        }, (error, events) => { console.log('error', error); });
        
        const bridgeCount = events.filter(e => e.returnValues.minter === NFTStorage.address).length;
        eventsCount += (events.length - events.filter(e => e.returnValues.minter === NFTStorage.address).length);
        console.log(events.length, bridgeCount, events.length - bridgeCount, eventsCount);
      });
    }
    catch (e) {
      console.log(e);
    }
  }

  console.log('Total', eventsCount);
  
  callback();
}