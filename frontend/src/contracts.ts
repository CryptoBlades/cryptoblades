import { abi as erc20Abi } from '../../build/contracts/IERC20.json';

import { networks as skillStakingRewardsNetworks } from '../../build/contracts/SkillStakingRewardsUpgradeable.json';
import { networks as lpStakingRewardsNetworks } from '../../build/contracts/LPStakingRewardsUpgradeable.json';
import { networks as lp2StakingRewardsNetworks } from '../../build/contracts/LP2StakingRewardsUpgradeable.json';
import { networks as skillTokenNetworks } from '../../build/contracts/SkillToken.json';
import { networks as lpTokenNetworks } from '../../build/contracts/ExperimentToken.json';
import { networks as lp2TokenNetworks } from '../../build/contracts/ExperimentToken2.json';
import { abi as stakingRewardsAbi } from '../../build/contracts/IStakingRewards.json';

import { abi as cryptoBladesAbi, networks as cryptoBladesNetworks } from '../../build/contracts/CryptoBlades.json';
import { abi as raidAbi, networks as raidNetworks } from '../../build/contracts/RaidBasic.json';
import { abi as charactersAbi } from '../../build/contracts/Characters.json';
import { abi as weaponsAbi } from '../../build/contracts/Weapons.json';
import { abi as randomsAbi } from '../../build/contracts/IRandoms.json';
import { abi as marketAbi, networks as marketNetworks } from '../../build/contracts/NFTMarket.json';

import Web3 from 'web3';
import { allStakeTypes, Contracts, isStakeType } from './interfaces';

import { raid as featureFlagRaid, stakeOnly as featureFlagStakeOnly, market as featureFlagMarket } from './feature-flags';

interface RaidContracts {
  RaidBasic?: Contracts['RaidBasic'];
}

interface MarketContracts {
  NFTMarket?: Contracts['NFTMarket'];
}

async function setUpStakingContracts(web3: Web3, networkId: string) {
  let availableStakingContracts = allStakeTypes;

  if(process.env.VUE_APP_STAKE_TYPES_AVAILABLE) {
    availableStakingContracts = process.env.VUE_APP_STAKE_TYPES_AVAILABLE
      .split(',')
      .filter(isStakeType);
  }

  const skillStakingRewardsContractAddr = process.env.VUE_APP_SKILL_STAKING_REWARDS_CONTRACT_ADDRESS || (skillStakingRewardsNetworks as any)[networkId].address;
  const lpStakingRewardsContractAddr = process.env.VUE_APP_LP_STAKING_REWARDS_CONTRACT_ADDRESS || (lpStakingRewardsNetworks as any)[networkId]?.address;
  const lp2StakingRewardsContractAddr = process.env.VUE_APP_LP_2_STAKING_REWARDS_CONTRACT_ADDRESS || (lp2StakingRewardsNetworks as any)[networkId]?.address;

  const skillTokenContractAddr = process.env.VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS || (skillTokenNetworks as any)[networkId].address;
  const lpTokenContractAddr = process.env.VUE_APP_LP_TOKEN_CONTRACT_ADDRESS || (lpTokenNetworks as any)[networkId]?.address;
  const lp2TokenContractAddr = process.env.VUE_APP_LP_2_TOKEN_CONTRACT_ADDRESS || (lp2TokenNetworks as any)[networkId]?.address;

  const SkillStakingRewards = new web3.eth.Contract(stakingRewardsAbi as any, skillStakingRewardsContractAddr);
  const SkillToken = new web3.eth.Contract(erc20Abi as any, skillTokenContractAddr);

  let LPStakingRewards = null;
  let LPToken = null;
  if(availableStakingContracts.includes('lp') && lpStakingRewardsContractAddr) {
    LPStakingRewards = new web3.eth.Contract(stakingRewardsAbi as any, lpStakingRewardsContractAddr);
    LPToken = new web3.eth.Contract(erc20Abi as any, lpTokenContractAddr);
  }

  let LP2StakingRewards = null;
  let LP2Token = null;
  if(availableStakingContracts.includes('lp2') && lp2StakingRewardsContractAddr) {
    LP2StakingRewards = new web3.eth.Contract(stakingRewardsAbi as any, lp2StakingRewardsContractAddr);
    LP2Token = new web3.eth.Contract(erc20Abi as any, lp2TokenContractAddr);
  }

  return { SkillStakingRewards, LPStakingRewards, LP2StakingRewards, SkillToken, LPToken, LP2Token };
}

export async function setUpContracts(web3: Web3): Promise<Contracts> {
  const networkId = process.env.VUE_APP_NETWORK_ID || '5777';

  const stakingContracts = await setUpStakingContracts(web3, networkId);

  if (featureFlagStakeOnly) {
    return stakingContracts;
  }

  const cryptoBladesContractAddr = process.env.VUE_APP_CRYPTOBLADES_CONTRACT_ADDRESS || (cryptoBladesNetworks as any)[networkId].address;

  const CryptoBlades = new web3.eth.Contract(cryptoBladesAbi as any, cryptoBladesContractAddr);
  const [charactersAddr, weaponsAddr, randomsAddr] = await Promise.all([
    CryptoBlades.methods.characters().call(),
    CryptoBlades.methods.weapons().call(),
    CryptoBlades.methods.randoms().call(),
  ]);
  const Randoms = new web3.eth.Contract(randomsAbi as any, randomsAddr);
  const Characters = new web3.eth.Contract(charactersAbi as any, charactersAddr);
  const Weapons = new web3.eth.Contract(weaponsAbi as any, weaponsAddr);

  const raidContracts: RaidContracts = {};
  if(featureFlagRaid) {
    const raidContractAddr = process.env.VUE_APP_RAID_CONTRACT_ADDRESS || (raidNetworks as any)[networkId].address;

    raidContracts.RaidBasic = new web3.eth.Contract(raidAbi as any, raidContractAddr);
  }

  const marketContracts: MarketContracts = {};
  if(featureFlagMarket) {
    const marketContractAddr = process.env.VUE_APP_MARKET_CONTRACT_ADDRESS || (marketNetworks as any)[networkId].address;

    marketContracts.NFTMarket = new web3.eth.Contract(marketAbi as any, marketContractAddr);
  }

  return {
    ...stakingContracts,
    CryptoBlades, Randoms, Characters, Weapons,
    ...raidContracts,
    ...marketContracts
  };
}

export const INTERFACE_ID_TRANSFER_COOLDOWNABLE = '0xe62e6974';
