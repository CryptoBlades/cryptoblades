export interface IWeaponHistory{
  buyerAddress: string;
  price: number;
  sellerAddress: string;
  stat1Element: string;
  stat1Value: number;
  stat2Element: string;
  stat2Value: number;
  stat3Element: string;
  stat3Value: number;
  timestamp: string;
  type: string;
  weaponElement: string;
  weaponId: string;
  charId: string;
  weaponStars: number;
  id: string;
}

export interface WeaponTransactionHistoryData{
  weaponId: string;
  weaponName: string;
  weaponPrice: number;
}

export interface ICharacterHistory{
  buyerAddress: string;
  charElement: string;
  charId: string;
  charLevel: string;
  price: number;
  sellerAddress: string;
  timestamp: string;
  type: string;
  id: string;
}

export interface CharacterTransactionHistoryData{
  charId: string;
  charName: string;
  charPrice: number;
}
