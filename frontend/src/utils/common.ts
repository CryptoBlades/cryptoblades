import axios from 'axios';
import BigNumber from 'bignumber.js';
import Web3 from 'web3';
import config from '../../app-config.json';
import {router} from '@/main';
import {getConfigValue, Networks} from '@/contracts';
import {networks as pvpNetworks} from '../../../build/contracts/PvpArena.json';
import {networks as simpleQuestsNetworks} from '../../../build/contracts/SimpleQuests.json';
import {QuestItemType} from '@/views/Quests.vue';
import {abi as erc20Abi} from '../../../build/contracts/ERC20.json';
import store from '@/store/store';

BigNumber.config({ROUNDING_MODE: BigNumber.ROUND_DOWN});
BigNumber.config({EXPONENTIAL_AT: 100});

export function addChainToRouter(chain: string) {
  router.replace(
    {
      query: Object.assign({...router.currentRoute.query}, {chain}),
    },
    () => {
    }
  );
}

interface Config {
  environments: Record<string, Chain>;
}

interface Chain {
  chains: Record<string, Record<string, any>>;
}

// executes when network is changed in wallet
(window as any).ethereum?.on('chainChanged', (chainIdHex: string) => {
  const chainId = parseInt(chainIdHex, 16);
  const env = window.location.href.startsWith('https://test') ? 'test' : 'production';
  const chains = (config as Config).environments[env].chains;

  for (const [chainName, values] of Object.entries(chains)) {
    if (+values.VUE_APP_NETWORK_ID === chainId) {
      localStorage.setItem('currentChain', chainName);
      addChainToRouter(chainName);
    }
  }
  window.location.reload();
});

// executes when account is changed in wallet
(window as any).ethereum?.on('accountsChanged', async () => {
  const accounts = await store.state.web3.eth.getAccounts();
  store.commit('setAccounts', { accounts });
  store.dispatch('setUpContractEvents');
  store.dispatch('fetchUserDetails');
});

export const apiUrl = (url: string) => `${process.env.VUE_APP_API_URL || 'https://api.cryptoblades.io'}/${url}`;

export const getCurrentGasPrices = async () => {
  const response = await axios.get('https://www.gasnow.org/api/v3/gas/price');
  return {
    low: response.data.data.slow / 1e9,
    medium: response.data.data.standard / 1e9,
    high: response.data.data.fast / 1e9
  };
};

export const toBN = (value: string | number): BigNumber => {
  const valueString = typeof value === 'string' ? value : String(value);

  return new BigNumber(valueString);
};

export const bnMinimum = (...values: string[]): BigNumber => {
  return BigNumber.minimum(...values);
};

export const fromWeiEther = (value: string | BigNumber): string => {
  return new BigNumber(value).div('1000000000000000000').toFixed();
};

export const gasUsedToBnb = (gasUsed: number, gasPrice: string): string => {
  const gasCost = gasUsed * Number(gasPrice);

  return Web3.utils.fromWei(gasCost.toString()).toString();
};

export const copyNftUrl = (id: number | string, type?: string): void => {
  const path = `/#/nft-display/${type}/${id}`;
  const dummy = document.createElement('input'),
    text = window.location.origin + path;
  document.body.appendChild(dummy);
  dummy.value = text;
  dummy.select();
  document.execCommand('copy');
  document.body.removeChild(dummy);
};

export const addTokenToMetamask = async (address: string, symbol: string): Promise<void> => {
  try {
    const contract = new (window as any).ethereum.Contract(erc20Abi as any[], address);
    const decimals = await contract.methods.decimals().call();
    await (window as any).ethereum?.request({
      method: 'wallet_watchAsset',
      params: {
        type: 'ERC20',
        options: {
          address,
          symbol,
          decimals
        },
      },
    });
  } catch (error) {
    console.error(error);
  }
};

export const isValidWeb3Address = (walletAddress: string) => {
  return Web3.utils.isAddress(walletAddress);
};

export const currentChainSupportsPvP = () => {
  const networkId = getConfigValue('VUE_APP_NETWORK_ID') || '5777';
  const contractAddress = process.env.VUE_APP_PVP_CONTRACT_ADDRESS ||
    getConfigValue('VUE_APP_PVP_CONTRACT_ADDRESS') || (pvpNetworks as Networks)[networkId]?.address;
  return !!contractAddress;
};

export const currentChainSupportsQuests = () => {
  const networkId = getConfigValue('VUE_APP_NETWORK_ID') || '5777';
  const contractAddress = process.env.VUE_APP_SIMPLE_QUESTS_CONTRACT_ADDRESS ||
    getConfigValue('VUE_APP_SIMPLE_QUESTS_CONTRACT_ADDRESS') || (simpleQuestsNetworks as Networks)[networkId]?.address;
  return !!contractAddress;
};

export const getTimeRemaining = (end: string) => {
  const total = new Date(+end * 1000).getTime() - new Date().getTime();
  let seconds: string | number = Math.floor((total / 1000) % 60);
  let minutes: string | number = Math.floor((total / 1000 / 60) % 60);
  let hours: string | number = Math.floor((total / (1000 * 60 * 60)) % 24);
  let days: string | number = Math.floor((total / (1000 * 60 * 60 * 24)));
  if (seconds < 10) {
    seconds = String(seconds).padStart(2, '0');
  }
  if (minutes < 10) {
    minutes = String(minutes).padStart(2, '0');
  }
  if (hours < 10) {
    hours = String(hours).padStart(2, '0');
  }
  if (days < 10) {
    days = String(days).padStart(2, '0');
  }

  return {
    total,
    days,
    hours,
    minutes,
    seconds
  };
};

export const questItemTypeSupportsStars = (questItemType: QuestItemType): boolean => {
  return questItemType === QuestItemType.WEAPON
    || questItemType === QuestItemType.JUNK
    || questItemType === QuestItemType.TRINKET
    || questItemType === QuestItemType.SHIELD;
};

export const questItemTypeSupportsTimesValue = (questItemType: QuestItemType): boolean => {
  return questItemType !== QuestItemType.STAMINA
    && questItemType !== QuestItemType.EXPERIENCE
    && questItemType !== QuestItemType.SOUL
    && questItemType !== QuestItemType.DUST;
};
