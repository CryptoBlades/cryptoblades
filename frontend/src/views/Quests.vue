<template>
  <div class="position-relative quest-wrapper">
    <div class="quest-nav">
      <QuestNav
        :activeTab="activeTab"
        @toggle="onChangeTab"
      />
    </div>
    <div class="d-flex flex-wrap quests-container gap-4">
      <div class="d-flex justify-content-between w-100 weekly-progress-container">
        <div class="d-flex flex-column justify-content-between gap-2">
          <span class="quests-title">{{ $t('quests.quest') }}</span>
        </div>
        <div v-if="weeklyReward && weeklyReward.id && currentWeeklyCompletions !== undefined && weeklyReward.completionsGoal"
            class="d-flex flex-column justify-content-between gap-2 align-items-end">
          <div class="d-flex align-items-center gap-2 flex-wrap">
            <div class="d-flex flex-column justify-content-between gap-2">
              <div class="d-flex justify-content-between gap-4 flex-wrap ">
                <span class="text-uppercase weekly-progress">{{ $t('quests.weeklyProgress') }}</span>
                <span v-if="nextWeekResetTime" class="next-reset"><img :src="hourglass" class="hourglass-icon"
                                                                      alt="Hourglass"/> {{
                    $t('quests.resetsIn', {time: nextWeekResetTime})
                  }}</span>
              </div>
              <div class="quest-progress w-100">
                <div class="quest-progress-bar" role="progressbar"
                    :style="`width: calc(${currentWeeklyCompletions/weeklyReward.completionsGoal*100}% - 8px);`"
                    :aria-valuenow="currentWeeklyCompletions"
                    aria-valuemin="0" :aria-valuemax="weeklyReward.completionsGoal">
                </div>
                <span v-if="currentWeeklyCompletions <= weeklyReward.completionsGoal"
                      class="quest-progress-value">{{ `${currentWeeklyCompletions} / ${weeklyReward.completionsGoal}` }}</span>
              </div>
            </div>
            <div class="d-flex justify-content-center align-items-center gap-2 position-relative">

            <!-- incoming: <div class="d-flex justify-content-center align-items-center gap-2 mx-auto mt-3"> -->
              <span v-if="weeklyClaimed" class="claimed-banner">{{ $t('quests.claimed') }}</span>
              <QuestComponentIcon :questItemType="weeklyReward.rewardType" :rarity="weeklyReward.rewardRarity"
                                  :amount="weeklyReward.rewardAmount"
                                  :externalAddress="weeklyReward.rewardExternalAddress"/>
              <QuestComponentIcon v-if="weeklyReward.reputationAmount !== 0" :questItemType="QuestItemType.REPUTATION"
                                  :amount="weeklyReward.reputationAmount"/>
            </div>
          </div>
          <cb-button class="top-button" v-if="!weeklyClaimed"
          :isDisabled="isLoading || !canClaimWeeklyReward" @clickEvent="claimWeekly"
            :toolTip="!canClaimWeeklyReward ? $t('quests.cannotClaimWeeklyTooltip') : ''" :title="$t('quests.claimWeeklyReward')"></cb-button>
        </div>
      </div>
      <div class="character-quests-container">
        <div v-if="activeTab === 'character-quests'">
          <div>
            <span class="quests-title-2">Next Quest Type</span>
          </div>
          <b-form-checkbox size="lg" :checked="pickable" @change="pickable=!pickable" switch>
            <b class="float-left">{{ pickable ? 'Special' : 'Random' }}</b>
          </b-form-checkbox>
        </div>
        <div v-if="pickable" ok-only class="centered-modal flex-wrap" size="xl" title="Pick your Quest">
          <div v-if="isLoading">
            <i class="fas fa-spinner fa-spin"/>
            {{ $t('quests.loading') }}
          </div>
          <div>
            <b-form inline>
              <label class="mr-sm-2">Special Quest Tier</label>
              <b-form-select class="mt-2 mb-2" v-model="pickableQuestTier">
                <b-form-select-option v-for="tier in rarities" :key="tier" :value="tier">
                  {{ $t(`quests.rarityType.${Rarity[tier]}`) }}
                </b-form-select-option>
              </b-form-select>
            </b-form>
              <div v-if="isLoading">
                <i class="fas fa-spinner fa-spin"/>
                {{ $t('quests.loading') }}
              </div>
              <h3 v-else-if="quests.length === 0">
                {{ $t('quests.noQuestTemplatesInSelectedTier') }} </h3>
                <!-- TEST -->
              <div v-else class="d-flex flex-row flex-wrap gap-3">
                <div v-for="(quest, index) in quests" :key="quest.id" class="quest-row quest-row-special p-3 gap-5">
                  <QuestRequirements :quest="quest" :index="index"/>
                  <QuestRewards :quest="quest"/>
                  <b-form-radio class="flex-1 custom-action-btn gap-2 p-2"
                    v-model="pickedQuestId" :value="quest.id">{{ $t('quests.setAsNextQuest') }}</b-form-radio>
                  <!-- <div class="pickBtn-wrapper">
                    <b-button class="flex-1 custom-action-btn" variant="primary">
                      @click="handlePick(quest.id)"
                      {{pickButtonLabel}}
                    </b-button>
                  </div> -->
                </div>
              </div>
              <!-- TEST -->
          </div>
        </div>
        <div v-if="activeTab === 'character-quests'" class="character-quests-content">
          <span class="quests-title-2">Character Quests</span>
          <div v-if="isLoading">
            <i class="fas fa-spinner fa-spin"/>
            {{ $t('quests.loading') }}
          </div>
          <div v-if="characters.length !== 0 && !isLoading" class="d-flex flex-wrap flex-row w-100">
            <div v-for="character in characters" :key="character.id" class="my-3 mr-3">
              <QuestRow :questTemplateType="QuestTemplateType.QUEST" :characterId="character.id"
                        :reputationLevelRequirements="reputationLevelRequirements"
                        :pickable="pickable" :pickedQuestId="pickedQuestId" @refresh-quest-data="onRefreshQuestData"/>
            </div>
            <br>
            <b-modal v-model="showWeeklyClaimedModal" ok-only class="centered-modal" :title="$t('quests.weeklyReward')">
              <div v-if="isLoading">
                <i class="fas fa-spinner fa-spin"/>
                {{ $t('quests.loading') }}
              </div>
              <QuestReward v-else :type="weeklyReward.rewardType" :rarity="weeklyReward.rewardRarity"
                          :rewards="weeklyRewards"
                          :amount="weeklyReward.rewardAmount" :reputationAmount="weeklyReward.reputationAmount"
                          :externalAddress="weeklyReward.rewardExternalAddress"/>
            </b-modal>
          </div>
          <div v-else class="m-4 font-weight-bold w-100">
          {{ $t('quests.youNeedToHaveAtLeastOneCharacter') }}.<br>
          {{ $t('combat.recruitAtPlaza') }}
          </div>
        </div>
      </div>
      <div v-if="activeTab === 'wallet-quests'" class="wallet-quests-content">
        <span v-if="walletQuests && walletQuests.length" class="quests-title-2">Wallet Quests</span>
        <!-- TODO: This will come back when we add additional tiers to Wallet Quests -->
        <!--      <div class="form-control-wrapper">-->
        <!--        <select class="form-control" v-model="walletQuestTier" >-->
        <!--              <option :value="undefined">Select a Rarity</option>-->
        <!--          <option v-for="x in rarities" :value="x" :key="x">{{$t(`quests.rarityType.${Rarity[x]}`)}}</option>-->
        <!--        </select>-->
        <!--      </div>-->
        <div v-if="isLoadingWalletQuests">
          <i class="fas fa-spinner fa-spin"/>
          {{ $t('quests.loading') }}
        </div>
        <div v-else class="d-flex flex-wrap">
          <div v-for="quest in walletQuests" :key="quest.id" class="d-flex my-3 mr-3">
            <QuestRow :quest="quest" :questTemplateType="QuestTemplateType.WALLET"
                      :reputationLevelRequirements="reputationLevelRequirements"
                      @refresh-quest-data="onRefreshQuestData"/>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions, mapGetters, mapState} from 'vuex';
