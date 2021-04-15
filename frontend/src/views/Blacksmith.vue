<template>
  <div class="body main-font">
    <div v-if="ownWeapons.length > 0">
      <h1>Weapon to reforge:</h1>
      <weapon-grid v-model="reforgeWeaponId" />

      <h1>Weapon to burn:</h1>
      <weapon-grid v-model="burnWeaponId" />

      <div class="button-row">
        <big-button
          class="button"
          mainText="Forge sword"
          subText="(SKILL)"
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

    <div class="blank-slate" v-if="ownWeapons.length === 0">
      You do not currently have any weapons.
      <br>
      You can forge one by clicking the button below.
      <br>
      <br>
      <big-button
        class="button"
        mainText="Forge sword"
        @click="onForgeWeapon"
      />
    </div>
  </div>
</template>

<script>
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import BigButton from '../components/BigButton.vue';
import { mapActions, mapGetters } from 'vuex';

export default {
  data() {
    return {
      reforgeWeaponId: null,
      burnWeaponId: null,
    };
  },

  computed: {
    ...mapGetters(['ownWeapons']),

    canReforge() {
      return (
        this.reforgeWeaponId === null ||
        this.burnWeaponId === null ||
        this.reforgeWeaponId === this.burnWeaponId
      );
    },
  },

  methods: {
    ...mapActions(['mintWeapon', 'reforgeWeapon']),

    async onForgeWeapon() {
      try {
        await this.mintWeapon();
      } catch (e) {
        console.error(e);
        alert('Could not forge sword: insuffucient funds or transaction denied.');
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
        alert('Could not forge sword: insuffucient funds or transaction denied.');
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
