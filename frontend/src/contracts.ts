import { abi as erc20Abi } from '../../build/contracts/IERC20.json';

import { networks as skillStakingRewardsNetworks } from '../../build/contracts/SkillStakingRewardsUpgradeable.json';
import { networks as lpStakingRewardsNetworks } from '../../build/contracts/LPStakingRewardsUpgradeable.json';
import { networks as lp2StakingRewardsNetworks } from '../../build/contracts/LP2StakingRewardsUpgradeable.json';
import { networks as skillTokenNetworks } from '../../build/contracts/SkillToken.json';
import { networks as lpTokenNetworks } from '../../build/contracts/ExperimentToken.json';
import { networks as lp2TokenNetworks } from '../../build/contracts/ExperimentToken2.json';
import { abi as stakingRewardsAbi } from '../../build/contracts/IStakingRewards.json';

import { abi as cryptoBladesAbi, networks as cryptoBladesNetworks } from '../../build/contracts/CryptoBlades.json';
import { abi as raidAbi, networks as raidNetworks } from '../../build/contracts/Raid1.json';
import { abi as charactersAbi } from '../../build/contracts/Characters.json';
import { abi as weaponsAbi } from '../../build/contracts/Weapons.json';
import { abi as blacksmithAbi } from '../../build/contracts/Blacksmith.json';
import { abi as shieldsAbi } from '../../build/contracts/Shields.json';
import { abi as weaponRenameTagConsumablesAbi } from '../../build/contracts/WeaponRenameTagConsumables.json';
import { abi as characterRenameTagConsumablesAbi } from '../../build/contracts/CharacterRenameTagConsumables.json';
import { abi as characterFireTraitChangeConsumablesAbi } from '../../build/contracts/CharacterFireTraitChangeConsumables.json';
import { abi as characterEarthTraitChangeConsumablesAbi } from '../../build/contracts/CharacterEarthTraitChangeConsumables.json';
import { abi as characterWaterTraitChangeConsumablesAbi } from '../../build/contracts/CharacterWaterTraitChangeConsumables.json';
import { abi as characterLightningTraitChangeConsumablesAbi } from '../../build/contracts/CharacterLightningTraitChangeConsumables.json';
import { abi as raidTrinketAbi } from '../../build/contracts/RaidTrinket.json';
import { abi as keyboxAbi } from '../../build/contracts/KeyLootbox.json';
import { abi as junkAbi } from '../../build/contracts/Junk.json';
import { abi as randomsAbi } from '../../build/contracts/IRandoms.json';
import { abi as marketAbi, networks as marketNetworks } from '../../build/contracts/NFTMarket.json';
import { abi as waxBridgeAbi, networks as waxBridgeNetworks } from '../../build/contracts/WaxBridge.json';

import Web3 from 'web3';
import { Contracts, isStakeType, StakeType, StakingContracts } from './interfaces';

import { StakingContractEntry, stakingContractsInfo } from './stake-types';

import {
  raid as featureFlagRaid,
  stakeOnly as featureFlagStakeOnly,
  market as featureFlagMarket,
} from './feature-flags';

interface RaidContracts {
  Raid1?: Contracts['Raid1'];
}

interface MarketContracts {
  NFTMarket?: Contracts['NFTMarket'];
}

const networkId = process.env.VUE_APP_NETWORK_ID || '5777';

type Networks = Partial<Record<string, { address: string }>>;

type Abi = any[];

const stakingContractAddressesFromBuild: Partial<Record<StakeType, Partial<StakingContractEntry>>> = {
  skill: {
    stakingRewardsAddress: (skillStakingRewardsNetworks as Networks)[networkId]?.address,
    stakingTokenAddress: (skillTokenNetworks as Networks)[networkId]?.address
  },
  lp: {
    stakingRewardsAddress: (lpStakingRewardsNetworks as Networks)[networkId]?.address,
    stakingTokenAddress: (lpTokenNetworks as Networks)[networkId]?.address
  },
  lp2: {
    stakingRewardsAddress: (lp2StakingRewardsNetworks as Networks)[networkId]?.address,
    stakingTokenAddress: (lp2TokenNetworks as Networks)[networkId]?.address
  }
};