import {Nft} from '@/interfaces/Nft';
import {Accessors} from 'vue/types/options';
import QuestRow from '@/components/smart/QuestRow.vue';
import QuestComponentIcon from '@/components/smart/QuestComponentIcon.vue';
import QuestReward from '@/components/smart/QuestReward.vue';
// import QuestsList from '@/components/smart/QuestsList.vue';
import QuestRequirements from '@/components/smart/QuestRequirements.vue';
import QuestRewards from '@/components/smart/QuestRewards.vue';
import hourglass from '@/assets/hourglass.png';
import {getTimeRemaining} from '@/utils/common';
import {NftIdType} from '@/components/smart/NftList.vue';
import QuestNav from '@/components/QuestNav.vue';
import {
  Quest,
  QuestTemplateType,
  Rarity,
  ReputationLevelRequirements,
  WeeklyReward,
  QuestItemType,
  RewardType } from '@/interfaces';

interface StoreMappedActions {
  fetchCharacters(characterIds: (string | number)[]): Promise<void>;

  getCharacterQuestData(payload: { characterId: string | number }): Promise<Quest>;

  getReputationLevelRequirements(): Promise<ReputationLevelRequirements>;

  nextWeeklyQuestCompletionGoalReset(): Promise<string>;

  getWeeklyCompletions(): Promise<number>;

