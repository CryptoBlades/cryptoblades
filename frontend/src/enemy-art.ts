// import img1 from './assets/enemies/Blood Spider.png';
// import img2 from './assets/enemies/GoblinFemale_Light.gif';
// import img3 from './assets/enemies/GoblinMale_Heavy.gif';
// import img4 from './assets/enemies/GoblinMale_Light.gif';
// import img5 from './assets/enemies/Orc Archer.png';
// import img6 from './assets/enemies/Ord Warden.png';
// import img7 from './assets/enemies/Venom Spitter.png';
// import img8 from './assets/enemies/OrcMale_Warrior.gif';

// import aprilFools1 from './assets/enemies/april_fools/monk.png';
// import aprilFools2 from './assets/enemies/april_fools/cavalry.png';
// import aprilFools3 from './assets/enemies/april_fools/demoman.png';
// import aprilFools4 from './assets/enemies/april_fools/sniper.png';
// import aprilFools5 from './assets/enemies/april_fools/archer.png';
// import aprilFools6 from './assets/enemies/april_fools/jedi.png';
// import aprilFools7 from './assets/enemies/april_fools/rid.png';
// import aprilFools8 from './assets/enemies/april_fools/baghead.png';
// import aprilFools9 from './assets/enemies/april_fools/spider.png';
// import aprilFools10 from './assets/enemies/april_fools/banan_cut.png';
// import aprilFools11 from './assets/enemies/april_fools/hedgehog.png';
// import aprilFools12 from './assets/enemies/april_fools/knight.png';
// import aprilFools13 from './assets/enemies/april_fools/cat.png';
// import aprilFools14 from './assets/enemies/april_fools/ogre.png';

import goblin1 from './assets/second-anniversary/enemies/goblin1.gif';
import goblin2 from './assets/second-anniversary/enemies/goblin2.gif';
import goblin3 from './assets/second-anniversary/enemies/goblin3.gif';
import goblin4 from './assets/second-anniversary/enemies/goblin4.gif';
import goblin5 from './assets/second-anniversary/enemies/goblin5.gif';
import goblin6 from './assets/second-anniversary/enemies/goblin6.gif';
import goblin7 from './assets/second-anniversary/enemies/goblin7.gif';
import goblin8 from './assets/second-anniversary/enemies/goblin8.gif';

const allImages = [
  // img1, img2, img3, img4, img5, img6, img7, img8,
  // aprilFools1, aprilFools2, aprilFools3, aprilFools4, aprilFools5,
  // aprilFools6, aprilFools7, aprilFools8, aprilFools9, aprilFools10,
  // aprilFools11, aprilFools12, aprilFools13, aprilFools14,
  goblin1, goblin2, goblin3, goblin4, goblin5, goblin6,
  goblin7, goblin8
];

export function getEnemyArt(enemyID: number) {
  return allImages[enemyID % allImages.length];
}
