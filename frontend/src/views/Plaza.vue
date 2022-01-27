<template>
  <div class="body main-font">
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
    <div v-if="soulCreationActive && haveCharacters">
      <div class="d-flex justify-content-space-between mb-3">
        <div class="chooser">
          <div class="navbar-staking">
            <button
              class="switch"
              :class="{ switch_active: !isUpgrading }"
              @click="isUpgrading = false;"
            >
              <span>{{$t('plaza.burn')}}</span>
            </button>
            <button
              class="switch"
              :class="{ switch_active: isUpgrading }"
              @click="isUpgrading = true; clearAllBurn();"
            >
              <span>{{$t('plaza.upgrade')}}</span>
            </button>
          </div>
        </div>
        <div class="d-flex justify-content-flex-end ml-auto">
          <b-button
            v-if="!isUpgrading"
            variant="primary"
            class="ml-3"
            @click="showBurnConfirmation"
            v-tooltip="$t('plaza.burnSelected')"
            :disabled="burnCharacterIds.length === 0 || powerLimitExceeded || (burnOption === 1 && !targetCharacterId) || !canBurn()">
            {{$t('plaza.burn')}}: {{burnCharacterIds.length}} {{$t('characters')}}<br>
            ({{burnCost }} SKILL)
          </b-button>
          <b-button
            v-if="isUpgrading"
            variant="primary"
            class="ml-3"
            @click="showUpgradeConfirmation"
            v-tooltip="$t('plaza.upgradeSelected')"
            :disabled="soulAmount.toString() === '0' || !targetCharacterId || powerLimitExceeded">
            {{$t('plaza.upgrade')}} {{$t('character')}}<br>
            ({{soulAmount}} {{$t('plaza.soul')}})
          </b-button>
          <b-button
            variant="primary"
            class="ml-3 gtag-link-others"
            @click="toggleSoulCreation"
            v-tooltip="$t('plaza.recruitNew')">
            {{$t('plaza.cancelBurning')}}
          </b-button>
        </div>
      </div>
      <div>
        <div class="col-md-12">
          <div class="row mobile-flip">
            <div class="col-md-4 character-container" v-if="!isUpgrading">
              <h1 align="center" class="text-center">{{$t('plaza.selectBurnCharacter')}}</h1>
              <character-list :showFilters="true" :showGivenCharacterIds="true" :characterIds="remainingCharactersIds" @input="addBurnCharacter"/>
            </div>
            <div class="col-md-4 character-container" v-if="!isUpgrading">
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
            <div class="col-md-8 d-flex character-container flex-column align-items-center" v-if="isUpgrading">
              <h1 align="center" class="text-center">{{$t('plaza.selectSoulAmount')}}</h1>
              <div class="soul-image mt-5" />
              <h2>Soul</h2>
              <div class="range">
                <div class="boxed soul-box">
                  <h2>{{soulAmount}}/{{soulBalance}}</h2>
                </div>
                <div class="field">
                  <div class="value left">0</div>
                  <input v-model="soulAmount" type="range" min="0" :max="soulBalance" value="0" steps="1">
                  <div class="value right">{{ soulBalance }}</div>
                </div>
              </div>
            </div>
            <div class="col-md-4">
              <div class="d-flex flex-row w-100 align-items-center mt-2">
                <h3 class="mt-2">{{isUpgrading ? $t('plaza.characterToUpgrade') : $t('plaza.burnInto')}}:</h3>
                <b-form-select v-if="!isUpgrading" class="w-50 ml-1" size="sm" :value="burnOption" v-model="burnOption">
                  <b-form-select-option :value="0">{{$t('plaza.soul')}}</b-form-select-option>
                  <b-form-select-option :value="1">{{$t('character')}}</b-form-select-option>
                </b-form-select>
              </div>
              <div v-if="burnOption === 0 && !isUpgrading" class="d-flex flex-column mt-3 align-items-center">
                <div class="soul-image" />
                <h2>Soul</h2>
                <h2>{{soulBalance}} (+{{Math.floor(burnPower/10)}})</h2>
              </div>
              <div v-if="burnOption === 1 || isUpgrading" :class="targetCharacterId ? 'd-flex flex-column align-items-center' : ''">
                <b-button
                  v-if="targetCharacterId"
                  variant="primary"
                  class="mt-4"
                  @click="clearTargetCharacterId()">
                  {{$t('plaza.clearTargetCharacterId')}}
                </b-button>
                <character-list :showFilters="true" v-if="!targetCharacterId" :showGivenCharacterIds="true"
                  :characterIds="remainingCharactersIds" @input="selectTargetCharacterId"/>
                <character-list class="mt-4" v-if="targetCharacterId" :showGivenCharacterIds="true"
                  :characterIds="[targetCharacterId]" />
                <div v-if="targetCharacterId">
                  <h2 :class="powerLimitExceeded ? 'text-danger' : ''">{{$t('CharacterDisplay.power')}} +{{burnPower}}/{{remainingPowerLimit}}</h2>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <b-tabs justified v-if="!soulCreationActive">
      <b-tab @click="garrisonTabActive = false" v-if="haveCharacters">
        <template #title>
          {{$t('plaza.plaza')}}
          <hint class="hint" :text="$t('plaza.plazaHint')" />
        </template>
        <div class="row mt-3">
          <div class="col">
            <div>
              <div class="d-flex justify-content-space-between">
                <h1>{{$t('characters')}} ({{ ownCharacters.length }} / 4)</h1>
                <div class="d-flex justify-content-flex-end ml-auto">
                  <b-button
                    v-if="burningEnabled"
                    :disabled="!haveCharacters"
                    variant="primary"
                    class="ml-3 gtag-link-others"
                    @click="toggleSoulCreation"
                    v-tooltip="$t('plaza.recruitNew')" tagname="recruit_character">
                    {{$t('plaza.burn')}} / {{$t('plaza.upgrade')}}
                  </b-button>
                  <b-button
                    :disabled="!canRecruit()"
                    variant="primary"
                    class="ml-3 gtag-link-others"
                    @click="onMintCharacter"
                    v-tooltip="$t('plaza.recruitNew')" tagname="recruit_character">
                    {{$t('plaza.recruit')}} ({{ recruitCost }} NON-IGO SKILL) <i class="fas fa-plus"></i>
                  </b-button>
                </div>
              </div>

              <character-list
                :value="currentCharacterId"
                :showNftOptions="true"
                @input="setCurrentCharacter"
              />
            </div>
          </div>
        </div>
      </b-tab>
      <b-tab @click="garrisonTabActive = true" v-if="haveCharacters">
        <template #title>
          {{$t('plaza.garrison')}}
          <hint class="hint" :text="$t('plaza.garrisonHint')" />
        </template>
        <div class="row mt-3">
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
                    {{$t('plaza.claimXp')}}
                  </b-button>
                  <b-button
                    v-if="burningEnabled"
                    :disabled="!haveCharacters"
                    variant="primary"
                    class="ml-3 gtag-link-others"
                    @click="toggleSoulCreation"
                    v-tooltip="$t('plaza.recruitNew')">
                    {{$t('plaza.burn')}} / {{$t('plaza.upgrade')}}
                  </b-button>
                  <b-button
                    v-if="ownCharacters.length === 4"
                    :disabled="!canRecruit()"
                    variant="primary"
                    class="ml-3 gtag-link-others"
                    @click="onMintCharacter"
                    v-tooltip="$t('plaza.recruitNew')" tagname="recruit_character">
                    {{$t('plaza.recruit')}} ({{ recruitCost }} NON-IGO SKILL) <i class="fas fa-plus"></i>
                  </b-button>
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
      </b-tab>
    </b-tabs>
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
    <b-modal class="centered-modal text-center" ref="upgrade-confirmation-modal" :title="$t('plaza.upgradeConfirmation')"
      @ok="onUpgradeConfirm" :ok-disabled="!targetCharacterId || !soulAmount">
      <div class="d-flex flex-column align-items-center">
        <character-list class="mt-2 justify-content-center" v-if="targetCharacterId" :showGivenCharacterIds="true"
          :characterIds="[targetCharacterId]" />
      </div>
      <div class="text-center">
        <b-icon icon="exclamation-circle" variant="danger" />
        {{ $t('plaza.upgradeConfirm') }}: {{ soulAmount }} {{ $t('plaza.soul') }}<br>
        {{ $t('plaza.cantBeUndone') }}
      </div>
      <div class="text-center">
        <b-icon icon="exclamation-circle" variant="danger" /> {{ $t('plaza.noRefunds')}}
      </div>
    </b-modal>
  </div>
