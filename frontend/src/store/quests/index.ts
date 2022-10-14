import {
  IState,
  Contract,
} from '@/interfaces';
import {Quest, Rarity, ReputationLevelRequirements, RequirementType, RewardType, TierChances, WeeklyReward, QuestTemplateType} from '@/views/Quests.vue';
import BigNumber from 'bignumber.js';
// import Web3 from 'web3';
import {abi as erc20Abi} from '@/../../build/contracts/ERC20.json';
import {IERC721, ERC20} from '@/../../build/abi-interfaces';

import {abi as erc721Abi} from '@/../../build/contracts/IERC721.json';

import {Dispatch} from 'vuex';
import { getGasPrice } from '../store';


const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });


const quests = {
  actions: {
    async getQuestDeadline({rootState}: {rootState: IState}, {questID}: {questID: number}) {
      const {SimpleQuests} = rootState.contracts();
      if(!SimpleQuests || !rootState.defaultAccount) return;

      return await SimpleQuests.methods.questDeadlines(questID).call(defaultCallOptions(rootState));
    },

    async getQuestSupply({rootState}: {rootState: IState}, {questID}: {questID: number}){
      const {SimpleQuests} = rootState.contracts();
      if(!SimpleQuests || !rootState.defaultAccount) return;

      return await SimpleQuests.methods.questSupplies(questID).call(defaultCallOptions(rootState));
    },

    async getQuestTemplates({rootState, dispatch}: {rootState: IState, dispatch: Dispatch}, {tier}: {tier: number}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const questTemplates: Quest[] = [];

      const questTemplatesIds = await SimpleQuests.methods.getQuestTemplates(tier).call(defaultCallOptions(rootState));

      if(questTemplatesIds.length === 0) return questTemplates;

      interface QuestTemplate {
        progress: string | number;
        id: string;
        tier: string;
        requirementType: string;
        requirementRarity: string;
        requirementAmount: string;
        requirementExternalAddress: string;
        rewardType: string;
        rewardRarity: string;
        rewardAmount: string;
        rewardExternalAddress: string;
        reputationAmount: string;
      }

      const quests = await Promise.all<QuestTemplate>(questTemplatesIds.map(questID =>
        SimpleQuests.methods.quests(questID).call(defaultCallOptions(rootState)) as unknown as QuestTemplate));

      for (const quest of quests) {
        if (tier >= 30 && tier < 40) {
          quest.progress = await dispatch('getWalletQuestProgress', {questID: +quest.id});
        }
        const emptyAccount = '0x0000000000000000000000000000000000000000';
        if(quest.requirementExternalAddress !== emptyAccount
          && ((quest.requirementType && +quest.requirementType as RequirementType === RequirementType.EXTERNAL)
            || (quest.requirementType && +quest.requirementType as RequirementType === RequirementType.EXTERNAL_HOLD))) {
          const currencyContract = new rootState.web3.eth.Contract(erc20Abi as any[], quest.requirementExternalAddress);
          try{
            const currencyDecimals = await currencyContract.methods.decimals().call(defaultCallOptions(rootState));
            quest.requirementAmount = new BigNumber(quest.requirementAmount).div(new BigNumber(10 ** currencyDecimals)).toFixed();
            quest.progress = new BigNumber(quest.progress).div(new BigNumber(10 ** currencyDecimals)).toFixed();
          } catch {
            // Contract does not support decimals
          }
        }

        if(quest.rewardExternalAddress !== emptyAccount
          && +quest.rewardType as RewardType === RewardType.EXTERNAL) {
          const currencyContract = new rootState.web3.eth.Contract(erc20Abi as any[], quest.rewardExternalAddress);
          try{
            const currencyDecimals = await currencyContract.methods.decimals().call(defaultCallOptions(rootState));
            quest.rewardAmount = new BigNumber(quest.rewardAmount).div(new BigNumber(10 ** currencyDecimals)).toFixed();
          } catch {
            // Contract does not support decimals
          }
        }
        const questTemplate = {
          progress: +quest.progress,
          id: +quest.id,
          tier: +quest.tier as Rarity,
          requirementType: +quest.requirementType as RequirementType,
          requirementRarity: +quest.requirementRarity as Rarity,
          requirementAmount: +quest.requirementAmount,
          requirementExternalAddress: quest.requirementExternalAddress,
          rewardType: +quest.rewardType as RewardType,
          rewardRarity: +quest.rewardRarity as Rarity,
          rewardAmount: +quest.rewardAmount,
          rewardExternalAddress: quest.rewardExternalAddress,
          reputationAmount: +quest.reputationAmount,
        } as Quest;
        questTemplates.push(questTemplate);
      }

      return questTemplates;
    },

    async addQuestTemplate(
      { rootState }: {rootState: IState},
      {questTemplate, tierOffset, supply, deadline}: {questTemplate: Quest, tierOffset: number, supply: number, deadline: number}){
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const emptyAccount = '0x0000000000000000000000000000000000000000';

      if (!questTemplate.requirementExternalAddress) {
        questTemplate.requirementExternalAddress = emptyAccount;
      }

      if (!questTemplate.rewardExternalAddress) {
        questTemplate.rewardExternalAddress = emptyAccount;
      }

      let requirementAmount: string | number = questTemplate.requirementAmount;

      if(questTemplate.requirementType === RequirementType.EXTERNAL){
        const contract = new rootState.web3.eth.Contract(erc20Abi as any[], questTemplate.requirementExternalAddress);
        try {
          const currencyDecimals = await contract.methods.decimals().call(defaultCallOptions(rootState));
          requirementAmount = new BigNumber(requirementAmount).multipliedBy(new BigNumber(10 ** currencyDecimals)).toString();
        } catch {
          // Contract does not support decimals
        }
      }

      let rewardAmount: string | number = questTemplate.rewardAmount;

      if(questTemplate.rewardType === RewardType.EXTERNAL){
        const contract = new rootState.web3.eth.Contract(erc20Abi as any[], questTemplate.rewardExternalAddress);
        try {
          const currencyDecimals = await contract.methods.decimals().call(defaultCallOptions(rootState));
          rewardAmount = new BigNumber(rewardAmount).multipliedBy(new BigNumber(10 ** currencyDecimals)).toString();
        } catch {
          // Contract does not support decimals
        }
      }

      const tier = questTemplate.tier! + tierOffset;
      return await SimpleQuests.methods.addNewQuestTemplate(tier!,
        questTemplate.requirementType!, questTemplate.requirementRarity!, requirementAmount, questTemplate.requirementExternalAddress,
        questTemplate.rewardType!, questTemplate.rewardRarity!, rewardAmount, questTemplate.rewardExternalAddress,
        questTemplate.reputationAmount, supply, deadline).send(defaultCallOptions(rootState));
    },

    async deleteQuest({ rootState }: {rootState: IState}, {tier, questID}: {tier: number, questID: number}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      return await SimpleQuests.methods.deleteQuestTemplate(tier, questID).send(defaultCallOptions(rootState));
    },

    async getCharacterQuestData({ rootState }: {rootState: IState}, {characterId}: {characterId: number}) {
      const { SimpleQuests } = rootState.contracts();
      if(!SimpleQuests || !rootState.defaultAccount) return;

      const questID = await SimpleQuests.methods.characterQuest(characterId).call(defaultCallOptions(rootState));


      const quest = await SimpleQuests.methods.quests(questID).call(defaultCallOptions(rootState)) as unknown as {
        progress: string | number;
        id: string;
        tier: string;
        requirementType: string;
        requirementRarity: string;
        requirementAmount: string;
        requirementExternalAddress: string;
        rewardType: string;
        rewardRarity: string;
        rewardAmount: string;
        rewardExternalAddress: string;
        reputationAmount: string;
      };

      const charQuestDataRaw = await SimpleQuests.methods.getCharacterQuestData(characterId).call(defaultCallOptions(rootState));
      const emptyAccount = '0x0000000000000000000000000000000000000000';
      quest.progress = +charQuestDataRaw[0];
      if(quest.requirementExternalAddress !== emptyAccount
        && ((quest.requirementType && +quest.requirementType as RequirementType === RequirementType.EXTERNAL)
          || (quest.requirementType && +quest.requirementType as RequirementType === RequirementType.EXTERNAL_HOLD))) {
        const currencyContract = new rootState.web3.eth.Contract(erc20Abi as any[], quest.requirementExternalAddress);
        try{
          const currencyDecimals = await currencyContract.methods.decimals().call(defaultCallOptions(rootState));
          quest.requirementAmount = new BigNumber(quest.requirementAmount).div(new BigNumber(10 ** currencyDecimals)).toFixed();
          quest.progress = new BigNumber(quest.progress).div(new BigNumber(10 ** currencyDecimals)).toFixed();
        } catch {
          // Contract does not support decimals
        }
      }

      if(quest.rewardExternalAddress !== emptyAccount
        && +quest.rewardType as RewardType === RewardType.EXTERNAL) {
        const currencyContract = new rootState.web3.eth.Contract(erc20Abi as any[], quest.rewardExternalAddress);
        try{
          const currencyDecimals = await currencyContract.methods.decimals().call(defaultCallOptions(rootState));
          quest.rewardAmount = new BigNumber(quest.rewardAmount).div(new BigNumber(10 ** currencyDecimals)).toFixed();
        } catch {
          // Contract does not support decimals
        }
      }

      return {
        progress: +quest.progress,
        type: +charQuestDataRaw[3] as QuestTemplateType,
        reputation: +charQuestDataRaw[2],
        id: +quest.id,
        tier: +quest.tier as Rarity,
        requirementType: +quest.requirementType as RequirementType,
        requirementRarity: +quest.requirementRarity as Rarity,
        requirementAmount: +quest.requirementAmount,
        requirementExternalAddress: quest.requirementExternalAddress,
        rewardType: +quest.rewardType as RewardType,
        rewardRarity: +quest.rewardRarity as Rarity,
        rewardAmount: +quest.rewardAmount,
        rewardExternalAddress: quest.rewardExternalAddress,
        reputationAmount: +quest.reputationAmount,
      } as Quest;
    },

    async getQuestTierChances({ rootState }: {rootState: IState}, {tier}: {tier: number}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const tierChancesRaw = await SimpleQuests.methods.getTierChances(tier).call(defaultCallOptions(rootState));
      const legendary = 100 - +tierChancesRaw[3];
      const epic = 100 - +tierChancesRaw[2] - legendary;
      const rare = 100 - +tierChancesRaw[1] - epic - legendary;
      const uncommon = 100 - +tierChancesRaw[0] - rare - epic - legendary;
      const common = 100 - uncommon - rare - epic - legendary;
      return {common, uncommon, rare, epic, legendary} as TierChances;
    },

    async setQuestTierChances({ rootState }: {rootState: IState}, {tier, tierChances}: {tier: number, tierChances: TierChances}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const uncommon = String(100 - tierChances.uncommon - tierChances.rare - tierChances.epic - tierChances.legendary);
      const rare = String(100 - tierChances.rare - tierChances.epic - tierChances.legendary);
      const epic = String(100 - tierChances.epic - tierChances.legendary);
      const legendary = String(100 - tierChances.legendary);

      return await SimpleQuests.methods.setTierChances(tier, [uncommon, rare, epic, legendary]).send(defaultCallOptions(rootState));
    },

    async setSkipQuestStaminaCost({ rootState }: {rootState: IState}, {staminaCost}: {staminaCost: number}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const VAR_SKIP_QUEST_STAMINA_COST = await SimpleQuests.methods.VAR_SKIP_QUEST_STAMINA_COST().call(defaultCallOptions(rootState));

      return await SimpleQuests.methods.setVar(VAR_SKIP_QUEST_STAMINA_COST, staminaCost).send(defaultCallOptions(rootState));
    },

    async getSkipQuestStaminaCost({ rootState }: {rootState: IState}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const VAR_SKIP_QUEST_STAMINA_COST = await SimpleQuests.methods.VAR_SKIP_QUEST_STAMINA_COST().call(defaultCallOptions(rootState));

      return await SimpleQuests.methods.vars(VAR_SKIP_QUEST_STAMINA_COST).call(defaultCallOptions(rootState));
    },

    async getWeeklyCompletionsGoal({ rootState }: {rootState: IState}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const weekInSeconds = 604800;
      return await SimpleQuests.methods.weeklyCompletionsGoal(Math.floor(Date.now() / 1000 / weekInSeconds % 53)).call(defaultCallOptions(rootState));
    },

    async setWeeklyReward({ rootState }: {rootState: IState}, {weeklyReward}: {weeklyReward: WeeklyReward}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const emptyAccount = '0x0000000000000000000000000000000000000000';
      if (!weeklyReward.rewardExternalAddress) {
        weeklyReward.rewardExternalAddress = emptyAccount;
      }

      const result =await SimpleQuests.methods.setWeeklyReward(weeklyReward.rewardType,
        weeklyReward.rewardRarity, weeklyReward.rewardAmount,
        weeklyReward.rewardExternalAddress, weeklyReward.reputationAmount,
        weeklyReward.weekNumber, weeklyReward.completionsGoal)
        .send(defaultCallOptions(rootState));

      return result.events.RewardAdded.returnValues.rewardID;
    },

    async getWeeklyReward({ rootState }: {rootState: IState}, {timestamp}: {timestamp: number}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const weekInSeconds = 604800;
      const week = Math.floor(timestamp / 1000 / weekInSeconds % 53) + 1;

      const weeklyRewardRaw = await SimpleQuests.methods.rewards(week).call(defaultCallOptions(rootState)) as unknown as {
        id: string;
        rewardType: string;
        rewardRarity: string;
        rewardAmount: string;
        rewardExternalAddress: string;
        reputationAmount: string;
      };

      const weeklyCompletionsGoal = +await SimpleQuests.methods.weeklyCompletionsGoal(week).call(defaultCallOptions(rootState));
      return {
        id: +weeklyRewardRaw.id,
        rewardType: +weeklyRewardRaw.rewardType as RewardType,
        rewardRarity: +weeklyRewardRaw.rewardRarity as Rarity,
        rewardAmount: +weeklyRewardRaw.rewardAmount,
        rewardExternalAddress: weeklyRewardRaw.rewardExternalAddress,
        reputationAmount: +weeklyRewardRaw.reputationAmount,
        completionsGoal: weeklyCompletionsGoal,
      } as WeeklyReward;
    },

    async claimWeeklyReward({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const weekInSeconds = 604800;
      const currentWeek = Math.floor(Date.now() / 1000 / weekInSeconds);

      const reward = await SimpleQuests.methods.rewards(Math.floor(currentWeek % 53) + 1).call(defaultCallOptions(rootState));
      const rewardID = +reward[0];

      if(rewardID === 0) {
        return;
      }

      if (!await SimpleQuests.methods.hasRandomWeeklyRewardSeedRequested(rewardID).call(defaultCallOptions(rootState))) {
        await SimpleQuests.methods.generateRewardWeeklySeed(rewardID).send(defaultCallOptions(rootState));
      }
      const result = await SimpleQuests.methods.claimWeeklyReward().send(defaultCallOptions(rootState));

      const questRewards = result.events.WeeklyRewardClaimed.returnValues.rewards;
      await Promise.all([
        dispatch('updateWeaponIds'),
        dispatch('updateShieldIds'),
        dispatch('updateTrinketIds'),
        dispatch('updateJunkIds'),
        dispatch('updateKeyLootboxIds'),
      ]);
      return questRewards;
    },

    async hasClaimedWeeklyReward({ rootState }: {rootState: IState}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const weekInSeconds = 604800;
      const currentWeek = Math.floor(Date.now() / 1000 / weekInSeconds);

      const rewardID = +await SimpleQuests.methods.rewards(Math.floor(currentWeek % 53)).call(defaultCallOptions(rootState));

      if(rewardID === 0) {
        return false;
      }

      return await SimpleQuests.methods.weeklyRewardClaimed(rootState.defaultAccount, currentWeek).call(defaultCallOptions(rootState));
    },

    async getReputationLevelRequirements({rootState}: { rootState: IState }) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const [
        VAR_REPUTATION_LEVEL_2,
        VAR_REPUTATION_LEVEL_3,
        VAR_REPUTATION_LEVEL_4,
        VAR_REPUTATION_LEVEL_5,
      ] = await Promise.all([
        SimpleQuests.methods.VAR_REPUTATION_LEVEL_2().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_REPUTATION_LEVEL_3().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_REPUTATION_LEVEL_4().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_REPUTATION_LEVEL_5().call(defaultCallOptions(rootState)),
      ]);


      const requirementsRaw = await SimpleQuests.methods.getVars([
        VAR_REPUTATION_LEVEL_2,
        VAR_REPUTATION_LEVEL_3,
        VAR_REPUTATION_LEVEL_4,
        VAR_REPUTATION_LEVEL_5,
      ]).call(defaultCallOptions(rootState));
      return {
        level2: +requirementsRaw[0],
        level3: +requirementsRaw[1],
        level4: +requirementsRaw[2],
        level5: +requirementsRaw[3]
      } as ReputationLevelRequirements;
    },

    async setReputationLevelRequirements({ rootState }: {rootState: IState}, {requirements}: {requirements: string[]}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const [
        VAR_REPUTATION_LEVEL_2,
        VAR_REPUTATION_LEVEL_3,
        VAR_REPUTATION_LEVEL_4,
        VAR_REPUTATION_LEVEL_5,
      ] = await Promise.all([
        SimpleQuests.methods.VAR_REPUTATION_LEVEL_2().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_REPUTATION_LEVEL_3().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_REPUTATION_LEVEL_4().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_REPUTATION_LEVEL_5().call(defaultCallOptions(rootState)),
      ]);

      return await SimpleQuests.methods.setVars([
        VAR_REPUTATION_LEVEL_2,
        VAR_REPUTATION_LEVEL_3,
        VAR_REPUTATION_LEVEL_4,
        VAR_REPUTATION_LEVEL_5,
      ], requirements).send(defaultCallOptions(rootState));
    },

    async isUsingPromoQuests({rootState}: { rootState: IState }) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const [
        VAR_COMMON_TIER,
        VAR_UNCOMMON_TIER,
        VAR_RARE_TIER,
        VAR_EPIC_TIER,
        VAR_LEGENDARY_TIER,
      ] = await Promise.all([
        SimpleQuests.methods.VAR_COMMON_TIER().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_UNCOMMON_TIER().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_RARE_TIER().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_EPIC_TIER().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_LEGENDARY_TIER().call(defaultCallOptions(rootState)),
      ]);

      const tiersRaw = await SimpleQuests.methods.getVars([
        VAR_COMMON_TIER,
        VAR_UNCOMMON_TIER,
        VAR_RARE_TIER,
        VAR_EPIC_TIER,
        VAR_LEGENDARY_TIER,
      ]).call(defaultCallOptions(rootState));

      return !(+tiersRaw[0] === 0 && +tiersRaw[1] === 1 && +tiersRaw[2] === 2 && +tiersRaw[3] === 3 && +tiersRaw[4] === 4);
    },

    async toggleUsePromoQuests({ rootState }: {rootState: IState}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      const [
        VAR_COMMON_TIER,
        VAR_UNCOMMON_TIER,
        VAR_RARE_TIER,
        VAR_EPIC_TIER,
        VAR_LEGENDARY_TIER,
      ] = await Promise.all([
        SimpleQuests.methods.VAR_COMMON_TIER().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_UNCOMMON_TIER().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_RARE_TIER().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_EPIC_TIER().call(defaultCallOptions(rootState)),
        SimpleQuests.methods.VAR_LEGENDARY_TIER().call(defaultCallOptions(rootState)),
      ]);

      const tiersRaw = await SimpleQuests.methods.getVars([
        VAR_COMMON_TIER,
        VAR_UNCOMMON_TIER,
        VAR_RARE_TIER,
        VAR_EPIC_TIER,
        VAR_LEGENDARY_TIER,
      ]).call(defaultCallOptions(rootState));

      if(+tiersRaw[0] === 0 && +tiersRaw[1] === 1 && +tiersRaw[2] === 2 && +tiersRaw[3] === 3 && +tiersRaw[4] === 4) {
        return await SimpleQuests.methods.setVars([
          VAR_COMMON_TIER,
          VAR_UNCOMMON_TIER,
          VAR_RARE_TIER,
          VAR_EPIC_TIER,
          VAR_LEGENDARY_TIER,
        ], ['10', '11', '12', '13', '14']).send(defaultCallOptions(rootState));
      } else {
        return await SimpleQuests.methods.setVars([
          VAR_COMMON_TIER,
          VAR_UNCOMMON_TIER,
          VAR_RARE_TIER,
          VAR_EPIC_TIER,
          VAR_LEGENDARY_TIER,
        ], ['0', '1', '2', '3', '4']).send(defaultCallOptions(rootState));
      }
    },

    async hasStaminaToSkipQuest({ rootState }: {rootState: IState}, {characterID}: {characterID: number}) {
      const {SimpleQuests, Characters} = rootState.contracts();
      if (!SimpleQuests || !Characters || !rootState.defaultAccount) return;

      const VAR_SKIP_QUEST_STAMINA_COST = await SimpleQuests.methods.VAR_SKIP_QUEST_STAMINA_COST().call(defaultCallOptions(rootState));
      const staminaPoints = +await Characters.methods.getStaminaPoints(characterID).call(defaultCallOptions(rootState));
      const staminaCost = +await SimpleQuests.methods.vars(VAR_SKIP_QUEST_STAMINA_COST).call(defaultCallOptions(rootState));

      return staminaPoints >= staminaCost;
    },

    async hasFreeSkip({ rootState }: {rootState: IState}, {characterID}: {characterID: number}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      return await SimpleQuests.methods.hasFreeSkip(characterID).call(defaultCallOptions(rootState));
    },

    async nextFreeSkip({ rootState }: {rootState: IState}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      return await SimpleQuests.methods.nextFreeSkip().call(defaultCallOptions(rootState));
    },

    async nextWeeklyQuestCompletionGoalReset({ rootState }: {rootState: IState}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      return await SimpleQuests.methods.nextWeeklyQuestCompletionGoalReset().call(defaultCallOptions(rootState));
    },

    async getWeeklyCompletions({ rootState }: {rootState: IState}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      return await SimpleQuests.methods.getWeeklyCompletions(rootState.defaultAccount).call(defaultCallOptions(rootState));
    },

    async skipQuest(
      { rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
      {characterID, pickedQuestID}: {characterID: number, pickedQuestID: number}) {
      const { SimpleQuests } = rootState.contracts();
      if(!SimpleQuests || !rootState.defaultAccount) return;
      await SimpleQuests.methods.skipQuest(characterID, pickedQuestID).send(defaultCallOptions(rootState));
      await dispatch('combat/fetchCharacterStamina', characterID);
    },

    async completeQuest(
      { rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
      {characterID, pickedQuestID}: {characterID: number, pickedQuestID: number}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      if (!await SimpleQuests.methods.hasRandomQuestRewardSeedRequested(characterID).call(defaultCallOptions(rootState))) {
        await SimpleQuests.methods.generateRewardQuestSeed(characterID).send(defaultCallOptions(rootState));
      }
      const result = await SimpleQuests.methods.completeQuest(characterID, pickedQuestID).send(defaultCallOptions(rootState));

      const questRewards = result.events.QuestRewarded.returnValues.rewards;
      await Promise.all([
        dispatch('fetchCharacter', {characterId: characterID}),
        dispatch('updateWeaponIds'),
        dispatch('updateShieldIds'),
        dispatch('updateTrinketIds'),
        dispatch('updateJunkIds'),
        dispatch('updateKeyLootboxIds'),
        dispatch('fetchDustBalance'),
        dispatch('combat/fetchCharacterStamina', characterID),
        dispatch('fetchGenesisSoulBalance'),
        dispatch('updateCharacterIds'),
      ]);
      return questRewards;
    },

    async requestQuest({ rootState }: {rootState: IState}, {characterID}: {characterID: number}) {
      const { SimpleQuests } = rootState.contracts();
      if(!SimpleQuests || !rootState.defaultAccount) return;

      if (!await SimpleQuests.methods.hasRandomQuestSeedRequested(characterID).call(defaultCallOptions(rootState))) {
        await SimpleQuests.methods.generateRequestQuestSeed(characterID).send(defaultCallOptions(rootState));
      }

      return await SimpleQuests.methods.requestQuest(characterID).send(defaultCallOptions(rootState));
    },

    async submitProgress({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, {characterID, tokenIds}: {characterID: number, tokenIds: string[]}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      await SimpleQuests.methods.submitProgress(characterID, tokenIds).send(defaultCallOptions(rootState));

      await Promise.all([
        dispatch('updateWeaponIds'),
        dispatch('updateShieldIds'),
        dispatch('updateTrinketIds'),
        dispatch('updateJunkIds'),
        dispatch('updateKeyLootboxIds'),
      ]);
    },

    async submitProgressAmount({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, {characterID, amount}: {characterID: number, amount: number}) {
      const {SimpleQuests} = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      await SimpleQuests.methods.submitProgressAmount(characterID, amount).send(defaultCallOptions(rootState));
      await Promise.all([
        dispatch('combat/fetchCharacterStamina', characterID),
        dispatch('fetchGenesisSoulBalance', characterID),
        dispatch('fetchDustBalance'),
      ]);
    },

    async submitExternalProgress(
      { rootState }: {rootState: IState},
      {characterID, tokenIds, tokenAddress}: {characterID: number, tokenIds: string[], tokenAddress: string}) {
      const {SimpleQuests, PartnerVault} = rootState.contracts();
      if (!SimpleQuests || !PartnerVault || !rootState.defaultAccount) return;

      const tokenContract = new rootState.web3.eth.Contract(erc721Abi as any[], tokenAddress) as Contract<IERC721>;

      const isApprovedForAll = await tokenContract.methods.isApprovedForAll(rootState.defaultAccount, SimpleQuests.options.address)
        .call(defaultCallOptions(rootState));

      if(tokenIds.length === 1 && !isApprovedForAll) {
        await tokenContract.methods.approve(PartnerVault.options.address, tokenIds[0]).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice()
        });
      } else if (!isApprovedForAll) {
        await tokenContract.methods.setApprovalForAll(PartnerVault.options.address, true).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice()
        });
      }

      return await SimpleQuests.methods.submitProgress(characterID, tokenIds).send(defaultCallOptions(rootState));
    },

    async submitExternalProgressAmount(
      { rootState }: {rootState: IState},
      {characterID, amount, currencyAddress}: {characterID: number, amount: number, currencyAddress: string}) {
      const {SimpleQuests, PartnerVault} = rootState.contracts();
      if (!SimpleQuests || !PartnerVault || !rootState.defaultAccount) return;

      const currencyContract = new rootState.web3.eth.Contract(erc20Abi as any[], currencyAddress) as Contract<ERC20>;
      const currencyDecimals = +await currencyContract.methods.decimals().call(defaultCallOptions(rootState));
      const amountTimesDecimals = new BigNumber(amount).multipliedBy(new BigNumber(10 ** currencyDecimals));
      await currencyContract.methods.approve(PartnerVault.options.address, amountTimesDecimals.toString()).send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice()
      });

      return await SimpleQuests.methods.submitProgressAmount(characterID, amountTimesDecimals.toString()).send(defaultCallOptions(rootState));
    },
    async getWalletQuestProgress({ rootState }: {rootState: IState}, {questID}: {questID: number}) {
      const { SimpleQuests } = rootState.contracts();
      if (!SimpleQuests || !rootState.defaultAccount) return;

      return +await SimpleQuests.methods.walletQuestProgress(rootState.defaultAccount, questID).call(defaultCallOptions(rootState));
    },
    async submitWalletProgress(
      { rootState }: {rootState: IState}, {questID, tokenIds}: {questID: number, tokenIds: string[]}) {
      const { SimpleQuests } = rootState.contracts();
      if(!SimpleQuests || !rootState.defaultAccount) return;

      return await SimpleQuests.methods.submitWalletProgress(questID, tokenIds).send(defaultCallOptions(rootState));
    },

    async submitWalletExternalProgress(
      { rootState }: {rootState: IState}, {questID, tokenIds, tokenAddress}: {questID: number, tokenIds: string[], tokenAddress: string}) {
      const {SimpleQuests, PartnerVault} = rootState.contracts();
      if (!SimpleQuests || !PartnerVault || !rootState.defaultAccount) return;

      const tokenContract = new rootState.web3.eth.Contract(erc721Abi as any[], tokenAddress) as Contract<IERC721>;

      const isApprovedForAll = await tokenContract.methods.isApprovedForAll(rootState.defaultAccount, SimpleQuests.options.address)
        .call(defaultCallOptions(rootState));

      if(tokenIds.length === 1 && !isApprovedForAll) {
        await tokenContract.methods.approve(PartnerVault.options.address, tokenIds[0]).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice()
        });
      } else if (!isApprovedForAll) {
        await tokenContract.methods.setApprovalForAll(PartnerVault.options.address, true).send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice()
        });
      }

      return await SimpleQuests.methods.submitWalletProgress(questID, tokenIds).send(defaultCallOptions(rootState));
    },

    async submitWalletProgressAmount(
      { rootState }: {rootState: IState}, {questID, amount}: {questID: number, amount: number}) {
      const { SimpleQuests } = rootState.contracts();
      if(!SimpleQuests || !rootState.defaultAccount) return;

      return await SimpleQuests.methods.submitWalletProgressAmount(questID, amount).send(defaultCallOptions(rootState));
    },

    async submitWalletExternalProgressAmount(
      { rootState }: {rootState: IState}, {questID, amount, currencyAddress}: {questID: number, amount: number, currencyAddress: string}) {
      const {SimpleQuests, PartnerVault} = rootState.contracts();
      if (!SimpleQuests || !PartnerVault || !rootState.defaultAccount) return;

      const currencyContract = new rootState.web3.eth.Contract(erc20Abi as any[], currencyAddress) as Contract<ERC20>;
      const currencyDecimals = +await currencyContract.methods.decimals().call(defaultCallOptions(rootState));
      const amountTimesDecimals = new BigNumber(amount).multipliedBy(new BigNumber(10 ** currencyDecimals));
      await currencyContract.methods.approve(PartnerVault.options.address, amountTimesDecimals.toString()).send({
        from: rootState.defaultAccount,
        gasPrice: getGasPrice()
      });

      return await SimpleQuests.methods.submitWalletProgressAmount(questID, amountTimesDecimals.toString()).send(defaultCallOptions(rootState));
    },
    async completeWalletQuest({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, {questID}: {questID: number}) {
      const { SimpleQuests } = rootState.contracts();
      if(!SimpleQuests || !rootState.defaultAccount) return;

      const result = await SimpleQuests.methods.completeWalletQuest(questID).send(defaultCallOptions(rootState));

      const questRewards = result.events.WalletQuestRewarded.returnValues.rewards;
      await Promise.all([
        dispatch('updateWeaponIds'),
        dispatch('updateShieldIds'),
        dispatch('updateTrinketIds'),
        dispatch('updateJunkIds'),
        dispatch('updateKeyLootboxIds'),
        dispatch('fetchDustBalance'),
        dispatch('fetchGenesisSoulBalance'),
        dispatch('updateCharacterIds'),
      ]);
      return questRewards;
    },
    async requestPickableQuest({ rootState }: {rootState: IState}, {characterID, questID}: {characterID: number, questID: number}) {
      const { SimpleQuests } = rootState.contracts();
      if(!SimpleQuests || !rootState.defaultAccount) return;
      return await SimpleQuests.methods.requestPickableQuest(characterID, questID).send(defaultCallOptions(rootState));
    }
  },
};


export default quests;
