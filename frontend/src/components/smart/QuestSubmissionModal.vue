<template>
  <b-modal v-if="quest" class="centered-modal" v-model="showModal" button-size="lg" no-close-on-backdrop scrollable
           :title="$t('quests.turnIn')" size="xl" @close="resetTokens" @cancel="resetTokens"
           :ok-title="$t('quests.submit')" :ok-disabled="isLoading"
           @ok.prevent="quest.requirementType === RequirementType.DUST ? submitDust() : submit()">
    <div v-if="quest.requirementType === RequirementType.WEAPON" class="d-flex">
      <weapon-grid v-model="selectedToken" :weaponIds="ownedTokens" :ignore="tokensToBurn"
                   :showGivenWeaponIds="true" @chooseweapon="addBurnToken"
                   :starsOptions="[quest.requirementRarity + 1]" :canFavorite="false"/>
      <weapon-grid :weaponIds="tokensToBurn" :showGivenWeaponIds="true" @chooseweapon="removeBurnToken"
                   :starsOptions="[quest.requirementRarity + 1]" :canFavorite="false"/>
    </div>
    <div v-else-if="quest.requirementType === RequirementType.DUST" class="d-flex align-items-center flex-column">
      <dust-balance-display class="w-50 p-5" :rarities="[quest.requirementRarity]"/>
      <h2>{{ $t('quests.howMuchToTurnIn') }}</h2>
      <b-form-input type="number" v-model="dustToBurn" class="w-50" :min="0" :max="maxDust()"/>
      <b-button class="m-3" variant="primary" @click="setRequiredDust">{{ $t('quests.setRequiredAmount') }}</b-button>
    </div>
    <div v-else class="d-flex">
      <nft-list v-model="selectedToken" :showGivenNftIdTypes="true" :nftIdTypes="ownedNftIdTypes"
                @choosenft="addNftIdType" :starsOptions="[quest.requirementRarity + 1]"
                :typesOptions="[upperFirstChar(RequirementType[quest.requirementType])]"/>
      <nft-list :showGivenNftIdTypes="true" :nftIdTypes="nftIdTypesToBurn" @choosenft="removeNftIdType"
                :starsOptions="[quest.requirementRarity + 1]"
                :typesOptions="[upperFirstChar(RequirementType[quest.requirementType])]"/>
    </div>
  </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import WeaponGrid from '@/components/smart/WeaponGrid.vue';
import {mapActions, mapGetters, mapState} from 'vuex';
import NftList, {NftIdType} from '@/components/smart/NftList.vue';
import {Quest, Rarity, RequirementType, RewardType} from '@/views/Quests.vue';
import Events from '@/events';
import DustBalanceDisplay from '@/components/smart/DustBalanceDisplay.vue';

interface StoreMappedActions {
  submitProgress(payload: { characterID: string | number, tokenIds: (string | number)[] }): Promise<void>;

  submitDustProgress(payload: { characterID: string | number, amount: string | number }): Promise<void>;
}

interface Data {
  quest?: Quest;
  characterId: number | string;
  questProgress: number;
  showModal: boolean;
  ownedTokens: string[];
  tokensToBurn: (string | number)[];
  ownedNftIdTypes: NftIdType[];
  nftIdTypesToBurn: NftIdType[];
  dustToBurn: number;
  selectedToken?: number;
  isLoading: boolean;
}

