import { abi as cryptoBladesAbi, networks as cryptoBladesNetworks } from '../../build/contracts/CryptoBlades.json';
import { abi as stakingRewardsAbi, networks as stakingRewardsNetworks } from '../../build/contracts/StakingRewards.json';
import { abi as skillTokenAbi, networks as skillTokenNetworks } from '../../build/contracts/SkillToken.json';

import { abi as charactersAbi } from '../../build/contracts/Characters.json';
import { abi as weaponsAbi } from '../../build/contracts/Weapons.json';

import Web3 from 'web3';
import { Contract as Web3EthContract } from 'web3-eth-contract';

export interface Contracts {
  SkillToken: Web3EthContract;
  StakingRewards: Web3EthContract;
  CryptoBlades?: Web3EthContract;
  Characters?: Web3EthContract;
  Weapons?: Web3EthContract;
}

export async function setUpContracts(web3: Web3, featureFlagStakeOnly: boolean): Promise<Contracts> {
  const networkId = process.env.VUE_APP_NETWORK_ID || '5777';
  const cryptoBladesContractAddr = process.env.VUE_APP_CRYPTOBLADES_CONTRACT_ADDRESS || (cryptoBladesNetworks as any)[networkId].address;
  const stakingRewardsContractAddr = process.env.VUE_APP_STAKING_REWARDS_CONTRACT_ADDRESS || (stakingRewardsNetworks as any)[networkId].address;
  const skillTokenContractAddr = process.env.VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS || (skillTokenNetworks as any)[networkId].address;

  const StakingRewards = new web3.eth.Contract(stakingRewardsAbi as any, stakingRewardsContractAddr);
  const SkillToken = new web3.eth.Contract(skillTokenAbi as any, skillTokenContractAddr);

  if (featureFlagStakeOnly) {
    return { StakingRewards, SkillToken };
  }

  const CryptoBlades = new web3.eth.Contract(cryptoBladesAbi as any, cryptoBladesContractAddr);
  const [charactersAddr, weaponsAddr] = await Promise.all([
    CryptoBlades.methods.getCharactersAddress().call(),
    CryptoBlades.methods.getWeaponsAddress().call(),
  ]);
  const Characters = new web3.eth.Contract(charactersAbi as any, charactersAddr);
  const Weapons = new web3.eth.Contract(weaponsAbi as any, weaponsAddr);

  return { CryptoBlades, Characters, Weapons, StakingRewards, SkillToken };
}
