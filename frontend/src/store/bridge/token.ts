/* eslint-disable @typescript-eslint/no-unused-vars */
import {
  Contract,
  IState,
} from '@/interfaces';
import {Dispatch} from 'vuex';
import {NftTransfer, TransferedNft} from '@/interfaces/Nft';
import {approveFeeWalletOnly} from '@/contract-call-utils';
import BigNumber from 'bignumber.js';

const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });
import {IERC20} from '@/../../build/abi-interfaces';
import { getGasPrice } from '../store';

const token = {
  actions: {
    async isTokenSupported({rootState}: {rootState: IState}, tokenAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.isTokenSupported(tokenAddress).call(defaultCallOptions(rootState));

    },
    async getSupportedTokenTypes({rootState}: {rootState: IState}) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getSupportedTokenTypes().call(defaultCallOptions(rootState));
    },
    async bridgeIsEnabled({rootState}: {rootState: IState}) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.bridgeIsEnabled().call(defaultCallOptions(rootState));
    },
    async chainBridgeEnabled({rootState}: {rootState: IState}, chainId: string | number) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.chainBridgeEnabled(chainId).call(defaultCallOptions(rootState));
    },
    getEnabledChainsForBridging({rootState}: {rootState: IState}) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getEnabledChainsForBridging().call(defaultCallOptions(rootState));
    },
    async bridgeOutToken(
      {rootState}: {rootState: IState},
      {tokenAddress, amount, targetChain}: {tokenAddress: string, amount: string, targetChain: string | number}) {
      const { ERC20Bridge, SkillToken } = rootState.contracts();
      if(!ERC20Bridge) return;

      //init new contract for other tokens
      //const xToken = new web3.eth.Contract(erc20Abi as Abi, xTokenAddress);
      //const TokenContract: Contract<IERC20> = tokenAddress === SkillToken.options.address ? SkillToken : new Contract(IERC20, tokenAddress);
      if(tokenAddress !== SkillToken.options.address) return;
      SkillToken.methods.approve(ERC20Bridge.options.address, amount);

      return ERC20Bridge.methods.bridgeOutToken(tokenAddress, amount, targetChain).send(defaultCallOptions(rootState));
    },
    async getTokenBridgeMinAmount({rootState}: {rootState: IState}, tokenAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getTokenBridgeVal(tokenAddress, 0).call(defaultCallOptions(rootState));
    },
    async getTokenBrideFee({rootState}: {rootState: IState}, tokenAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getTokenBridgeVal(tokenAddress, 1).call(defaultCallOptions(rootState));
    },
    async getTokenBridgeMaxAmount({rootState}: {rootState: IState}, tokenAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getTokenBridgeVal(tokenAddress, 2).call(defaultCallOptions(rootState));
    },
    async getBridgeTransferOfPlayer({rootState}: {rootState: IState}, playerAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getBridgeTransferOfPlayer(playerAddress).call(defaultCallOptions(rootState));
    },
    async getBridgeOutTransferOfPlayerHistory({rootState}: {rootState: IState}, playerAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getBridgeOutTransferOfPlayerHistory(playerAddress).call(defaultCallOptions(rootState));
    },
    async getBridgeInTransferOfPlayerHistory({rootState}: {rootState: IState}, playerAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getBridgeInTransferOfPlayerHistory(playerAddress).call(defaultCallOptions(rootState));
    },
    async getBridgeOutTransfer({rootState}: {rootState: IState}, playerAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getBridgeOutTransfer(playerAddress).call(defaultCallOptions(rootState));
    },
    async getBridgeInTransfer({rootState}: {rootState: IState}, playerAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getBridgeOutTransfer(playerAddress).call(defaultCallOptions(rootState));
    },
    async getProxyContract({rootState}: {rootState: IState}, tokenAddress: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getProxyContract(tokenAddress).call(defaultCallOptions(rootState));
    },
    async getChainsSupportingERCs({rootState}: {rootState: IState}, token: string) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getChainsSupportingERCs(token).call(defaultCallOptions(rootState));
    },
    async getERCsSupportedByChain({rootState}: {rootState: IState}, chainId: string | number) {
      const { ERC20Bridge } = rootState.contracts();
      if(!ERC20Bridge) return;

      return ERC20Bridge.methods.getERCsSupportedByChain(chainId).call(defaultCallOptions(rootState));
    },
  },
};


export default token;