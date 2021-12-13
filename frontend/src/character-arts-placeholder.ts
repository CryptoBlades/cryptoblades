
import img1 from './assets/placeholder/chara-0.png';
import img2 from './assets/placeholder/chara-1.png';
import img3 from './assets/placeholder/chara-2.png';
import img4 from './assets/placeholder/chara-3.png';
import head1 from './assets/placeholder/chara-head-0.png';
import head2 from './assets/placeholder/chara-head-1.png';
import head3 from './assets/placeholder/chara-head-2.png';
import head4 from './assets/placeholder/chara-head-3.png';

import { ICharacter } from './interfaces';

const allImages = [img1, img2, img3, img4];

const allHeadImages = [head1, head2, head3, head4];

export function getCharacterArt(character: ICharacter) {
  if (!character) {
    return null;
  }

  return allImages[character.id % allImages.length];
}

export function getCharacterArtById(characterId: number) {
  if (!characterId && characterId !== 0) {
    return null;
  }

  return allImages[characterId % allImages.length];
}

export function getCharacterHeadArt(character: ICharacter){
  if(!character) {
    return null;
  }

  return allHeadImages[character.id % allHeadImages.length];

}