  getWeeklyReward(payload: { timestamp: number }): Promise<WeeklyReward>;

  hasClaimedWeeklyReward(): Promise<boolean>;

  claimWeeklyReward(): Promise<number[]>;

  isUsingPromoQuests(): Promise<boolean>;

  getQuestTemplates(payload: { tier: number }): Promise<Quest[]>;
}

interface StoreMappedGetters {
  charactersWithIds(ids: (string | number)[]): Nft[];
}

interface Data {
  weeklyReward?: WeeklyReward;
  characters: Nft[];
  reputationLevelRequirements?: ReputationLevelRequirements;
  weeklyClaimed: boolean;
  showWeeklyClaimedModal: boolean;
  weeklyRewards: NftIdType[];
  isLoading: boolean;
  isLoadingWalletQuests: boolean;
  nextWeekResetTime: string;
  nextWeekResetCheckInterval?: ReturnType<typeof setInterval>;
  currentWeeklyCompletions: number;
  showQuestsListModal: boolean;
  rarities: Rarity[];
  tier?: Rarity;
  usePromoQuests: boolean;
  questTemplateType: QuestTemplateType;
  walletQuests: Quest[];
  walletQuestTier: Rarity;
  activeTab: string;
  pickableQuestTier?: Rarity;
  quests: Quest[];
  pickable: boolean;
  pickedQuestId: number;
}

