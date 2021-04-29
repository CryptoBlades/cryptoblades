
import { ICharacter, ITarget, IWeapon, WeaponTrait, WeaponElement } from './interfaces';

export function characterFromContract(id: number, data: string): ICharacter {
  const xp = data[0];
  const level = parseInt(data[1], 10);
  const trait = data[2];
  const staminaTimestamp = data[3];
  const appearance = data[4];
  return { id, xp, level, trait, staminaTimestamp, appearance };
}

export function getStatPatternFromProperties(properties: number): number {
  return (properties >> 5) & 0x7f;
}

export function getStat1Trait(statPattern: number): number {
  return (statPattern % 5);
}

export function getStat2Trait(statPattern: number): number {
  return ((statPattern / 5) % 5);
}

export function getStat3Trait(statPattern: number): number {
  return (((statPattern / 5) / 5) % 5);
}

export function statNumberToName(statNum: number): string {
  switch(statNum) {
  case WeaponTrait.CHA: return 'CHA';
  case WeaponTrait.DEX: return 'DEX';
  case WeaponTrait.INT: return 'INT';
  case WeaponTrait.PWR: return 'PWR';
  case WeaponTrait.STR: return 'STR';
  default:              return '???';
  }
}

export function getWeaponTraitFromProperties(properties: number): number {
  return (properties >> 3) & 0x3;
}

export function traitNumberToName(traitNum: number): string {
  switch(traitNum) {
  case WeaponElement.Fire:        return 'Fire';
  case WeaponElement.Earth:       return 'Earth';
  case WeaponElement.Water:       return 'Water';
  case WeaponElement.Lightning:   return 'Lightning';
  default:                        return '???';
  }
}

export function weaponFromContract(id: number, data: string): IWeapon {
  const properties = data[0];
  const stat1 = data[1];
  const stat2 = data[2];
  const stat3 = data[3];
  const level = +data[4];
  const blade = data[5];
  const crossguard = data[6];
  const grip = data[7];
  const pommel = data[8];

  const stat1Value = +stat1;
  const stat2Value = +stat2;
  const stat3Value = +stat3;

  const pattern1 = getStatPatternFromProperties(stat1Value);
  const stat1Type = getStat1Trait(pattern1);

  const pattern2 = getStatPatternFromProperties(stat2Value);
  const stat2Type = getStat1Trait(pattern2);

  const pattern3 = getStatPatternFromProperties(stat3Value);
  const stat3Type = getStat1Trait(pattern3);

  const traitNum = getWeaponTraitFromProperties(+properties);

  const stars = (+properties) & 0x7;
  return {
    id, properties,
    element: traitNumberToName(traitNum),
    stat1: statNumberToName(stat1Type), stat1Value,
    stat2: statNumberToName(stat2Type), stat2Value,
    stat3: statNumberToName(stat3Type), stat3Value,
    level,
    blade, crossguard, grip, pommel,
    stars
  };
}

export function targetFromContract(data: string): ITarget {
  const n = parseInt(data, 10);
  return {
    original: data,
    power: n & 0b11111111_11111111_11111111,
    trait: n >> 24
  };
}
