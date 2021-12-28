
// import img1 from './assets/raid-bosses/CB_Hellborn Brute.gif';
// import img2 from './assets/raid-bosses/CB_Hellborn Executioner.gif';
// import img3 from './assets/raid-bosses/CB_Hellborn Marauder.gif';
// import img4 from './assets/raid-bosses/CB_Hellborn Overlord.gif';
// import img5 from './assets/raid-bosses/CB_Hellborn Shaman.gif';
// import img6 from './assets/raid-bosses/DragonFlyIdle_512.gif';

// import img7 from './assets/raid-bosses/CB_Hellborn M13.gif';
// import img8 from './assets/raid-bosses/CB_Hellborn Ste1n.gif';
// import img9 from './assets/raid-bosses/CB_Hellborn Moneth.gif';
// import img10 from './assets/raid-bosses/CB_Hellborn Skulpin.gif';
// import img11 from './assets/raid-bosses/CB_Hellborn Plitszkin.gif';

import christmas1 from './assets/raid-bosses/KokMhei.gif';
import christmas2 from './assets/raid-bosses/KocuZe.gif';
import christmas3 from './assets/raid-bosses/Jestinsane.gif';
import christmas4 from './assets/raid-bosses/Krypton.gif';
import christmas5 from './assets/raid-bosses/Melics.gif';

const allImages = [
  // img1, img2, img3, img4, img5, img6,
  // img7, img8, img9, img10, img11,
  christmas1, christmas2, christmas3, christmas4, christmas5];

export function getBossArt(id: number) {
  return allImages[id % allImages.length];
}
