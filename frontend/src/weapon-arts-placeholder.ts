
import img1 from './assets/placeholder/sword-placeholder-0.png';
import img2 from './assets/placeholder/sword-placeholder-1.png';
import img3 from './assets/placeholder/sword-placeholder-2.png';
import img4 from './assets/placeholder/sword-placeholder-3.png';
import img5 from './assets/placeholder/sword-placeholder-4.png';
import img6 from './assets/placeholder/sword-placeholder-5.png';
import img7 from './assets/placeholder/sword-placeholder-6.png';

import { IWeapon } from './interfaces';

const allImages = [img1, img2, img3, img4, img5, img6, img7];

export function getWeaponArt(weapon: IWeapon) {
  if (!weapon) {
    return null;
  }

  return allImages[weapon.id % allImages.length];
}
