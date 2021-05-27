import { Web3JsCallOptions, Web3JsAbiCall } from '../../abi-common';
import { Contracts } from './interfaces';

export type CryptoBladesAlias = NonNullable<Contracts['CryptoBlades']>;

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
  callOpts: Web3JsCallOptions,
  approveOpts: Web3JsCallOptions,
  fn: CryptoBladesMethodsFunction
) {
  const feeInSkill = await getFeeInSkillFromUsd(cryptoBladesContract, callOpts, fn);

  return await skillToken.methods
    .approve(cryptoBladesContract.options.address, feeInSkill)
    .send(approveOpts);
}
