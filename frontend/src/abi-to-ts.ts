type Head<T extends any[]> = T extends [] ? never : T[0];
type Tail<T extends any[]> = T extends [unknown, ...infer Tail] ? Tail : [];

interface AbiTypes {
  uint256: string;
  'uint256[]': string[];
  int256: string;
  uint64: string;
  'uint32[4]': [string, string, string, string];
  uint32: string;
  int32: string;
  uint16: string;
  uint8: string;
  address: string;
  bool: boolean;
  bytes4: string;
}
type ValidAbiTypes = keyof AbiTypes;
type LookupAbiType<T extends ValidAbiTypes> = AbiTypes[T];

type AbiTupleParams<T extends any[]> = [] extends T ? [] : [LookupAbiType<Head<T>>, ...AbiTupleParams<Tail<T>>];

interface IO {
  name: string;
  type: ValidAbiTypes;
}

interface FunctionAbi {
  name: string;
  inputs: IO[];
  outputs: IO[];
  type: 'function';
}

type AbiIOArrayToTuple<T extends IO[]> = [] extends T ? [] : [Head<T>['type'], ...AbiIOArrayToTuple<Tail<T>>];

type ReturnValue<T extends any[]> = T extends [] ? void : (T extends [infer U] ? U : T);

interface Web3CallOptions {
  from: string | null;
}

interface TransactionResult {
  events: any;
}

interface AbiCall<R> {
  call(opts: Web3CallOptions): Promise<R>;
  send(opts: Web3CallOptions): Promise<TransactionResult>;
}

type AbiFunction<T extends FunctionAbi> =
  (...args: AbiTupleParams<AbiIOArrayToTuple<T['inputs']>>)
    =>
    AbiCall<ReturnValue<AbiTupleParams<AbiIOArrayToTuple<T['outputs']>>>>;

type IsFunctionType<T, K extends keyof T> = T[K] extends FunctionAbi ? T[K]['name'] : never;

export type AbiMethods<T> = {
  [K in keyof T as IsFunctionType<T, K>]: T[K] extends FunctionAbi ? AbiFunction<T[K]> : never
};

// import { IERC20, Characters } from '../../build/abis';

// const test = {} as AbiMethods<typeof Characters>;

// const ierc20: AbiMethods<typeof IERC20> = {
//   totalSupply() {
//     return '100';
//   },

//   balanceOf(address) {
//     return '20';
//   },

//   transfer(recipient, amount) {
//     return false;
//   },

//   allowance(owner, spender) {
//     return '0';
//   },

//   approve(spender, amount) {
//     return false;
//   },

//   transferFrom(owner, recipient, amount) {
//     return false;
//   }
// };
// let funcs: AbiFunctions<typeof Characters>;

// let funcs: AbiFunctions<typeof Characters> = { approve(recipient, amount) {} };

// type ApprovalInputTuple = AbiIOArrayToTuple<typeof Characters[0]['inputs']>;

// const test: AbiTupleParams<ApprovalInputTuple> = ['0x111', 'wew', '1'];
