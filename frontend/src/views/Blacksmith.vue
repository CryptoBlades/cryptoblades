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
        :mainText="`Forge sword for ${forgeCost} SKILL`"
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
              tagname="reforge_weapon"
              v-tooltip="'Burn weapons to buff selected weapon'">
              Reforge
            </b-button>

            <b-button
              variant="primary"
              class="ml-3"
              @click="onClickForge(0)"
              :disabled="disableForge"
              v-tooltip="'Forge new weapon'">
              <span v-if="disableForge">
                Cooling forge...
              </span>

              <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                Forge x1 ({{ forgeCost }} SKILL) <i class="fas fa-plus"></i>
              </span>
            </b-button>

              <b-button
              variant="primary"
              class="ml-3"
              @click="onClickForge(1)"
              :disabled="disableForge"
              v-tooltip="'Forge new weapon'">
              <span v-if="disableForge">
                Cooling forge...
              </span>

              <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                x10 ({{ forgeCost*10 }} SKILL) <i class="fas fa-plus"></i>
              </span>
            </b-button>

            <b-icon-question-circle class="centered-icon" scale="1.5"
              v-on:click="onShowForgeDetails" v-tooltip.bottom="'Click for forge percentages'"/>

            <b-modal hide-footer ref="forge-details-modal" title="Forge Percentages">
              <div>
                5+ star @ 1% chance. Estimated cost {{Number.parseFloat(forgeCost * (1/0.01)).toFixed(2)}} SKILL.
              </div>
              <div>
                4+ star @ 6% chance. Estimated cost {{Number.parseFloat(forgeCost * (1/0.06)).toFixed(2)}} SKILL.
              </div>
              <div>
                3+ star @ 21% chance. Estimated cost {{Number.parseFloat(forgeCost * (1/0.21)).toFixed(2)}} SKILL.
              </div>
              <div>
                2+ star @ 56% chance. Estimated cost {{Number.parseFloat(forgeCost * (1/0.56)).toFixed(2)}} SKILL.
              </div>
              <div>
                1+ star @ 100% chance.
              </div>
            </b-modal>

            <b-modal hide-footer ref="forge-element-selector-modal" title="Select Element" @hide="onHideModal">
              <div class="row justify-content-md-center">
                <img v-on:click="setChoosenElement($event, 100)" class="elements-modal" src="../assets/Question_mark_white_icon.png"/>
                <img v-on:click="setChoosenElement($event, 0)" class="elements-modal" src="../assets/elements/fire.png"/>
                <img v-on:click="setChoosenElement($event, 1)" class="elements-modal" src="../assets/elements/earth.png"/>
                <img v-on:click="setChoosenElement($event, 2)" class="elements-modal" src="../assets/elements/lightning.png"/>
                <img v-on:click="setChoosenElement($event, 3)" class="elements-modal" src="../assets/elements/water.png"/>
              </div>
              <div class="row justify-content-md-center margin-top">
                <b-button
                v-if="clickedForgeButton === 0"
                variant="primary"
                class="row justify-content-md-center"
                @click="onForgeWeapon"
                :disabled="disableConfirmButton"
                v-tooltip="'Forge new weapon'">
                  <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                    Forge ({{Number.parseFloat(forgeCost * this.chosenElementFee).toFixed(2)}} SKILL)
                  </span>
                </b-button>
                <b-button
                v-if="clickedForgeButton === 1"
                variant="primary"
                class="row justify-content-md-center"
                @click="onForgeWeaponx10"
                :disabled="disableConfirmButton"
                v-tooltip="'Forge new weapon'">
                  <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                    Forge ({{Number.parseFloat(forgeCost * this.chosenElementFee * 10).toFixed(2)}} SKILL)
                  </span>
                </b-button>
              </div>
            </b-modal>
          </div>
        </div>

        <weapon-grid v-model="reforgeWeaponId" />
        <b-modal size="xl" class="centered-modal " ref="new-weapons" ok-only>
                    <template #modal-header>
                         <div v-if="!spin" class="new-weapon-header-text text-center">
                              <strong>Forging Results</strong>
                         </div>
                         <div v-if="spin" class="new-weapon-header-text text-center">
                              <strong>Be patient, the irons are hot...</strong>
                         </div>
                    </template>
                    <div class="text-center">
                      <b-spinner v-if="spin" type="grow" label="Loading..."></b-spinner>
                      <b-spinner v-if="spin" type="grow" label="Loading..."></b-spinner>
                      <b-spinner v-if="spin" type="grow" label="Loading..."></b-spinner>
                    </div>
                    <weapon-grid v-if="!spin" :showGivenWeaponIds="true" :weaponIds="newForged" :newWeapon="true"/>

                    <template #modal-footer>
                    </template>
                </b-modal>
      </div>

      <div class="col-6" v-if="showReforge">
        <div class="d-flex justify-content-space-between">
          <h1>Choose Burn Weapon</h1>

          <div class="d-flex justify-content-flex-end ml-auto">
            <b-button
              variant="primary"
              class="ml-3"
              tagname="confirm_forge_weapon"
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
            This item has been previously reforged and only half of each LBs will carry over!
          </div>
        </b-modal>

        <weapon-grid v-model="burnWeaponId" :ignore="reforgeWeaponId" :showReforgedWeaponsDefVal="false" :showFavoriteWeaponsDefVal="false" />
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
import { BModal } from 'bootstrap-vue';


