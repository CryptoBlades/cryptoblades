export function getWeaponRarity(rarity: any) {
  if (!rarity) {
    return null;
  }
  if(rarity === 0) return 'Normal';
  if(rarity === 1) return 'Rare';
  if(rarity === 2) return 'Unique';
  if(rarity === 3) return 'Legendary';
  if(rarity === 4) return 'Mythical';
}

