<template>
  <div>
    <h1>Combat</h1>
    <h1 style="color: red" v-if="error != null">Error: {{ error }}</h1>
    <character-list
      :characters="ownCharacters"
      :selectedCharacterId="selectedCharacterId"
      @select="selectedCharacterId = $event.id"
    />
    <weapon-grid
      :weapons="ownWeapons"
      :selectedWeaponId="selectedWeaponId"
      @select="selectedWeaponId = $event.id"
    />

    <ul class="encounter-list" v-if="targets.length > 0">
      <li v-for="(e, i) in targets" :key="i">
        <character />
        <big-button
          class="encounter-button"
          :mainText="`Monster with trait ${e.trait}`"
          :subText="`Power ${e.power}`"
          @click="onClickEncounter(e)"
        />
      </li>
    </ul>

    <p v-if="isLoadingTargets">Loading...</p>
  </div>
</template>

<script>
import Character from "../components/Character.vue";
import BigButton from "../components/BigButton.vue";
import CharacterList from "../components/CharacterList.vue";
import WeaponGrid from "../components/WeaponGrid.vue";

import { mapActions, mapGetters } from "vuex";

export default {
  data() {
    return {
      selectedWeaponId: null,
      selectedCharacterId: null,

      error: null,
    };
  },

  computed: {
    ...mapGetters([
      "getTargetsByCharacterIdAndWeaponId",
      "ownCharacters",
      "ownWeapons",
    ]),

    targets() {
      return this.getTargetsByCharacterIdAndWeaponId(
        this.selectedCharacterId,
        this.selectedWeaponId
      );
    },

    isLoadingTargets() {
      return (
        this.targets.length === 0 &&
        this.selectedCharacterId != null &&
        this.selectedWeaponId != null
      );
    },

    selections() {
      return [this.selectedCharacterId, this.selectedWeaponId];
    },
  },

  watch: {
    async selections([characterId, weaponId]) {
      await this.fetchTargets({ characterId, weaponId });
    },
  },

  methods: {
    ...mapActions(["fetchTargets", "doEncounter"]),

    async onClickEncounter(targetToFight) {
      if (this.selectedWeaponId == null || this.selectedCharacterId == null) {
        return;
      }

      try {
        const success = await this.doEncounter({
          characterId: this.selectedCharacterId,
          weaponId: this.selectedWeaponId,
          targetString: targetToFight.original,
        });

        if (success) {
          alert("Battle succeeded!");
        } else {
          alert("Battle failed...");
        }
        this.error = null;
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
