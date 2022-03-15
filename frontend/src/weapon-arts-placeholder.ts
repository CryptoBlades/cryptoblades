
import img1 from './assets/placeholder/sword-placeholder-0.png';
import img2 from './assets/placeholder/sword-placeholder-1.png';
import img3 from './assets/placeholder/sword-placeholder-2.png';
import img4 from './assets/placeholder/sword-placeholder-3.png';
import img5 from './assets/placeholder/sword-placeholder-4.png';
import img6 from './assets/placeholder/sword-placeholder-5.png';
import img7 from './assets/placeholder/sword-placeholder-6.png';

import specialImg1 from './assets/special-weapons/pluto-alliance.png';

import { IWeapon } from './interfaces';

const allImages = [img1, img2, img3, img4, img5, img6, img7];
// remove normal placeholders when adding new special event img
const specialImage = [specialImg1, img1, img2, img3, img4, img5, img6, img7];

export function getWeaponArt(weapon: IWeapon) {
  if (!weapon) {
    return null;
  }

  if(weapon.weaponType > 0) {
    return specialImage[weapon.weaponType - 1];
  }

  return allImages[weapon.id % allImages.length];
}

// don't use, won't show partner weapon images
export function getWeaponArtById(weaponId: number) {
  if (!weaponId) {
    return null;
  }

  return allImages[weaponId % allImages.length];
}