export default Vue.extend({
  components: {
    QuestRow,
    QuestComponentIcon,
    QuestReward,
    QuestNav,
    QuestRequirements,
    QuestRewards,
  },

  props: {
    showCosmetics: {
      type: Boolean,
      default: true
    },
  },

  data() {
    return {
      weeklyReward: undefined,
      characters: [],
      reputationLevelRequirements: undefined,
      weeklyRewards: [],
      weeklyClaimed: true,
      showWeeklyClaimedModal: false,
      isLoading: false,
      isLoadingWalletQuests: false,
      nextWeekResetTime: '',
      currentWeeklyCompletions: 0,
      showQuestsListModal: false,
      rarities: [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY],
      tier: undefined,
      usePromoQuests: false,
      hourglass,
      QuestItemType,
      Rarity,
      QuestTemplateType,
      questTemplateType: QuestTemplateType.QUEST,
      walletQuests:[],
      walletQuestTier: 0,
      activeTab: 'wallet-quests',
      pickableQuestTier: Rarity.COMMON,
      quests: [],
      pickable: false,
      pickedQuestId: 0,
    } as Data;
  },

  computed: {
    ...mapState(['ownedCharacterIds']),
    ...mapGetters(['charactersWithIds', 'getCharacterCosmetic']) as Accessors<StoreMappedGetters>,

    canClaimWeeklyReward(): boolean {
      return !!this.weeklyReward && !this.weeklyClaimed && this.weeklyGoalReached;
    },

    weeklyGoalReached(): boolean {
      return this.currentWeeklyCompletions >= this.weeklyReward?.completionsGoal!;
    },

    tierOffset(): number {
      switch(this.questTemplateType){
      default:
        return 0;
      case QuestTemplateType.PROMO:
        return 10;
      case QuestTemplateType.PICKABLE:
        return 20;
      case QuestTemplateType.WALLET:
        return 30;
      }
    },
  },

  methods: {
    ...mapActions([
      'fetchCharacters',
      'getCharacterQuestData',
      'getReputationLevelRequirements',
      'nextWeeklyQuestCompletionGoalReset',
      'getWeeklyCompletions',
      'getWeeklyReward',
      'hasClaimedWeeklyReward',
      'claimWeeklyReward',
      'isUsingPromoQuests',
      'getQuestTemplates'
    ]) as StoreMappedActions,

    onChangeTab(tab: string) {
      this.activeTab = tab;
    },

    async fetchPickableQuests() {
      try {
        this.isLoading = true;
        this.quests = await this.getQuestTemplates({tier: this.pickableQuestTier! + 20});
      } finally {
        this.isLoading = false;
      }
    },

    // async handlePick(questID: number) {
    //   try {
    //     this.isLoading = true;
    //     //this.pickedQuestID: questID
    //     // if(this.actionAfterPick === ActionAfterPick.COMPLETE){
    //     //   await this.completeQuest({characterID: this.character.id, pickedQuestID: questID});
    //     // }
    //     // else if(this.actionAfterPick === ActionAfterPick.SKIP){
    //     //   await this.skipQuest({characterID: this.character.id, pickedQuestID: questID});
    //     // }
    //     // else if(this.actionAfterPick === ActionAfterPick.REQUEST){
    //     //   await this.requestPickableQuest({characterID: this.character.id, questID});
    //     // }
    //     //this.$emit('refresh-quest-data');
    //   } finally {
    //     this.isLoading = false;
    //     // this.$forceUpdate();
    //   }
    // },

    async claimWeekly() {
      if (!this.canClaimWeeklyReward) {
        return;
      }

      try {
        this.isLoading = true;
        const rewards = await this.claimWeeklyReward();
        const rewardType = this.weeklyReward?.rewardType;
        if (!rewardType || rewardType === RewardType.EXPERIENCE || rewardType === RewardType.DUST || rewardType === RewardType.SOUL) {
          this.showWeeklyClaimedModal = true;
          return;
        } else {
          this.weeklyRewards = rewards.map((reward: number) => {
            return {type: QuestItemType[rewardType].toLowerCase(), id: reward} as NftIdType;
          });
          this.weeklyClaimed = true;
          this.showWeeklyClaimedModal = true;
        }
      } finally {
        await this.refreshQuestData();
        this.isLoading = false;
      }
    },

    async refreshQuestData() {
      try {
        this.isLoading = true;
        this.isLoadingWalletQuests = true;
        this.walletQuests = await this.getQuestTemplates({tier: this.walletQuestTier + 30});
        this.isLoadingWalletQuests = false;
        const [
          usePromoQuests,
          currentWeeklyCompletions,
          weeklyReward,
          weeklyClaimed,
          reputationLevelRequirements,
          characters,
        ] = await Promise.all([
          this.isUsingPromoQuests(),
          this.getWeeklyCompletions(),
          this.getWeeklyReward({timestamp: Date.now()}),
          this.hasClaimedWeeklyReward(),
          this.getReputationLevelRequirements(),
          Promise.all(this.charactersWithIds(this.ownedCharacterIds).filter(Boolean).map(async (character) => {
            character.quest = await this.getCharacterQuestData({characterId: character.id});
            return character;
          })),
          this.getNextWeekResetTime(),
        ]);
        this.usePromoQuests = usePromoQuests;
        this.currentWeeklyCompletions = +currentWeeklyCompletions;
        this.weeklyReward = weeklyReward;
        this.weeklyClaimed = weeklyClaimed;
        this.reputationLevelRequirements = reputationLevelRequirements;
        this.characters = characters;
      } finally {
        this.isLoading = false;
      }
    },

    async getNextWeekResetTime() {
      const nextWeekResetTimestamp = await this.nextWeeklyQuestCompletionGoalReset();
      if (this.nextWeekResetCheckInterval) {
        clearInterval(this.nextWeekResetCheckInterval);
      }
      this.nextWeekResetCheckInterval = setInterval(async () => {
        const {total, days, hours, minutes, seconds} = getTimeRemaining(nextWeekResetTimestamp);
        this.nextWeekResetTime = `${days}d ${hours}h ${minutes}m ${seconds}s`;
        if (total <= 1000 && this.nextWeekResetCheckInterval) {
          clearInterval(this.nextWeekResetCheckInterval);
          this.currentWeeklyCompletions = +await this.getWeeklyCompletions();
          this.weeklyReward = await this.getWeeklyReward({timestamp: Date.now()});
          this.weeklyClaimed = await this.hasClaimedWeeklyReward();
        }
      }, 1000);
    },

    async onRefreshQuestData() {
      await this.refreshQuestData();
    },
  },

  async mounted() {
    await this.refreshQuestData();
  },

  beforeDestroy() {
    if (this.nextWeekResetCheckInterval) {
      clearInterval(this.nextWeekResetCheckInterval);
    }
  },

  watch: {
    async defaultAccount(){
      await this.refreshQuestData();
    },
    async ownedCharacterIds(characterIds) {
      await this.fetchCharacters(characterIds);
      await this.refreshQuestData();
    },
    async walletQuestTier() {
      this.walletQuests = [];
      this.isLoadingWalletQuests = true;
      this.walletQuests = await this.getQuestTemplates({tier: this.walletQuestTier+30});
      this.isLoadingWalletQuests = false;
    },
    pickableQuestTier(): void {
      this.fetchPickableQuests();
    },
    pickable(isPickable) {
      if (!isPickable) {
        this.pickedQuestId = 0;
      }
      else {
        this.fetchPickableQuests();
      }
    },
    activeTab(currentTab, previousTab) {
      if (currentTab !== 'character-quests' && previousTab && this.pickable) {
        this.pickable = false;
      }
    },
  },
});
</script>

