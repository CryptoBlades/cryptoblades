
<template>
  <div class="p-5 mb-5 background-image">
    <div class="background-image"></div>
    <div v-if="!haveCharacters" class="blank-slate">
      <div class="current-promotion">
        <div class="tob-bg-img promotion-decoration">
          <img class="vertical-decoration bottom" src="../assets/border-element.png">
        </div>
        <strong class="upper-text">{{ $t("plaza.welcome") }}</strong>
        <div class="bot-bg-img promotion-decoration">
            <img src="../assets/border-element.png">
        </div>
      </div>
      <big-button
        class="button"
        :mainText="$t('plaza.recruitCharacter') + ` ${recruitCost} SKILL`"
        :disabled="!canRecruit()"
        @click="onMintCharacter"
        tagname="recruit_character"
      />
      <div v-if="formatSkill() < recruitCost" >
        <br>
        <i18n path="plaza.notEnoughSkill" tag="label" for="plaza.notEnoughSkillLink">
          <a v-bind:href="`${getExchangeUrl}`" target="_blank" rel="noopener noreferrer">{{$t("plaza.notEnoughSkillLink")}}</a>
        </i18n>
        <a :href="getExchangeTransakUrl()" target="_blank" rel="noopener noreferrer"> {{$t("plaza.buyBNBTransak")}}</a>.

      </div>
    </div>
    <template v-else>
      <CharacterNav :garrison="garrison" :havePlazaCharacters="havePlazaCharacters" @toggle="toggleGarrison" />
      <template v-if="!garrison && havePlazaCharacters">
         <character />
      </template>
      <template v-else>
        <div class="row mt-3 z-index-1">
          <div class="col">
            <div>
              <div class="d-flex justify-content-space-between">
                <h1>{{$t('characters')}} ({{ ownedGarrisonCharacterIds.length }})</h1>
                <div class="d-flex justify-content-flex-end ml-auto">
                  <b-button
                    v-if="canClaimGarrisonXp"
                    :disabled="isClaimingXp"
                    variant="primary"
                    class="ml-3 gtag-link-others"
                    @click="onClaimGarrisonXp">
                    {{isClaimingXp ? `${$t('plaza.claiming')}` : $t('plaza.claimXp')}}
                  </b-button>
                  <b-button
                    v-if="ownCharacters.length === 4"
                    variant="primary"
                    class="ml-3 gtag-link-others"
                    @click="onMintCharacter"
                    v-tooltip="$t('plaza.recruitNew')" tagname="recruit_character">
                    {{$t('plaza.recruit')}} ({{ recruitCost }} NON-IGO SKILL) <i class="fas fa-plus"></i>
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
      </template>
    </template>
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
import BN from 'bignumber.js';
import i18n from '@/i18n';
import { Nft } from '@/interfaces/Nft';
import BigButton from '@/components/BigButton.vue';
import CharacterList from '@/components/smart/CharacterList.vue';
import CharacterNav from '@/components/CharacterNav.vue';
import Character from '@/components/smart/Character.vue';

import { fromWeiEther, toBN } from '../utils/common';



interface StoreMappedActions {
  fetchMintCharacterFee(): Promise<string>;
  mintCharacter(value: boolean): Promise<void>;
  fetchMintCharacterPriceDecreasePerSecond(): Promise<number>;
  fetchCharacterMintIncreasePrice(): Promise<number>;
  fetchMintCharacterMinPrice(): Promise<number>;
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

  garrison: boolean;
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
      'characterCosmetics'
    ]),
    ...mapGetters(['getCharacterName','getCharacterPower', 'contracts', 'ownCharacters', 'getExchangeUrl']),
    selectedCharacter(): Nft{
      return this.characters[this.currentCharacterId];
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
  },
  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions([
      'mintCharacter',
      'fetchMintCharacterPriceDecreasePerSecond',
      'fetchCharacterMintIncreasePrice',
      'fetchMintCharacterMinPrice',
      'fetchMintCharacterFee'
    ]) as StoreMappedActions,
    ...mapGetters(['getExchangeTransakUrl']) as StoreMappedGetters,
    toggleGarrison() {
      this.garrison = !this.garrison;
    },
    async onMintCharacter() {
      try {
        await this.mintCharacter(this.mintSlippageApproved);
      } catch (e) {
        (this as any).$dialog.notify.error(i18n.t('plaza.couldNotMint'));
      }
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
      const skillRecruitCost = await this.contracts.CryptoBlades.methods.usdToSkill(recruitCost).call();
      this.recruitCost = new BN(skillRecruitCost).div(new BN(10).pow(18)).toFixed(4);
    },
  },
  async mounted(){
    this.checkStorage();
  },
  async created(){
    this.mintPriceDecreasePerHour = new BN(await this.fetchMintCharacterPriceDecreasePerSecond()).div(new BN(10).pow(18)).multipliedBy(60*60).toFixed(6);
    this.mintCharacterPriceIncrease = new BN(await this.fetchCharacterMintIncreasePrice()).div(new BN(10).pow(18)).toFixed(6);
    this.mintCharacterMinPrice = new BN(await this.fetchMintCharacterMinPrice()).div(new BN(10).pow(18)).toFixed(4);
    this.updateMintCharacterFee();
    this.updateInterval = setInterval(async () => { await this.updateMintCharacterFee(); }, 2000);
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
}

</style>