<template>
  <div>
  <div class="results-panel">
    <div class="float-center">
      <h1 class="text-center outcome result-title text-uppercase">
        {{ $t('combatResults.teamFightResult') }}
      </h1>
      <div class="mb-0" v-if="getCharactersWonAFight() > 0">
        <h5>
          {{ $t('combatResults.totalEarnings') }}: ${{ getAggregatedCharacterEarnings() }}
        </h5>
      </div>
      <div class="d-flex flex-wrap justify-content-center">
        <div
          v-for="(value, key) in fightResults.fightResultsMap"
          :key="key"
          class="mx-5 my-5"
        >
          <h5 class="text-center fight-result">{{ formattedOutcome(value).toUpperCase() }}</h5>
          <h5 class="text-center mb-0" v-if="!value.isVictory">
            <b>
              {{ getCleanCharacterName(key.toString()) }}
            </b>
          </h5>
          <div class="d-flex align-items-center">
            <div class="win-details">
              <h5>{{$t('combatResults.youRolled')}}</h5>
            </div>
            <div class="win-details mx-3">
              <img src="../assets/arrow-right.png" alt="">
            </div>
            <div class="win-details">
              <h5>{{value.playerRoll}}</h5>
            </div>
          </div>
          <div class="d-flex align-items-center">
            <div class="win-details">
              <h5>{{$t('combatResults.enemyRolled')}}</h5>
            </div>
            <div class="win-details mx-3">
              <img src="../assets/arrow-right.png" alt="">
            </div>
            <div class="win-details">
              <h5>{{value.enemyRoll}}</h5>
            </div>
          </div>
          <div class="you-earned" v-if="value.isVictory">
            <h5 class="text-center mb-0">
              <b>
                {{ getCleanCharacterName(key.toString()) }}
              </b>
            </h5>
            <h5>{{$t('combatResults.characterEarned')}}</h5>
          </div>
          <div v-if="value.isVictory" class="earned">
            <div v-if="!isGenesisCharacter(key)">
              <div>
                <b>{{ formattedSkill(value) }}</b>
                <span>
                  <small class="mr-2">(<b>${{ fightRewardsAmountInUSD(value, key) }}</b>)</small>
                  <Hint :text="$t('combatResults.earnedSkillHint')" />
                </span>
              </div>
              <div>
                <span class="mr-2" v-html="$t('combatResults.earnedSkill')"> </span>
                <Hint :text="$t('combatResults.hint')" />
              </div>
            </div>
            <div v-else>
              <div>
                <b>{{ formattedSkill(value) }}</b>
                <span>
                  <small class="mr-2">(<b>${{ fightRewardsAmountInUSD(value, key) }}</b>)</small>
                  <Hint :text="$t('combatResults.earnedValorHint')" />
                </span>
              </div>
              <div>
                <span class="mr-2" v-html="$t('combatResults.earnedValor')"> </span>
                <Hint :text="$t('combatResults.hint')" />
              </div>
            </div>
          </div>
          <div class="xp-gain" v-if="value.isVictory">
            + {{  formattedXpGain(value)  }}
          </div>
        </div>
      </div>
      <h6 class="text-center gas-spent">
        {{$t('combatResults.gasFee', {
          bnbGasUsed : fightResults.bnbGasUsed,
          gasToken : gasToken
          })
        }}
      </h6>
    </div>
  </div>
  <div v-if="showAds && !isMobile()" class="ad-container align-items-center mt-5">
    <script2 async src="https://coinzillatag.com/lib/display.js"></script2>
      <div class="coinzilla" data-zone="C-316621de2f7b8b25140"></div>
        <script2>
              window.coinzilla_display = window.coinzilla_display || [];
              var c_display_preferences = {};
              c_display_preferences.zone = "316621de2f7b8b25140";
              c_display_preferences.width = "300";
              c_display_preferences.height = "250";
              coinzilla_display.push(c_display_preferences);
        </script2>
  </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {fromWeiEther, toBN} from '../utils/common';
import {PropType} from 'vue/types/options';
import axios from 'axios';
import {getConfigValue} from '@/contracts';
import i18n from '@/i18n';
import {TranslateResult} from 'vue-i18n';
import '@/mixins/general';
import Hint from '@/components/Hint.vue';
import { mapActions, mapGetters, mapState } from 'vuex';
import { SupportedProject } from '@/views/Treasury.vue';
import { Accessors } from 'vue/types/options';
import { getCleanName } from '@/rename-censor';


