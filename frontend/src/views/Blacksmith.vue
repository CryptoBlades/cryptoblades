<template>
  <div class="body main-font">
    <b-tabs justified>
      <b-tab :title="$t('weapons')">
        <div class="blank-slate" v-if="ownWeapons.length === 0">
          <span v-html="$t('blacksmith.noWeapons')"/>
          <br>
          <br>
          <big-button
            class="button"
            :mainText="$t('blacksmith.forgeSwordFor') + ` ${forgeCost} SKILL`"
            @click="onForgeWeapon"
          />
        </div>
        <div class="row mt-3" v-if="ownWeapons.length > 0 && !showReforge">
          <div class="col">
            <div class="d-flex justify-content-space-between">
              <h1>{{$t('weapons')}} ({{ ownWeapons.length }})</h1>
              <div class="d-flex justify-content-flex-end ml-auto">
                <b-button
                        variant="primary"
                        class="ml-3"
                        v-if="reforgeWeaponId !== null && ownWeapons.length > 0"
                        @click="displayDustReforge()"
                        tagname="reforge_weapon"
                        v-tooltip="$t('blacksmith.useDust')">
                  {{$t('blacksmith.reforgeWithDust')}}
                </b-button>
                <b-button
                        variant="primary"
                        class="ml-3"
                        @click="displayDustCreation()"
                        tagname="reforge_weapon"
                        v-tooltip="$t('blacksmith.burnWeapons')">
                  {{$t('blacksmith.createDust')}}
                </b-button>
                <b-button
                        variant="primary"
                        class="ml-3"
                        @click="onClickSpecialForge()"
                        :disabled="disableForge"
                        v-tooltip="$t('blacksmith.specialForgeTooltip')">
                  <span v-if="disableForge">{{$t('blacksmith.coolingForge')}}</span>
                  <span v-else class="gtag-link-others">
                    {{$t('blacksmith.specialForge')}}
                  </span>
                </b-button>
                <b-button
                        variant="primary"
                        class="ml-3"
                        @click="onClickForge(0)"
                        :disabled="disableForge"
                        v-tooltip="$t('blacksmith.forgeNew')">
                  <span v-if="disableForge">{{$t('blacksmith.coolingForge')}}</span>
                  <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                    {{$t('blacksmith.forge')}} x1 ({{ forgeCost }} SKILL) <i class="fas fa-plus"></i>
                  </span>
                </b-button>

                <b-button
                        variant="primary"
                        class="ml-3"
                        @click="onClickForge(1)"
                        :disabled="disableForge || (disableX10ForgeWithStaked && useStakedForForge)"
                        v-tooltip="$t('blacksmith.forge10New')">
                  <span v-if="disableForge">{{$t('blacksmith.coolingForge')}}</span>
                  <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                    {{$t('blacksmith.forge')}} x10 ({{ (forgeCost*10).toFixed(4) }} SKILL)
                    <i class="fas fa-plus"></i>
                  </span>
                </b-button>
                  <b-checkbox
                    variant="primary"
                    class="mx-3 my-auto"
                    :disabled="disableUseStakedForForge"
                    v-model="useStakedForForge">
                    <span v-if="disableUseStakedForForge"> <b>{{$t('blacksmith.notEnoughStakedSkill')}}<br></b></span>
                    <span v-html="$t('blacksmith.spendStakedFunds')"></span>
                  </b-checkbox>
                <b-icon-question-circle class="centered-icon" scale="1.5"
                  v-on:click="onShowForgeDetails" v-tooltip.bottom="$t('blacksmith.clickForForgePercentages')"/>

                <b-modal hide-footer ref="forge-details-modal" :title="$t('blacksmith.forgePercentages')">
                  <div>
                    {{$t('blacksmith.forgePercentage.5star')}} {{Number.parseFloat(forgeCost * (1/0.01)).toFixed(2)}} SKILL.
                  </div>
                  <div>
                    {{$t('blacksmith.forgePercentage.4star')}} {{Number.parseFloat(forgeCost * (1/0.06)).toFixed(2)}} SKILL.
                  </div>
                  <div>
                    {{$t('blacksmith.forgePercentage.3star')}} {{Number.parseFloat(forgeCost * (1/0.21)).toFixed(2)}} SKILL.
                  </div>
                  <div>
                    {{$t('blacksmith.forgePercentage.2star')}} {{Number.parseFloat(forgeCost * (1/0.56)).toFixed(2)}} SKILL.
                  </div>
                  <div>
                    {{$t('blacksmith.forgePercentage.1star')}}
                  </div>
                </b-modal>

                <b-modal hide-footer ref="forge-element-selector-modal" title="Select Element">
                  <div class="row justify-content-md-center select-elements-container">
                    <div id="random-border" v-on:click="setChosenElement($event, 100)"> </div>
                    <div id="fire-border" v-on:click="setChosenElement($event, 0)"> </div>
                    <div id="earth-border" v-on:click="setChosenElement($event, 1)"> </div>
                    <div id="lightning-border" v-on:click="setChosenElement($event, 2)"> </div>
                    <div id="water-border" v-on:click="setChosenElement($event, 3)"> </div>
                  </div>
                  <div v-if="activeSpecialWeaponEventsIds.length > 0" class="row justify-content-md-center select-elements-container align-items-baseline mt-4">
                    <h5>{{$t('blacksmith.pickSpecialEvent')}}:</h5>
                    <h6 class="mt-2">{{$t('blacksmith.specialEvent')}}:</h6>
                    <b-form-select class="w-50 ml-1" size="sm" v-model="selectedSpecialWeaponEventId"
                      :value="selectedSpecialWeaponEventId" @change="updateSpecialWeaponEventId($event)">
                      <b-form-select-option v-for="id in activeSpecialWeaponEventsIds" :key="id" :value="id">
                        {{specialWeaponEvents[id] && specialWeaponEvents[id].name}}
                      </b-form-select-option>
                    </b-form-select>
                  </div>
                  <div class="row justify-content-md-center margin-top">
                    <b-button
                      v-if="clickedForgeButton === 0"
                      variant="primary"
                      class="row justify-content-md-center"
                      @click="onForgeWeapon"
                      :disabled="disableConfirmButton"
                      v-tooltip="$t('blacksmith.forgeNew')">
                        <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                          {{$t('blacksmith.forge')}} ({{Number.parseFloat(forgeCost * this.chosenElementFee).toFixed(2)}} SKILL)
                        </span>
                    </b-button>
                    <b-button
                      v-if="clickedForgeButton === 1"
                      variant="primary"
                      class="row justify-content-md-center"
                      @click="onForgeWeaponx10"
                      :disabled="disableConfirmButton"
                      v-tooltip="$t('blacksmith.forge10New')">
                        <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                          {{$t('blacksmith.forge')}} ({{Number.parseFloat(forgeCost * this.chosenElementFee * 10).toFixed(2)}} SKILL)
                        </span>
                    </b-button>
                  </div>
                </b-modal>
                <b-modal size="xl" class="centered-modal " ref="new-weapons" ok-only>
                  <template #modal-header>
                    <div v-if="!spin" class="new-weapon-header-text text-center">
                      <strong>{{$t('blacksmith.forgeResults')}}</strong>
                    </div>
                    <div v-if="spin" class="new-weapon-header-text text-center">
                      <strong>{{$t('blacksmith.forgingSwords')}}</strong>
                    </div>
                  </template>
                  <div class="text-center">
                    <b-spinner v-if="spin" type="grow" :label="$t('blacksmith.loading')"></b-spinner>
                    <b-spinner v-if="spin" type="grow" :label="$t('blacksmith.loading')"></b-spinner>
                    <b-spinner v-if="spin" type="grow" :label="$t('blacksmith.loading')"></b-spinner>
                  </div>
                  <weapon-grid v-if="!spin" :showGivenWeaponIds="true" :weaponIds="newForged" :newWeapon="true"/>
                  <template #modal-footer></template>
                </b-modal>
              </div>
            </div>
            <div class="" v-if="showBlacksmith">
              <weapon-grid :showNftOptions="true" v-model="reforgeWeaponId" />
            </div>
          </div>
        </div>

        <div class="row mt-3" v-if="showReforge && !showReforgeDust">
          <div class="col">
            <div class="d-flex justify-content-space-between">
              <h1>{{$t('blacksmith.createDust')}}</h1>
              <div class="d-flex justify-content-flex-end ml-auto">
                <b-button
                        variant="primary"
                        tagname="confirm_forge_weapon"
                        class="confirmReforge ml-3"
                        @click="showMassDustConfirmation"
                        v-tooltip="$t('blacksmith.burnSelected')"
                        :disabled="burnWeaponIds.length === 0">
                  {{$t('blacksmith.createDust')}}: {{burnWeaponIds.length}} {{$t('weapons')}}
                  <br>
                  ({{burnCost * burnWeaponIds.length }} SKILL)
                </b-button>
                <b-button
                        variant="primary"
                        tagname="confirm_forge_weapon"
                        class="confirmReforge ml-3"
                        @click="cancelReforge()"
                        v-tooltip="$t('blacksmith.cancelWeaponDusting')">
                        {{$t('blacksmith.cancelDusting')}}
                </b-button>
              </div>
            </div>
          </div>
        </div>

        <div class="row mt-3">
          <div class="col-md-12" v-if="showReforge && showReforgeDust === true">
            <div>
              <div class="col-lg-12 weapon-container">
                <div class="col-lg-12">
                  <h1 class="text-center">{{$t('blacksmith.selectDustAmount')}}</h1>
                </div>
                <div class="row">
                  <div class="col-lg-2"></div>
                  <div class="col-lg-2 dust-container" align="center">
                    <div class="dust">
                      LB: <span class="text-warning">15 {{$t('blacksmith.powerPerLevel')}}</span>
                      <div class="dust-image1"></div>
                    </div>
                    <h2 class="text-center">{{$t('blacksmith.lesser')}}</h2>
                    <div class="boxed">
                      <h2>{{lesserDust}}/{{getLesserDust()}}</h2>
                    </div>
                    <div class="range">
                      <div class="sliderValue">
                        <span>100</span>
                      </div>
                      <div class="field">
                        <div class="value left">0</div>
                        <input v-model="lesserDust" type="range" min="0" :max="getLesserDust()" value="0" steps="1">
                        <div class="value right">{{getLesserDust()}}</div>
                      </div>
                    </div>
                  </div>
                  <div class="col-lg-2 dust-container" align="center">
                    <div class="dust">
                      4B: <span class="text-warning">30 {{$t('blacksmith.powerPerLevel')}}</span>
                      <div class="dust-image2"></div>
                    </div>
                    <h2 class="text-center">{{$t('blacksmith.greater')}}</h2>
                    <div class="boxed">
                      <h2>{{greaterDust}}/{{getGreaterDust()}}</h2>
                    </div>
                    <div class="range">
                      <div class="sliderValue">
                        <span>100</span>
                      </div>
                      <div class="field">
                        <div class="value left">0</div>
                        <input v-model="greaterDust" type="range" min="0" :max="getGreaterDust()" value="0" steps="1">
                        <div class="value right">{{getGreaterDust()}}</div>
                      </div>
                    </div>
                  </div>
                  <div class="col-lg-2 weapon-container dust-container" align="center">
                    <div class="dust">
                      5B: <span class="text-warning">75 {{$t('blacksmith.powerPerLevel')}}</span>
                      <div class="dust-image3"></div>
                    </div>
                    <h2 class="text-center">{{$t('blacksmith.powerful')}}</h2>
                    <div class="boxed">
                      <h2>{{powerfulDust}}/{{getPowerfulDust()}}</h2>
                    </div>
                    <div class="range">
                      <div class="sliderValue">
                        <span>0</span>
                      </div>
                      <div class="field">
                        <div class="value left">0</div>
                        <input v-model="powerfulDust" type="range" min="0" :max="getPowerfulDust()" value="0" steps="1">
                        <div class="value right">{{getPowerfulDust()}}</div>
                      </div>
                    </div>
                  </div>
                  <div class="col-lg-3">
                    <div v-if="showReforge && showDustForge === false">
                      <div class="confirmReforge">
                        <div class="weapon" :hidden="reforgeWeaponId === null">
                          <div v-if="$slots.above || $scopedSlots.above">
                            <slot name="above" :weapon="getWeaponToUpgrade()"></slot>
                          </div>
                          <div class="weapon-icon-wrapper">
                            <weapon-icon v-if="getWeaponToUpgrade()" class="weapon-icon" :weapon="getWeaponToUpgrade()" />
                          </div>
                          <div class="text-center" :hidden="burnWeaponId === 0"></div>
                        </div>
                        <b-button
                                variant="primary"
                                tagname="confirm_forge_weapon"
                                class="confirmReforge"
                                @click="showDustReforgeConfirmation"
                                :disabled="lesserDust == '0' && greaterDust == '0' && powerfulDust == '0'"
                                v-tooltip="$t('blacksmith.reforgeSelected')">
                          {{$t('blacksmith.confirmReforge')}}
                          <br>
                          <br>
                          {{$t('blacksmith.use')}}: {{lesserDust}} {{$t('blacksmith.lesser')}}
                          <br>
                          {{$t('blacksmith.use')}}: {{greaterDust}} {{$t('blacksmith.greater')}}
                          <br>
                          {{$t('blacksmith.use')}}: {{powerfulDust}} {{$t('blacksmith.powerful')}}
                          <br>
                          ({{ dustReforgeCost }} SKILL)
                        </b-button>
                        <b-button
                                variant="primary"
                                tagname="confirm_forge_weapon"
                                class="confirmReforge"
                                @click="displayBlacksmith()"
                                v-tooltip="$t('blacksmith.cancelReforge')">
                          {{$t('blacksmith.cancelReforge')}}
                        </b-button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="row mt-3">
          <div class="col-md-12" v-if="showReforge && showReforgeDust === false">
            <div>
              <div class="col-md-12">
                <div class="row mobile-flip">
                  <div class="col-md-5 weapon-container" align="center">
                    <h1 class="text-center">{{$t('blacksmith.selectBurnWeapon')}}</h1>
                    <weapon-grid v-model="burnWeaponId" :ignore="burnWeaponIds"
                      :showGivenWeaponIds="true" :weaponIds="hideWeapons" @chooseweapon="addBurnWeapon" />
                  </div>
                  <div class="col-md-4 weapon-container">
                    <div v-if="showReforge && showDustForge === true">
                      <h1 class="text-center">
                        <b-button
                                variant="primary"
                                tagname="confirm_forge_weapon"
                                class="multiForging"
                                @click="clearAllMassBurn()"
                                v-tooltip="$t('blacksmith.clearAll')"
                                :disabled="burnWeaponIds === []">
                          {{$t('blacksmith.clearAll')}}
                        </b-button>
                      </h1>
                      <div class="weapon-grid-container">
                        <weapon-grid :showGivenWeaponIds="true" :weaponIds="burnWeaponIds" @chooseweapon="removeBurnWeapon" />
                      </div>
                    </div>
                  </div>
                  <div class="col-md-3 upgrade-container">
                <div v-if="showReforge && showDustForge === true">
                  <div class="confirmReforge">
                    <h2 class="text-center">{{$t('blacksmith.createDust')}}</h2>
                        <div class="dust-image1"></div>
                      <h2 class="text-center">{{$t('blacksmith.lesser')}}</h2>
                        <h2>{{getLesserDust()}}</h2>
                        <div class="dust-image2"></div>
                      <h2 class="text-center">{{$t('blacksmith.greater')}}</h2>
                        <h2>{{getGreaterDust()}}</h2>
                        <div class="dust-image3"></div>
                      <h2 class="text-center">{{$t('blacksmith.powerful')}}</h2>
                        <h2>{{getPowerfulDust()}}</h2>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
          </div>
        </div>
      </b-tab>
      <b-tab>
        <template #title>
          {{$t('equipment')}} <b-icon-question-circle class="centered-icon" scale="0.8"
            v-tooltip.bottom="$t('blacksmith.buyShield')"/>
        </template>
        <div class="row mt-3">
          <div class="col">
            <div class="d-flex justify-content-space-between">
              <h1>{{$t('equipment')}} ({{ nftsCount }})</h1>
            </div>
            <nft-list v-if="nftsCount > 0" v-model="selectedNft"/>
          </div>
        </div>
      </b-tab>
      <b-tab>
        <template #title>
          {{$t('blacksmith.dustStorage')}} <b-icon-question-circle class="centered-icon" scale="0.8" v-tooltip.bottom="$t('blacksmith.dustGained')"/>
        </template>
        <dust-balance-display/>
      </b-tab>
      <b-tab>
        <template #title>
          {{$t('blacksmith.lands')}} <b-icon-question-circle class="centered-icon" scale="0.8" v-tooltip.bottom="$t('blacksmith.landsAvailable')"/>
        </template>
        <div class="row mt-3">
          <div class="col">
            <nft-list :isLandTab="true" :showLimit="30" />
          </div>
        </div>
      </b-tab>
    </b-tabs>
    <b-modal class="centered-modal text-center" ref="dustreforge-confirmation-modal"
             :title="$t('blacksmith.dustReforgeConfirmation')" @ok="onReforgeWeaponWithDust">
      <div class="row">
        <div class="headings">
          <h2 class="text-center">{{$t('blacksmith.upgrade')}}</h2>
          <div class="weapon" v-if="reforgeWeaponId">
            <div v-if="$slots.above || $scopedSlots.above">
              <slot name="above" :weapon="getWeaponToUpgrade()"></slot>
            </div>
            <div class="weapon-icon-wrapper">
              <weapon-icon v-if="getWeaponToUpgrade()" class="weapon-icon" :weapon="getWeaponToUpgrade()" />
            </div>
          </div>
        </div>
      </div>
      <br/>
      <div class="text-center" v-text="$t('blacksmith.reforgeConfirm')" />
      <p class="text-center">
        {{lesserDust}} {{$t('blacksmith.lesser')}} {{$t('blacksmith.dust')}}
        <br>
        {{greaterDust}} {{$t('blacksmith.greater')}} {{$t('blacksmith.dust')}}
        <br>
        {{powerfulDust}} {{$t('blacksmith.powerful')}} {{$t('blacksmith.dust')}}
      </p>
      <div class="text-center">
        <b-icon icon="exclamation-circle" variant="danger" /> {{$t('blacksmith.cantBeUndone')}}
      </div>
    </b-modal>

    <b-modal class="centered-modal text-center" ref="mass-dust-confirmation-modal" :title="$t('blacksmith.reforgeConfirmation')" @ok="onMassBurnWeapons">
      <div class="text-center">
        <b-icon icon="exclamation-circle" variant="danger" />
        {{ $t('blacksmith.burnWarning', { weaponAmount: burnWeaponIds.length })}}
        {{ $t('blacksmith.cantBeUndone')}}
      </div>
      <div class="text-center">
        <b-icon icon="exclamation-circle" variant="danger" /> {{ $t('blacksmith.noRefunds')}}
      </div>
    </b-modal>

    <b-modal class="centered-text-modal" ref="reforge-bonuses-modal" :title="$t('blacksmith.reforgeBonuses')">
      <div>
        {{ $t('blacksmith.reforgeBonus.5star')}}
      </div>
      <div>
        {{ $t('blacksmith.reforgeBonus.4star')}}
      </div>
      <div>
        {{ $t('blacksmith.reforgeBonus.3star')}}
      </div>
      <div>
        {{ $t('blacksmith.reforgeBonus.2star')}}
      </div>
      <div>
        {{ $t('blacksmith.reforgeBonus.1star')}}
      </div>
    </b-modal>
    <SpecialWeaponForgeModal />
  </div>
