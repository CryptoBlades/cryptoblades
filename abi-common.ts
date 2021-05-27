export interface Web3JsCallOptions {
  from: string | null;
}

export interface Web3JsTransactionResult {
  events: any;
  blockNumber: number;
}

type BlockNumber = number | string | 'latest' | 'earliest' | 'pending';

export interface Web3JsAbiCall<R> {
  call(opts: Web3JsCallOptions, defaultBlock?: BlockNumber): Promise<R>;
  send(opts: Web3JsCallOptions): Promise<Web3JsTransactionResult>;
}
