
import { ICharacter, ITarget, IWeapon } from './interfaces';

export function characterFromContract(id: number, data: string): ICharacter {
  const xp = data[0];
  const level = parseInt(data[1], 10);
  const trait = data[2];
  const staminaTimestamp = data[3];
  const appearance = data[4];
  return { id, xp, level, trait, staminaTimestamp, appearance };
}

export function weaponFromContract(id: number, data: string): IWeapon {
  const properties = data[0];
  const stat1 = data[1];
  const stat2 = data[2];
  const stat3 = data[3];
  const level = data[4];
  const blade = data[5];
  const crossguard = data[6];
  const grip = data[7];
  const pommel = data[8];

  const stars = (+properties) & 0x7;
  return { id, properties, stat1, stat2, stat3, level, blade, crossguard, grip, pommel, stars };
}

export function targetFromContract(data: string): ITarget {
  const n = parseInt(data, 10);
  return {
    original: data,
    power: n & 0b11111111_11111111_11111111,
    trait: n >> 24
  };
}
