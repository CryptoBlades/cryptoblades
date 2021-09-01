export interface RaidRewards {
  rewardsClaimed: any;
  weapons: Weapon[];
  junks: Junk[];
  keyboxes: Keybox[];
  bonusXp: BonusXp[];
  dustLb: DustLb[];
  dust4b: Dust4b[];
  dust5b: Dust5b[];
}

export interface Weapon {
  tokenID: number;
}

export interface Junk {
  tokenID: number;
}

export interface Keybox {
  tokenID: number;
}

export interface BonusXp {
  charID: string;
  amount: string;
}

export interface DustLb {
  amount: number;
}

export interface Dust4b {
  amount: number;
}

export interface Dust5b {
  amount: number;
}
