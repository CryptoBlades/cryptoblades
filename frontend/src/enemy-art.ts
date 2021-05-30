import img1 from './assets/enemies/ElfFemale_Spearwoman.gif';
import img2 from './assets/enemies/GoblinFemale_Light.gif';
import img3 from './assets/enemies/GoblinMale_Heavy.gif';
import img4 from './assets/enemies/GoblinMale_Light.gif';
import img5 from './assets/enemies/HumanFemale_Archer.gif';
import img6 from './assets/enemies/HumanMale_Bandit.gif';
import img7 from './assets/enemies/HumanMale_Knight.gif';
import img8 from './assets/enemies/OrcMale_Warrior.gif';

const allImages = [img1, img2, img3, img4, img5, img6, img7, img8];

export function getEnemyArt(enemyID: number) {
  return allImages[enemyID % allImages.length];
}