export default {


  data() {
    return {
      showReforge: false,
      reforgeWeaponId: null,
      burnWeaponId: null,
      forgeCost: 0,
      reforgeCost: 0,
      disableForge: false,
      forgeMultiplier: 10,
      newForged: [],
      currentListofWeapons: [],
      x10Forge: false,
      x1Forge: false,
      onError: false,
      spin: false,
      selectedElement: null,
      chosenElementFee: null,
      disableConfirmButton: true,
      clickedForgeButton: null,
    };
  },

  computed: {
    ...mapState(['defaultAccount','ownedWeaponIds']),
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
    ...mapActions(['mintWeapon', 'reforgeWeapon', 'mintWeaponN']),

    async onForgeWeapon() {
      if(this.disableForge) return;

      this.$refs['forge-element-selector-modal'].hide();

      this.getCurrentListofWeapons();
      this.onError = false;
      this.x1Forge = true;
      this.disableForge = true;

      setTimeout(() => {
        this.disableForge = false;
      }, 10000);

      try {
        await this.mintWeapon({chosenElement: this.selectedElement, chosenElementFee: this.chosenElementFee});

        this.viewNewWeapons(1);

      } catch (e) {
        console.error(e);
        this.onError = true;
        this.$dialog.notify.error('Could not forge sword: insuffucient funds or transaction denied.');
      }
    },

    async onForgeWeaponx10(){
      if(this.disableForge) return;
      this.disableForge = true;

      this.$refs['forge-element-selector-modal'].hide();

      this.getCurrentListofWeapons();
      this.onError = false;
      this.x10Forge = true;

      setTimeout(() => {
        this.disableForge = false;
      }, 10000);

      try {
        await this.mintWeaponN({num: this.forgeMultiplier, chosenElement: this.selectedElement, chosenElementFee: this.chosenElementFee});

        this.viewNewWeapons(this.forgeMultiplier);

      } catch (e) {
        console.error(e);
        this.onError = true;
        this.$dialog.notify.error('Could not forge sword: insuffucient funds or transaction denied.');
      }
    },
    onShowForgeDetails() {
      this.$refs['forge-details-modal'].show();
    },

    onClickForge(i) {
      this.clickedForgeButton = i;
      this.$refs['forge-element-selector-modal'].show();
    },

    setChoosenElement(ele, i) {
      this.selectedElement = i;
      if (i === 100) {
        this.chosenElementFee = 1;
      } else{
        this.chosenElementFee = 2;
      }
      Array.from(ele.srcElement.parentNode.childNodes).forEach((child) => {
        child.style.transform = 'scale(1)';
      });
      ele.srcElement.style.transform = 'scale(1.4)';
      this.disableConfirmButton = false;
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

    getCurrentListofWeapons(){
      this.ownedWeaponIds.forEach(x => {
        this.currentListofWeapons.push(x);
      });
    },

    viewNewWeapons(newWeaponCount = 1){
      this.newForged = this.ownedWeaponIds.slice(-newWeaponCount);

      // eslint-disable-next-line no-constant-condition
      if (this.newForged.length > 0 && !this.onError){
        this.spin = true;
        this.$refs['new-weapons'].show();

        setTimeout(() => {
          this.spin = false;
        }, 10000);
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
        this.$dialog.notify.error('Could not forge sword: insuffucient funds or transaction denied.');
      }
    },

    onHideModal(){
      this.disableConfirmButton = true;
    }
  },

  components: {
    WeaponGrid,
    BigButton,
    WeaponIcon,
    BModal,
  },
};
</script>

<style scoped>

.new-weapon-header-text{
   color: #9e8a57;
  font-size: 34px;
}

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

.centered-icon {
  align-self: center;
  margin-left: 5px;
}

.elements-modal{
  width: 10%;
  height: 10%;
  margin-left: 3%;
  margin-right: 3%;
}

img.elements-modal:hover {
  transform:scale(1.4)
}

.margin-top {
  margin-top: 2%;
}
</style>