interface StoreMappedTreasuryGetters {
  getPartnerProjects: SupportedProject[];
  getProjectMultipliers: Record<number, string>
}

interface CombatResult {
  isVictory: boolean;
  playerRoll: string
  enemyRoll: string;
  xpGain: string;
  skillGain: string;
}

interface StoreMappedTreasuryState {
  payoutCurrencyId: string;
  partnerProjectMultipliers: Record<number, string>;
  partnerProjectRatios: Record<number, string>;
  defaultSlippage: string;
}
interface StoreMappedTreasuryActions{
  getPartnerProjectMultiplier(id: number): Promise<string>;
  fetchPartnerProjects(): Promise<void>;
}

interface IFightResults {
  fightResultsMap: Record<number, CombatResult>,
  bnbGasUsed: string
}

export default Vue.extend({
  components: {
    Hint
  },
  props: {
    fightResults: {
      type: Object as PropType<IFightResults>,
      default() {
        return {} as IFightResults;
      },
    }
  },
  data() {
    return {
      skillPrice: 0,
      valorPrice: 0,
      gasToken: '',
      showAds: false,
      highestMultiplier: 0,
      highestMultiplierProject: {} as Record<string, SupportedProject>,
      partnerProjects: [] as SupportedProject[],
    };
  },
  watch: {
    getPartnerProjects(newval) {
      this.partnerProjects = newval;
      this.getProjectMultiplier('SKILL');
      this.getProjectMultiplier('VALOR');
    }
  },
  computed: {
    ...mapGetters([
      'getCharacterName',
      'ownCharacters'
    ]),
    ...(mapGetters('treasury', ['getPartnerProjects', 'getProjectMultipliers']) as Accessors<StoreMappedTreasuryGetters>),
    ...(mapState('treasury',
      ['payoutCurrencyId','partnerProjectRatios','defaultSlippage'])as Accessors<StoreMappedTreasuryState>)
  },
  methods: {
    ...(mapActions('treasury', ['getPartnerProjectMultiplier', 'fetchPartnerProjects']) as StoreMappedTreasuryActions),
    async fetchPrices(): Promise<void> {
      const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=cryptoblades,binancecoin&vs_currencies=usd');
      this.skillPrice = response.data?.cryptoblades.usd;
    },
    async fetchValorPrice(): Promise<void> {
      const response = await axios.get('https://api.dexscreener.com/latest/dex/pairs/bsc/0x8730c8dedc59e3baffb67bf1fa63d4f0e2d9ecc9');
      this.valorPrice = +response.data?.pair?.priceUsd || 0;
    },
    async getProjectMultiplier(tokenSymbol: 'SKILL' | 'VALOR') {
      const filteredPartnerProjects = this.partnerProjects && this.partnerProjects.filter(partnerProject => partnerProject.tokenSymbol.includes(tokenSymbol));
      if(filteredPartnerProjects.length > 0) {
        filteredPartnerProjects.map(async (project) => {
          await this.getPartnerProjectMultiplier(project.id);
        });
        const projectMultipliers = await this.getProjectMultipliers;
        this.highestMultiplierProject[tokenSymbol] = filteredPartnerProjects.sort((a, b) => {
          const highestMultiplierA = +(toBN(+projectMultipliers[a.id]).div(toBN(10).pow(18)).toFixed(4));
          const highestMultiplierB = +(toBN(+projectMultipliers[b.id]).div(toBN(10).pow(18)).toFixed(4));

          return highestMultiplierA - highestMultiplierB;
        })[0];
      }
    },
    getCleanCharacterName(id: string): string {
      return getCleanName(this.getCharacterName(id));
    },
    formattedInUsd(value: string): string {
      if(!value) return '';
      return `($${value})`;
    },
    calculateSkillPriceInUsd(skill: number): number {
      if(!skill) return 0;
      return (skill as unknown as number * this.skillPrice as unknown as number);
    },
    checkStorage() {
      if (process.env.NODE_ENV === 'development') this.showAds = false;
      else this.showAds = localStorage.getItem('show-ads') === 'true';
    },
    formattedOutcome(fightResults: CombatResult): TranslateResult {
      if(fightResults.isVictory) return i18n.t('combatResults.won');
      else return i18n.t('combatResults.lost');
    },
    formattedXpGain(fightResults: CombatResult): string {
      return fightResults.xpGain + ' xp';
    },
    isGenesisCharacter(characterID: number): boolean {
      const currentCharacter = this.ownCharacters[characterID];

      return currentCharacter?.version === 0;
    },
    formattedSkill(fightResults: CombatResult): string {
      return toBN(fromWeiEther(fightResults.skillGain)).toFixed(6);
    },
    fightRewardsAmountInUSD(fightResults: CombatResult, characterID: number): string {
      if(!this.isGenesisCharacter(characterID)) {
        return ((this.valorPrice * +this.formattedSkill(fightResults) * this.highestProjectMultiplier(characterID)) || 0).toFixed(4);
      } else {
        return ((this.skillPrice * +this.formattedSkill(fightResults) * this.highestProjectMultiplier(characterID)) || 0).toFixed(4);
      }
    },
    getAggregatedCharacterEarnings() {
      let totalEarnings = 0;
      for(const key in this.fightResults.fightResultsMap) {
        const fightResult = this.fightResults.fightResultsMap[key];

        if(!this.isGenesisCharacter(+key)) {
          totalEarnings += ((this.valorPrice * +this.formattedSkill(fightResult) * this.highestProjectMultiplier(+key)) || 0);
        } else {
          totalEarnings += ((this.skillPrice * +this.formattedSkill(fightResult) * this.highestProjectMultiplier(+key)) || 0);
        }
      }

      return totalEarnings.toFixed(4);
    },
    getCharactersWonAFight() {
      let winner = 0;
      for(const key in this.fightResults.fightResultsMap) {
        const fightResult = this.fightResults.fightResultsMap[key];

        if(fightResult.isVictory) {
          winner += 1;
        }
      }

      return winner;
    },
    highestProjectMultiplier(characterID: number): number {
      return +(toBN(+this.getProjectMultipliers[+this.highestMultiplierProject[!this.isGenesisCharacter(characterID) ? 'VALOR' : 'SKILL']?.id || 0])
        .div(toBN(10).pow(18)).toFixed(4) || 0);
    }
  },
  async mounted() {
    await this.fetchPartnerProjects();
    this.gasToken = getConfigValue('currencySymbol') || 'BNB';

    await this.fetchValorPrice();
    await this.fetchPrices();
    this.checkStorage();
  },
});
</script>

