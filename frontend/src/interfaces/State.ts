import { ICharacter } from './Character';
import { IWeapon } from './Weapon';
import { ITarget } from './Target';
import { Contracts } from './Contracts';
import { Nft } from './Nft';
import { IShield } from './Shield';

export type StakeType = 'skill' | 'skill2' | 'lp' | 'lp2' | 'king';
export const allStakeTypes: StakeType[] = ['skill', 'skill2', 'lp', 'lp2', 'king'];

export function isStakeType(stakeType: string): stakeType is StakeType {
  return allStakeTypes.includes(stakeType as StakeType);
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

  //isOwnedCharacterRaidingById: Record<number, boolean>; // ?
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

export interface IItemPrices {
  itemWeaponRenamePrice: string;
  itemCharacterRenamePrice: string;
  itemCharacterTraitChangeFirePrice: string;
  itemCharacterTraitChangeEarthPrice: string;
  itemCharacterTraitChangeWaterPrice: string;
  itemCharacterTraitChangeLightningPrice: string;
  itemWeaponCosmeticGrayscalePrice: string;
  itemWeaponCosmeticContrastPrice: string;
  itemWeaponCosmeticSepiaPrice: string;
  itemWeaponCosmeticInvertPrice: string;
  itemWeaponCosmeticBlurPrice: string;
  itemWeaponCosmeticFireGlowPrice: string;
  itemWeaponCosmeticEarthGlowPrice: string;
  itemWeaponCosmeticLightningGlowPrice: string;
  itemWeaponCosmeticWaterGlowPrice: string;
  itemWeaponCosmeticRainbowGlowPrice: string;
  itemWeaponCosmeticDarkGlowPrice: string;
  itemWeaponCosmeticGhostPrice: string;
  itemWeaponCosmeticPoliceLightsPrice: string;
  itemWeaponCosmeticNeonBorderPrice: string;
  itemWeaponCosmeticRotatingNeonBorderPrice: string;
  itemWeaponCosmeticDiamondBorderPrice: string;
  itemWeaponCosmeticGoldBorderPrice: string;
  itemWeaponCosmeticSilverBorderPrice: string;
  itemWeaponCosmeticBronzeBorderPrice: string;
  itemCharacterCosmeticGrayscalePrice: string;
  itemCharacterCosmeticContrastPrice: string;
  itemCharacterCosmeticSepiaPrice: string;
  itemCharacterCosmeticInvertPrice: string;
  itemCharacterCosmeticBlurPrice: string;
  itemCharacterCosmeticFireGlowPrice: string;
  itemCharacterCosmeticEarthGlowPrice: string;
  itemCharacterCosmeticLightningGlowPrice: string;
  itemCharacterCosmeticWaterGlowPrice: string;
  itemCharacterCosmeticRainbowGlowPrice: string;
  itemCharacterCosmeticDarkGlowPrice: string;
  itemCharacterCosmeticGhostPrice: string;
  itemCharacterCosmeticPoliceLightsPrice: string;
  itemCharacterCosmeticNeonBorderPrice: string;
  itemCharacterCosmeticDiamondBorderPrice: string;
  itemCharacterCosmeticGoldBorderPrice: string;
  itemCharacterCosmeticSilverBorderPrice: string;
  itemCharacterCosmeticBronzeBorderPrice: string;
}

export interface IState {
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
  ownedWeaponIds: number[];
  ownedShieldIds: number[];
  ownedTrinketIds: number[];
  ownedJunkIds: number[];
  ownedKeyLootboxIds: number[];
  maxStamina: number;
  ownedDust: string[];

  currentCharacterId: number | null;
  characters: Record<number, ICharacter>;
  characterStaminas: Record<number, number>;
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

  staking: Record<StakeType, IStakeState>;
  stakeOverviews: Record<StakeType, IStakeOverviewState>;

  raid: IRaidState;

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
  payoutCurrencyId: string;

  itemPrices: IItemPrices;
}
