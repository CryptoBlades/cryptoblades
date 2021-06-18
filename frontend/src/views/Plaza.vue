<template>
  <div class="body main-font">

    <div v-if="ownCharacters.length === 0" class="blank-slate">
      You do not have any characters.
      <br>
      You can recruit one by clicking the button below.
      <br>
      <br>
      <big-button
        class="button"
        mainText="Recruit character"
        @click="onMintCharacter"
      />
    </div>

    <div class="row mt-3" v-if="ownCharacters.length > 0">
      <div class="col">
        <div v-if="ownCharacters.length > 0">
          <div class="d-flex justify-content-space-between">
            <h1>Characters ({{ ownCharacters.length }} / 4)</h1>

            <b-button
              v-if="ownCharacters.length < 4"
              variant="primary"
              class="ml-auto"
              @click="onMintCharacter"
              v-tooltip="'Recruit new character'">
              Recruit ({{ recruitCost }} SKILL) <i class="fas fa-plus"></i>
            </b-button>
          </div>

          <character-list
            :value="currentCharacterId"
            @input="setCurrentCharacter"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import BN from 'bignumber.js';

import BigButton from '../components/BigButton.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';

export default {
  computed: {
    ...mapState(['characters', 'maxStamina', 'currentCharacterId', 'defaultAccount']),
    ...mapGetters([
      'contracts',
      'ownCharacters',
      'ownWeapons',
      'currentCharacter',
      'currentCharacterStamina',
      'getCharacterName',
    ]),

    character() {
      if (!this.currentCharacter) {
        return {
          id: null,
          name: '???',
          level: -1,
          experience: -1,
        };
      }

      const c = this.currentCharacter;
      return {
        id: c.id,
        name: this.getCharacterName(c.id),
        level: c.level,
        experience: c.xp,
      };
    },
  },

  async created() {
    const recruitCost = await this.contracts.CryptoBlades.methods.mintCharacterFee().call({ from: this.defaultAccount });
    const skillRecruitCost = await this.contracts.CryptoBlades.methods.usdToSkill(recruitCost).call();
    this.recruitCost = BN(skillRecruitCost).div(BN(10).pow(18)).toFixed(4);
  },

  data() {
    return {
      recruitCost: this.recruitCost
    };
  },

  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions(['mintCharacter']),

    async onMintCharacter() {
      try {
        await this.mintCharacter();
      } catch (e) {
        this.$dialog.alert('Could not mint character: insufficient funds or transaction denied.');
      }
    },
  },

  components: {
    BigButton,
    CharacterList,
  },
};
</script>

<style scoped>
</style>
