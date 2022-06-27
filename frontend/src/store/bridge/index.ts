import nft from './nft';
import token from './token';

const bridge = {
  actions: {
    ...nft.actions,
    ...token.actions
  },
};


export default bridge;