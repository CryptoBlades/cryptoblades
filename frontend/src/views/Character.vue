
<template>
  <div class="background-image">
    <div class="blind-background"></div>
    <div v-if="!haveCharacters" class="blank-slate">
      <div class="initial-recruitment">
        <div class="tob-bg-img promotion-decoration">
          <img class="vertical-decoration bottom" src="../assets/border-element.png">
        </div>
        <strong class="upper-text">{{ $t("plaza.welcome") }}</strong>
        <div class="bot-bg-img promotion-decoration">
            <img src="../assets/border-element.png">
        </div>
        <big-button
        class="button mt-5"
        :mainText="$t('plaza.recruitCharacter') + ` ${recruitCost} SKILL`"
        :disabled="!canRecruit()"
        @click="onMintCharacter"
        tagname="recruit_character"
      />
      </div>
      <div v-if="formatSkill() < recruitCost" >
        <br>
        <i18n path="plaza.notEnoughSkill" tag="label" for="plaza.notEnoughSkillLink">
          <a v-bind:href="`${getExchangeUrl}`" target="_blank" rel="noopener noreferrer">{{$t("plaza.notEnoughSkillLink")}}</a>
        </i18n>
        <a :href="getExchangeTransakUrl()" target="_blank" rel="noopener noreferrer"> {{$t("plaza.buyBNBTransak")}}</a>.

      </div>
    </div>
    <div class="p-5" v-else>
      <CharacterNav
        :garrison="garrison"
        :havePlazaCharacters="havePlazaCharacters"
        @toggle="toggleGarrison"
        :recruitCost="recruitCost"
        :ownCharacters="ownCharacters"
        @mintCharacter="onMintCharacter"
      />
      <template v-if="!garrison && havePlazaCharacters">
         <character />
      </template>
      <template v-else>
        <div v-if="!soulCreationActive" class="row mt-3 z-index-1">
          <div class="col">
            <div>
              <div class="d-flex flex-column flex-md-row justify-content-space-between">
                <h1>{{$t('characters')}} ({{ ownedGarrisonCharacterIds.length }})</h1>
                <div class="d-flex justify-content-flex-end ml-md-auto">
                  <b-button
                    v-if="canClaimGarrisonXp"
                    :disabled="isClaimingXp"
                    variant="primary"
                    class="ml-3 gtag-link-others"
                    @click="onClaimGarrisonXp">
                    {{isClaimingXp ? `${$t('plaza.claiming')}` : $t('plaza.claimXp')}}
                  </b-button>
                  <b-button
                    v-if="burningEnabled"
                    :disabled="!haveCharacters"
                    variant="primary"
                    class="ml-3 gtag-link-others"
                    @click="toggleSoulCreation"
                    v-tooltip="$t('plaza.recruitNew')">
                    {{$t('plaza.burn')}}
                  </b-button>
                  <b-checkbox
                    v-if="ownCharacters.length === 4"
                    variant="primary"
                    class="mx-3 my-auto"
                    v-model="mintSlippageApproved">
                    <span><b>{{$t('plaza.approveMintSlippage')}}</b></span>
                    <b-icon-question-circle class="ml-1 centered-icon" v-tooltip.bottom="$t('plaza.dynamicPricesDetails',
                      { decreaseAmount: mintPriceDecreasePerHour, increaseAmount: mintCharacterPriceIncrease, minimumPrice: mintCharacterMinPrice})"/>
                  </b-checkbox>
                </div>
              </div>
              <character-list
                :showNftOptions="true"
                :isGarrison="true"
                @input="setCurrentCharacter"
              />
            </div>
          </div>
        </div>
        <div class="pt-5" v-else>
          <div class="d-flex justify-content-space-between mb-3">
            <div class="d-flex justify-content-flex-end ml-auto">
              <b-button
                variant="primary"
                class="ml-3 garrison-buttons"
                @click="showBurnConfirmation"
                v-tooltip="$t('plaza.burnSelected')"
                :disabled="burnCharacterIds.length === 0 || powerLimitExceeded || (burnOption === 1 && !targetCharacterId) || !canBurn() || isBurnInProgress">
                {{isBurnInProgress ? `${$t('plaza.burning')}` : `${$t('plaza.burn')}: ${this.burnCharacterIds.length} ${$t('characters')}`}}<br>
                ({{burnCost }} SKILL)
              </b-button>
              <b-button
                variant="primary"
                class="ml-3 gtag-link-others garrison-buttons"
                @click="toggleSoulCreation"
                v-tooltip="$t('plaza.cancelBurning')">
                {{$t('plaza.cancelBurning')}}
              </b-button>
            </div>
          </div>
          <div>
            <div class="col-md-12">
              <div class="row mobile-flip">
                <div class="col-md-4 character-container" >
                  <h1 align="center" class="text-center">{{$t('plaza.selectBurnCharacter')}}</h1>
                  <character-list :showFilters="true" :showGivenCharacterIds="true" :characterIds="remainingCharactersIds" @input="addBurnCharacter"/>
                </div>
                <div class="col-md-4 character-container" >
                  <h1 class="text-center">{{$t('plaza.charactersToBurn')}}</h1>
                  <h1 class="text-center mt-3 mb-4">
                    <b-button
                      class="mt-2 mb-1"
                      variant="primary"
                      @click="clearAllBurn()"
                      v-tooltip="$t('blacksmith.clearAll')"
                      :disabled="burnCharacterIds === []">
                      {{$t('blacksmith.clearAll')}}
                    </b-button>
                  </h1>
                  <character-list class="mt-4" :showGivenCharacterIds="true" :characterIds="burnCharacterIds" @input="removeBurnCharacter"/>
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>
    </div>
    <b-modal class="centered-modal text-center" ref="burn-confirmation-modal" :title="$t('plaza.burnConfirmation')"
      @ok="onBurnConfirm" :ok-disabled="burnCharacterIds.length === 0">
      <div class="text-center">
        <b-icon icon="exclamation-circle" variant="danger" />
        {{ $t('plaza.burnWarning', { characterAmount: burnCharacterIds.length })}}<br>
        {{ $t('plaza.cantBeUndone')}}
      </div>
      <div class="text-center">
        <b-icon icon="exclamation-circle" variant="danger" /> {{ $t('plaza.noRefunds')}}
      </div>
    </b-modal>
    <div v-if="showAds && !isMobile()" class="ad-container align-items-center">
      <script2 async src="https://coinzillatag.com/lib/sticky.js"></script2>
        <div class="coinzilla" data-zone="C-2621de2f7c4f7a272"></div>
        <script2>window.coinzilla_sticky = window.coinzilla_sticky
            || [];function czilla(){coinzilla_sticky.push(arguments);}czilla('2621de2f7c4f7a272');</script2>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { mapActions, mapGetters, mapState, mapMutations } from 'vuex';
