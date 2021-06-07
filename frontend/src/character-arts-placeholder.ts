
import img1 from './assets/placeholder/chara-0.png';
import img2 from './assets/placeholder/chara-1.png';
import img3 from './assets/placeholder/chara-2.png';
import img4 from './assets/placeholder/chara-3.png';
import { ICharacter } from './interfaces';

const allImages = [img1, img2, img3, img4];

export function getCharacterArt(character: ICharacter) {
  if (!character) {
    return null;
  }

  return allImages[character.id % allImages.length];
}
