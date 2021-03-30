<template>
  <div class="body">
    <h1>Blacksmith</h1>

    <h2>Weapon to reforge:</h2>
    <weapon-grid v-model="reforgeWeaponId" />

    <h2>Weapon to burn:</h2>
    <weapon-grid v-model="burnWeaponId" />

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
      reforgeWeaponId: null,
      burnWeaponId: null,
    };
  },

  computed: {
    ...mapGetters(["ownWeapons"]),

    canReforge() {
      return (
        this.reforgeWeaponId == null ||
        this.burnWeaponId == null ||
        this.reforgeWeaponId === this.burnWeaponId
      );
    },
  },

  methods: {
    ...mapActions(["mintWeapon", "reforgeWeapon"]),

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
          burnWeaponId: this.burnWeaponId,
          reforgeWeaponId: this.reforgeWeaponId,
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
