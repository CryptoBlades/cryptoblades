export const raid = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_RAID + '').toLowerCase());

export const reforging = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_REFORGING + '').toLowerCase());

export const portal = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_PORTAL + '').toLowerCase());

export const pvp = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_PVP + '').toLowerCase());

export const quests = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_QUESTS + '').toLowerCase());

export const nft_bridge = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_NFT_BRIDGE + '').toLowerCase());

export const burningManager = ['1', 'true', 't'].includes((process.env.VUE_APP_FEATURE_FLAG_BURNING_MANAGER + '').toLowerCase());
