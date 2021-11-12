
export enum ShieldElement {
  Fire = 0,
  Earth = 1,
  Lightning = 2,
  Water = 3,
}

export enum ShieldTrait {
  STR = 0,
  DEX = 1,
  CHA = 2,
  INT = 3,
  DEF = 4
}
export interface IShield {
  id: number;
  properties: string;
  element: string;
  stat1: string;
  stat1Value: number;
  stat1Type: number;
  stat2: string;
  stat2Value: number;
  stat2Type: number;
  stat3: string;
  stat3Value: number;
  stat3Type: number;
  stars: number;
}