<style scoped lang="scss">
@import '../styles/character-cosmetics.css';
.quest-nav{
  div.menu-nav{
    height: 60px;
    padding-left: 50px;
    padding-right: 50px;
    padding-top: 10px;
    padding-bottom: 10px;
    border-bottom: 1px solid #424A59;
    background-color:#000E29;
  }
}

.custom-action-btn{
  font-family: Roboto;
  background: transparent !important;
  border: #EDCD90 1px solid !important;
  color: #FFF !important;
  width: clamp(200px, 10vw, 250px);
  max-height: 50px;
  display: flex;
  justify-content: center;
}

// .character-quests-content > div:nth-child(2) {
//   flex-wrap: wrap;
// }

@media (max-width: 600px) {
  .quest-nav{
    padding: 0px;

    div.menu-nav{
      padding-left: 0px;
      padding-right: 0px;
      padding-top: 10px;
      padding-bottom: 10px;
      border-bottom: 1px solid #424A59;
      background-color:#000E29;
    }
  }
}

.quest-wrapper{
  background: transparent url("../../src/assets/questsBackground.png") 0 0 no-repeat padding-box;
  background-size: clamp(100%, 100%, 100%) auto;
}
.top-button{
  margin: 10px 0 !important;
  height: 75px !important; /* :'( */
}
.quests-container-wrapper{
  background-image: url('../../src/assets/questsBackground.png');
  background-repeat: no-repeat;
  background-size: clamp(100%, 100%, 100%) auto;
  background-position: center;
  min-height: 95vh;
  min-width: 100%;
  display: inline-flex;
  padding-top: 50px;
}
.quests-container{
  width: clamp(200px, 75vw, 2000px);
  margin: 0 auto;
  padding: 50px 0;
}

