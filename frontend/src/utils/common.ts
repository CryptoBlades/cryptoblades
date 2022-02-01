import axios from 'axios';
import BigNumber from 'bignumber.js';
import Web3 from 'web3';
import config from '../../app-config.json';
import {router} from '@/main';
import {getConfigValue, Networks} from '@/contracts';
import {networks as pvpNetworks} from '../../../build/contracts/PvpArena.json';

BigNumber.config({ ROUNDING_MODE: BigNumber.ROUND_DOWN });
BigNumber.config({ EXPONENTIAL_AT: 100 });

const web3 = new Web3(Web3.givenProvider || process.env.VUE_APP_WEB3_FALLBACK_PROVIDER);

export function addChainToRouter(chain: string){
  router.replace(
    {
      query: Object.assign({ ...router.currentRoute.query }, { chain }),
    },
    () => {}
  );
}

interface Config {
  environments: Record<string, Chain>;
}

interface Chain {
  chains: Record<string, Record<string, any>>;
}

// executes when network is changed in MetaMask
(window as any).ethereum?.on('chainChanged', (chainIdHex: string) => {
  const chainId = parseInt(chainIdHex, 16);
  const env = window.location.href.startsWith('https://test') ? 'test' : 'production';
  const chains = (config as Config).environments[env].chains;

  for (const [chainName, values] of Object.entries(chains)){
    if(+values.VUE_APP_NETWORK_ID === chainId){
      localStorage.setItem('currentChain', chainName);
      addChainToRouter(chainName);
    }
  }
  window.location.reload();
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

export const toBN = (value: string|number): BigNumber => {
  const valueString = typeof value === 'string' ? value : String(value);

  return new BigNumber(valueString);
};

export const bnMinimum = (...values: string[]): BigNumber => {
  return BigNumber.minimum(...values);
};

export const fromWeiEther = (value: string|BigNumber): string => {
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
    await (web3.currentProvider as any).request({
      method: 'wallet_watchAsset',
      params: {
        type: 'ERC20',
        options: {
          address,
          symbol,
          decimals: 18
        },
      },
    });
  } catch (error) {
    console.error(error);
  }
};

export const currentChainSupportsMerchandise = () => {
  const currentChain = localStorage.getItem('currentChain') || 'BSC';
  const merchandiseSupportedChains = config.merchandiseSupportedChains;
  if (!currentChain || !merchandiseSupportedChains) {
    return false;
  }
  return merchandiseSupportedChains.includes(currentChain);
};

export const currentChainSupportsPvP = () => {
  const networkId = getConfigValue('VUE_APP_NETWORK_ID') || '5777';
  const pvpContractAddr = process.env.VUE_APP_PVP_CONTRACT_ADDRESS ||
    getConfigValue('VUE_APP_PVP_CONTRACT_ADDRESS') || (pvpNetworks as Networks)[networkId]?.address;
  return !!pvpContractAddr;
};
