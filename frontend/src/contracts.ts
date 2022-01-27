import { abi as erc20Abi } from '../../build/contracts/IERC20.json';
import { abi as erc721Abi } from '../../build/contracts/IERC721.json';

import { networks as skillStakingRewardsNetworks } from '../../build/contracts/SkillStakingRewardsUpgradeable.json';
import { networks as skillStakingRewards90Networks } from '../../build/contracts/SkillStakingRewardsUpgradeable90.json';
import { networks as skillStakingRewards180Networks } from '../../build/contracts/SkillStakingRewardsUpgradeable180.json';
import { networks as lpStakingRewardsNetworks } from '../../build/contracts/LPStakingRewardsUpgradeable.json';
import { networks as lp2StakingRewardsNetworks } from '../../build/contracts/LP2StakingRewardsUpgradeable.json';
import { networks as skillTokenNetworks } from '../../build/contracts/SkillToken.json';
import { networks as lpTokenNetworks } from '../../build/contracts/ExperimentToken.json';
import { networks as lp2TokenNetworks } from '../../build/contracts/ExperimentToken2.json';
import { networks as cbkLandT1StakingRewardsNetworks } from '../../build/contracts/CBKLandT1StakingRewardsUpgradeable.json';
import { networks as cbkLandT2StakingRewardsNetworks } from '../../build/contracts/CBKLandT2StakingRewardsUpgradeable.json';
import { networks as cbkLandT3StakingRewardsNetworks } from '../../build/contracts/CBKLandT3StakingRewardsUpgradeable.json';
import { networks as cbkLandNetworks } from '../../build/contracts/CBKLand.json';
import { abi as stakingRewardsAbi } from '../../build/contracts/IStakingRewards.json';
import { abi as nftStakingRewardsAbi } from '../../build/contracts/INftStakingRewards.json';

import { abi as cryptoBladesAbi, networks as cryptoBladesNetworks } from '../../build/contracts/CryptoBlades.json';
import { abi as raidAbi, networks as raidNetworks } from '../../build/contracts/Raid1.json';
import { abi as charactersAbi } from '../../build/contracts/Characters.json';
import { abi as weaponsAbi } from '../../build/contracts/Weapons.json';
import { abi as blacksmithAbi } from '../../build/contracts/Blacksmith.json';
import { abi as shieldsAbi } from '../../build/contracts/Shields.json';
import { abi as garrisonAbi } from '../../build/contracts/Garrison.json';
import { abi as cbkLandSaleAbi } from '../../build/contracts/CBKLandSale.json';
import { abi as promosAbi } from '../../build/contracts/Promos.json';
import { abi as merchandiseAbi, networks as merchandiseNetworks } from '../../build/contracts/Merchandise.json';
import { abi as cbkLandAbi } from '../../build/contracts/CBKLand.json';
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
import { abi as pvpAbi, networks as pvpNetworks } from '../../build/contracts/PvpArena.json';
import { abi as weaponCosmeticsAbi } from '../../build/contracts/WeaponCosmetics.json';
import { abi as characterCosmeticsAbi } from '../../build/contracts/CharacterCosmetics.json';
import { abi as nftStorageAbi, networks as nftStorageNetworks } from '../../build/contracts/NFTStorage.json';
import { abi as treasuryAbi, networks as treasuryNetworks } from '../../build/contracts/Treasury.json';
import { abi as burningManagerAbi, networks as burningManagerNetworks } from '../../build/contracts/BurningManager.json';
import { abi as kingStakingRewardsUpgradeableAbi,
  networks as kingStakingRewardsUpgradeableNetworks }
  from '../../build/contracts/KingStakingRewardsUpgradeable.json';
import { abi as kingStakingRewardsUpgradeable90Abi,
  networks as kingStakingRewardsUpgradeable90Networks }
  from '../../build/contracts/KingStakingRewardsUpgradeable90.json';
import { abi as kingStakingRewardsUpgradeable180Abi,
  networks as kingStakingRewardsUpgradeable180Networks }
  from '../../build/contracts/KingStakingRewardsUpgradeable180.json';
import config from '../app-config.json';


import Web3 from 'web3';
import { Contracts, isStakeType, isNftStakeType, StakeType, NftStakeType, StakingContracts, NftStakingContracts } from './interfaces';

import { StakingContractEntry, stakingContractsInfo, nftStakingContractsInfo } from './stake-types';

