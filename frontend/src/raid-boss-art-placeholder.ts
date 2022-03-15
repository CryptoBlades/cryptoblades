import hellborn1 from './assets/raid-bosses/CB_Hellborn Brute.gif';
import hellborn2 from './assets/raid-bosses/CB_Hellborn Executioner.gif';
import hellborn3 from './assets/raid-bosses/CB_Hellborn Marauder.gif';
import hellborn4 from './assets/raid-bosses/CB_Hellborn Overlord.gif';
import hellborn5 from './assets/raid-bosses/CB_Hellborn Shaman.gif';
import hellborn6 from './assets/DragonFlyIdle_512.gif';

// import halloween1 from './assets/raid-bosses/CB_Hellborn M13.gif';
// import halloween2 from './assets/raid-bosses/CB_Hellborn Ste1n.gif';
// import halloween3 from './assets/raid-bosses/CB_Hellborn Moneth.gif';
// import halloween4 from './assets/raid-bosses/CB_Hellborn Skulpin.gif';
// import halloween5 from './assets/raid-bosses/CB_Hellborn Plitszkin.gif';

// import christmas1 from './assets/raid-bosses/KokMhei.gif';
// import christmas2 from './assets/raid-bosses/KocuZe.gif';
// import christmas3 from './assets/raid-bosses/Jestinsane.gif';
// import christmas4 from './assets/raid-bosses/Krypton.gif';
// import christmas5 from './assets/raid-bosses/Melics.gif';

const allImages = [
  hellborn1, hellborn2, hellborn3, hellborn4, hellborn5, hellborn6,
  // halloween1, halloween2, halloween3, halloween4, halloween5,
  // christmas1, christmas2, christmas3, christmas4, christmas5
];

export function getBossArt(id: number) {
  return allImages[id % allImages.length];
}