</template>

<script lang='ts'>
import BN from 'bignumber.js';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import BigButton from '../components/BigButton.vue';
import Vue from 'vue';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import WeaponIcon from '../components/WeaponIcon.vue';
import { BModal } from 'bootstrap-vue';
import NftList from '@/components/smart/NftList.vue';
import { Contracts, IState } from '@/interfaces';
import { Accessors } from 'vue/types/options';
import DustBalanceDisplay from '@/components/smart/DustBalanceDisplay.vue';
import { fromWeiEther, toBN } from '@/utils/common';
import i18n from '@/i18n';
import Events from '../events';
import SpecialWeaponForgeModal from '@/components/smart/SpecialWeaponForgeModal.vue';

type StoreMappedState = Pick<IState, 'defaultAccount' | 'ownedWeaponIds' | 'skillBalance' | 'inGameOnlyFunds' | 'skillRewards' |
'specialWeaponEvents' | 'activeSpecialWeaponEventsIds' | 'specialWeaponEventId'>;

interface StoreMappedGetters {
  contracts: Contracts;
  ownWeapons: any[];
  nftsCount: number;
  stakedSkillBalanceThatCanBeSpent: number;
}

interface Data {
  showReforge: boolean;
  showBlacksmith: boolean,
  showDustForge: boolean,
  showReforgeDust: boolean,
  reforgeWeaponId: string | null;
  burnWeaponId: string | null;
  selectedNft: string | null;
  forgeCost: string;
  reforgeCost: string;
  dustReforgeCost: string,
  burnCost: string,
  disableForge: boolean;
  newForged: number[];
  currentListofWeapons: string[];
  selectedElement: number | null,
  chosenElementFee: number | null,
  clickedForgeButton: number | null,
  spin: boolean;
  lesserDust: string,
  greaterDust: string,
  powerfulDust: string,
  dust: string[],
  allowDustForge: false,
  burnWeaponIds: any[],
  onError: boolean;
  hideWeapons: any[];
  useStakedForForge: boolean;
  disableUseStakedForForge: boolean;
  disableX10ForgeWithStaked: boolean;
  forgeCostBN: BN;
  targetSkin: string;
  haveWeaponCosmetic1: number;
  haveWeaponCosmetic2: number;
  selectedSpecialWeaponEventId: number;
}

