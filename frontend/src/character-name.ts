
import seedrandom from 'seedrandom';
import * as characterNames from './assets/character-names.json';

const names: Record<string, string[]> = (characterNames as any).default || characterNames;

const getRandom = (rng: any, arr: string[]): string => arr[Math.floor(rng() * arr.length)];

export const getCharacterNameFromSeed = (seed: number) => {
  const rng = seedrandom(seed.toString());

  const firstKey = getRandom(rng, ['one', 'two', 'three', 'more']);
  const secondKey = getRandom(rng, ['one', 'two', 'three', 'more']);

  const firstName = getRandom(rng, names[firstKey]);
  const secondName = getRandom(rng, names[secondKey]);

  return `${firstName} ${secondName}`;
};