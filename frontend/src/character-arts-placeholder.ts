
import WaterKnight from './assets/characters/KnightWater.png';
import LightningKnight from './assets/characters/KnightLightning.png';
import FireKnight from './assets/characters/KnightFire.png';
import EarthKnight from './assets/characters/KnightEarth.png';
import Archer from './assets/characters/Archer.png';
import Mage from './assets/characters/Mage.png';
import Paladin from './assets/characters/Paladin.png';
import Spearman from './assets/characters/Spearman.png';
import head1 from './assets/placeholder/chara-head-0.png';
import head2 from './assets/placeholder/chara-head-1.png';
import head3 from './assets/placeholder/chara-head-2.png';
import head4 from './assets/placeholder/chara-head-3.png';

import { CharacterTrait, ICharacter } from './interfaces';

const characterImages = {earth: EarthKnight, fire: FireKnight, water: WaterKnight, lightning: LightningKnight};
const characterV2Images = {earth: Spearman, fire: Archer, water: Mage, lightning: Paladin};

const allHeadImages = [head1, head2, head3, head4];

export function getCharacterArt(character: ICharacter) {
  if (!character) {
    return null;
  }

  if(character.version === 0) {
    switch (+character.trait) {
    case CharacterTrait.Earth: return characterImages.earth;
    case CharacterTrait.Fire: return characterImages.fire;
    case CharacterTrait.Water: return characterImages.water;
    case CharacterTrait.Lightning: return characterImages.lightning;
    default: return characterImages.earth;
    }
  }
  else {
    switch (+character.trait) {
    case CharacterTrait.Earth: return characterV2Images.earth;
    case CharacterTrait.Fire: return characterV2Images.fire;
    case CharacterTrait.Water: return characterV2Images.water;
    case CharacterTrait.Lightning: return characterV2Images.lightning;
    default: return characterV2Images.earth;
    }
  }
}

export function getCharacterArtByTraitAndVersion(characterTrait: string, version: number) {
  if (!characterTrait) {
    return null;
  }

  if(version === 0) {
    switch (characterTrait) {
    case 'Earth': return characterImages.earth;
    case 'Fire': return characterImages.fire;
    case 'Water': return characterImages.water;
    case 'Lightning': return characterImages.lightning;
    default: return characterImages.earth;
    }
  }
  else {
    switch (characterTrait) {
    case 'Earth': return characterV2Images.earth;
    case 'Fire': return characterV2Images.fire;
    case 'Water': return characterV2Images.water;
    case 'Lightning': return characterV2Images.lightning;
    default: return characterV2Images.earth;
    }
  }
}

export function getCharacterHeadArt(character: ICharacter){
  if(!character) {
    return null;
  }

  return allHeadImages[character.id % allHeadImages.length];

}
