<template>
  <b-modal v-if="quest" class="centered-modal" v-model="showModal" button-size="lg" no-close-on-backdrop scrollable
           :title="'Turn-in'" size="xl" @close="tokensToBurn = []" @cancel="tokensToBurn = []" :ok-title="'Submit'"
           @ok="submit">
    <div v-if="quest.requirementType === RequirementType.WEAPON" class="d-flex">
      <weapon-grid v-model="burnTokenId" :weaponIds="ownedTokens" :ignore="tokensToBurn"
                   :showGivenWeaponIds="true" @chooseweapon="addBurnToken"
                   :starsOptions="[quest.requirementRarity + 1]"/>
      <weapon-grid :weaponIds="tokensToBurn" :showGivenWeaponIds="true" @chooseweapon="removeBurnToken"
                   :starsOptions="[quest.requirementRarity + 1]"/>
    </div>
  </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import {Quest, Rarity, RequirementType, RewardType} from '@/components/smart/QuestDetails.vue';
import WeaponGrid from '@/components/smart/WeaponGrid.vue';
import {mapActions, mapState} from 'vuex';

interface StoreMappedActions {
  submitProgress(payload: { characterID: string | number, tokenIds: (string | number)[] }): Promise<void>;
}

interface Data {
  quest: Quest | undefined;
  characterId: number | string;
  showModal: boolean;
  ownedTokens: string[];
  tokensToBurn: string[];
  burnTokenId: number | undefined;
}

export default Vue.extend({
  components: {WeaponGrid},

  props: {},

  data() {
    return {
      quest: undefined,
      characterId: '',
      showModal: false,
      ownedTokens: [],
      tokensToBurn: [],
      burnTokenId: undefined,
      RequirementType,
      RewardType,
      Rarity,
    } as Data;
  },


  computed: {
    ...mapState(['ownedWeaponIds']),
  },

  methods: {
    ...mapActions(['submitProgress']) as StoreMappedActions,

    addBurnToken(id: number) {
      this.tokensToBurn.push(id.toString());
      this.ownedTokens = this.ownedTokens.filter(val => !this.tokensToBurn.includes(val));
      this.burnTokenId = undefined;
    },

    removeBurnToken(id: number) {
      this.ownedTokens.push(id.toString());
      this.tokensToBurn = this.tokensToBurn.filter(x => x !== id.toString());
    },

    async submit() {
      await this.submitProgress({characterID: this.characterId, tokenIds: this.tokensToBurn});
    }
  },

  async mounted() {
    this.$root.$on('quest-submission-modal', (quest: Quest, characterId: string | number) => {
      if (quest) {
        this.quest = quest;
        this.characterId = characterId;
        this.showModal = true;
        if(this.quest.requirementType === RequirementType.WEAPON) {
          this.ownedTokens = this.ownedWeaponIds;
        }
      } else {
        this.showModal = false;
        this.ownedTokens = [];
      }
    });
  }
});
</script>

<style scoped>
</style>