import { BModal } from 'bootstrap-vue';
import BN from 'bignumber.js';
import i18n from '@/i18n';
import { Nft } from '@/interfaces/Nft';
import { CharacterPower } from '@/interfaces';
import BigButton from '@/components/BigButton.vue';
import CharacterList from '@/components/smart/CharacterList.vue';
import CharacterNav from '@/components/CharacterNav.vue';
import Character from '@/components/smart/Character.vue';

import { fromWeiEther, toBN } from '../utils/common';
import {
  burningManager as featureFlagBurningManager
} from '../feature-flags';




interface StoreMappedActions {
  fetchMintCharacterFee(): Promise<string>;
  mintCharacter(value: boolean): Promise<void>;
  fetchMintCharacterPriceDecreasePerSecond(): Promise<number>;
  fetchCharacterMintIncreasePrice(): Promise<number>;
  fetchMintCharacterMinPrice(): Promise<number>;
  fetchSoulBalance(): Promise<string>;
  fetchBurnPowerMultiplier(): Promise<string>;
  fetchCharactersBurnCost(payload: string[]): Promise<string>;
  burnCharactersIntoSoul(payload: string[]): Promise<void>;
  burnCharactersIntoCharacter(payload: {burnIds: string[], targetId: string}): Promise<void>;
}

