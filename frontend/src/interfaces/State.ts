import { ICharacter } from './Character';
import { IWeapon } from './Weapon';
import { ITarget } from './Target';
import { Contracts } from './Contracts';
import { Nft } from './Nft';
import { IShield } from './Shield';
import Web3 from 'web3';
export type StakeType = 'skill' | 'skill2' | 'lp' | 'lp2' | 'king' | 'skill90' | 'skill180' | 'king90' | 'king180';
export const allStakeTypes: StakeType[] = ['skill', 'skill2', 'lp', 'lp2', 'king', 'skill90', 'skill180', 'king90', 'king180'];
export type NftStakeType = 'cbkLandT1' | 'cbkLandT2' | 'cbkLandT3';
export const allNftStakeTypes: NftStakeType[] = ['cbkLandT1', 'cbkLandT2', 'cbkLandT3'];


export function isStakeType(stakeType: string): stakeType is StakeType {
  return allStakeTypes.includes(stakeType as StakeType);
}

export function isNftStakeType(stakeType: string): stakeType is NftStakeType {
  return allNftStakeTypes.includes(stakeType as NftStakeType);
}

export interface IWeb3EventSubscription {
  unsubscribe(): void;
}

export interface IStakeState {
  ownBalance: string;
  stakedBalance: string;
  remainingCapacityForDeposit: string | null;
  remainingCapacityForWithdraw: string;
  contractBalance: string;
  currentRewardEarned: string;
  rewardMinimumStakeTime: number;
  rewardDistributionTimeLeft: number;
  unlockTimeLeft: number;
}

export interface IStakeOverviewState {
  rewardRate: string;
  rewardsDuration: number;
  totalSupply: string;
  minimumStakeTime: number;
  rewardDistributionTimeLeft: number;
}

export interface IRaidState {
  index: string;
  expectedFinishTime: string;
  raiderCount: string;
  playerPower: string;
  bossPower: string;
  bossTrait: string;
  status: string;
  joinSkill: string;
  staminaCost: string;
  durabilityCost: string;
  xpReward: string;
  accountPower: string;
}
export interface IPartnerProject {
  id: string;
  name: string;
  tokenSymbol: string;
  tokenAddress: string;
  tokenSupply: string;
  tokensClaimed: string;
  tokenPrice: string;
  isActive: boolean;
}
export interface IState {
  web3: Web3;
  contracts: () => Contracts;
  eventSubscriptions: () => IWeb3EventSubscription[];
  accounts: string[];
  defaultAccount: string | null;
  currentNetworkId: number | null;
  skillPriceInUsd: number;

  fightGasOffset: string;
  fightBaseline: string;

  skillBalance: string;
  skillRewards: string;
  maxRewardsClaimTax: string;
  rewardsClaimTax: string;
  xpRewards: Record<string, string>;
  inGameOnlyFunds: string;
  directStakeBonusPercent: number;
  ownedCharacterIds: number[];
  ownedGarrisonCharacterIds: number[];
  ownedWeaponIds: number[];
  ownedShieldIds: number[];
  ownedTrinketIds: number[];
  ownedJunkIds: number[];
  ownedKeyLootboxIds: number[];
  maxStamina: number;
  ownedDust: string[];
  currentChainSupportsPvP: boolean;
  currentChainSupportsQuests: boolean;
  hasAdminAccess: boolean;
  hasMinterAccess: boolean;

  currentCharacterId: number | null;
  characters: Record<number, ICharacter>;
  garrisonCharacters: Record<number, ICharacter>;
  characterStaminas: Record<number, number>;
  characterPowers: Record<number, number>;
  characterIsInArena: Record<number, boolean>;
  characterRenames: Record<number, string>;
  characterCosmetics: Record<number, string>;

  currentWeaponId: number | null;
  weapons: Record<number, IWeapon>;
  weaponDurabilities: Record<number, number>;
  weaponRenames: Record<number, string>;
  weaponCosmetics: Record<number, string>;
  maxDurability: number;
  targetsByCharacterIdAndWeaponId: Record<number, Record<number, ITarget>>;

  currentNftType: string | null;
  currentNftId: number | null;

  waxBridgeWithdrawableBnb: string;
  waxBridgeRemainingWithdrawableBnbDuringPeriod: string;
  waxBridgeTimeUntilLimitExpires: number;

  isInCombat: boolean;
  isCharacterViewExpanded: boolean;

  shields: Record<number, IShield>;
  currentShieldId: number | null;
  trinkets: Record<number, Nft>;
  junk: Record<number, Nft>;
  keyboxes: Record<number, Nft>;

  nfts: Record<string, Record<number | string, Nft>>;

  partnerProjects: Record<number, IPartnerProject>;
  partnerProjectMultipliers: Record<number, string>;
  partnerProjectRatios: Record<number, string>;
  payoutCurrencyId: string;
  defaultSlippage: string;
}
