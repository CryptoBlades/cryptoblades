import { ICharacter } from './Character';
import { IWeapon } from './Weapon';

export interface IState {
  contracts: Record<string, any>;
  accounts: string[];
  defaultAccount: string | null;

  skillBalance: string;
  ownedCharacterIds: number[];
  ownedWeaponIds: number[];
  maxStamina: number;

  currentCharacterId: number | null;
  characters: Record<number, ICharacter>;
  characterStaminas: Record<number, number>;

  weapons: Record<number, IWeapon>;
  targetsByCharacterIdAndWeaponId: Record<number, any>;

  stakedSkillBalance: string;
  stakeRemainingCapacityForDeposit: string;
  stakeRemainingCapacityForWithdraw: string;
  stakeContractBalance: string;
  stakeCurrentRewardEarned: string;
  stakeRewardPeriodEndUnix: number;
  stakeRewardPeriodDurationSeconds: number;
  stakeRewardMinimumStakeTime: number;
  stakeRewardDistributionTimeLeft: number;
  stakeUnlockTimeLeft: number;
  
}
