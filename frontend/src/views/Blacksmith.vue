<template>
  <div class="body main-font">
    <div v-if="ownWeapons.length > 0" class="weapon-container">
      <div class="sub-container">
        <h1>
          Weapons
          <button class="mint-weapon"
            @click="onForgeWeapon"
            v-tooltip="'Forge new weapon'">
            Forge <i class="fas fa-plus"></i>
          </button>
        </h1>

        <weapon-grid v-model="reforgeWeaponId" />

        <div class="button-row" v-if="reforgeWeaponId">
          <big-button
            class="button"
            mainText="Reforge Sword"
            v-tooltip="'Gain stats by burning a different weapon'"
            @click="showReforge = true"
          />
        </div>
      </div>

      <div class="sub-container">
        <div v-if="showReforge">
          <h1>Choose Weapon to burn</h1>
          <weapon-grid v-model="burnWeaponId" :ignore="reforgeWeaponId" />

          <div class="button-row">
            <big-button
              class="button"
              mainText="Confirm Reforge"
              :disabled="canReforge"
              @click="onReforgeWeapon"
            />
          </div>
        </div>
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
      showReforge: false,
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

  watch: {
    reforgeWeaponId() {
      this.showReforge = false;
    }
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

        this.burnWeaponId = null;
      } catch (e) {
        console.error(e);
        alert('Could not forge sword: insufficient funds or transaction denied.');
      }
    }
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

.mint-weapon {
  height: 2.5rem;
  width: 6rem;
  font-size: 1.3rem;
  color: rgba(255, 255, 255, 0.6);
  background: none;
  border: none;
  border-radius: 0.1em;
  margin-right: 1em;
  float: right;
}

.weapon-container {
  display: flex;
  flex-direction: row;
  width: 100%;
}

.sub-container {
  flex: 1;
}
</style>
