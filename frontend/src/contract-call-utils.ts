import BigNumber from 'bignumber.js';
import { Web3JsCallOptions, Web3JsAbiCall, Web3JsSendOptions } from '../../abi-common';
import { Contract, Contracts } from './interfaces';

export type CryptoBladesAlias = NonNullable<Contracts['CryptoBlades']>;
export type NFTMarketAlias = NonNullable<Contracts['NFTMarket']>;

type MethodsFunction<T extends Contract<unknown>> = (contract: T['methods']) => Web3JsAbiCall<string>;
type CryptoBladesMethodsFunction = MethodsFunction<CryptoBladesAlias>;

export async function getFeeInSkillFromUsdFromAnyContract<T extends Contract<unknown>>(
  cryptoBladesContract: CryptoBladesAlias,
  feeContract: T,
  opts: Web3JsCallOptions,
  fn: MethodsFunction<T>
): Promise<string> {
  const feeInUsd = await fn(feeContract.methods).call(opts);

  const feeInSkill = await cryptoBladesContract.methods
    .usdToSkill(feeInUsd)
    .call(opts);

  return feeInSkill;
}

export async function getFeeInSkillFromUsd(
  cryptoBladesContract: CryptoBladesAlias,
  opts: Web3JsCallOptions,
  fn: CryptoBladesMethodsFunction
): Promise<string> {
  return getFeeInSkillFromUsdFromAnyContract(
    cryptoBladesContract,
    cryptoBladesContract,
    opts,
    fn
  );
}

type WithOptionalFrom<T extends { from: unknown }> = Omit<T, 'from'> & Partial<Pick<T, 'from'>>;

export async function approveFeeWalletOnly<T extends Contract<unknown>>(
  feeContract: T,
  skillToken: Contracts['SkillToken'],
  from: NonNullable<Web3JsCallOptions['from']>,
  callOpts: WithOptionalFrom<Web3JsCallOptions>,
  approveOpts: WithOptionalFrom<Web3JsSendOptions>,
  feeInSkill: BigNumber
) {
  const callOptsWithFrom: Web3JsCallOptions = { from, ...callOpts };
  const approveOptsWithFrom: Web3JsSendOptions = { from, ...approveOpts };

  const allowance = await skillToken.methods
    .allowance(from, feeContract.options.address)
    .call(callOptsWithFrom);

  if (feeInSkill.lte(allowance)) {
    return null;
  }

  return await skillToken.methods
    .approve(feeContract.options.address, feeInSkill.toString())
    .send(approveOptsWithFrom);
}

export async function approveFeeFixed<T extends Contract<unknown>>(
  cryptoBladesContract: CryptoBladesAlias,
  feeContract: T,
  skillToken: Contracts['SkillToken'],
  from: NonNullable<Web3JsCallOptions['from']>,
  skillRewardsAvailable: string,
  callOpts: WithOptionalFrom<Web3JsCallOptions>,
  approveOpts: WithOptionalFrom<Web3JsSendOptions>,
  feeInSkill: BigNumber,
  { feeMultiplier, allowInGameOnlyFunds, allowSkillRewards }:
  { feeMultiplier?: string | number, allowInGameOnlyFunds?: boolean, allowSkillRewards?: boolean } = {}
) {
  const callOptsWithFrom: Web3JsCallOptions = { from, ...callOpts };

  if(allowInGameOnlyFunds === undefined) {
    allowInGameOnlyFunds = true;
  }

  if(allowSkillRewards === undefined) {
    allowSkillRewards = true;
  }

  if(feeMultiplier !== undefined) {
    feeInSkill = feeInSkill.times(feeMultiplier).integerValue(BigNumber.ROUND_CEIL);
  }

  if(allowSkillRewards) {
    try {
      feeInSkill = await cryptoBladesContract.methods
        .getSkillNeededFromUserWallet(from, feeInSkill.toString(), allowInGameOnlyFunds)
        .call(callOptsWithFrom)
        .then((n: BigNumber.Value) => new BigNumber(n));
    }
    catch(err) {
      const paidByRewardPool = feeInSkill.lte(skillRewardsAvailable);

      if(paidByRewardPool) {
        return null;
      }
    }
  }

  return await approveFeeWalletOnly(
    feeContract,
    skillToken,
    from,
    callOpts,
    approveOpts,
    feeInSkill
  );
}

export async function approveFeeDynamic<T extends Contract<unknown>>(
  cryptoBladesContract: CryptoBladesAlias,
  feeContract: T,
  skillToken: Contracts['SkillToken'],
  from: NonNullable<Web3JsCallOptions['from']>,
  skillRewardsAvailable: string,
  callOpts: WithOptionalFrom<Web3JsCallOptions>,
  approveOpts: WithOptionalFrom<Web3JsSendOptions>,
  fn: MethodsFunction<T>,
  { feeMultiplier, allowInGameOnlyFunds, allowSkillRewards }:
  { feeMultiplier?: string | number, allowInGameOnlyFunds?: boolean, allowSkillRewards?: boolean } = {},
  fnReturnsSkill: boolean = false,
) {
  const callOptsWithFrom: Web3JsCallOptions = { from, ...callOpts };

  const feeInSkill = new BigNumber(
    fnReturnsSkill ?
      await fn(feeContract.methods).call(callOptsWithFrom) :
      await getFeeInSkillFromUsdFromAnyContract(
        cryptoBladesContract,
        feeContract,
        callOptsWithFrom,
        fn
      )
  );

  return await approveFeeFixed(
    cryptoBladesContract,
    feeContract,
    skillToken,
    from,
    skillRewardsAvailable,
    callOpts,
    approveOpts,
    feeInSkill,
    { feeMultiplier, allowInGameOnlyFunds, allowSkillRewards }
  );
}

export async function approveFeeWalletOrRewards<T extends Contract<unknown>>(
  cryptoBladesContract: CryptoBladesAlias,
  feeContract: T,
  skillToken: Contracts['SkillToken'],
  from: NonNullable<Web3JsCallOptions['from']>,
  callOpts: WithOptionalFrom<Web3JsCallOptions>,
  approveOpts: WithOptionalFrom<Web3JsSendOptions>,
  feeInSkill: BigNumber,
  skillRewardsAvailable: string
) {
  return await approveFeeFixed(
    cryptoBladesContract,
    feeContract,
    skillToken,
    from,
    skillRewardsAvailable,
    callOpts,
    approveOpts,
    feeInSkill,
    { allowSkillRewards: true }
  );
}

export async function approveFee(
  cryptoBladesContract: CryptoBladesAlias,
  skillToken: Contracts['SkillToken'],
  from: NonNullable<Web3JsCallOptions['from']>,
  skillRewardsAvailable: string,
  callOpts: WithOptionalFrom<Web3JsCallOptions>,
  approveOpts: WithOptionalFrom<Web3JsSendOptions>,
  fn: CryptoBladesMethodsFunction,
  opts: { feeMultiplier?: string | number, allowInGameOnlyFunds?: boolean } = {}
) {
  return await approveFeeDynamic(
    cryptoBladesContract,
    cryptoBladesContract,
    skillToken,
    from,
    skillRewardsAvailable,
    callOpts,
    approveOpts,
    fn,
    opts
  );
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
