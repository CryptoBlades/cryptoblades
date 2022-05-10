
import img1 from './assets/placeholder/weapon7.png';
import img2 from './assets/placeholder/weapon1.png';
import img3 from './assets/placeholder/weapon2.png';
import img4 from './assets/placeholder/weapon3.png';
import img5 from './assets/placeholder/weapon4.png';
import img6 from './assets/placeholder/weapon5.png';
import img7 from './assets/placeholder/weapon6.png';

import { IWeapon } from './interfaces';

const allImages = [img1, img2, img3, img4, img5, img6, img7];

export function getWeaponArt(weapon: IWeapon) {
  if (!weapon) {
    return null;
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
