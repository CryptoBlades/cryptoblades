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
      //check multiple providers available & exclude walletconnect
      if(!(window as any).ethereum.providers && providerName !== SupportedWallets.WALLETCONNECT){
        const web3 = new Web3(Web3.givenProvider);
        commit('setWeb3', web3, { root: true });
      }
      else if(providerName === SupportedWallets.METAMASK){
        const web3 = new Web3((window as any).ethereum.providers.find((x: any) => x.isMetaMask));
        commit('setWeb3', web3, { root: true });
        dispatch('configureWallet');
      }

      else if(providerName === SupportedWallets.COINBASE){
        const web3 = new Web3((window as any).ethereum.providers.find((x: any) => x.isCoinbaseWallet));
        commit('setWeb3', web3, { root: true });
        dispatch('configureWallet');
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
        localStorage.setItem('lastConnectedWallet', providerName);
        commit('setConnectionState', ConnectionState.CONNECTED);
        commit('setConnectedWallet', providerName);
        return true;
      }
      else{
        commit('setConnectionState', ConnectionState.DISCONNECTED);
        return false;
      }
    },
    async testConnection({rootState}: {rootState: IState}){
      return rootState.web3.eth
        .requestAccounts()
        .then((res) => {
          console.log(res);
          return true;
        })
        .catch((err) => {
          console.log(err);
          return false;
        });
    },
    async configureWallet({rootState, dispatch}: {rootState: IState, dispatch: Dispatch}) {
      const currentNetwork = await rootState.web3.eth.net.getId();
      if(currentNetwork === +getConfigValue('VUE_APP_NETWORK_ID')) return;
      await dispatch('configureChainNet', {
        networkId: +getConfigValue('VUE_APP_NETWORK_ID'),
        chainId: getConfigValue('chainId'),
        chainName: getConfigValue('VUE_APP_EXPECTED_NETWORK_NAME'),
        currencyName: getConfigValue('currencyName'),
        currencySymbol: getConfigValue('currencySymbol'),
        currencyDecimals: +getConfigValue('currencyDecimals'),
        rpcUrls: getConfigValue('rpcUrls'),
        blockExplorerUrls: getConfigValue('blockExplorerUrls'),
        skillAddress: getConfigValue('VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS')
      });
    },

    async configureChainNet(
      {rootState, commit}: {rootState: IState, commit: Commit},
      { networkId, chainId, chainName, currencyName, currencySymbol, currencyDecimals, rpcUrls, blockExplorerUrls, skillAddress }:
      { networkId: number,
        chainId: string,
        chainName: string,
        currencyName: string,
        currencySymbol: string,
        currencyDecimals: number,
        rpcUrls: string[],
        blockExplorerUrls: string[],
        skillAddress: string,
      })
    {
      commit('setNetworkId', networkId, { root: true });
      try {
        await (rootState.web3.currentProvider as any).request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId }],
        });
      } catch (switchError) {
        try {
          await (rootState.web3.currentProvider as any).request({
            method: 'wallet_addEthereumChain',
            params: [
              {
                chainId,
                chainName,
                nativeCurrency: {
                  name: currencyName,
                  symbol: currencySymbol,
                  decimals: currencyDecimals,
                },
                rpcUrls,
                blockExplorerUrls,
              },
            ],
          });
        } catch (addError) {
          console.error(addError);
          return;
        }
      }

      try {
        await (rootState.web3.currentProvider as any).request({
          method: 'wallet_watchAsset',
          params: {
            type: 'ERC20',
            options: {
              address: skillAddress,
              symbol: 'SKILL',
              decimals: 18,
              image: 'https://app.cryptoblades.io/android-chrome-512x512.png',
            },
          },
        });
      } catch (error) {
        console.error(error);
      }

      window.location.reload();
    },
  },
  // checkWalletConnection({state, commit, dispatch}: {commit: Commit, state: IWalletState, dispatch: Dispatch}){
  //   if(state.connectionState === ConnectionState.CONNECTED){
  //     return true;
  //   }
  // }
};


export default wallet;
















