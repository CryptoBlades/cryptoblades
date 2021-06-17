<template>
  <div class="body main-font">

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

    <div class="row mt-3" v-if="ownWeapons.length > 0">
      <div class="col-6">
        <div class="d-flex justify-content-space-between">
          <h1>Weapons ({{ ownWeapons.length }})</h1>

          <b-button
            variant="primary"
            class="ml-auto"
            @click="onForgeWeapon"
            v-tooltip="'Forge new weapon'">
            Forge ({{ forgeCost }} SKILL) <i class="fas fa-plus"></i>
          </b-button>
        </div>

        <weapon-grid v-model="reforgeWeaponId" />

        <div class="button-row" v-if="reforgeWeaponId !== null">
          <big-button
            class="button"
            mainText="Reforge Sword"
            v-if="ownWeapons.length > 1"
            v-tooltip="'Gain stats by burning a different weapon'"
            @click="showReforge = true"
          />
        </div>
      </div>

      <div class="col-6">
        <div v-if="showReforge && ownWeapons.length > 1">
          <h1>Choose Weapon to burn</h1>
          <weapon-grid v-model="burnWeaponId" :ignore="reforgeWeaponId" />

          <div class="button-row">
            <big-button
              class="button"
              :mainText="'Confirm Reforge (' + reforgeCost + ' SKILL)'"
              :disabled="canReforge"
              @click="onReforgeWeapon"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import BN from 'bignumber.js';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import BigButton from '../components/BigButton.vue';
import { mapActions, mapGetters, mapState } from 'vuex';

export default {
  data() {
    return {
      showReforge: false,
      reforgeWeaponId: null,
      burnWeaponId: null,
      forgeCost: 0,
      reforgeCost: 0,
      disableForge: false
    };
  },

  computed: {
    ...mapState(['contracts', 'defaultAccount']),
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

  async created() {
    const forgeCost = await this.contracts.CryptoBlades.methods.mintWeaponFee().call({ from: this.defaultAccount });
    const skillForgeCost = await this.contracts.CryptoBlades.methods.usdToSkill(forgeCost).call();
    this.forgeCost = BN(skillForgeCost).div(BN(10).pow(18)).toFixed(4);

    const reforgeCost = await this.contracts.CryptoBlades.methods.reforgeWeaponFee().call({ from: this.defaultAccount });
    const skillReforgeCost = await this.contracts.CryptoBlades.methods.usdToSkill(reforgeCost).call();
    this.reforgeCost = BN(skillReforgeCost).div(BN(10).pow(18)).toFixed(4);
  },

  methods: {
    ...mapActions(['mintWeapon', 'reforgeWeapon']),

    async onForgeWeapon() {
      if(this.disableForge) return;

      this.disableForge = true;

      setTimeout(() => {
        this.disableForge = false;
      }, 10000);

      try {
        await this.mintWeapon();
      } catch (e) {
        console.error(e);
        this.$dialog.alert('Could not forge sword: insuffucient funds or transaction denied.');
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
        this.$dialog.alert('Could not forge sword: insuffucient funds or transaction denied.');
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
  width: 14rem;
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
