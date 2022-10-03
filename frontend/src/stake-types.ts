import { getConfigValue } from './contracts';
import { allStakeTypes, allNftStakeTypes, isStakeType, isNftStakeType, StakeType, NftStakeType  } from './interfaces';

let availableStakingContracts = allStakeTypes;
let availableNftStakingContracts = allNftStakeTypes;

if(getConfigValue('VUE_APP_STAKE_TYPES_AVAILABLE')) {
  availableStakingContracts = getConfigValue('VUE_APP_STAKE_TYPES_AVAILABLE')
    .split(',')
    .filter(isStakeType);
}

if(getConfigValue('VUE_APP_NFT_STAKE_TYPES_AVAILABLE')) {
  availableNftStakingContracts = getConfigValue('VUE_APP_NFT_STAKE_TYPES_AVAILABLE')
    .split(',')
    .filter(isNftStakeType);
}

export interface StakingContractEntry {
  stakingRewardsAddress: string;
  stakingTokenAddress: string;
}

export const stakingContractsInfo: Partial<Record<StakeType, Partial<StakingContractEntry>>> = {
  skill: {
    stakingRewardsAddress: getConfigValue('VUE_APP_SKILL_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS')
  }
};

if(availableStakingContracts.includes('skill60')) {
  stakingContractsInfo.skill60 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_SKILL_STAKING_REWARDS_60_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('valor')) {
  stakingContractsInfo.valor = {
    stakingRewardsAddress: getConfigValue('VUE_APP_VALOR_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_VALOR_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('lpValor')) {
  stakingContractsInfo.lpValor = {
    stakingRewardsAddress: getConfigValue('VUE_APP_LP_VALOR_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_LP_VALOR_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('lpValor2')) {
  stakingContractsInfo.lpValor2 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_LP_VALOR_2_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_LP_VALOR_2_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('skill2')) {
  stakingContractsInfo.skill2 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_SKILL2_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_SKILL2_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('lp')) {
  stakingContractsInfo.lp = {
    stakingRewardsAddress: getConfigValue('VUE_APP_LP_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_LP_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('lp2')) {
  stakingContractsInfo.lp2 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_LP_2_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_LP_2_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('king')) {
  stakingContractsInfo.king = {
    stakingRewardsAddress: getConfigValue('VUE_APP_KING_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_KING_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('king90')) {
  stakingContractsInfo.king90 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_KING_STAKING_REWARDS_90_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_KING_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('king180')) {
  stakingContractsInfo.king180 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_KING_STAKING_REWARDS_180_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_KING_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('skill90')) {
  stakingContractsInfo.skill90 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_SKILL_STAKING_REWARDS_90_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS')
  };
}

if(availableStakingContracts.includes('skill180')) {
  stakingContractsInfo.skill180 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_SKILL_STAKING_REWARDS_180_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS')
  };
}


export const nftStakingContractsInfo: Partial<Record<NftStakeType, Partial<StakingContractEntry>>> = {};

if(availableNftStakingContracts.includes('cbkLandT1')) {
  nftStakingContractsInfo.cbkLandT1 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_CBK_LAND_T1_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_CBK_LAND_TOKEN_CONTRACT_ADDRESS')
  };
}
if(availableNftStakingContracts.includes('cbkLandT2')) {
  nftStakingContractsInfo.cbkLandT2 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_CBK_LAND_T2_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_CBK_LAND_TOKEN_CONTRACT_ADDRESS')
  };
}
if(availableNftStakingContracts.includes('cbkLandT3')) {
  nftStakingContractsInfo.cbkLandT3 = {
    stakingRewardsAddress: getConfigValue('VUE_APP_CBK_LAND_T3_STAKING_REWARDS_CONTRACT_ADDRESS'),
    stakingTokenAddress: getConfigValue('VUE_APP_CBK_LAND_TOKEN_CONTRACT_ADDRESS')
  };
}

interface HumanReadableDetailsForStakeType {
  stakeTokenName: string;
  rewardTokenName: string;
  stakeTitle: string;
  deprecated?: boolean;
  note?: string;
}

const defaultHumanReadableDetailsForStakeTypes: Record<StakeType, HumanReadableDetailsForStakeType> = {
  skill: {
    stakeTokenName: 'SKILL',
    rewardTokenName: 'SKILL',
    stakeTitle: 'SKILL for SKILL (Old)',
    deprecated: true
  },
  skill2: {
    stakeTokenName: 'SKILL',
    rewardTokenName: 'SKILL',
    stakeTitle: 'SKILL for SKILL'
  },
  lp: {
    stakeTokenName: 'SKILL-WBNB',
    rewardTokenName: 'SKILL',
    stakeTitle: 'SKILL-WBNB for SKILL'
  },
  lp2: {
    stakeTokenName: 'SKILL-BNB',
    rewardTokenName: 'SKILL',
    stakeTitle: 'SKILL-BNB for SKILL V2'
  },
  lpValor: {
    stakeTokenName: 'SKILL-VALOR',
    rewardTokenName: 'VALOR',
    stakeTitle: '30 days SKILL-VALOR (APE LP) for VALOR'
  },
  lpValor2: {
    stakeTokenName: 'KING-VALOR',
    rewardTokenName: 'VALOR',
    stakeTitle: '30 days KING-VALOR (APE LP) for VALOR'
  },
  king: {
    stakeTokenName: 'KING',
    rewardTokenName: 'KING',
    stakeTitle: 'KING for KING'
  },
  king90: {
    stakeTokenName: 'KING',
    rewardTokenName: 'KING',
    stakeTitle: '90 days KING for KING'
  },
  king180: {
    stakeTokenName: 'KING',
    rewardTokenName: 'KING',
    stakeTitle: '180 days KING for KING'
  },
  skill60: {
    stakeTokenName: 'SKILL',
    rewardTokenName: 'SKILL',
    stakeTitle: '60 days SKILL for SKILL (Revenue Share)',
    note: 'This pool allows your tokens to be used as rewards within CryptoBlades, and in return you gain 2 months of high-APR SKILL, and additionally collect revenue-share from CryptoBlades from 2 months onwards. Once you unstake, you are removed from the revenue share. Same as staking, revenue share is determined based on your share of the staking pool. So as more people unstake, their share gets distributed amongst the remaining stakers.'
  },
  skill90: {
    stakeTokenName: 'SKILL',
    rewardTokenName: 'SKILL',
    stakeTitle: '90 days SKILL for SKILL'
  },
  skill180: {
    stakeTokenName: 'SKILL',
    rewardTokenName: 'SKILL',
    stakeTitle: '180 days SKILL for SKILL'
  },
  valor: {
    stakeTokenName: 'VALOR',
    rewardTokenName: 'VALOR',
    stakeTitle: '30 days VALOR for VALOR'
  }
};

const defaultHumanReadableDetailsForNftStakeTypes: Record<NftStakeType, HumanReadableDetailsForStakeType> = {
  cbkLandT1: {
    stakeTokenName: 'CBKL (T1)',
    rewardTokenName: 'KING',
    stakeTitle: 'CBKL TIER 1 for KING'
  },
  cbkLandT2: {
    stakeTokenName: 'CBKL (T2)',
    rewardTokenName: 'KING',
    stakeTitle: 'CBKL TIER 2 for KING'
  },
  cbkLandT3: {
    stakeTokenName: 'CBKL (T3)',
    rewardTokenName: 'KING',
    stakeTitle: 'CBKL TIER 3 for KING'
  }
};

export const humanReadableDetailsForStakeTypes = defaultHumanReadableDetailsForStakeTypes;
export const humanReadableDetailsForNftStakeTypes = defaultHumanReadableDetailsForNftStakeTypes;

const stakeTypeForUnclaimedRewards = getConfigValue('VUE_APP_STAKE_TYPE_FOR_UNCLAIMED_REWARDS');

export const stakeTypeThatCanHaveUnclaimedRewardsStakedTo: StakeType =
  stakeTypeForUnclaimedRewards && isStakeType(stakeTypeForUnclaimedRewards)
    ? stakeTypeForUnclaimedRewards
    : 'skill';
