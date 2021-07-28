import axios from 'axios';
import BigNumber from 'bignumber.js';

BigNumber.config({ ROUNDING_MODE: BigNumber.ROUND_DOWN });
BigNumber.config({ EXPONENTIAL_AT: 100 });

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
  if(!valueString.includes('.')) return new BigNumber(valueString);

  // return new BigNumber(valueString.substring(0, valueString.indexOf('.')));

  return new BigNumber(valueString.substring(valueString.indexOf('.'), valueString.length));
};

export const bnMinimum = (...values: string[]): BigNumber => {
  return BigNumber.minimum(...values);
};
