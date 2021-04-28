
export enum Element {
  Fire = 0,
  Earth = 1,
  Lightning = 2,
  Water = 3,
}

export enum Trait {
  STR = 0,
  DEX = 1,
  CHA = 2,
  INT = 3,
  PWR = 4
}
export interface IWeapon {
  id: number;
  properties: string;
  stat1: string;
  stat1Value: number;
  stat2: string;
  stat2Value: number;
  stat3: string;
  stat3Value: number;
  level: string;
  blade: string;
  crossguard: string;
  grip: string;
  pommel: string;
  stars: number;
}
