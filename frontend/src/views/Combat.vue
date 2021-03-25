<template>
  <div>
    <h1>Combat</h1>
    <h1 style="color: red" v-if="error != null">Error: {{ error }}</h1>
    <character-list
      :characters="characters"
      :selectedCharacterId="selectedCharacterId"
      @select="selectedCharacterId = $event.id"
    />
    <weapon-grid
      :weapons="weapons"
      :selectedWeaponId="selectedWeaponId"
      @select="selectedWeaponId = $event.id"
    />
    <ul class="encounter-list">
      <li v-for="(e, i) in targets" :key="i">
        <character />
        <big-button
          class="encounter-button"
          :mainText="`Monster with trait ${e.trait}`"
          :subText="`Power ${e.power}`"
          @click="onClickEncounter(i, e)"
        />
      </li>
    </ul>
  </div>
</template>

<script>
import Character from "../components/Character.vue";
import BigButton from "../components/BigButton.vue";
import CharacterList from "../components/CharacterList.vue";
import WeaponGrid from "../components/WeaponGrid.vue";

import { targetFromContract } from "../contract-models";

export default {
  props: ["weapons", "characters"],
  inject: ["web3", "contractProvider"],

  data() {
    return {
      selectedWeaponId: null,
      selectedCharacterId: null,
      targets: [],

      error: null,
    };
  },

  computed: {
    selections() {
      return [this.selectedCharacterId, this.selectedWeaponId];
    },
  },

  watch: {
    async selections([characterId, weaponId]) {
      await this.updateTargets(characterId, weaponId);
    },
  },

  methods: {
    async updateTargets(characterId, weaponId) {
      if (characterId == null || weaponId == null) {
        this.targets = [];
        return;
      }

      const targets = await this.contractProvider.CryptoBlades.methods
        .getTargets(characterId, weaponId)
        .call();

      this.targets = targets.map(targetFromContract);
    },

    async onClickEncounter(i, targetToFight) {
      if (this.selectedWeaponId == null || this.selectedCharacterId == null) {
        return;
      }

      try {
        const res = await this.contractProvider.CryptoBlades.methods
          .fight(
            this.selectedCharacterId,
            this.selectedWeaponId,
            targetToFight.original
          )
          .send({ from: this.web3.eth.defaultAccount });

        const {
          character,
          weapon,
          playerRoll,
          enemyRoll,
        } = res.events.FightOutcome.returnValues;

        if (parseInt(playerRoll, 10) >= parseInt(enemyRoll, 10)) {
          alert("Battle succeeded!");
        } else {
          alert("Battle failed...");
        }

        await this.updateTargets(character, weapon);
      } catch (e) {
        console.error(e);
        this.error = e.message;
      }
    },
  },

  created() {},

  components: {
    Character,
    BigButton,
    CharacterList,
    WeaponGrid,
  },
};
</script>

<style scoped>
.encounter-list {
  list-style-type: none;
  display: flex;
  margin: 0;
  padding: 0;
  justify-content: space-around;
}

.encounter-button {
  width: 8cm;
}
</style>
