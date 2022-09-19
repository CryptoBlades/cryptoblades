
import WaterKnight from '../../assets/characters/KnightWater.png';
import LightningKnight from '../../assets/characters/KnightLightning.png';
import FireKnight from '../../assets/characters/KnightFire.png';
import EarthKnight from '../../assets/characters/KnightEarth.png';
import head1 from '../../assets/placeholder/chara-head-0.png';
import head2 from '../../assets/placeholder/chara-head-1.png';
import head3 from '../../assets/placeholder/chara-head-2.png';
import head4 from '../../assets/placeholder/chara-head-3.png';

import { CharacterTrait, ICharacter } from '../../interfaces';

const characterImages = {earth: EarthKnight, fire: FireKnight, water: WaterKnight, lightning: LightningKnight};

const allHeadImages = [head1, head2, head3, head4];

export function getCharacterArt(character: ICharacter) {
  if (!character) {
    return null;
  }

  switch (+character.trait) {
  case CharacterTrait.Earth: return characterImages.earth;
  case CharacterTrait.Fire: return characterImages.fire;
  case CharacterTrait.Water: return characterImages.water;
  case CharacterTrait.Lightning: return characterImages.lightning;
  default: return characterImages.earth;
  }
}

export function getCharacterArtByTrait(characterTrait: string) {
  if (!characterTrait) {
    return null;
  }

  switch (characterTrait) {
  case 'Earth': return characterImages.earth;
  case 'Fire': return characterImages.fire;
  case 'Water': return characterImages.water;
  case 'Lightning': return characterImages.lightning;
  default: return characterImages.earth;
  }
}

export function getCharacterHeadArt(character: ICharacter){
  if(!character) {
    return null;
  }

  return allHeadImages[character.id % allHeadImages.length];

}
