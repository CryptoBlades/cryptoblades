export const raid = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_RAID + '').toLowerCase());

export const stakeOnly = ['1', 'true', 't'].includes((process.env.VUE_APP_STAKING_ONLY + '').toLowerCase());
