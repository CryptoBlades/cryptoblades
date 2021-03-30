<template>
  <div class="body">
    <h1>Blacksmith</h1>

    <h2>Weapon to reforge:</h2>
    <weapon-grid
      :weapons="ownWeapons"
      :selectedWeaponId="selectedWeaponIdForReforging"
      @select="selectWeaponForReforging"
    />
    <h2>Weapon to burn:</h2>
    <weapon-grid
      :weapons="ownWeapons"
      :selectedWeaponId="selectedWeaponIdForBurning"
      @select="selectWeaponForBurning"
    />

    <div class="button-row">
      <big-button
        class="button"
        mainText="Forge sword"
        subText="(1 loot)"
        @click="onForgeWeapon"
      />
      <big-button
        class="button"
        mainText="Reforge sword"
        subText="(+weapon xp sacrificing another)"
        :disabled="canReforge"
        @click="onReforgeWeapon"
      />
    </div>
  </div>
</template>

<script>
import WeaponGrid from "../components/WeaponGrid.vue";
import BigButton from "../components/BigButton.vue";
import { mapActions, mapGetters } from "vuex";

export default {
  data() {
    return {
      selectedWeaponIdForReforging: null,
      selectedWeaponIdForBurning: null,
    };
  },

  computed: {
    ...mapGetters(["ownWeapons"]),

    canReforge() {
      return (
        this.selectedWeaponIdForReforging == null ||
        this.selectedWeaponIdForBurning == null ||
        this.selectedWeaponIdForReforging === this.selectedWeaponIdForBurning
      );
    },
  },

  methods: {
    ...mapActions(["mintWeapon", "reforgeWeapon"]),

    selectWeaponForReforging(weapon) {
      if (this.selectedWeaponIdForReforging == weapon.id) {
        this.selectedWeaponIdForReforging = null;
        return;
      }

      this.selectedWeaponIdForReforging = weapon.id;
    },

    selectWeaponForBurning(weapon) {
      if (this.selectedWeaponIdForBurning == weapon.id) {
        this.selectedWeaponIdForBurning = null;
        return;
      }

      this.selectedWeaponIdForBurning = weapon.id;
    },

    async onForgeWeapon() {
      try {
        await this.mintWeapon();
      } catch (e) {
        console.error(e);
      }
    },

    async onReforgeWeapon() {
      try {
        await this.reforgeWeapon({
          burnWeaponId: this.selectedWeaponIdForBurning,
          reforgeWeaponId: this.selectedWeaponIdForReforging,
        });
      } catch (e) {
        console.error(e);
      }
    },
  },

  components: {
    WeaponGrid,
    BigButton,
  },
};
</script>

<style scoped>
.button-row {
  margin-top: 1em;
  display: flex;
}

.button + .button {
  margin-left: 1em;
}
</style>
