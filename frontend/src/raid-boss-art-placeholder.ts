import hellborn1 from './assets/raid-bosses/CB_Hellborn Brute.gif';
import hellborn2 from './assets/raid-bosses/CB_Hellborn Executioner.gif';
import hellborn3 from './assets/raid-bosses/CB_Hellborn Marauder.gif';
import hellborn4 from './assets/raid-bosses/CB_Hellborn Overlord.gif';
import hellborn5 from './assets/raid-bosses/CB_Hellborn Shaman.gif';
import hellborn6 from './assets/DragonFlyIdle_512.gif';

// import halloween1 from './assets/raid-bosses/halloween/CB_Hellborn M13.gif';
// import halloween2 from './assets/raid-bosses/halloween/CB_Hellborn Ste1n.gif';
// import halloween3 from './assets/raid-bosses/halloween/CB_Hellborn Moneth.gif';
// import halloween4 from './assets/raid-bosses/halloween/CB_Hellborn Skulpin.gif';
// import halloween5 from './assets/raid-bosses/halloween/CB_Hellborn Plitszkin.gif';

// import christmas1 from './assets/raid-bosses/christmas/KokMhei.gif';
// import christmas2 from './assets/raid-bosses/christmas/KocuZe.gif';
// import christmas3 from './assets/raid-bosses/christmas/Jestinsane.gif';
// import christmas4 from './assets/raid-bosses/christmas/Krypton.gif';
// import christmas5 from './assets/raid-bosses/christmas/Melics.gif';

// import aprilFools1 from './assets/raid-bosses/april_fools/shaman.png';
// import aprilFools2 from './assets/raid-bosses/april_fools/brute.png';
// import aprilFools3 from './assets/raid-bosses/april_fools/sad_hat_guy.png';

const allImages = [
  hellborn1, hellborn2, hellborn3, hellborn4, hellborn5, hellborn6,
  // halloween1, halloween2, halloween3, halloween4, halloween5,
  // christmas1, christmas2, christmas3, christmas4, christmas5,
  // aprilFools3, aprilFools1, aprilFools2,
];

export function getBossArt(id: number) {
  return allImages[id % allImages.length];
}