import {
  raid as featureFlagRaid,
  stakeOnly as featureFlagStakeOnly,
  market as featureFlagMarket,
  pvp as featureFlagPvP,
  burningManager as featureFlagBurningManager
} from './feature-flags';
import {currentChainSupportsPvP} from '@/utils/common';

interface RaidContracts {
  Raid1?: Contracts['Raid1'];
}

interface PvPContracts {
  PvpArena?: Contracts['PvpArena'];
}

interface MarketContracts {
  NFTMarket?: Contracts['NFTMarket'];
}

interface Config {
  environments: Record<string, Chain>;
}

interface Chain {
  chains: Record<string, Record<string, any>>;
}

export function getConfigValue(key: string): any {
  if (process.env.VUE_APP_STAGE === 'alpha') {
    return process.env[key];
  }

  if(process.env.NODE_ENV === 'development') return '';
  const env = window.location.href.startsWith('https://test') ? 'test' : 'production';
  const chain = localStorage.getItem('currentChain') || 'BSC';
  return (config as Config).environments[env].chains[chain][key];
}

let networkId = getConfigValue('VUE_APP_NETWORK_ID') || '5777';

export type Networks = Partial<Record<string, { address: string }>>;

type Abi = any[];

const stakingContractAddressesFromBuild: Partial<Record<StakeType, Partial<StakingContractEntry>>> = {
  skill: {
    stakingRewardsAddress: (skillStakingRewardsNetworks as Networks)[networkId]?.address,
    stakingTokenAddress: (skillTokenNetworks as Networks)[networkId]?.address
  },
  skill90: {
    stakingRewardsAddress: (skillStakingRewards90Networks as Networks)[networkId]?.address,
    stakingTokenAddress: (skillTokenNetworks as Networks)[networkId]?.address
  },
  skill180: {
    stakingRewardsAddress: (skillStakingRewards180Networks as Networks)[networkId]?.address,
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

const nftStakingContractAddressesFromBuild: Partial<Record<NftStakeType, Partial<StakingContractEntry>>> = {
  cbkLandT1: {
    stakingRewardsAddress: (cbkLandT1StakingRewardsNetworks as Networks)[networkId]?.address,
    stakingTokenAddress: (cbkLandNetworks as Networks)[networkId]?.address
  },
  cbkLandT2: {
    stakingRewardsAddress: (cbkLandT2StakingRewardsNetworks as Networks)[networkId]?.address,
    stakingTokenAddress: (cbkLandNetworks as Networks)[networkId]?.address
  },
  cbkLandT3: {
    stakingRewardsAddress: (cbkLandT3StakingRewardsNetworks as Networks)[networkId]?.address,
    stakingTokenAddress: (cbkLandNetworks as Networks)[networkId]?.address
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

function getNftStakingContractsInfoWithDefaults(): Partial<Record<NftStakeType, Partial<StakingContractEntry>>> {
  const out: Partial<Record<NftStakeType, Partial<StakingContractEntry>>> = {};

  for(const nftStakeType of Object.keys(nftStakingContractsInfo).filter(isNftStakeType)) {
    const nftStakingContractInfo = nftStakingContractsInfo[nftStakeType]!;
    if(nftStakingContractInfo.stakingRewardsAddress && nftStakingContractInfo.stakingTokenAddress) {
      out[nftStakeType] = {
        stakingRewardsAddress: nftStakingContractInfo.stakingRewardsAddress,
        stakingTokenAddress: nftStakingContractInfo.stakingTokenAddress
      };
    }
    else {
      out[nftStakeType] = Object.assign({}, nftStakingContractInfo, nftStakingContractAddressesFromBuild[nftStakeType]);
    }
  }

  return out;
}

async function setUpStakingContracts(web3: Web3) {
  networkId = getConfigValue('VUE_APP_NETWORK_ID') || '5777';
  const stakingContractsInfo = getStakingContractsInfoWithDefaults();
  const nftStakingContractsInfo = getNftStakingContractsInfoWithDefaults();

  const staking: StakingContracts = {};
  const nftStaking: NftStakingContracts = {};

  for(const stakeType of Object.keys(stakingContractsInfo).filter(isStakeType)) {
    const stakingContractInfo = stakingContractsInfo[stakeType]!;

    if(!stakingContractInfo.stakingRewardsAddress || !stakingContractInfo.stakingTokenAddress) continue;
    staking[stakeType] = {
      StakingRewards: new web3.eth.Contract(stakingRewardsAbi as Abi, stakingContractInfo.stakingRewardsAddress),
      StakingToken: new web3.eth.Contract(erc20Abi as Abi, stakingContractInfo.stakingTokenAddress)
    };
  }

  for(const stakeType of Object.keys(nftStakingContractsInfo).filter(isNftStakeType)) {
    const nftStakingContractInfo = nftStakingContractsInfo[stakeType]!;

    if(!nftStakingContractInfo.stakingRewardsAddress || !nftStakingContractInfo.stakingTokenAddress) continue;
    nftStaking[stakeType] = {
      StakingRewards: new web3.eth.Contract(nftStakingRewardsAbi as Abi, nftStakingContractInfo.stakingRewardsAddress),
      StakingToken: new web3.eth.Contract(erc721Abi as Abi, nftStakingContractInfo.stakingTokenAddress)
    };
  }

  const skillTokenAddress = getConfigValue('VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS') || (skillTokenNetworks as Networks)[networkId]!.address;
  const SkillToken = new web3.eth.Contract(erc20Abi as Abi, skillTokenAddress);

  return {
    SkillToken,

    staking,
    nftStaking
  };
}

export async function setUpContracts(web3: Web3): Promise<Contracts> {

  const stakingContracts = await setUpStakingContracts(web3);

  if (featureFlagStakeOnly) {
    return stakingContracts;
  }

  const cryptoBladesContractAddr = getConfigValue('VUE_APP_CRYPTOBLADES_CONTRACT_ADDRESS') || (cryptoBladesNetworks as Networks)[networkId]!.address;
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

  const garrisonAddr = await Characters.methods.garrison().call();
  const Garrison = new web3.eth.Contract(garrisonAbi as Abi, garrisonAddr);

  const shieldsAddr = await Blacksmith.methods.shields().call();
  const Shields = new web3.eth.Contract(shieldsAbi as Abi, shieldsAddr);

  const promosAddr = await Characters.methods.promos().call();
  const Promos = new web3.eth.Contract(promosAbi as Abi, promosAddr);

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

  const cosmeticsWeaponIndex = await Blacksmith.methods.ITEM_COSMETIC_WEAPON().call();
  const cosmeticsWeaponAddr = await Blacksmith.methods.getAddressOfItem(cosmeticsWeaponIndex).call();
  const WeaponCosmetics = new web3.eth.Contract(weaponCosmeticsAbi as Abi, cosmeticsWeaponAddr);

  const cosmeticsCharacterIndex = await Blacksmith.methods.ITEM_COSMETIC_CHARACTER().call();
  const cosmeticsCharacterAddr = await Blacksmith.methods.getAddressOfItem(cosmeticsCharacterIndex).call();
  const CharacterCosmetics = new web3.eth.Contract(characterCosmeticsAbi as Abi, cosmeticsCharacterAddr);

  const NFTStorageAddr = getConfigValue('VUE_APP_STORAGE_CONTRACT_ADDRESS') || (nftStorageNetworks as Networks)[networkId]!.address;
  const NFTStorage = new web3.eth.Contract(nftStorageAbi as Abi, NFTStorageAddr);

  const cbkLandSaleAddr = await Blacksmith.methods.cbkLandSale().call();
  const CBKLandSale = new web3.eth.Contract(cbkLandSaleAbi as Abi, cbkLandSaleAddr);

  const merchandiseAddr = getConfigValue('VUE_APP_MERCHANDISE_CONTRACT_ADDRESS') || (merchandiseNetworks as Networks)[networkId]!.address;
  const Merchandise = new web3.eth.Contract(merchandiseAbi as Abi, merchandiseAddr);

  const cbkLandAddr = await CBKLandSale.methods.cbkLand().call();
  const CBKLand = new web3.eth.Contract(cbkLandAbi as Abi, cbkLandAddr);

  const raidContracts: RaidContracts = {};
  let raidTrinketAddress = '';
  let keyboxAddress = '';
  let junkAddress = '';
  if(featureFlagRaid) {
    const raidContractAddr = getConfigValue('VUE_APP_RAID_CONTRACT_ADDRESS') || (raidNetworks as Networks)[networkId]!.address;

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
    const marketContractAddr = getConfigValue('VUE_APP_MARKET_CONTRACT_ADDRESS') || (marketNetworks as Networks)[networkId]!.address;

    marketContracts.NFTMarket = new web3.eth.Contract(marketAbi as Abi, marketContractAddr);
  }

  const pvpContracts: PvPContracts = {};
  if(featureFlagPvP && currentChainSupportsPvP()){
    const pvpContractAddr = process.env.VUE_APP_PVP_CONTRACT_ADDRESS ||
    getConfigValue('VUE_APP_PVP_CONTRACT_ADDRESS') || (pvpNetworks as Networks)[networkId]!.address;

    pvpContracts.PvpArena = new web3.eth.Contract(pvpAbi as Abi, pvpContractAddr);
  }

  const waxBridgeContractAddr = getConfigValue('VUE_APP_WAX_BRIDGE_CONTRACT_ADDRESS') || (waxBridgeNetworks as Networks)[networkId]!.address;
  const WaxBridge = new web3.eth.Contract(waxBridgeAbi as Abi, waxBridgeContractAddr);

  const treasuryContractAddr = getConfigValue('VUE_APP_TREASURY_CONTRACT_ADDRESS') || (treasuryNetworks as Networks)[networkId]!.address;
  const Treasury = new web3.eth.Contract(treasuryAbi as Abi, treasuryContractAddr);

  let BurningManager;
  if(featureFlagBurningManager) {
    const burningManagerContractAddr = getConfigValue('VUE_APP_BURNING_MANAGER_CONTRACT_ADDRESS') || (burningManagerNetworks as Networks)[networkId]!.address;
    BurningManager = new web3.eth.Contract(burningManagerAbi as Abi, burningManagerContractAddr);
  }

  let KingStakingRewardsUpgradeable;
  if(stakingContracts.staking.king) {
    const kingStakingRewardsUpgradeableAddress = getConfigValue('VUE_APP_KING_STAKING_REWARDS_CONTRACT_ADDRESS')
      || (kingStakingRewardsUpgradeableNetworks as Networks)[networkId]!.address;
    KingStakingRewardsUpgradeable = new web3.eth.Contract(kingStakingRewardsUpgradeableAbi as Abi, kingStakingRewardsUpgradeableAddress);
  }

  let KingStakingRewardsUpgradeable90;
  if(stakingContracts.staking.king) {
    const kingStakingRewardsUpgradeable90Address = getConfigValue('VUE_APP_KING_STAKING_REWARDS_90_CONTRACT_ADDRESS')
      || (kingStakingRewardsUpgradeable90Networks as Networks)[networkId]!.address;
    KingStakingRewardsUpgradeable90 = new web3.eth.Contract(kingStakingRewardsUpgradeable90Abi as Abi, kingStakingRewardsUpgradeable90Address);
  }

  let KingStakingRewardsUpgradeable180;
  if(stakingContracts.staking.king) {
    const kingStakingRewardsUpgradeable180Address = getConfigValue('VUE_APP_KING_STAKING_REWARDS_180_CONTRACT_ADDRESS')
      || (kingStakingRewardsUpgradeable180Networks as Networks)[networkId]!.address;
    KingStakingRewardsUpgradeable180 = new web3.eth.Contract(kingStakingRewardsUpgradeable180Abi as Abi, kingStakingRewardsUpgradeable180Address);
  }

  return {
    ...stakingContracts,
    CryptoBlades, Randoms, Characters, Weapons, Blacksmith, Shields, Garrison, WeaponRenameTagConsumables, CharacterRenameTagConsumables,
    CharacterFireTraitChangeConsumables, CharacterEarthTraitChangeConsumables, CharacterWaterTraitChangeConsumables, CharacterLightningTraitChangeConsumables,
    RaidTrinket, KeyLootbox, Junk,
    WeaponCosmetics, CharacterCosmetics,
    NFTStorage, CBKLandSale, CBKLand, Merchandise, Promos,
    ...raidContracts,
    ...pvpContracts,
    ...marketContracts,
    WaxBridge,
    Treasury,
    BurningManager,
    KingStakingRewardsUpgradeable,
    KingStakingRewardsUpgradeable90,
    KingStakingRewardsUpgradeable180
  };
}

export const INTERFACE_ID_TRANSFER_COOLDOWNABLE = '0xe62e6974';
