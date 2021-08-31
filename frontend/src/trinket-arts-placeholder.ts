
import img1 from './assets/trinkets/trinket1.png';

const allImages = [img1];

export function getTrinketArt(id: number) {
  return allImages[id % allImages.length];
}
