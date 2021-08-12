import { CensorSensor } from 'censor-sensor';

const censor = new CensorSensor();

export const getCleanName = (name: string): string => {
  return censor.cleanProfanityIsh(name);
};

export const isProfaneIsh = (name: string): boolean => {
  return censor.isProfaneIsh(name);
};