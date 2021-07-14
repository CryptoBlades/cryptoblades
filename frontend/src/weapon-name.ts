
import seedrandom from 'seedrandom';
import * as weaponNames from './assets/weapon-names.json';

const names: Record<string, string[]> = (weaponNames as any).default || weaponNames;

const getRandom = (rng: any, arr: string[]): string => arr[Math.floor(rng() * arr.length)];

// basic weapon (TYPE)
const basic = (rng: any): string => {
  return getRandom(rng, names.type);
};

// normal weapon (ADJ TYPE)
const normal = (rng: any): string => {
  const prefix = getRandom(rng, names.prefix);
  const type = getRandom(rng, names.type);

  return `${prefix} ${type}`;
};

// material weapon (ADJ MAT TYPE)
const material = (rng: any): string => {
  const prefix = getRandom(rng, names.prefix);
  const type = getRandom(rng, names.type);
  const material = getRandom(rng, names.material);

  return `${prefix} ${material} ${type}`;
};

// special weapon (SPEC)
const special = (rng: any): string => {
  return getRandom(rng, names.specialtype);
};

// super special weapon (OWN, SPEC SUFF)
const owned = (rng: any): string => {
  const prefix = getRandom(rng, names.specialprefix);
  const type = getRandom(rng, names.specialtype);
  const suffix = getRandom(rng, names.suffix);

  return `${prefix} ${type} ${suffix}`;
};


export const getWeaponNameFromSeed = (seed: number, stars: number) => {
  const rng = seedrandom(seed.toString());

  const roll = Math.floor(rng() * 100);

  if(stars === 1) {
    return basic(rng);
  }

  if(stars <= 3) {
    if(roll <= 25) return material(rng);
    return normal(rng);
  }

  if(stars === 4) {
    if(roll <= 1) return special(rng);
    if(roll <= 50) return material(rng);
    return normal(rng);
  }

  if(stars === 5) {
    if(roll <= 75) return special(rng);
    return owned(rng);
  }

  if(stars > 5) {
    return owned(rng);
  }

  return basic(rng);
};
