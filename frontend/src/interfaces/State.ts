import { ICharacter } from './Character';
import { IWeapon } from './Weapon';
import { ITarget } from './Target';
import { Contracts } from './Contracts';

export type StakeType = 'skill' | 'lp';
export const allStakeTypes: StakeType[] = ['skill', 'lp'];

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
  expectedFinishTime: string;
  raiderCount: number;
  bounty: string;
  totalPower: string;
  weaponDrops: string[];
  staminaDrainSeconds: number;

  isOwnedCharacterRaidingById: Record<number, boolean>; // ?
}

export interface IState {
  contracts: Contracts;
  accounts: string[];
  defaultAccount: string | null;
  currentNetworkId: number | null;

  skillBalance: string;
  ownedCharacterIds: number[];
  ownedWeaponIds: number[];
  maxStamina: number;

  currentCharacterId: number | null;
  characters: Record<number, ICharacter>;
  characterStaminas: Record<number, number>;

  weapons: Record<number, IWeapon>;
  targetsByCharacterIdAndWeaponId: Record<number, Record<number, ITarget>>;

  staking: Record<StakeType, IStakeState>;
  stakeOverviews: Record<StakeType, IStakeOverviewState>;

  raid: IRaidState;
}
