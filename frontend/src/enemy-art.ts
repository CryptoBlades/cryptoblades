import img1 from './assets/enemies/Enemy1.gif';
import img2 from './assets/enemies/Enemy2.gif';
import img3 from './assets/enemies/Enemy3.gif';
import img4 from './assets/enemies/Enemy4.gif';
import img5 from './assets/enemies/Enemy5.gif';
import img6 from './assets/enemies/Enemy6.gif';
import img7 from './assets/enemies/Enemy7.gif';
import img8 from './assets/enemies/Enemy8.gif';

const allImages = [img1, img2, img3, img4, img5, img6, img7, img8];

export function getEnemyArt(enemyID: number) {
  return allImages[enemyID % allImages.length];
}