</template>

<script lang='ts'>
import BN from 'bignumber.js';
import BigButton from '../components/BigButton.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import Hint from '../components/Hint.vue';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import { fromWeiEther, toBN } from '../utils/common';
import Vue from 'vue';
import i18n from '@/i18n';
import { BModal } from 'bootstrap-vue';
import { CharacterPower } from '@/interfaces';

import {
  burningManager as featureFlagBurningManager
} from '../feature-flags';

interface Data {
  recruitCost: string;
  garrisonTabActive: boolean;
  showAds: boolean;
  soulCreationActive: boolean;
  burnCharacterIds: string[];
  remainingCharactersIds: string[];
  targetCharacterId: string;
  burnOption: number;
  soulBalance: number;
  burnCost: number;
  isUpgrading: boolean;
  soulAmount: number;
  remainingPowerLimit: number;
  burnPowerMultiplier: number;
  isClaimingXp: boolean;
}

export default Vue.extend({
  computed: {
    ...mapState(['characters', 'ownedGarrisonCharacterIds', 'maxStamina', 'currentCharacterId', 'defaultAccount', 'skillBalance', 'xpRewards']),
    ...mapGetters([
      'contracts',
      'ownCharacters',
      'ownGarrisonCharacters',
      'currentCharacter',
      'currentCharacterStamina',
      'getCharacterName',
      'getExchangeUrl',
      'getCharacterPower',
      'getCharacterIsInArena'
    ]),

    character(): any {
      if (!this.currentCharacter) {
        return {
          id: null,
          name: '???',
          level: -1,
          experience: -1,
        };
      }

      const c = this.currentCharacter;
      return {
        id: c.id,
        name: this.getCharacterName(c.id),
        level: c.level,
        experience: c.xp,
      };
    },

    haveCharacters(): boolean {
      return this.ownedGarrisonCharacterIds.length > 0 || this.ownCharacters.length > 0;
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

    burningEnabled(): boolean {
      return featureFlagBurningManager;
    },

    canClaimGarrisonXp(): boolean {
      return this.ownedGarrisonCharacterIds.filter((id: string|number) => +this.xpRewards[id] > 0).length > 0;
    }
  },

  async created() {
    console.log(this.getExchangeUrl, this.getExchangeTransakUrl());
    const recruitCost = await this.contracts.CryptoBlades.methods.mintCharacterFee().call({ from: this.defaultAccount });
    const skillRecruitCost = await this.contracts.CryptoBlades.methods.usdToSkill(recruitCost).call();
    this.recruitCost = new BN(skillRecruitCost).div(new BN(10).pow(18)).toFixed(4);
  },

  data() {
    return {
      recruitCost: '0',
      garrisonTabActive: false,
      showAds: false,
      soulCreationActive: false,
      burnCharacterIds: [],
      remainingCharactersIds: [],
      targetCharacterId: '',
      burnOption: 0,
      soulBalance: 0,
      burnCost: 0,
      isUpgrading: false,
      soulAmount: 0,
      remainingPowerLimit: 0,
      burnPowerMultiplier: 1,
      isClaimingXp: false
    } as Data;
  },

  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions(['mintCharacter', 'fetchSoulBalance', 'fetchCharactersBurnCost', 'upgradeCharacterWithSoul',
      'burnCharactersIntoSoul', 'burnCharactersIntoCharacter', 'claimGarrisonXp', 'fetchBurnPowerMultiplier']),
    ...mapGetters(['getExchangeTransakUrl']),

    async onMintCharacter() {
      try {
        await this.mintCharacter();
      } catch (e) {
        (this as any).$dialog.notify.error(i18n.t('plaza.couldNotMint'));
      }
    },
    formatSkill() {
      return fromWeiEther(this.skillBalance);
    },
    canRecruit() {
      const cost = toBN(this.recruitCost);
      const balance = toBN(this.skillBalance);
      return balance.isGreaterThanOrEqualTo(cost);
    },
    canBurn() {
      const cost = toBN(this.burnCost);
      const balance = toBN(+fromWeiEther(this.skillBalance));
      return balance.isGreaterThanOrEqualTo(cost);
    },
    checkStorage() {
      this.showAds =  localStorage.getItem('show-ads') === 'true';
    },
    async toggleSoulCreation() {
      this.soulCreationActive = !this.soulCreationActive;
      this.soulBalance = await this.fetchSoulBalance();
      await this.updateBurnCost();
      this.burnPowerMultiplier = +fromWeiEther(await this.fetchBurnPowerMultiplier());
      if(this.soulCreationActive) {
        this.remainingCharactersIds = this.ownCharacters.map((x: { id: string; }) => x.id.toString()).concat(this.ownedGarrisonCharacterIds as string[]);
      }
      this.isUpgrading = false;
    },
    async updateBurnCost() {
      this.burnCost = this.burnCharacterIds.length > 0 ? +fromWeiEther(await this.fetchCharactersBurnCost(this.burnCharacterIds)) : 0;
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
    selectTargetCharacterId(id: number) {
      this.targetCharacterId = id.toString();
      this.remainingCharactersIds = this.remainingCharactersIds.filter(val => val.toString() !== this.targetCharacterId);
      this.updatedRemainingPowerLimit();
    },
    updatedRemainingPowerLimit() {
      const targetCharacter = this.ownCharacters.concat(this.ownGarrisonCharacters)
        .find((x: { id: any; }) => x.id.toString() === this.targetCharacterId.toString());
      this.remainingPowerLimit = 4 * CharacterPower(targetCharacter.level) - this.getCharacterPower(this.targetCharacterId.toString());
    },
    clearTargetCharacterId() {
      this.remainingCharactersIds.push(this.targetCharacterId);
      this.targetCharacterId = '';
      this.remainingPowerLimit = 0;
    },
    clearAllBurn(){
      this.burnCharacterIds = [];
      this.remainingCharactersIds = (this.ownCharacters.map((x: { id: string; }) => x.id.toString())
        .concat(this.ownedGarrisonCharacterIds) as string[])
        .filter(x => x.toString() !== this.targetCharacterId);
      this.burnCost = 0;
    },
    showBurnConfirmation() {
      (this.$refs['burn-confirmation-modal'] as BModal).show();
    },
    showUpgradeConfirmation() {
      (this.$refs['upgrade-confirmation-modal'] as BModal).show();
    },
    async onBurnConfirm() {
      if(this.burnCharacterIds.length === 0) return;
      if(this.burnOption === 0) {
        // burning into soul
        await this.burnCharactersIntoSoul(this.burnCharacterIds);
      }
      else {
        // burning into character
        await this.burnCharactersIntoCharacter({ burnIds: this.burnCharacterIds, targetId: this.targetCharacterId });
        this.updatedRemainingPowerLimit();
      }
      this.soulBalance = await this.fetchSoulBalance();
      this.burnCharacterIds = [];
      this.burnCost = 0;
    },
    async onUpgradeConfirm() {
      if(!this.targetCharacterId || this.soulAmount === 0) return;
      await this.upgradeCharacterWithSoul({ charId: this.targetCharacterId, soulAmount: this.soulAmount });
      this.updatedRemainingPowerLimit();
      this.soulBalance = await this.fetchSoulBalance();
      this.soulAmount = 0;
    },
    async onClaimGarrisonXp() {
      this.isClaimingXp = true;
      await this.claimGarrisonXp(this.ownedGarrisonCharacterIds.filter((id: string|number) => +this.xpRewards[id] > 0));
      this.isClaimingXp = true;
    }
  },

  async mounted() {
    this.checkStorage();
  },

  components: {
    BigButton,
    CharacterList,
    Hint
  },
});
</script>

<style scoped>

.current-promotion {
  width: 40%;
  text-align: center;
}

@media all and (max-width:  767.98px) {
  .current-promotion {
    width: 100vw;
    margin-top: 90px;
    padding-left: 15px;
  }
}

.promotion-decoration {
  width: 100%;
  margin-left: auto;
  margin-right: auto;
  margin-top: 10px;
  margin-bottom: 10px;
}

.upper-text {
  text-transform: uppercase;
}

.character-container {
  border-right: 1px solid #9e8a57;
}

.soul-image {
  content: url("../assets/dusts/soulDust.png");
  max-width: 8em;
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

.soul-box {
  min-width: 140px;
  text-align: center;
}
</style>