.quests-title {
  font-family: 'Trajan', serif;
  font-size: 35px;
  font-weight: 400;
  color: #EDCD90;
}
.quests-title-2 {
  font: normal normal bold 20px/28px Trajan;
  color: #DABE75;
  width: 100%;
  margin-top: 25px;
}
.form-control-wrapper{
  position: relative;
  width: 100%;
}

.form-control-wrapper > select{
  padding-right: 20px;
  text-align: right;
  width: 15%;
}

.form-control-wrapper > select{
  background-color: rgba(255, 255, 255, 0);
  color: #fff;
}

.form-control-wrapper > select option{
  background-color: #171617;
  padding: 1px;
  color: #fff;
  text-align: left;
}

.form-control-wrapper > select option:hover{
  box-shadow: 0 0 10px 100px #000 inset;
  padding: 1px;
  color: #fff;
}

.form-control-wrapper:after {
  content: attr(data-content);
  width: 0;
  height: 0;
  border-top: 6px solid #666;
  position: absolute;
  left: 8px;
  top: 2px;
  font-family: Roboto;
  color: rgba(255, 255, 255, 0.541);
}

.next-reset {
  font: normal normal normal 15px/17px Arial;
  color: #B4B0A7;
}

.hourglass-icon {
  height: 17px;
}

.weekly-progress {
  font: normal normal bold 16px/20px Trajan;
  color: #DABE75;
}

.quest-progress {
  height: 19px;
  background: #070707;
  border: 1px solid #403A2C;
  display: flex;
  align-items: center;
  position: relative;
}

.quest-progress .quest-progress-bar {
  background: #DABE75;
  height: 11px;
  margin: 4px;
}

.quest-progress-value {
  text-align: center;
  font: normal normal normal 10px/11px Arial;
  color: #FFFFFF;
  position: absolute;
  width: 100%;
  font-weight: bold;
  text-shadow: -1px 0 #000, 0 1px #000, 1px 0 #000, 0 -1px #000;
}

.claimed-banner {
  position: absolute;
  text-transform: uppercase;
  transform: rotate(15deg);
  font-weight: bold;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
}

.quest-row {
  display: flex;
  width: 100%;
  background: rgba(0, 9, 26, 0.65);
  border: 1px solid #404857;
  border-radius: 10px;
  align-items: center;
  font-family: Roboto;
  height: clamp(200px, 20vh, 250px);
  justify-content: space-between;
  margin: 10px 0;
  padding: 10px 30px;
}

@media (max-width: 576px) {
  .quest-row {
    flex-direction: column;
    height: auto;
    gap: 1rem;
  }
}

.quest-row-wrapper{
  width: 100%;
  display: flex;
  flex-direction: column;
}

.quest-row-wrapper > div{
  margin: 20px 0;
}

.quest-row-special {
    flex-direction: column;
    height: auto;
    gap: 1rem;
    width: initial;
  }

@media (max-width: 576px) {
  .quests-container {
    padding: 1rem;
    margin-bottom: 3rem;
    width: 100%;
  }

  .weekly-progress{
    margin: 0 auto;
  }

  .weekly-progress-container {
    flex-direction: column;
    gap: 2rem;
  }
}
</style>
