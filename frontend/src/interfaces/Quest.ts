export interface WeeklyReward {
  id: number;
  rewardType: RewardType;
  rewardRarity: Rarity;
  rewardAmount: number;
  rewardExternalAddress?: string;
  reputationAmount: number;
  completionsGoal: number;
  weekNumber: number;
}

export interface Quest {
  progress: number;
  type?: QuestTemplateType;
  reputation: number;
  id: number;
  tier?: Rarity;
  requirementType?: RequirementType;
  requirementRarity?: Rarity;
  requirementAmount: number;
  requirementExternalAddress?: string;
  rewardType?: RewardType;
  rewardRarity?: Rarity;
  rewardAmount: number;
  rewardExternalAddress?: string;
  reputationAmount: number;
  deadline?: number;
  supply?: number;
}

export enum RequirementType {
  NONE,
  WEAPON,
  JUNK,
  DUST,
  TRINKET,
  SHIELD,
  STAMINA,
  SOUL,
  RAID,
  EXTERNAL = 10,
  EXTERNAL_HOLD = 11,
}

export enum RewardType {
  NONE,
  WEAPON,
  JUNK,
  DUST,
  TRINKET,
  SHIELD,
  EXPERIENCE = 9,
  SOUL = 7,
  CHARACTER = 12,
  EXTERNAL = 10,
}

// NOTE: Numbers should represent ItemType in SimpleQuests.sol
export enum QuestItemType {
  NONE,
  WEAPON,
  JUNK,
  DUST,
  TRINKET,
  SHIELD,
  STAMINA,
  SOUL,
  RAID,
  EXPERIENCE,
  EXTERNAL,
  EXTERNAL_HOLD,
  CHARACTER,
  REPUTATION = 99
}

export enum Rarity {
  COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
}

export enum DustRarity {
  LESSER, GREATER, POWERFUL
}

export enum ReputationTier {
  PEASANT, TRADESMAN, NOBLE, KNIGHT, KING
}

export enum QuestTemplateType {
  QUEST=0,
  PROMO=10,
  WALLET=30,
  PICKABLE=20
}
export interface ReputationLevelRequirements {
  level2: number;
  level3: number;
  level4: number;
  level5: number;
}

export interface TierChances {
  common: number;
  uncommon: number;
  rare: number;
  epic: number;
  legendary: number;
}

export interface QuestItemsInfo {
  questItems: Record<string, Record<string, any>>;
}
