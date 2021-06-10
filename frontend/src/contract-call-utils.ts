import BigNumber from 'bignumber.js';
import { Web3JsCallOptions, Web3JsAbiCall } from '../../abi-common';
import { Contract, Contracts } from './interfaces';

export type CryptoBladesAlias = NonNullable<Contracts['CryptoBlades']>;
export type NFTMarketAlias = NonNullable<Contracts['NFTMarket']>;

type CryptoBladesMethodsFunction = (cryptoBladesContract: CryptoBladesAlias['methods']) => Web3JsAbiCall<string>;

export async function getFeeInSkillFromUsd(
  cryptoBladesContract: CryptoBladesAlias,
  opts: Web3JsCallOptions,
  fn: CryptoBladesMethodsFunction
): Promise<string> {
  const feeInUsd = await fn(cryptoBladesContract.methods).call(opts);

  const feeInSkill = await cryptoBladesContract.methods
    .usdToSkill(feeInUsd)
    .call(opts);

  return feeInSkill;
}

export async function approveFee(
  cryptoBladesContract: CryptoBladesAlias,
  skillToken: Contracts['SkillToken'],
  skillRewardsAvailable: string,
  callOpts: Web3JsCallOptions,
  approveOpts: Web3JsCallOptions,
  fn: CryptoBladesMethodsFunction
) {
  const feeInSkill = await getFeeInSkillFromUsd(cryptoBladesContract, callOpts, fn);

  const paidByRewardPool = new BigNumber(feeInSkill).lte(skillRewardsAvailable);

  if(paidByRewardPool) {
    return null;
  }

  return await skillToken.methods
    .approve(cryptoBladesContract.options.address, feeInSkill)
    .send(approveOpts);
}

export async function approveMarketFee( // TEMP because i did not want to change the above
  marketContract: Contracts['NFTMarket'],
  skillToken: Contracts['SkillToken'],
  approveOpts: Web3JsCallOptions,
  price: string
) {
  return await skillToken.methods
    .approve(marketContract!.options.address, price)
    .send(approveOpts);
}

export async function approveNFTMarket(
  nftContract: NonNullable<Contracts['Weapons'] | Contracts['Characters']>,
  marketContract: NonNullable<Contracts['NFTMarket']>,
  approveOpts: Web3JsCallOptions,
  tokenId: string
) {
  return await nftContract!.methods
    .approve(marketContract!.options.address, tokenId)
    .send(approveOpts);
}

export async function waitUntilEvent(contract: Contract<unknown>, eventName: string, opts: object): Promise<object> {
  let subscriber: any;

  const data = await new Promise<object>((resolve, reject) => {
    subscriber = contract.events[eventName](opts, (err: Error | null, data: object | null) => {
      if(err) reject(err);
      else resolve(data!);
    });
  });

  subscriber.unsubscribe();

  return data;
}
