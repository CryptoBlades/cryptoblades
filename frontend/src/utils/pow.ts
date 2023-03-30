import PowChains from '../config/pow.json';
import Web3 from 'web3';
import { Wallet } from '@ethersproject/wallet';
import BN from 'bn.js';
import mineGasForTransaction from './miner';

interface Params {
  account: string;
  network: 'mainnet';
}

export async function userProofOfWork(params: Params): Promise<any> {
  const web3 = new Web3();

  const randomSignerWallet = Wallet.createRandom();

  const randomSignerPrivatekey = randomSignerWallet.privateKey;
  const randomSignerAddress = randomSignerWallet.address;

  const nonce = new BN(0);
  const gas = new BN(100000);

  const gasPrice: string = await mineGasForTransaction(web3, nonce, gas, randomSignerAddress);

  const chains = PowChains[params.network];
  const configurations = await Promise.all(chains.map(async(chain) => {
    const w3 = new Web3(chain.rpc);
    return {
      chain,
      web3: w3,
      to: chain.public.address,
      data: chain.public.fnHash + '000000000000000000000000' + params.account.substring(2),
      nonce,
      gas,
      gasPrice,
      balance: await w3.eth.getBalance(params.account)
    };
  }));

  const transactions = await Promise.all(configurations.map(async(config) => {
    return {
      signedTx: await config.web3.eth.accounts.signTransaction({
        from: randomSignerAddress,
        to: config.to,
        data: config.data,
        nonce: nonce.toNumber(),
        gas: gas.toNumber(),
        gasPrice
      }, randomSignerPrivatekey),
      w3: config.web3,
      chain: config.chain.name
    };

  }));

  const fillUps = await Promise.all(transactions.map(async(tx) => {
    if (!tx.signedTx.rawTransaction) return 'Error: Raw Transaction Does Not Exist';
    try {
      await tx.w3.eth.sendSignedTransaction(tx.signedTx.rawTransaction);
      return {
        name: tx.chain,
        action: 0
      };
    } catch (err) {
      return {
        name: tx.chain,
        action: 1
      };
    }
  }));

  return fillUps;
}