<style>
.results-panel {
  display: flex;
  flex-direction: row-reverse;
  justify-content: space-around;
  align-items: center;
  margin: auto;
  text-align: center;
}

.xp-gain,
.skill-gain {
  color: rgb(158, 138, 87) !important;
  font-family: Roboto;
  font-size: 14px;
}

.result-title {
  margin-bottom: 3em;
  color: #EDCD90;
}

.fight-result {
  color: #EDCD90;
}

.outcome {
  font-family: Trajan;
  font-size: 2em;
  padding: 0.1em;
  margin-top: 0.25em;
  margin-bottom: 1em;
}

.gas-spent {
  font-size: 1em;
  margin-bottom: 0;
}

.results-panel > div > div{
  margin-bottom: 40px;
}

.results-panel > div > div:nth-child(2) > div > div{
  text-align: center;
  padding: 0px;
}

.power-rolled{
  border-bottom: 1px solid rgba(255, 255, 255, 0.282);
  widows: 70%;
  margin: auto;
}

.power-rolled .win-details:nth-child(1){
  text-align: right;
}

.power-rolled .win-details:nth-child(2){
  text-align: center;
}

.power-rolled .win-details:nth-child(3){
  text-align: left;
  flex-wrap:nowrap;
}

.win-details{
  padding: 0px;
}

.win-details > h5{
  font-family: Roboto;
  color: rgba(255, 255, 255, 0.405);
  font-size: 1em;
  margin-bottom: 10px;
  margin-top: 10px;
}

.earned > h4{
  font-family: Roboto;
  color: #fff;
  font-size:1em;
}

.earned > h5{
  font-family: Roboto;
  color: rgb(186, 186, 4);
}

.gas-spent{
    font-family: Roboto;
    font-size: 0.8em;
    color: rgba(255, 255, 255, 0.357);
}

.win-details > img{
  width: 9px;
  margin-bottom: 10px;
  margin-top: 10px;
}

.you-earned > h4{
  font-size: 1.6em;
  font-family: 'Roboto', 'serif'  !important;
}

.ad-container {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.top-bg-img > img, .bot-bg-img > img {
    width: 69% !important;
}




@media all and (max-width: 600px) {
  /* .modal-dialog{
    margin-top: 10em;
  } */

  .outcome{
    font-size: 1.5em;
  }

  .modal-content{
    width: auto !important;
  }

  .float-center .container{
    padding: 0px !important;;
  }

  .float-center .container .power-rolled{
    padding: 0px !important;
    width: 100% !important;
  }
}

</style>
