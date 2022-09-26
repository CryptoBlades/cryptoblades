import { callData, getNFTCall } from '@/interfaces';

export function getNFTCall(abi: any, address: any, name: string, params: any[]): getNFTCall {
  const calls: callData[] = params.map((param: string[]) => ({
    address,
    name,
    params: param,
  }));
  return {
    abi,
    calls,
  };
}
