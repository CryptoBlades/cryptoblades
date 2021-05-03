import { abi as cryptoBladesAbi, networks as cryptoBladesNetworks } from '../../build/contracts/CryptoBlades.json';
import { abi as skillStakingRewardsAbi, networks as skillStakingRewardsNetworks } from '../../build/contracts/SkillStakingRewards.json';
import { abi as lpStakingRewardsAbi, networks as lpStakingRewardsNetworks } from '../../build/contracts/LPStakingRewards.json';
import { abi as raidAbi, networks as raidNetworks } from '../../build/contracts/RaidBasic.json';
import { networks as skillTokenNetworks } from '../../build/contracts/SkillToken.json';
import { networks as lpTokenNetworks } from '../../build/contracts/ExperimentToken.json';
import { abi as erc20Abi } from '../../build/contracts/IERC20.json';

import { abi as charactersAbi } from '../../build/contracts/Characters.json';
import { abi as weaponsAbi } from '../../build/contracts/Weapons.json';

import Web3 from 'web3';
import { Contracts } from './interfaces';

export async function setUpContracts(web3: Web3, featureFlagStakeOnly: boolean): Promise<Contracts> {
  const networkId = process.env.VUE_APP_NETWORK_ID || '5777';
  const skillStakingRewardsContractAddr = process.env.VUE_APP_SKILL_STAKING_REWARDS_CONTRACT_ADDRESS || (skillStakingRewardsNetworks as any)[networkId].address;
  const lpStakingRewardsContractAddr = process.env.VUE_APP_LP_STAKING_REWARDS_CONTRACT_ADDRESS || (lpStakingRewardsNetworks as any)[networkId].address;
  const skillTokenContractAddr = process.env.VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS || (skillTokenNetworks as any)[networkId].address;
  const lpTokenContractAddr = process.env.VUE_APP_LP_TOKEN_CONTRACT_ADDRESS || (lpTokenNetworks as any)[networkId].address;

  const SkillStakingRewards = new web3.eth.Contract(skillStakingRewardsAbi as any, skillStakingRewardsContractAddr);
  const LPStakingRewards = new web3.eth.Contract(lpStakingRewardsAbi as any, lpStakingRewardsContractAddr);
  const SkillToken = new web3.eth.Contract(erc20Abi as any, skillTokenContractAddr);
  const LPToken = new web3.eth.Contract(erc20Abi as any, lpTokenContractAddr);

  if (featureFlagStakeOnly) {
    return { SkillStakingRewards, LPStakingRewards, SkillToken, LPToken };
  }

  const cryptoBladesContractAddr = process.env.VUE_APP_CRYPTOBLADES_CONTRACT_ADDRESS || (cryptoBladesNetworks as any)[networkId].address;
  const raidContractAddr = process.env.VUE_APP_RAID_CONTRACT_ADDRESS || (raidNetworks as any)[networkId].address;

  const CryptoBlades = new web3.eth.Contract(cryptoBladesAbi as any, cryptoBladesContractAddr);
  const [charactersAddr, weaponsAddr] = await Promise.all([
    CryptoBlades.methods.getCharactersAddress().call(),
    CryptoBlades.methods.getWeaponsAddress().call(),
  ]);
  const Characters = new web3.eth.Contract(charactersAbi as any, charactersAddr);
  const Weapons = new web3.eth.Contract(weaponsAbi as any, weaponsAddr);
  const RaidBasic = new web3.eth.Contract(raidAbi as any, raidContractAddr);

  return { CryptoBlades, Characters, Weapons, SkillStakingRewards, LPStakingRewards, SkillToken, LPToken, RaidBasic };
}
