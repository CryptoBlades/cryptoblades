<template>
  <b-modal v-if="quest" class="centered-modal" v-model="showModal" button-size="lg" no-close-on-backdrop scrollable
           :title="'Turn-in'" size="xl" @close="weaponsToBurn = []" @cancel="weaponsToBurn = []" :ok-title="'Submit'"
           @ok="submit">
    <div class="d-flex">
      <weapon-grid v-model="burnWeaponId" :weaponIds="ownedWeapons" :ignore="weaponsToBurn"
                   :showGivenWeaponIds="true" @chooseweapon="addBurnWeapon"
                   :starsOptions="[quest.requirementRarity + 1]"/>
      <weapon-grid :weaponIds="weaponsToBurn" :showGivenWeaponIds="true" @chooseweapon="removeBurnWeapon"
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
  ownedWeapons: string[];
  weaponsToBurn: string[];
  burnWeaponId: number | undefined;
}

export default Vue.extend({
  components: {WeaponGrid},

  props: {},

  data() {
    return {
      quest: undefined,
      characterId: '',
      showModal: false,
      ownedWeapons: [],
      weaponsToBurn: [],
      burnWeaponId: undefined,
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

    addBurnWeapon(id: number) {
      this.weaponsToBurn.push(id.toString());
      this.ownedWeapons = this.ownedWeapons.filter(val => !this.weaponsToBurn.includes(val));
      this.burnWeaponId = undefined;
    },

    removeBurnWeapon(id: number) {
      this.ownedWeapons.push(id.toString());
      this.weaponsToBurn = this.weaponsToBurn.filter(x => x !== id.toString());
    },

    async submit() {
      await this.submitProgress({characterID: this.characterId, tokenIds: this.weaponsToBurn});
    }
  },

  async mounted() {
    this.$root.$on('quest-submission-modal', (quest: Quest, characterId: string | number) => {
      if (quest) {
        this.quest = quest;
        this.characterId = characterId;
        this.showModal = true;
        this.ownedWeapons = this.ownedWeaponIds;
      } else {
        this.showModal = false;
        this.ownedWeapons = this.ownedWeaponIds;
      }
    });
  }
});
</script>

<style scoped>
</style>
