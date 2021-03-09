import abi from '../../build/ABI.json';

export { abi };

export function createContracts(web3) {
  const Kryptoknights = new web3.eth.Contract(abi, process.env.VUE_APP_KRYPTOKNIGHTS_CONTRACT_ADDRESS);

  return { Kryptoknights };
}