export default Vue.extend({
  data() {
    return {
      showReforge: false,
      showBlacksmith: true,
      showDustForge: false,
      showReforgeDust: false,
      reforgeWeaponId: null,
      burnWeaponId: null,
      selectedNft: null,
      forgeCost: '0',
      reforgeCost: '0',
      dustReforgeCost: '0',
      burnCost: '0',
      disableForge: false,
      newForged: [],
      currentListofWeapons: [],
      selectedElement: null,
      chosenElementFee: null,
      clickedForgeButton: null,
      spin: false,
      lesserDust: '0',
      greaterDust: '0',
      powerfulDust: '0',
      dust: [],
      allowDustForge: false,
      burnWeaponIds: [],
      onError: false,
      hideWeapons: [],
      useStakedForForge:false,
      disableUseStakedForForge: false,
      disableX10ForgeWithStaked: false,
      forgeCostBN: new BN(0),
      targetSkin: '',
      haveWeaponCosmetic1: 0,
      haveWeaponCosmetic2: 0,
      selectedSpecialWeaponEventId: 0
    } as Data;
  },

  computed: {
    ...(mapState(['defaultAccount','ownedWeaponIds','ownedShieldIds','skillBalance', 'inGameOnlyFunds', 'skillRewards',
      'activeSpecialWeaponEventsIds', 'specialWeaponEvents', 'specialWeaponEventId']) as Accessors<StoreMappedState>),
    ...(mapGetters([
      'contracts', 'ownWeapons', 'nftsCount', 'ownShields',
      'getPowerfulDust', 'getGreaterDust', 'getLesserDust',
      'stakedSkillBalanceThatCanBeSpent'
    ]) as Accessors<StoreMappedGetters>),

    totalSkillBalance(): BN {
      console.log(toBN(fromWeiEther(this.skillRewards)).plus(toBN(fromWeiEther(this.inGameOnlyFunds))).plus(toBN(fromWeiEther(this.skillBalance))).toString());
      return toBN(fromWeiEther(this.skillRewards)).plus(toBN(fromWeiEther(this.inGameOnlyFunds))).plus(toBN(fromWeiEther(this.skillBalance)));
    },

    disableConfirmButton(): boolean {
      return this.selectedElement === null || !this.chosenElementFee ||
        this.totalSkillBalance.lt(this.forgeCostBN.times(this.chosenElementFee).times(this.clickedForgeButton ? 10 : 1));
    }
  },

  watch: {
    reforgeWeaponId() {
      this.showReforge = false;
      this.burnWeaponId = null;
    },
    stakedSkillBalanceThatCanBeSpent(){
      const stakedSkillBalanceThatCanBeSpentBN: BN = new BN(this.stakedSkillBalanceThatCanBeSpent).div(new BN(10).pow(18));

      if((stakedSkillBalanceThatCanBeSpentBN.minus(this.forgeCostBN.multipliedBy(0.8))).isLessThan(0)) {
        this.disableUseStakedForForge = true;
      }
      if((stakedSkillBalanceThatCanBeSpentBN.minus(this.forgeCostBN.multipliedBy(0.8).multipliedBy(10))).isLessThan(0)){
        this.disableX10ForgeWithStaked = true;
      }
    }
  },

  async created() {
    await this.fetchSpecialWeaponEvents();
    this.selectedSpecialWeaponEventId = +this.specialWeaponEventId;
    if(!this.contracts.CryptoBlades || !this.contracts.BurningManager) return;
    const forgeCost = await this.contracts.CryptoBlades.methods.mintWeaponFee().call({ from: this.defaultAccount });
    const skillForgeCost = await this.contracts.CryptoBlades.methods.usdToSkill(forgeCost).call({ from: this.defaultAccount });
    this.forgeCost = new BN(skillForgeCost).div(new BN(10).pow(18)).toFixed(4);
    const stakedSkillBalanceThatCanBeSpentBN: BN = new BN(this.stakedSkillBalanceThatCanBeSpent).div(new BN(10).pow(18));
    this.forgeCostBN = new BN(skillForgeCost).div(new BN(10).pow(18));

    if((stakedSkillBalanceThatCanBeSpentBN.minus(this.forgeCostBN.multipliedBy(0.8))).isLessThan(0)) {
      this.disableUseStakedForForge = true;
    }
    if((stakedSkillBalanceThatCanBeSpentBN.minus(this.forgeCostBN.multipliedBy(0.8).multipliedBy(10))).isLessThan(0)){
      this.disableX10ForgeWithStaked = true;
    }
    const reforgeCost = await this.contracts.BurningManager.methods.reforgeWeaponFee().call({ from: this.defaultAccount });
    const skillReforgeCost = await this.contracts.BurningManager.methods.usdToSkill(reforgeCost).call({ from: this.defaultAccount });
    this.reforgeCost = new BN(skillReforgeCost).div(new BN(10).pow(18)).toFixed(4);

    const reforgeDustCost = await this.contracts.BurningManager.methods.reforgeWeaponWithDustFee().call({ from: this.defaultAccount });
    const skillDustReforgeCost = await this.contracts.BurningManager.methods.usdToSkill(reforgeDustCost).call({ from: this.defaultAccount });
    this.dustReforgeCost = new BN(skillDustReforgeCost).div(new BN(10).pow(18)).toFixed(4);

    const burnCost = await this.contracts.BurningManager.methods.burnWeaponFee().call({ from: this.defaultAccount });
    const skillBurnCost = await this.contracts.BurningManager.methods.usdToSkill(burnCost).call({ from: this.defaultAccount });
    this.burnCost = new BN(skillBurnCost).div(new BN(10).pow(18)).toFixed(4);
  },

  methods: {
    ...mapActions(['mintWeapon', 'reforgeWeapon', 'mintWeaponN',
      'burnWeapon', 'reforgeWeaponWithDust', 'massBurnWeapons', 'fetchSpecialWeaponEvents']),
    ...mapMutations(['updateSpecialWeaponEventId']),

    toggleCheckbox() {
      this.useStakedForForge = !this.useStakedForForge;
      if (this.useStakedForForge) localStorage.setItem('useStakedForForge', 'true');
      else localStorage.setItem('useStakedForForge', 'false');
    },

    onClickSpecialForge() {
      Events.$emit('show-special-forge-modal');
    },

    async onForgeWeapon() {
      if(this.disableForge) return;

      (this.$refs['forge-element-selector-modal']as BModal)?.hide();

      const forgeMultiplier = 1;

      this.disableForge = true;
      // Incase the network or mm are having issues, after 1 min we reshow
      const failbackTimeout = setTimeout(() => {
        this.disableForge = false;
      }, 30000);

      try {
        await this.mintWeapon({
          useStakedSkillOnly: this.useStakedForForge,
          chosenElement: this.selectedElement || 100,
          eventId: this.selectedSpecialWeaponEventId
        });

      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error(i18n.t('blacksmith.couldNotForge'));
      } finally {
        clearTimeout(failbackTimeout);
        this.disableForge = false;
        this.selectedElement = null;
      }
      this.relayFunction(forgeMultiplier);
    },

    async onForgeWeaponx10(){
      if(this.disableForge) return;

      (this.$refs['forge-element-selector-modal']as BModal).hide();

      this.disableForge = true;
      const forgeMultiplier = 10;

      // Incase the network or mm are having issues, after 1 min we reshow
      const failbackTimeout = setTimeout(() => {
        this.disableForge = false;
      }, 30000);

      try {
        await await this.mintWeaponN({
          num: forgeMultiplier,
          useStakedSkillOnly: this.useStakedForForge,
          chosenElement: this.selectedElement,
          eventId: this.selectedSpecialWeaponEventId
        });

      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error(i18n.t('blacksmith.couldNotForge'));
      } finally {
        clearTimeout(failbackTimeout);
        this.disableForge = false;
        this.selectedElement = null;
      }
      this.relayFunction(forgeMultiplier);

    },

    relayFunction(offset: number){
      try{
        this.viewNewWeapons(offset);
      } catch (e) {
        console.error(e);
        this.onError = true;
      }
    },

    onShowForgeDetails() {
      (this.$refs['forge-details-modal'] as BModal).show();
    },

    onClickForge(i: number) {
      if(+this.specialWeaponEventId === 0 && this.activeSpecialWeaponEventsIds.length > 0) {
        this.selectedSpecialWeaponEventId = +this.activeSpecialWeaponEventsIds[0];
      }
      else {
        this.selectedSpecialWeaponEventId = +this.specialWeaponEventId;
      }
      this.clickedForgeButton = i;
      this.chosenElementFee = null;
      (this.$refs['forge-element-selector-modal']as BModal).show();
    },

    setChosenElement(ele: any, i: number) {
      this.selectedElement = i;
      this.chosenElementFee = i === 100 ? 1 : 2;
      ele.srcElement.classList.toggle('done');
      Array.from(ele.srcElement.parentNode.childNodes).forEach((child: any) => {
        if (child !== ele.srcElement && child.classList.contains('done') === true){
          child.classList.toggle('done');
        }
      });
    },

    showReforgeConfirmation() {
      (this.$refs['reforge-confirmation-modal'] as BModal).show();
    },

    showDustReforgeConfirmation() {
      (this.$refs['dustreforge-confirmation-modal'] as BModal).show();
    },

    showMassDustConfirmation() {
      (this.$refs['mass-dust-confirmation-modal'] as BModal).show();
    },

    displayDustReforge() {
      this.showReforge = true;
      this.showBlacksmith = false;
      this.showReforgeDust = true;
      this.showDustForge = false;
      this.lesserDust = '0';
      this.greaterDust = '0';
      this.powerfulDust = '0';
    },
    displayDustCreation(){
      return this.showReforge = true,
      this.showBlacksmith = false,
      this.showDustForge = true,
      this.showReforgeDust = false,
      this.hideWeapons = this.ownedWeaponIds;
    },
    displayBlacksmith(){
      this.showReforge = false;
      this.showBlacksmith = true;
      this.showDustForge = false;
      this.showReforgeDust = false;
    },
    cancelReforge() {
      this.showReforge = false;
      this.showBlacksmith = true;
      this.showDustForge = false;
      this.showReforgeDust = false;
      this.burnWeaponIds = [];
      this.hideWeapons = this.ownedWeaponIds;
      this.lesserDust = '0';
      this.greaterDust = '0';
      this.powerfulDust = '0';
    },
    clearAllMassBurn(){
      return this.burnWeaponIds = [],
      this.hideWeapons = this.ownedWeaponIds;
    },
    getWeaponToUpgrade() {
      return this.ownWeapons.find(x => x.id === this.reforgeWeaponId);
    },

    addBurnWeapon(id: number){
      this.burnWeaponIds.push(id.toString());
      this.hideWeapons = this.hideWeapons.filter(val => !this.burnWeaponIds.includes(val.toString()));
      this.burnWeaponId = null;
    },

    removeBurnWeapon(id: number){
      this.hideWeapons.push(id.toString());
      this.burnWeaponIds = this.burnWeaponIds.filter(x => x !== id.toString());
    },

    viewNewWeapons(offset: number){
      this.newForged = [];
      this.ownedWeaponIds.forEach(x => {
        this.newForged.push(x);
      });

      this.newForged.splice(0, this.ownedWeaponIds.length - offset);


      // eslint-disable-next-line no-constant-condition
      if (this.newForged.length > 0 && !this.onError){
        this.spin = true;
        (this.$refs['new-weapons'] as BModal).show();

        setTimeout(() => {
          this.spin = false;
        }, 10000);
      }

    },

    async onReforgeWeaponWithDust() {
      try {
        await this.reforgeWeaponWithDust({
          reforgeWeaponId: this.reforgeWeaponId,
          lesserDust: this.lesserDust,
          greaterDust: this.greaterDust,
          powerfulDust:this.powerfulDust
        });

        this.lesserDust = '0';
        this.greaterDust = '0';
        this.powerfulDust = '0';

      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error(i18n.t('blacksmith.couldNotReforge'));
      }
    },

    async onMassBurnWeapons() {
      try {
        await this.massBurnWeapons({
          burnWeaponIds: this.burnWeaponIds,
        });
        this.burnWeaponIds = [];
        this.burnWeaponId = null;
      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error(i18n.t('blacksmith.couldNotBurn'));
      }
    },
  },

  components: {
    DustBalanceDisplay,
    WeaponGrid,
    BigButton,
    WeaponIcon,
    BModal,
    NftList,
    SpecialWeaponForgeModal
  },
});
</script>

