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
  tier?: number;
  chunkId?: number;
}

export type NftType = 'weapon' | 'character' | 'shield';

export const allNftTypes: NftType[] = ['weapon', 'character', 'shield'];

export interface TransferedNft {
  owner: string,
  nftType: number,
  sourceChain: number,
  sourceId: number,
  status: number,
  transferInsMeta: string,
  targetId?: number,
}

export interface NftTransfer {
  owner: string,
  nftAddress: string,
  nftId: number,
  requestBlock: number,
  lastUpdateBlock: number,
  chainId: number,
  status: number,
}

export function isNftType(nftType: string): nftType is NftType {
  return allNftTypes.includes(nftType as NftType);
}
