import BN from 'bn.js';
import Web3 from 'web3';
import * as crypto from 'crypto';

const DIFFICULTY = new BN(1);


export async function mineFreeGas(gasAmount: any, address: any, nonce: any, web3: any) {
  return new Promise(resolve => {
    const nonceHash = new BN(web3.utils.soliditySha3(nonce).slice(2), 16);
    const addressHash = new BN(web3.utils.soliditySha3(address).slice(2), 16);
    const nonceAddressXOR = nonceHash.xor(addressHash);
    const maxNumber = new BN(2).pow(new BN(256)).sub(new BN(1));
    const divConstant = maxNumber.div(DIFFICULTY);
    let candidate: any;

    // eslint-disable-next-line no-constant-condition
    while (true) {
      candidate = new BN(crypto.randomBytes(32).toString('hex'), 16);
      const candidateHash = new BN(web3.utils.soliditySha3(candidate).slice(2), 16);
      const resultHash = nonceAddressXOR.xor(candidateHash);
      const externalGas = divConstant.div(resultHash).toNumber();
      if (externalGas >= gasAmount) {
        break;
      }
    }

    resolve(candidate.toString());
  });
}

async function mineGasForTransaction(web3: Web3, nonce: any, gas: any, from: string): Promise<any> {
  const address = from;
  nonce = web3.utils.isHex(nonce) ? web3.utils.hexToNumber(nonce) : nonce;
  gas = web3.utils.isHex(gas) ? web3.utils.hexToNumber(gas) : gas;

  return address;
}

export default mineGasForTransaction;