<style scoped>


#random-border{
  background-image: url('../assets/questionmark-icon.png');
  background-size: 4em 4em;
  background-repeat: no-repeat;
  width: 4em;
  height: 4em;
  margin-left: 1em;
  margin-right: 1em;
}

#random-border:hover{
  background-image: url('../assets/questionmark-icon-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

#random-border.done {
  background-image: url('../assets/questionmark-icon-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

#fire-border{
  background-image: url('../assets/elements/fire.png');
  background-size: 4em 4em;
  background-repeat: no-repeat;
  width: 4em;
  height: 4em;
  margin-left: 1em;
  margin-right: 1em;
}

#fire-border:hover{
  background-image: url('../assets/elements/fire-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

#fire-border.done {
  background-image: url('../assets/elements/fire-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

#earth-border{
  background-image: url('../assets/elements/earth.png');
  background-size: 4em 4em;
  background-repeat: no-repeat;
  width: 4em;
  height: 4em;
  margin-left: 1em;
  margin-right: 1em;
}

#earth-border:hover{
  background-image: url('../assets/elements/earth-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

#earth-border.done {
  background-image: url('../assets/elements/earth-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

#lightning-border{
  background-image: url('../assets/elements/lightning.png');
  background-size: 4em 4em;
  background-repeat: no-repeat;
  width: 4em;
  height: 4em;
  margin-left: 1em;
  margin-right: 1em;
}

#lightning-border:hover{
  background-image: url('../assets/elements/lightning-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

#lightning-border.done {
  background-image: url('../assets/elements/lightning-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

#water-border{
  background-image: url('../assets/elements/water.png');
  background-size: 4em 4em;
  background-repeat: no-repeat;
  width: 4em;
  height: 4em;
  margin-left: 1em;
  margin-right: 1em;
}

#water-border:hover{
  background-image: url('../assets/elements/water-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

#water-border.done {
  background-image: url('../assets/elements/water-45.png');
  background-position: center;
  border: 2px solid white;
  transform: rotate(45deg);
}

.new-weapon-header-text{
   color: #9e8a57;
  font-size: 34px;
}

.weapon-container {
  border-right: 1px solid #9e8a57;
}

.confirmReforge{
  margin: 1em auto 2em;
  border-radius:0.15em;
  text-decoration:none;
  font-weight:400;
  text-align:center;
  width: 12em;
}
.confirmReforge:active{
  top:0.1em;
}

.weapon {
  min-height: 12em;
  max-height: 13em;
  border-style: dashed;
  border-color: #9e8a57;
  width: 12em;
  border-radius: 5px;
  cursor: pointer;
  margin-bottom: 2em;
}

.multiForging {
  align-items: center;
}

.headings {
  min-height: 13em;
  min-width: 13em;
  max-height: 13em;
  max-width: 13em;
  border-radius:0.15em;
  box-sizing: border-box;
  font-weight:400;
  width: 13em;
  margin: 1em auto 2em;
}

.upgrade-container {
  border-top: 1px solid #9e8a57;
  border-left: 1px solid #9e8a57;
}

.centered-modal {
  display: inline-block;
}

.centered-text-modal {
  justify-content: center;
  text-align: center;
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

.margin-top{
  margin-top: 1.7em;
}
.select-elements-container {
  margin-top: 0.7em;
}

@media (max-width: 1000px) {
  .mobile-flip{
    display: flex;
    flex-flow: column-reverse;
  }
}

</style>