function getStakingContractsInfoWithDefaults(): Partial<Record<StakeType, Partial<StakingContractEntry>>> {
  const out: Partial<Record<StakeType, Partial<StakingContractEntry>>> = {};

  for(const stakeType of Object.keys(stakingContractsInfo).filter(isStakeType)) {
    const stakingContractInfo = stakingContractsInfo[stakeType]!;
    if(stakingContractInfo.stakingRewardsAddress && stakingContractInfo.stakingTokenAddress) {
      out[stakeType] = {
        stakingRewardsAddress: stakingContractInfo.stakingRewardsAddress,
        stakingTokenAddress: stakingContractInfo.stakingTokenAddress
      };
    }
    else {
      out[stakeType] = Object.assign({}, stakingContractInfo, stakingContractAddressesFromBuild[stakeType]);
    }
  }

  return out;
}

async function setUpStakingContracts(web3: Web3) {
  const stakingContractsInfo = getStakingContractsInfoWithDefaults();

  const staking: StakingContracts = {};

  for(const stakeType of Object.keys(stakingContractsInfo).filter(isStakeType)) {
    const stakingContractInfo = stakingContractsInfo[stakeType]!;

    if(!stakingContractInfo.stakingRewardsAddress || !stakingContractInfo.stakingTokenAddress) continue;

    staking[stakeType] = {
      StakingRewards: new web3.eth.Contract(stakingRewardsAbi as Abi, stakingContractInfo.stakingRewardsAddress),
      StakingToken: new web3.eth.Contract(erc20Abi as Abi, stakingContractInfo.stakingTokenAddress)
    };
  }

  const skillTokenAddress = process.env.VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS || (skillTokenNetworks as Networks)[networkId]!.address;
  const SkillToken = new web3.eth.Contract(erc20Abi as Abi, skillTokenAddress);

  return {
    SkillToken,

    staking
  };
}

