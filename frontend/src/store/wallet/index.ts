/* eslint-disable no-empty-pattern */
import {
  IState,
} from '@/interfaces';
import {Dispatch, Commit} from 'vuex';
import Web3 from 'web3';
import WalletConnectProvider from '@walletconnect/web3-provider';
import { getConfigValue } from '@/contracts';
import config from '@/../app-config.json';
import { Provider } from '@truffle/hdwallet-provider/dist/constructor/types';

interface RPCS {
  [key: number]: string;
}

export enum SupportedWallets {
  METAMASK = 'MetaMask',
  COINBASE = 'CoinBase Wallet',
  WALLETCONNECT = 'WalletConnect',
}

enum ConnectionState {
  CONNECTED,
  CONNECTING,
  DISCONNECTED,
}

interface IWalletState{
  connectionState: ConnectionState;
  connectedWallet: SupportedWallets | null;
}

const wallet = {
  namespaced: true,
  state: {
    connectionState: ConnectionState.DISCONNECTED,
    connectedWallet: null,
  } as IWalletState,
  mutations: {
    setConnectionState(state: IWalletState, connectionState: ConnectionState) {
      state.connectionState = connectionState;
    },
    setConnectedWallet(state: IWalletState, connectedWallet: SupportedWallets) {
      state.connectedWallet = connectedWallet;
    }
  },
  getters: {
  },
  actions: {
    async connectWallet({state, commit, dispatch}: {commit: Commit, state: IWalletState, dispatch: Dispatch}, providerName: SupportedWallets) {
      console.log('connectWallet', providerName);
      //check multiple providers available
      if(!(window as any).ethereum.providers){
        console.log(Web3.givenProvider);
        const web3 = new Web3(Web3.givenProvider);
        commit('setWeb3', web3, { root: true });
      }
      else if(providerName === SupportedWallets.METAMASK){
        const web3 = new Web3((window as any).ethereum.providers.find((x: any) => x.isMetaMask));
        commit('setWeb3', web3, { root: true });
      }

      else if(providerName === SupportedWallets.COINBASE){
        const web3 = new Web3((window as any).ethereum.providers.find((x: any) => x.isCoinbaseWallet));
        commit('setWeb3', web3, { root: true });
      }

      else if (providerName === SupportedWallets.WALLETCONNECT){
        const rpc = {} as RPCS;
        config.supportedChains.forEach((chain) => {
          const chainId = getConfigValue('VUE_APP_NETWORK_ID', chain);
          rpc[chainId] = getConfigValue('rpcUrls',chain)[0];
        });

        let chainId;
        //check if wallet connect is already set
        if(localStorage.getItem('walletconnect')){
          chainId = JSON.parse(localStorage.getItem('walletconnect') || '').chainId;
        }
        else {
          chainId = +getConfigValue('VUE_APP_NETWORK_ID');
        }
        const walletConnectProvider = new WalletConnectProvider({
          rpc,
          chainId,
        });

        //  Enable session (triggers QR Code modal)
        await walletConnectProvider.enable();
        commit('setWeb3', new Web3(walletConnectProvider as Provider), { root: true });
      }

      state.connectionState = ConnectionState.CONNECTING;

      if(await dispatch('testConnection') || providerName === SupportedWallets.WALLETCONNECT){
        console.log('connection successful');
        localStorage.setItem('lastConnectedWallet', providerName);
        commit('setConnectionState', ConnectionState.CONNECTED);
        commit('setConnectedWallet', providerName);
        return true;
      }
      else{
        console.log('connection unsuccessful');
        commit('setConnectionState', ConnectionState.DISCONNECTED);
        return false;
      }
    },
    async testConnection({rootState}: {rootState: IState}){
      return rootState.web3.eth
        .requestAccounts()
        .then((x) => {
          console.log(x);
          return true;
        })
        .catch((x) => {
          console.log(x);
          return false;
        });
    },
  },
  // checkWalletConnection({state, commit, dispatch}: {commit: Commit, state: IWalletState, dispatch: Dispatch}){
  //   if(state.connectionState === ConnectionState.CONNECTED){
  //     return true;
  //   }
  // }
};


export default wallet;
















