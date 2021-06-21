
export enum WeaponElement {
  Fire = 0,
  Earth = 1,
  Lightning = 2,
  Water = 3,
}

export enum WeaponTrait {
  STR = 0,
  DEX = 1,
  CHA = 2,
  INT = 3,
  PWR = 4
}
export interface IWeapon {
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
  level: number;
  blade: string;
  crossguard: string;
  grip: string;
  pommel: string;
  stars: number;
  lowStarBurnPoints: number;
  fourStarBurnPoints: number;
  fiveStarBurnPoints: number;
  bonusPower: number;
}

function AdjustStatForTrait(statValue: number, statTrait: number, charTrait: number) {
  let value = statValue;
  if(statTrait === charTrait)
    value = Math.floor(value * 1.07);
  else if(statTrait === WeaponTrait.PWR)
    value = Math.floor(value * 1.03);
  return value;
}

function MultiplierPerEffectiveStat(statValue: number) {
  return statValue * 0.25;
}

export function Stat1PercentForChar(wep: IWeapon, trait: number) {
  return MultiplierPerEffectiveStat(AdjustStatForTrait(wep.stat1Value, wep.stat1Type, trait));
}

export function Stat2PercentForChar(wep: IWeapon, trait: number) {
  return MultiplierPerEffectiveStat(AdjustStatForTrait(wep.stat2Value, wep.stat2Type, trait));
}

export function Stat3PercentForChar(wep: IWeapon, trait: number) {
  return MultiplierPerEffectiveStat(AdjustStatForTrait(wep.stat3Value, wep.stat3Type, trait));
}

export function GetTotalMultiplierForTrait(wep: IWeapon, trait: number) {
  return 1 + (0.01 * (Stat1PercentForChar(wep, trait) + Stat2PercentForChar(wep, trait) + Stat3PercentForChar(wep, trait)));
}