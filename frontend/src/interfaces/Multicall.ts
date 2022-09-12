import { Web3JsAbiCall } from '../../../abi-common';

export interface getNFTCall {
  abi: any;
  calls: callData[];
}

export interface callData {
  address: string;
  name: string;
  params: string[];
}

export interface returnData {
  blockNumber: number;
  returnData: string[];
}

export interface MultiCall {
  aggregate(calldata: string[]): Web3JsAbiCall<returnData>;
}
