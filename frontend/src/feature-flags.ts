export const raid = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_RAID + '').toLowerCase());

export const stakeOnly = ['1', 'true', 't'].includes((process.env.VUE_APP_STAKING_ONLY + '').toLowerCase());

export const reforging = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_REFORGING + '').toLowerCase());

export const market = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_MARKET + '').toLowerCase());

export const market_blockchain = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_MARKET_USE_BLOCKCHAIN + '').toLowerCase());

export const portal = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_PORTAL + '').toLowerCase());