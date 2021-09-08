export interface Nft {
  id: number | string;
  type?: string;
  stars?: number;
  element?: string;
  stat1Type?: number;
  stat2Type?: number;
  stat3Type?: number;
  stat1?: string;
  stat2?: string;
  stat3?: string;
  stat1Value?: number;
  stat2Value?: number;
  stat3Value?: number;
  nftPrice?: number;
  amount?: number;
  effect?: number;
}

export type NftType = 'weapon' | 'character' | 'shield';

export const allNftTypes: NftType[] = ['weapon', 'character', 'shield'];

export function isNftType(nftType: string): nftType is NftType {
  return allNftTypes.includes(nftType as NftType);
}
