export interface Web3JsCallOptions {
  from: string | null;
  gasPrice?: string;
  gas?: string;
}

export interface Web3JsSendOptions extends Web3JsCallOptions {
  value?: string | number;
}

export interface Web3JsTransactionResult {
  events: any;
  blockNumber: number;
  gasUsed: number;
  transactionHash: string;
}

type BlockNumber = number | string | 'latest' | 'earliest' | 'pending';

export interface Web3JsAbiCall<R> {
  call(opts: Web3JsCallOptions, defaultBlock?: BlockNumber): Promise<R>;
  send(opts: Web3JsSendOptions): Promise<Web3JsTransactionResult>;
}
