const ChainlinkRandoms = artifacts.require("ChainlinkRandoms");

module.exports = async function (deployer, network) {
  if (network === 'bscmainnet' || network === 'bscmainnet-fork' || network === 'hecomainnet' || network === 'okexmainnet') {
    let linkToken, vrfCoordinator, keyHash, fee;
    if (network === 'bscmainnet' || network === 'bscmainnet-fork') {
      linkToken = '0x404460C6A5EdE2D891e8297795264fDe62ADBB75';
      vrfCoordinator = '0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31';
      keyHash = '0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c';
      fee = web3.utils.toWei('0.2', 'ether');
    }
    else if(network === 'hecomainnet' || network === 'okexmainnet') {
      linkToken = '0x0000000000000000000000000000000000000000';
      vrfCoordinator = '0x0000000000000000000000000000000000000000';
      keyHash = '0x0000000000000000000000000000000000000000';
      fee = web3.utils.toWei('0.2', 'ether');
    }

    deployer.deploy(ChainlinkRandoms, vrfCoordinator, linkToken, keyHash, fee);
  }
};
