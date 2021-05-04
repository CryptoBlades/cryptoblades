export interface Web3JsCallOptions {
  from: string | null;
}

export interface Web3JsTransactionResult {
  events: any;
}

export interface Web3JsAbiCall<R> {
  call(opts: Web3JsCallOptions): Promise<R>;
  send(opts: Web3JsCallOptions): Promise<Web3JsTransactionResult>;
}