interface StoreMappedGetters {
  getExchangeTransakUrl(): string;
}

interface Data {
  recruitCost: string;
  showAds: boolean;
  updateInterval: ReturnType<typeof setInterval> | null;
  mintSlippageApproved: boolean;
  mintPriceDecreasePerHour: string;
  mintCharacterPriceIncrease: string;
  mintCharacterMinPrice: string;
  soulCreationActive: boolean;
  garrison: boolean;
  soulBalance: number;
  burnCost: number;
  burnPowerMultiplier: number;
  burnCharacterIds: string[];
  remainingCharactersIds: string[];
  isUpgrading: boolean;
  isBurning: boolean;
  isTransferring: boolean;
  soulAmount: number;
  targetCharacterId: string;
  remainingPowerLimit: number;
  burnOption: number;
  isBurnInProgress: boolean
}

export default Vue.extend({
  data(): Data{
    return {
      garrison: false,
      updateInterval: null as ReturnType<typeof setInterval> | null,
      recruitCost: '0',
      mintSlippageApproved: false,
      mintPriceDecreasePerHour: '0',
      mintCharacterPriceIncrease: '0',
      mintCharacterMinPrice: '0',
      showAds: false,
      soulCreationActive: false,
      soulBalance: 0,
      burnCost: 0,
      burnPowerMultiplier: 1,
      burnCharacterIds: [],
      remainingCharactersIds: [],
      isUpgrading: false,
      isBurning: false,
      isTransferring: false,
      soulAmount: 0,
      targetCharacterId: '',
      remainingPowerLimit: 0,
      burnOption: 0,
      isBurnInProgress: false
    };
  },
  computed: {
    ...mapState([
      'characters',
      'currentCharacterId',
      'maxStamina',
      'ownedGarrisonCharacterIds',
      'characterStaminas',
      'skillBalance',
      'skillRewards',
      'ownedCharacterIds',
      'xpRewards',
      'characterCosmetics',
    ]),
    ...mapGetters([
      'getCharacterName',
      'ownGarrisonCharacters',
      'getCharacterPower',
      'contracts',
      'ownCharacters',
      'getExchangeUrl',
      'getCharacterIsInArena'
    ]),
    selectedCharacter(): Nft{
      return this.characters[this.currentCharacterId];
    },
    burnPower(): number {
      let power = 0;
      if(!this.isUpgrading) {
        this.ownCharacters.map((x: { id: number; }) => {
          if(this.burnCharacterIds.includes(x.id.toString())) {
            power += this.getCharacterPower(x.id);
          }
        });
        this.ownGarrisonCharacters.map((x: { id: number; }) => {
          if(this.burnCharacterIds.includes(x.id.toString())) {
            power += this.getCharacterPower(x.id);
          }
        });
        power = Math.floor(power * this.burnPowerMultiplier);
      }
      else {
        power = this.soulAmount * 10;
      }

      return power;
    },
    powerLimitExceeded(): boolean {
      return (this.isUpgrading || this.burnOption === 1) && this.burnPower > this.remainingPowerLimit;
    },
    haveCharacters(): boolean {
      return this.ownedGarrisonCharacterIds.length > 0 || this.ownCharacters?.length > 0;
    },
    havePlazaCharacters(): boolean {
      return this.ownCharacters?.length > 0;
    },
    canClaimGarrisonXp(): boolean {
      return this.ownedGarrisonCharacterIds.filter((id: string|number) => +this.xpRewards[id] > 0).length > 0;
    },
    burningEnabled(): boolean {
      return featureFlagBurningManager;
    },
  },
  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions([
      'mintCharacter',
      'fetchMintCharacterPriceDecreasePerSecond',
      'fetchCharacterMintIncreasePrice',
      'fetchMintCharacterMinPrice',
      'fetchMintCharacterFee',
      'fetchSoulBalance',
      'fetchBurnPowerMultiplier',
      'fetchCharactersBurnCost',
      'burnCharactersIntoSoul',
      'burnCharactersIntoCharacter',
    ]) as StoreMappedActions,
    ...mapGetters(['getExchangeTransakUrl']) as StoreMappedGetters,
    toggleGarrison() {
      if (this.garrison && this.ownedGarrisonCharacterIds.includes(this.currentCharacterId)) {
        this.setCurrentCharacter(this.ownedCharacterIds[0]);
      }
      this.garrison = !this.garrison;
    },
    async onMintCharacter() {
      try {
        await this.mintCharacter(this.mintSlippageApproved);
        await this.updateMintCharacterFee();
      } catch (e) {
        (this as any).$dialog.notify.error(i18n.t('plaza.couldNotMint'));
      }
    },
    async addBurnCharacter(id: number) {
      if(this.getCharacterIsInArena(id)) {
        (this as any).$dialog.notify.error(i18n.t('plaza.busyInArena'));
        return;
      }
      this.burnCharacterIds.push(id.toString());
      this.remainingCharactersIds = this.remainingCharactersIds.filter(val => !this.burnCharacterIds.includes(val.toString()));
      await this.updateBurnCost();
    },
    async removeBurnCharacter(id: number) {
      this.remainingCharactersIds.push(id.toString());
      this.burnCharacterIds = this.burnCharacterIds.filter(x => x !== id.toString());
      await this.updateBurnCost();
    },
    canBurn() {
      const cost = toBN(this.burnCost);
      const balance = toBN(+fromWeiEther(this.skillBalance) + +fromWeiEther(this.skillRewards));
      return balance.isGreaterThanOrEqualTo(cost);
    },
    showBurnConfirmation() {
      (this.$refs['burn-confirmation-modal'] as BModal).show();
    },
    async toggleSoulCreation() {
      this.soulCreationActive = !this.soulCreationActive;
      this.soulBalance = +(await this.fetchSoulBalance());
      await this.updateBurnCost();
      this.burnPowerMultiplier = +fromWeiEther(await this.fetchBurnPowerMultiplier());
      if(this.soulCreationActive) {
        this.remainingCharactersIds = this.ownCharacters.map((x: { id: string; }) => x.id.toString()).concat(this.ownedGarrisonCharacterIds as string[]);
      }
      this.isUpgrading = false;
    },
    clearAllBurn(){
      this.burnCharacterIds = [];
      this.remainingCharactersIds = (this.ownCharacters.map((x: { id: string; }) => x.id.toString())
        .concat(this.ownedGarrisonCharacterIds) as string[])
        .filter(x => x.toString() !== this.targetCharacterId);
      this.burnCost = 0;
    },
    setMaxSoulAmount() {
      if (this.isTransferring) {
        this.soulAmount = this.soulBalance;
      } else {
        this.soulAmount = this.remainingPowerLimit > this.soulBalance * 10 ? this.soulBalance : this.remainingPowerLimit / 10;
      }
    },
    async updateBurnCost() {
      this.burnCost = this.burnCharacterIds.length > 0 ? +fromWeiEther(await this.fetchCharactersBurnCost(this.burnCharacterIds)) : 0;
    },
    checkStorage() {
      if (process.env.NODE_ENV === 'development') this.showAds = false;
      else this.showAds = localStorage.getItem('show-ads') === 'true';
    },
    canRecruit() {
      const cost = toBN(this.recruitCost);
      const balance = toBN(+fromWeiEther(this.skillBalance) + +fromWeiEther(this.skillRewards));
      return balance.isGreaterThanOrEqualTo(cost);
    },
    formatSkill() {
      return fromWeiEther(this.skillBalance);
    },
    async updateMintCharacterFee() {
      const recruitCost = await this.fetchMintCharacterFee();
      console.log({recruitCost});
      const skillRecruitCost = await this.contracts.CryptoBlades.methods.usdToSkill(recruitCost).call();
      this.recruitCost = new BN(skillRecruitCost).div(new BN(10).pow(18)).toFixed(4);
    },
    updatedRemainingPowerLimit() {
      const targetCharacter = this.ownCharacters.concat(this.ownGarrisonCharacters)
        .find((x: { id: any; }) => x.id.toString() === this.targetCharacterId.toString());
      this.remainingPowerLimit = 4 * CharacterPower(targetCharacter.level) - this.getCharacterPower(this.targetCharacterId.toString());
    },
    async onBurnConfirm() {
      if(this.burnCharacterIds.length === 0) return;
      this.isBurnInProgress = true;
      try {
        if(this.burnOption === 0) {
          // burning into soul
          await this.burnCharactersIntoSoul(this.burnCharacterIds);
        }
        else {
          // burning into character
          await this.burnCharactersIntoCharacter({ burnIds: this.burnCharacterIds, targetId: this.targetCharacterId });
          this.updatedRemainingPowerLimit();
        }
      }
      finally {
        this.isBurnInProgress = false;
      }
      this.soulBalance = +(await this.fetchSoulBalance());
      this.burnCharacterIds = [];
      this.burnCost = 0;
    },
  },
  async mounted(){
    this.checkStorage();
  },
  watch: {
    async ownedCharacterIds(){
      await this.updateMintCharacterFee();
    }
  },
  async created(){
    this.mintPriceDecreasePerHour = new BN(await this.fetchMintCharacterPriceDecreasePerSecond()).div(new BN(10).pow(18)).multipliedBy(60*60).toFixed(6);
    this.mintCharacterPriceIncrease = new BN(await this.fetchCharacterMintIncreasePrice()).div(new BN(10).pow(18)).toFixed(6);
    this.mintCharacterMinPrice = new BN(await this.fetchMintCharacterMinPrice()).div(new BN(10).pow(18)).toFixed(4);
    this.updateMintCharacterFee();
  },
  components:{
    BigButton,
    CharacterList,
    CharacterNav,
    Character
  }
});
</script>
<style scoped lang="scss">

