<template>
  <b-modal v-if="quest" class="centered-modal" v-model="showModal" button-size="lg" no-close-on-backdrop scrollable
           :title="'Turn-in'" size="xl" @close="resetTokens" @cancel="resetTokens" :ok-title="'Submit'"
           @ok="submit">
    <div v-if="quest.requirementType === RequirementType.WEAPON" class="d-flex">
      <weapon-grid v-model="selectedToken" :weaponIds="ownedTokens" :ignore="tokensToBurn"
                   :showGivenWeaponIds="true" @chooseweapon="addBurnToken"
                   :starsOptions="[quest.requirementRarity + 1]"/>
      <weapon-grid :weaponIds="tokensToBurn" :showGivenWeaponIds="true" @chooseweapon="removeBurnToken"
                   :starsOptions="[quest.requirementRarity + 1]"/>
    </div>
    <div v-else-if="quest.requirementType === RequirementType.JUNK" class="d-flex">
      <nft-list v-model="selectedToken" :showGivenNftIdTypes="true" :nftIdTypes="ownedNftIdTypes"
                @choosenft="addNftIdType"/>
      <nft-list :showGivenNftIdTypes="true" :nftIdTypes="nftIdTypesToBurn" @choosenft="removeNftIdType"/>
    </div>
  </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import {Quest, Rarity, RequirementType, RewardType} from '@/components/smart/QuestDetails.vue';
import WeaponGrid from '@/components/smart/WeaponGrid.vue';
import {mapActions, mapState} from 'vuex';
import NftList, {NftIdType} from '@/components/smart/NftList.vue';

interface StoreMappedActions {
  submitProgress(payload: { characterID: string | number, tokenIds: (string | number)[] }): Promise<void>;
}

interface Data {
  quest: Quest | undefined;
  characterId: number | string;
  showModal: boolean;
  ownedTokens: string[];
  tokensToBurn: string[];
  ownedNftIdTypes: NftIdType[];
  nftIdTypesToBurn: NftIdType[];
  selectedToken: number | undefined;
}

export default Vue.extend({
  components: {WeaponGrid, NftList},

  props: {},

  data() {
    return {
      quest: undefined,
      characterId: '',
      showModal: false,
      ownedTokens: [],
      tokensToBurn: [],
      ownedNftIdTypes: [],
      nftIdTypesToBurn: [],
      selectedToken: undefined,
      RequirementType,
      RewardType,
      Rarity,
    } as Data;
  },


  computed: {
    ...mapState(['ownedWeaponIds', 'ownedTrinketIds', 'ownedJunkIds']),
  },

  methods: {
    ...mapActions(['submitProgress']) as StoreMappedActions,

    addBurnToken(id: number) {
      this.tokensToBurn.push(id.toString());
      this.ownedTokens = this.ownedTokens.filter(val => !this.tokensToBurn.includes(val));
      this.selectedToken = undefined;
    },

    removeBurnToken(id: number) {
      this.ownedTokens.push(id.toString());
      this.tokensToBurn = this.tokensToBurn.filter(x => x !== id.toString());
    },

    addNftIdType(nftIdType: NftIdType) {
      console.log(nftIdType);
      this.nftIdTypesToBurn.push(nftIdType);
      this.ownedNftIdTypes = this.ownedNftIdTypes.filter(val => !this.nftIdTypesToBurn.some(nftToBurn => nftToBurn.id === val.id));
      this.selectedToken = undefined;
    },

    removeNftIdType(nftIdType: NftIdType) {
      console.log(nftIdType);
      this.ownedNftIdTypes.push(nftIdType);
      this.nftIdTypesToBurn = this.nftIdTypesToBurn.filter(x => x.id !== nftIdType.id);
    },

    async submit() {
      await this.submitProgress({characterID: this.characterId, tokenIds: this.tokensToBurn});
      this.tokensToBurn = [];
    },

    resetTokens() {
      this.ownedTokens = [];
      this.ownedNftIdTypes = [];
      this.tokensToBurn = [];
      this.nftIdTypesToBurn = [];
    }
  },

  async mounted() {
    this.$root.$on('quest-submission-modal', (quest: Quest, characterId: string | number) => {
      if (quest) {
        this.quest = quest;
        this.characterId = characterId;
        this.showModal = true;
        if (this.quest.requirementType === RequirementType.WEAPON) {
          this.ownedTokens = this.ownedWeaponIds;
        } else if (this.quest.requirementType === RequirementType.JUNK) {
          this.ownedTokens = this.ownedJunkIds;
          this.ownedJunkIds?.forEach((id: string) => this.ownedNftIdTypes.push({id, type: 'junk'}));
        } else if (this.quest.requirementType === RequirementType.TRINKET) {
          this.ownedTokens = this.ownedTrinketIds;
          this.ownedTrinketIds?.forEach((id: string) => this.ownedNftIdTypes.push({id, type: 'trinket'}));
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
