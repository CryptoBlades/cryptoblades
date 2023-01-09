
export interface ICharacter {
  id: number;
  xp: string;
  level: number;
  trait: string;
  traitName: string;
  staminaTimestamp: string;
  head: string;
  arms: string;
  torso: string;
  legs: string;
  boots: string;
  race: string;
  version: number;
}

export interface IPowerData {
  pvePower: number[];
  pvpTierPower: number[];
  pvpFfaPower: number[];
  charTrait: number;
  wepTrait: number;
  shieldTrait: number;
}

export interface IStoredPowerData {
  0: Array<string>,
  1: Array<string>
  2: Array<string>
  3: string,
  4: string,
  5: string,
  6: string,
  7: string,
  charTrait: string
  level: string
  powerData: string
  pvePower: Array<string>
  pvpFfaPower: Array<string>
  pvpTierPower: Array<string>
  shieldTrait: string
  wepTrait: string
}

export enum CharacterTrait {
  Fire = 0,
  Earth = 1,
  Lightning = 2,
  Water = 3,
}

export function CharacterPower(level: number) {
  return ((1000 + level * 10) * (Math.floor(level / 10) + 1));
}

export function RequiredXp(level: number) {
  let xp = 16;
  for(let i = 0; i < level; i++) {
    if (xp <= 112) {
      xp += Math.floor(xp / 10);
    }
    else {
      xp += Math.floor((i-14) + 1);
    }
  }
  return xp;
}
