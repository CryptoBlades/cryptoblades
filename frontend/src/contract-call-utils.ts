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

  const from = callOpts.from;
  if(from !== null) {
    const allowance = await skillToken.methods
      .allowance(from, cryptoBladesContract.options.address)
      .call(callOpts);

    if(allowance >= feeInSkill) {
      return null;
    }
  }

  return await skillToken.methods
    .approve(cryptoBladesContract.options.address, feeInSkill)
    .send(approveOpts);
}

export async function waitUntilEvent(contract: Contract<unknown>, eventName: string, opts: Record<string, unknown>): Promise<Record<string, unknown>> {
  let subscriber: any;

  const data = await new Promise<Record<string, unknown>>((resolve, reject) => {
    subscriber = contract.events[eventName](opts, (err: Error | null, data: Record<string, unknown> | null) => {
      if(err) reject(err);
      else resolve(data!);
    });
  });

  subscriber.unsubscribe();

  return data;
}
