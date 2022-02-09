<template>
  <b-modal v-if="quest" class="centered-modal" v-model="showModal" button-size="lg" no-close-on-backdrop scrollable
           :title="$t('quests.turnIn')" size="xl" @close="resetTokens" @cancel="resetTokens"
           :ok-title="$t('quests.submit')" :busy="isLoading"
           :ok-disabled="isSubmitDisabled()"
           @ok.prevent="quest.requirementType === RequirementType.DUST
           || quest.requirementType === RequirementType.STAMINA
           || quest.requirementType === RequirementType.SOUL ? submitAmount() : submit()">
    <div v-if="quest.requirementType === RequirementType.WEAPON" class="d-flex">
      <weapon-grid v-model="selectedToken" :weaponIds="ownedTokens" :ignore="tokensToBurn"
                   showGivenWeaponIds @chooseweapon="addBurnToken"
                   :starsOptions="[quest.requirementRarity + 1]" :canFavorite="false"/>
      <weapon-grid :weaponIds="tokensToBurn" showGivenWeaponIds @chooseweapon="removeBurnToken"
                   :starsOptions="[quest.requirementRarity + 1]" :canFavorite="false"/>
    </div>
    <div
      v-else-if="quest.requirementType === RequirementType.DUST
      || quest.requirementType === RequirementType.STAMINA
       || quest.requirementType === RequirementType.SOUL"
      class="d-flex align-items-center flex-column">
      <dust-balance-display v-if="quest.requirementType === RequirementType.DUST" class="w-50 p-5"
                            :rarities="[quest.requirementRarity]"/>
      <nft-icon v-else-if="quest.requirementType === RequirementType.SOUL" :isDefault="true" :nft="{ type: 'soul' }"/>
      <h2>{{ $t('quests.howMuchToTurnIn') }}</h2>
      <b-form-input type="number" number v-model="amountToBurn" class="w-50" :min="0" :max="maxAmount()"/>
      <b-button class="m-3" variant="primary" @click="setRequiredAmount">{{ $t('quests.setRequiredAmount') }}</b-button>
    </div>
    <div v-else class="d-flex">
      <nft-list v-model="selectedToken" showGivenNftIdTypes :nftIdTypes="ownedNftIdTypes"
                @choosenft="addNftIdType" :starsOptions="[quest.requirementRarity + 1]"
                :typesOptions="[upperFirstChar(RequirementType[quest.requirementType])]"/>
      <nft-list showGivenNftIdTypes :nftIdTypes="nftIdTypesToBurn" @choosenft="removeNftIdType"
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
import NftIcon from '@/components/NftIcon.vue';

interface StoreMappedActions {
  submitProgress(payload: { characterID: string | number, tokenIds: (string | number)[] }): Promise<void>;

  submitProgressAmount(payload: { characterID: string | number, amount: number }): Promise<void>;

  fetchSoulBalance(): Promise<number>;
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
  amountToBurn: number;
  selectedToken?: number;
  isLoading: boolean;
  soulBalance: number;
}

export default Vue.extend({
  components: {WeaponGrid, NftList, DustBalanceDisplay, NftIcon},

  data() {
    return {
      quest: undefined,
      characterId: '',
      questProgress: 0,
      showModal: false,
      ownedTokens: [],
      tokensToBurn: [],
      ownedNftIdTypes: [],
      nftIdTypesToBurn: [],
      amountToBurn: 0,
      selectedToken: undefined,
      isLoading: false,
      soulBalance: 0,
      RequirementType,
      RewardType,
      Rarity,
    } as Data;
  },


  computed: {
    ...mapState(['ownedWeaponIds', 'ownedTrinketIds', 'ownedJunkIds', 'ownedShieldIds']),
    ...mapGetters(['getPowerfulDust', 'getGreaterDust', 'getLesserDust', 'getCharacterStamina']),
  },

  methods: {
    ...mapActions(['submitProgress', 'submitProgressAmount', 'fetchSoulBalance']) as StoreMappedActions,

    upperFirstChar(text: string) {
      return text[0].toUpperCase() + text.slice(1).toLowerCase();
    },

    maxAmount() {
      if (!this.quest) return 0;
      if (this.quest.requirementType === RequirementType.DUST) {
        if (this.quest.requirementRarity === Rarity.COMMON) {
          return this.getLesserDust();
        } else if (this.quest.requirementRarity === Rarity.UNCOMMON) {
          return this.getGreaterDust();
        } else if (this.quest.requirementRarity === Rarity.RARE) {
          return this.getPowerfulDust();
        } else return 0;
      } else if (this.quest.requirementType === RequirementType.STAMINA) {
        return this.getCharacterStamina(this.characterId);
      } else if (this.quest.requirementType === RequirementType.SOUL) {
        return this.soulBalance;
      }

    },

    setRequiredAmount() {
      if (!this.quest) return;
      this.amountToBurn = this.quest.requirementAmount - this.questProgress;
    },

    addBurnToken(id: number) {
      if (!this.quest) return;
      if (this.questProgress + this.tokensToBurn.length >= this.quest.requirementAmount) return;
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

    async submitAmount() {
      if (!this.quest) return;
      try {
        this.isLoading = true;
        await this.submitProgressAmount({characterID: this.characterId, amount: this.amountToBurn});
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
      this.amountToBurn = 0;
    },

    isSubmitDisabled() {
      return !this.quest
        || (this.quest.requirementType === RequirementType.DUST && this.amountToBurn === 0)
        || (this.quest.requirementType === RequirementType.STAMINA && this.amountToBurn === 0)
        || (this.quest.requirementType === RequirementType.SOUL && this.amountToBurn === 0)
        || (this.quest.requirementType === RequirementType.WEAPON && this.tokensToBurn.length === 0)
        || (this.quest.requirementType !== RequirementType.DUST
          && this.quest.requirementType !== RequirementType.WEAPON
          && this.quest.requirementType !== RequirementType.STAMINA
          && this.quest.requirementType !== RequirementType.SOUL
          && this.nftIdTypesToBurn.length === 0);
    }
  },

  mounted() {
    Events.$on('quest-submission-modal', async (quest: Quest, characterId: string | number, questProgress: number) => {
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
        } else if (this.quest.requirementType === RequirementType.SOUL) {
          this.soulBalance = await this.fetchSoulBalance();
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
