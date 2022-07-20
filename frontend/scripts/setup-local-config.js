const fs = require('fs-extra');
const { join } = require('path');

const APP_CONFIG = join(__dirname, '../app-config.json');
const LOCAL_NETWORK = join(__dirname, '../../networks/networks-1337.json');

const appConfig = JSON.parse(fs.readFileSync(APP_CONFIG));
const localNetwork = JSON.parse(fs.readFileSync(LOCAL_NETWORK));

const getContractAddress = (contract) => {
  return localNetwork[`build/contracts/${contract}.json`] ? localNetwork[`build/contracts/${contract}.json`].address : '';
};
const setupLocalConfigTask = async () => {
  fs.ensureDirSync('./');

  appConfig.supportedLocalChains = ['BNB'];
  appConfig.environments.local = {
    chains: {
      BNB: {
        featureSupport: {
          shield: true,
          merch: true,
          land: true,
          disableDynamicMinting: true
        },
        VUE_APP_WAX_BRIDGE_WAX_WALLET_ADDRESS: 'snoui.wam',
        VUE_APP_NETWORK_ID:'1337',
        VUE_APP_EXPECTED_NETWORK_ID:'1337',
        VUE_APP_EXPECTED_NETWORK_NAME:'Localhost',

        VUE_APP_STAKE_TYPES_AVAILABLE:'skill,skill2,skill90,skill180,king90,king180,cbkLandT1,cbkLandT2,cbkLandT3',
        VUE_APP_STAKE_TYPE_FOR_UNCLAIMED_REWARDS: 'skill',
        VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS: getContractAddress('SkillToken'),
        VUE_APP_SKILL2_TOKEN_CONTRACT_ADDRESS:'',
        VUE_APP_LP_TOKEN_CONTRACT_ADDRESS:'',
        VUE_APP_LP_2_TOKEN_CONTRACT_ADDRESS:'',
        VUE_APP_SKILL_STAKING_REWARDS_CONTRACT_ADDRESS: getContractAddress('SkillStakingRewardsUpgradeable'),
        VUE_APP_SKILL2_STAKING_REWARDS_CONTRACT_ADDRESS: getContractAddress('SkillStakingRewardsUpgradeable'),
        VUE_APP_LP_STAKING_REWARDS_CONTRACT_ADDRESS: getContractAddress('LPStakingRewardsUpgradeable'),
        VUE_APP_LP_2_STAKING_REWARDS_CONTRACT_ADDRESS: getContractAddress('LP2StakingRewardsUpgradeable'),
        VUE_APP_KING_TOKEN_CONTRACT_ADDRESS: getContractAddress('ExperimentToken'),
        VUE_APP_KING_STAKING_REWARDS_90_CONTRACT_ADDRESS: getContractAddress('KingStakingRewardsUpgradeable90'),
        VUE_APP_KING_STAKING_REWARDS_180_CONTRACT_ADDRESS: getContractAddress('KingStakingRewardsUpgradeable180'),
        VUE_APP_SKILL_STAKING_REWARDS_90_CONTRACT_ADDRESS: getContractAddress('SkillStakingRewardsUpgradeable90'),
        VUE_APP_SKILL_STAKING_REWARDS_180_CONTRACT_ADDRESS: getContractAddress('SkillStakingRewardsUpgradeable180'),
        VUE_APP_CBK_LAND_TOKEN_CONTRACT_ADDRESS: getContractAddress('CBKLand'),
        VUE_APP_CBK_LAND_T1_STAKING_REWARDS_CONTRACT_ADDRESS: getContractAddress('CBKLandT1StakingRewardsUpgradeable'),
        VUE_APP_CBK_LAND_T2_STAKING_REWARDS_CONTRACT_ADDRESS: getContractAddress('CBKLandT2StakingRewardsUpgradeable'),
        VUE_APP_CBK_LAND_T3_STAKING_REWARDS_CONTRACT_ADDRESS: getContractAddress('CBKLandT3StakingRewardsUpgradeable'),

        VUE_APP_CRYPTOBLADES_CONTRACT_ADDRESS: getContractAddress('CryptoBlades'),
        VUE_APP_RAID_CONTRACT_ADDRESS: getContractAddress('Raid1'),
        VUE_APP_MARKET_CONTRACT_ADDRESS: getContractAddress('NFTMarket'),
        VUE_APP_WAX_BRIDGE_CONTRACT_ADDRESS: getContractAddress('WaxBridge'),
        VUE_APP_STORAGE_CONTRACT_ADDRESS: getContractAddress('NFTStorage'),
        VUE_APP_TREASURY_CONTRACT_ADDRESS: getContractAddress('Treasury'),
        VUE_APP_PVP_CONTRACT_ADDRESS: getContractAddress('PvpArena'),
        VUE_APP_PVP_CORE_CONTRACT_ADDRESS: getContractAddress('PvpCore'),
        VUE_APP_PVP_RANKINGS_CONTRACT_ADDRESS: getContractAddress('PvpRankings'),
        VUE_APP_BURNING_MANAGER_CONTRACT_ADDRESS: getContractAddress('BurningManager'),
        VUE_APP_LAUNCHPAD_CONTRACT_ADDRESS: '',

        VUE_APP_MERCHANDISE_CONTRACT_ADDRESS: getContractAddress('Merchandise'),
        VUE_APP_SIMPLE_QUESTS_CONTRACT_ADDRESS: getContractAddress('SimpleQuests'),
        VUE_APP_PARTNER_GIVEAWAYS_CONTRACT_ADDRESS: getContractAddress('PartnerGiveaways'),

        VUE_APP_MULTICALL_CONTRACT_ADDRESS: '',

        chainId: '0x539',
        currencyName: 'BNB Local',
        currencyNetwork: 'BNB',
        currencySymbol: 'BNB',
        currencyTransak: 'BNB,BUSD',
        currencyDecimals: '18',
        rpcUrls: ['http://localhost:8545/'],
        blockExplorerUrls: [],
        exchangeUrl: '',
        fightGas: '0.0007'
      }
    }
  };
  fs.writeFileSync(APP_CONFIG, JSON.stringify(appConfig));
};

setupLocalConfigTask();