export default Vue.extend({
  components: {WeaponGrid, NftList, DustBalanceDisplay},

  data() {
    return {
      characterId: '',
      questProgress: 0,
      showModal: false,
      ownedTokens: [],
      tokensToBurn: [],
      ownedNftIdTypes: [],
      nftIdTypesToBurn: [],
      dustToBurn: 0,
      isLoading: false,
      RequirementType,
      RewardType,
      Rarity,
    } as Data;
  },


  computed: {
    ...mapState(['ownedWeaponIds', 'ownedTrinketIds', 'ownedJunkIds', 'ownedShieldIds']),
    ...mapGetters(['getPowerfulDust', 'getGreaterDust', 'getLesserDust']),
  },

  methods: {
    ...mapActions(['submitProgress', 'submitDustProgress']) as StoreMappedActions,

    upperFirstChar(text: string) {
      return text[0].toUpperCase() + text.slice(1).toLowerCase();
    },

    maxDust() {
      if (this.quest?.requirementRarity === Rarity.COMMON) {
        return this.getLesserDust();
      } else if (this.quest?.requirementRarity === Rarity.UNCOMMON) {
        return this.getGreaterDust();
      } else if (this.quest?.requirementRarity === Rarity.RARE) {
        return this.getPowerfulDust();
      } else return 0;
    },

    setRequiredDust() {
      if (!this.quest) return;
      this.dustToBurn = this.quest.requirementAmount - this.questProgress;
    },

    addBurnToken(id: number) {
      this.tokensToBurn.push(id.toString());
      this.ownedTokens = this.ownedTokens.filter(val => !this.tokensToBurn.includes(val.toString()));
      this.selectedToken = undefined;
    },

    removeBurnToken(id: number) {
      this.ownedTokens.push(id.toString());
      this.tokensToBurn = this.tokensToBurn.filter(x => x !== id.toString());
    },

    addNftIdType(nftIdType: NftIdType) {
      this.nftIdTypesToBurn.push(nftIdType);
      this.ownedNftIdTypes = this.ownedNftIdTypes.filter(val => !this.nftIdTypesToBurn.some(nftToBurn => nftToBurn.id === val.id));
      this.tokensToBurn = this.nftIdTypesToBurn.map(nftIdType => nftIdType.id);
      this.selectedToken = undefined;
    },

    removeNftIdType(nftIdType: NftIdType) {
      this.ownedNftIdTypes.push(nftIdType);
      this.nftIdTypesToBurn = this.nftIdTypesToBurn.filter(x => x.id !== nftIdType.id);
      this.tokensToBurn = this.nftIdTypesToBurn.map(nftIdType => nftIdType.id);
    },

    async submit() {
      try {
        this.isLoading = true;
        await this.submitProgress({characterID: this.characterId, tokenIds: this.tokensToBurn});
      } finally {
        this.resetTokens();
        Events.$emit('refresh-quest-data');
        this.showModal = false;
        this.isLoading = false;
      }
    },

    async submitDust() {
      try {
        this.isLoading = true;
        await this.submitDustProgress({characterID: this.characterId, amount: this.dustToBurn});
      } finally {
        this.resetTokens();
        Events.$emit('refresh-quest-data');
        this.showModal = false;
        this.isLoading = false;
      }
    },

    resetTokens() {
      this.ownedTokens = [];
      this.ownedNftIdTypes = [];
      this.tokensToBurn = [];
      this.nftIdTypesToBurn = [];
      this.dustToBurn = 0;
    }
  },

  async mounted() {
    this.$root.$on('quest-submission-modal', (quest: Quest, characterId: string | number, questProgress: number) => {
      if (quest) {
        this.quest = quest;
        this.characterId = characterId;
        this.questProgress = questProgress;
        this.showModal = true;
        if (this.quest.requirementType === RequirementType.WEAPON) {
          this.ownedTokens = this.ownedWeaponIds;
        } else if (this.quest.requirementType === RequirementType.JUNK) {
          this.ownedTokens = this.ownedJunkIds;
          this.ownedJunkIds?.forEach((id: string) => this.ownedNftIdTypes.push({id, type: 'junk'}));
        } else if (this.quest.requirementType === RequirementType.TRINKET) {
          this.ownedTokens = this.ownedTrinketIds;
          this.ownedTrinketIds?.forEach((id: string) => this.ownedNftIdTypes.push({id, type: 'trinket'}));
        } else if (this.quest.requirementType === RequirementType.SHIELD) {
          this.ownedTokens = this.ownedShieldIds;
          this.ownedShieldIds?.forEach((id: string) => this.ownedNftIdTypes.push({id, type: 'shield'}));
        }
      } else {
        this.showModal = false;
        this.resetTokens();
      }
    });
  }
});
</script>

<style scoped>
</style>
