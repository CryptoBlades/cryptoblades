import { CensorSensor } from 'censor-sensor';

const censor = new CensorSensor();

//disable censor for tier 2,3,4
for (let i = 4; i > 1; i--) censor.disableTier(i);

export const getCleanName = (name: string): string => {
  return censor.cleanProfanityIsh(name);
};

export const isProfaneIsh = (name: string): boolean => {
  return censor.isProfaneIsh(name);
};