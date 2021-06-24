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
      <div class="col">
        <div class="d-flex justify-content-space-between">
          <h1>Weapons ({{ ownWeapons.length }})</h1>

          <div class="d-flex justify-content-flex-end ml-auto">
            <b-button
              variant="primary"
              v-if="reforgeWeaponId !== null && ownWeapons.length > 0"
              @click="showReforge = true"
              v-tooltip="'Burn weapons to buff selected weapon'">
              Reforge
            </b-button>

            <b-button
              variant="primary"
              class="ml-3"
              @click="onForgeWeapon"
              :disabled="disableForge"
              v-tooltip="'Forge new weapon'">
              <span v-if="disableForge">
                Cooling forge...
              </span>

              <span v-if="!disableForge">
                Forge ({{ forgeCost }} SKILL) <i class="fas fa-plus"></i>
              </span>
            </b-button>
          </div>
        </div>

        <weapon-grid v-model="reforgeWeaponId" />
      </div>

      <div class="col-6" v-if="showReforge">
        <div class="d-flex justify-content-space-between">
          <h1>Choose Burn Weapon</h1>

          <div class="d-flex justify-content-flex-end ml-auto">
            <b-button
              variant="primary"
              class="ml-3"
              @click="showReforgeConfirmation"
              :disabled="canReforge"
              v-tooltip="'Forge new weapon'">
              Confirm Reforge ({{ reforgeCost }} SKILL)
            </b-button>
          </div>
        </div>

        <b-modal class="centered-modal" ref="reforge-confirmation-modal" title="Reforge Confirmation"
          @ok="onReforgeWeapon">
          <div class="text-center" v-text="'Are you sure you want to reforge with this weapon?'" />
          <div class="weapon" :hidden="burnWeaponId == null">
            <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
              <slot name="above" :weapon="getWeaponToBurn()"></slot>
            </div>
            <div class="weapon-icon-wrapper">
              <weapon-icon class="weapon-icon" :weapon="getWeaponToBurn()" />
            </div>
          </div>
          <div class="text-center" :hidden="burnWeaponId == null || !isWeaponRare()">
            <b-icon icon="exclamation-circle" variant="danger" /> This is a rare weapon!
          </div>
          <div class="text-center" :hidden="burnWeaponId == null || !isWeaponReforged()">
            <b-icon icon="exclamation-circle" variant="danger" />
            This item has been previously reforged and LBs will not carry over!
          </div>
        </b-modal>

        <weapon-grid v-model="burnWeaponId" :ignore="reforgeWeaponId" />
      </div>
    </div>
  </div>
</template>

<script>
import BN from 'bignumber.js';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import BigButton from '../components/BigButton.vue';
import { mapActions, mapGetters, mapState } from 'vuex';
import WeaponIcon from '../components/WeaponIcon.vue';

export default {
  data() {
    return {
      showReforge: false,
      reforgeWeaponId: null,
      burnWeaponId: null,
      forgeCost: 0,
      reforgeCost: 0,
      disableForge: false,
    };
  },

  computed: {
    ...mapState(['defaultAccount']),
    ...mapGetters(['contracts', 'ownWeapons']),

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
      this.burnWeaponId = null;
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

    showReforgeConfirmation() {
      this.$refs['reforge-confirmation-modal'].show();
    },

    isWeaponRare() {
      return this.getWeaponToBurn().stars >= 3;
    },

    isWeaponReforged() {
      return this.getWeaponToBurn().bonusPower > 0;
    },

    getWeaponToBurn() {
      return this.ownWeapons.find(x => x.id === this.burnWeaponId);
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
    WeaponIcon,
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

.weapon {
  width: 12em;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 5px;
  cursor: pointer;
  margin-left: auto;
  margin-right: auto;
}

.centered-modal {
  justify-content: center;
}

</style>
