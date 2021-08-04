import axios from 'axios';
import BigNumber from 'bignumber.js';

BigNumber.config({ ROUNDING_MODE: BigNumber.ROUND_DOWN });
BigNumber.config({ EXPONENTIAL_AT: 100 });

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

export const gasUsedToBnb = (gasUsed: number): string =>{
  const gweiPrice = 5;

  const gweiToBnbFactor = 1000000000;

  return ((gasUsed * gweiPrice) / gweiToBnbFactor).toFixed(6);
};