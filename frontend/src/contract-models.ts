
import { ICharacter, ITarget, IWeapon, WeaponTrait, WeaponElement, IRaidState } from './interfaces';
import { Nft } from './interfaces/Nft';
import { IShield } from './interfaces/Shield';

export function traitNumberToName(traitNum: number): string {
  switch(+traitNum) {
  case WeaponElement.Fire:        return 'Fire';
  case WeaponElement.Earth:       return 'Earth';
  case WeaponElement.Water:       return 'Water';
  case WeaponElement.Lightning:   return 'Lightning';
  default:                        return '???';
  }
}

export function traitNameToNumber(traitName: string): number {
  switch(traitName) {
  case 'Fire':        return WeaponElement.Fire;
  case 'Earth':       return WeaponElement.Earth;
  case 'Lightning':   return WeaponElement.Lightning;
  case 'Water':       return WeaponElement.Water;
  default:            return 255;
  }
}

export function characterFromContract(id: string | number, data: string[]): ICharacter {
  const xp = data[0];
  const level = parseInt(data[1], 10);
  const trait = data[2];
  const traitName = traitNumberToName(+data[2]);
  const staminaTimestamp = data[3];
  const head = data[4];
  const arms = data[5];
  const torso = data[6];
  const legs = data[7];
  const boots = data[8];
  const race = data[9];
  return { id: +id, xp, level, trait, traitName, staminaTimestamp, head, arms, torso, legs, boots, race };
}

export function getStatPatternFromProperties(properties: number): number {
  return (properties >> 5) & 0x7f;
}

export function getStat1Trait(statPattern: number): number {
  return (statPattern % 5);
}

export function getStat2Trait(statPattern: number): number {
  return (Math.floor(statPattern / 5) % 5);
}

export function getStat3Trait(statPattern: number): number {
  return (Math.floor(Math.floor(statPattern / 5) / 5) % 5);
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

export function trinketFromContract(id: string | number, data: string[]): Nft {
  return {
    id: +id,
    type: 'trinket',
    stars: +data[0],
    //effect: +data[1]
  };
}

export function junkFromContract(id: string | number, stars: string): Nft {
  return {
    id: +id,
    type: 'junk',
    stars: +stars,
  };
}

export function shieldFromContract(id: string | number, data: string[]): IShield {
  const properties = data[0];
  const stat1 = data[1];
  const stat2 = data[2];
  const stat3 = data[3];

  const stat1Value = +stat1;
  const stat2Value = +stat2;
  const stat3Value = +stat3;

  const statPattern = getStatPatternFromProperties(+properties);
  const stat1Type = getStat1Trait(statPattern);
  const stat2Type = getStat2Trait(statPattern);
  const stat3Type = getStat3Trait(statPattern);

  const traitNum = getWeaponTraitFromProperties(+properties);

  const stars = (+properties) & 0x7;
  return {
    id: +id, properties,
    element: traitNumberToName(traitNum),
    stat1: statNumberToName(stat1Type), stat1Value, stat1Type,
    stat2: statNumberToName(stat2Type), stat2Value, stat2Type,
    stat3: statNumberToName(stat3Type), stat3Value, stat3Type,
    stars,
  };
}

export function weaponFromContract(id: string | number, data: string[]): IWeapon {
  const properties = data[0];
  const stat1 = data[1];
  const stat2 = data[2];
  const stat3 = data[3];
  const level = +data[4];
  const blade = data[5];
  const crossguard = data[6];
  const grip = data[7];
  const pommel = data[8];
  const burnPoints = +data[9];
  const bonusPower = +data[10];

  const stat1Value = +stat1;
  const stat2Value = +stat2;
  const stat3Value = +stat3;

  const statPattern = getStatPatternFromProperties(+properties);
  const stat1Type = getStat1Trait(statPattern);
  const stat2Type = getStat2Trait(statPattern);
  const stat3Type = getStat3Trait(statPattern);

  const traitNum = getWeaponTraitFromProperties(+properties);

  const lowStarBurnPoints = burnPoints & 0xff;
  const fourStarBurnPoints = (burnPoints >> 8) & 0xff;
  const fiveStarBurnPoints = (burnPoints >> 16) & 0xff;

  const stars = (+properties) & 0x7;
  return {
    id: +id, properties,
    element: traitNumberToName(traitNum),
    stat1: statNumberToName(stat1Type), stat1Value, stat1Type,
    stat2: statNumberToName(stat2Type), stat2Value, stat2Type,
    stat3: statNumberToName(stat3Type), stat3Value, stat3Type,
    level,
    blade, crossguard, grip, pommel,
    stars,
    lowStarBurnPoints,
    fourStarBurnPoints,
    fiveStarBurnPoints,
    bonusPower
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

export function raidFromContract(data: string[]): IRaidState {
  const index = data[0];
  const expectedFinishTime = data[1];
  const raiderCount = data[2];
  const playerPower = data[3];
  const bossPower = data[4];
  const bossTrait = data[5];
  const status = data[6];
  const joinSkill = data[7];
  const staminaCost = data[8];
  const durabilityCost = data[9];
  const xpReward = data[10];
  const accountPower = data[11];
  return {
    index, expectedFinishTime, raiderCount, playerPower, bossPower, bossTrait, status,
    joinSkill, staminaCost, durabilityCost, xpReward, accountPower
  };
}