.background-image {
  background-image: url('../assets/artwork-fantasy-art-ruins.png') ;
  background-size: cover;
  background-repeat: no-repeat;
  background-position: top right;
  min-height: calc(100vh - 120px);
  height: 100%;
}

.background-image > div:nth-child(1){
  background-color: rgb(0, 0, 0, 0.3);
  height: 100%;
  width: 100%;
  position: absolute;
}

.initial-recruitment {
  z-index: 1;
}

.garrison-buttons{
  z-index: 2;
}

.chooser {
  height: 72px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 16px;
}

.switch {
  height: 55px;
  padding: 0 20px;
  font-size: 22px;
  min-width: 15px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  border-color: transparent;
  color: #9e8a57;
  border-radius: 100px;
  line-height: 24px;
  box-sizing: border-box;
  white-space: nowrap;
  text-align: center;
  border: 1px solid transparent;
  box-shadow: 0 2px 0 rgb(0 0 0 / 2%);
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.645, 0.045, 0.355, 1);
  user-select: none;
  touch-action: manipulation;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}

.switch_active {
  border: 2px solid rgb(37, 167, 219);
  color: #9e8a57;
  cursor: pointer;
  font-weight: bold;
  background: linear-gradient(180deg, rgba(31, 31, 34, 1) 0%, rgba(24, 27, 30, 1) 5%, rgba(24, 38, 45, 1) 100%);
}
.switch_active:hover,
.switch:hover {
  transform: scale(0.97);
}

.navbar-staking {
  display: flex;
  border: 1px solid #3c3c3c;
  box-sizing: border-box;
  border-radius: 100px;
  width: 100%;
}

</style>