export async function setUpContracts(web3: Web3): Promise<Contracts> {
  const stakingContracts = await setUpStakingContracts(web3);

  if (featureFlagStakeOnly) {
    return stakingContracts;
  }

  const cryptoBladesContractAddr = process.env.VUE_APP_CRYPTOBLADES_CONTRACT_ADDRESS || (cryptoBladesNetworks as Networks)[networkId]!.address;

  const CryptoBlades = new web3.eth.Contract(cryptoBladesAbi as Abi, cryptoBladesContractAddr);
  const [charactersAddr, weaponsAddr, randomsAddr, blacksmithAddr] = await Promise.all([
    CryptoBlades.methods.characters().call(),
    CryptoBlades.methods.weapons().call(),
    CryptoBlades.methods.randoms().call(),
    CryptoBlades.methods.blacksmith().call(),
  ]);
  const Randoms = new web3.eth.Contract(randomsAbi as Abi, randomsAddr);
  const Characters = new web3.eth.Contract(charactersAbi as Abi, charactersAddr);
  const Weapons = new web3.eth.Contract(weaponsAbi as Abi, weaponsAddr);
  const Blacksmith = new web3.eth.Contract(blacksmithAbi as Abi, blacksmithAddr);

  const shieldsAddr = await Blacksmith.methods.shields().call();
  const Shields = new web3.eth.Contract(shieldsAbi as Abi, shieldsAddr);

  const weaponRenameTagConsumablesIndex = await Blacksmith.methods.ITEM_WEAPON_RENAME().call();
  const weaponRenameTagConsumablesAddr = await Blacksmith.methods.getAddressOfItem(weaponRenameTagConsumablesIndex).call();
  const WeaponRenameTagConsumables = new web3.eth.Contract(weaponRenameTagConsumablesAbi as Abi, weaponRenameTagConsumablesAddr);

  const characterRenameTagConsumablesIndex = await Blacksmith.methods.ITEM_CHARACTER_RENAME().call();
  const characterRenameTagConsumablesAddr = await Blacksmith.methods.getAddressOfItem(characterRenameTagConsumablesIndex).call();
  const CharacterRenameTagConsumables = new web3.eth.Contract(characterRenameTagConsumablesAbi as Abi, characterRenameTagConsumablesAddr);

  const CharacterFireTraitChangeConsumablesIndex = await Blacksmith.methods.ITEM_CHARACTER_TRAITCHANGE_FIRE().call();
  const characterFireTraitChangeConsumablesAddr = await Blacksmith.methods.getAddressOfItem(CharacterFireTraitChangeConsumablesIndex).call();
  const CharacterFireTraitChangeConsumables = new web3.eth.Contract(characterFireTraitChangeConsumablesAbi as Abi, characterFireTraitChangeConsumablesAddr);

  const CharacterEarthTraitChangeConsumablesIndex = await Blacksmith.methods.ITEM_CHARACTER_TRAITCHANGE_EARTH().call();
  const characterEarthTraitChangeConsumablesAddr = await Blacksmith.methods.getAddressOfItem(CharacterEarthTraitChangeConsumablesIndex).call();
  const CharacterEarthTraitChangeConsumables = new web3.eth.Contract(characterEarthTraitChangeConsumablesAbi as Abi, characterEarthTraitChangeConsumablesAddr);

  const CharacterWaterTraitChangeConsumablesIndex = await Blacksmith.methods.ITEM_CHARACTER_TRAITCHANGE_WATER().call();
  const characterWaterTraitChangeConsumablesAddr = await Blacksmith.methods.getAddressOfItem(CharacterWaterTraitChangeConsumablesIndex).call();
  const CharacterWaterTraitChangeConsumables = new web3.eth.Contract(characterWaterTraitChangeConsumablesAbi as Abi, characterWaterTraitChangeConsumablesAddr);

  const CharacterLightningTraitChangeConsumablesIndex = await Blacksmith.methods.ITEM_CHARACTER_TRAITCHANGE_LIGHTNING().call();
  const characterLightningTraitChangeConsumablesAddr = await Blacksmith.methods.getAddressOfItem(CharacterLightningTraitChangeConsumablesIndex).call();
  const CharacterLightningTraitChangeConsumables = new web3.eth.Contract(characterLightningTraitChangeConsumablesAbi as Abi,
    characterLightningTraitChangeConsumablesAddr);



  const raidContracts: RaidContracts = {};
  let raidTrinketAddress = '';
  let keyboxAddress = '';
  let junkAddress = '';
  if(featureFlagRaid) {
    const raidContractAddr = process.env.VUE_APP_RAID_CONTRACT_ADDRESS || (raidNetworks as Networks)[networkId]!.address;

    const Raid1 = new web3.eth.Contract(raidAbi as Abi, raidContractAddr);
    raidContracts.Raid1 = Raid1;

    // for the time being, junk, keylootbox and trinket are dependent on raids for the address
    const RAID_LINK_TRINKET = await Raid1.methods.LINK_TRINKET().call();
    const RAID_LINK_KEYBOX = await Raid1.methods.LINK_KEYBOX().call();
    const RAID_LINK_JUNK = await Raid1.methods.LINK_JUNK().call();
    raidTrinketAddress = await Raid1.methods.getLinkAddress(RAID_LINK_TRINKET).call();
    keyboxAddress = await Raid1.methods.getLinkAddress(RAID_LINK_KEYBOX).call();
    junkAddress = await Raid1.methods.getLinkAddress(RAID_LINK_JUNK).call();
  }

  const RaidTrinket = new web3.eth.Contract(raidTrinketAbi as Abi, raidTrinketAddress);
  const KeyLootbox = new web3.eth.Contract(keyboxAbi as Abi, keyboxAddress);
  const Junk = new web3.eth.Contract(junkAbi as Abi, junkAddress);

  const marketContracts: MarketContracts = {};
  if(featureFlagMarket) {
    const marketContractAddr = process.env.VUE_APP_MARKET_CONTRACT_ADDRESS || (marketNetworks as Networks)[networkId]!.address;

    marketContracts.NFTMarket = new web3.eth.Contract(marketAbi as Abi, marketContractAddr);
  }

  const waxBridgeContractAddr = process.env.VUE_APP_WAX_BRIDGE_CONTRACT_ADDRESS || (waxBridgeNetworks as Networks)[networkId]!.address;
  const WaxBridge = new web3.eth.Contract(waxBridgeAbi as Abi, waxBridgeContractAddr);

  return {
    ...stakingContracts,
    CryptoBlades, Randoms, Characters, Weapons, Blacksmith, Shields, WeaponRenameTagConsumables, CharacterRenameTagConsumables,
    CharacterFireTraitChangeConsumables, CharacterEarthTraitChangeConsumables, CharacterWaterTraitChangeConsumables, CharacterLightningTraitChangeConsumables,
    RaidTrinket, KeyLootbox, Junk,
    ...raidContracts,
    ...marketContracts,
    WaxBridge,
  };
}

export const INTERFACE_ID_TRANSFER_COOLDOWNABLE = '0xe62e6974';