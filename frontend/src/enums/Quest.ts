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
