
import img1 from './assets/junk/junk1.png';
import img2 from './assets/junk/junk2.png';
import img3 from './assets/junk/junk3.png';
import img4 from './assets/junk/junk4.png';
import img5 from './assets/junk/junk5.png';
import img6 from './assets/junk/junk6.png';

const allImages = [img1, img2, img3, img4, img5, img6];

export function getJunkArt(id: number) {
  return allImages[id % allImages.length];
}
