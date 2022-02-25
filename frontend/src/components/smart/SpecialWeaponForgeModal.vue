<template>
  <b-modal v-model="showModal" hide-footer size="lg" class="centered-text-modal" ref="special-forge-modal" :title="$t('blacksmith.specialForge')">
      <b-tabs justified>
        <b-tab :title="$t('blacksmith.forge')">
          <div class="d-flex justify-content-center mt-3" v-if="isLoading">
            <h4>{{$t('blacksmith.loading')}} <img class="spinner" src="../../assets/loadingSpinner.svg" /></h4>
          </div>
          <div v-else>
            <div class="d-flex mt-3 align-items-center">
              <h5 class="mb-0">{{$t('blacksmith.specialEvent')}}:</h5>
              <b-form-select :disabled="!activeSpecialWeaponEventsIds.length && !inactiveEventsIdsWithUnclaimedOrders.length" class="w-50 ml-1" size="sm"
                v-model="selectedSpecialWeaponEventId" @change="updateSpecialWeaponEventId($event)">
                <b-form-select-option v-for="id in activeSpecialWeaponEventsIds.concat(inactiveEventsIdsWithUnclaimedOrders)" :key="+id" :value="+id">
                  {{specialWeaponEvents[id] && specialWeaponEvents[id].name}}
                </b-form-select-option>
              </b-form-select>
            </div>
            <h5 v-if="!activeSpecialWeaponEventsIds.length" class="d-flex justify-content-center mt-3">{{$t('blacksmith.noActiveEvents')}}</h5>
            <div v-if="selectedSpecialWeaponEventId">
              <div v-if="!isForging" class="d-flex mt-3 info-div">
                <div class="d-flex flex-column justify-items-center w-50 mb-3">
                  <img :src="eventWeaponImgPath" class="weapon-img"/>
                  <div class="d-flex mt-3 align-items-center">
                    <h5 class="mb-0">{{$t('blacksmith.availableElements')}}</h5>
                    <h5 v-if="availableElement === 100 || availableElement === 0" class="fire-icon ml-2 mb-0" />
                    <h5 v-if="availableElement === 100 || availableElement === 1" class="earth-icon mb-0" />
                    <h5 v-if="availableElement === 100 || availableElement === 2" class="lightning-icon mb-0" />
                    <h5 v-if="availableElement === 100 || availableElement === 3" class="water-icon mb-0 mr-2" />
                  </div>
                </div>
                <div class="w-50 mb-3">
                  <span v-if="endsIn > 0">{{$t('blacksmith.endsIn')}}: {{eventEndsIn}}</span>
                  <span v-if="endsIn < 0">{{$t('blacksmith.ended')}}</span>
                  <h4>{{partnerName}}</h4>
                  <div class="mt-2">
                    <h5 class="text-justify">{{eventDetails}}</h5>
                    <a class="a-button" :href="eventPartnerWebsite" target="_blank">{{eventPartnerWebsite}}</a>
                  </div>
                </div>
              </div>
              <div class="d-flex flex-column align-items-center justify-self-start" v-if="specialWeaponsSupply && !isForging">
                <div class="w-100 mt-1 progress w-90 justify-items-center">
                  <div class="progress-bar progress-bar-striped progress-bar-animated" role="progressbar"
                    :style="[{'width': progressBarWidth, 'background-color': '#9e8a57'}]"/>
                </div>
                <h5 class="mb-0">{{$t('blacksmith.totalWeaponsForged')}} {{orderedCount}}/{{specialWeaponsSupply}}</h5>
              </div>
              <div class="d-flex mt-3 info-div justify-content-center" v-if="isForging">
                <img :src="forgingGifSrc" />
              </div>
              <div class="top-border-forge mt-3" v-if="!isEventWeaponOrdered && !isEventWeaponForged && hasSupplyLeft">
                <div class="d-flex mt-3 align-items-center">
                  <h5 class="mb-0">{{$t('blacksmith.forgeOption')}}:</h5>
                  <b-form-select v-if="forgeCosts && forgeCosts.length > 0" :disabled="!activeSpecialWeaponEventsIds.length" class="w-50 ml-1" size="sm"
                    v-model="forgeOption" @change="updateSpecialWeaponEventId($event)">
                    <b-form-select-option :value="1">
                      3-5* {{$t('blacksmith.for')}} {{forgeCosts[0]}} {{$t('blacksmith.shards')}}
                      {{$t('blacksmith.or')}} {{formattedSkillCost(4)}} SKILL
                    </b-form-select-option>
                    <b-form-select-option :value="2">
                      4-5* {{$t('blacksmith.for')}} {{forgeCosts[1]}} {{$t('blacksmith.shards')}}
                      {{$t('blacksmith.or')}} {{formattedSkillCost(5)}} SKILL
                    </b-form-select-option>
                    <b-form-select-option :value="3">
                      5* {{$t('blacksmith.for')}} {{forgeCosts[2]}} {{$t('blacksmith.shards')}}
                      {{$t('blacksmith.or')}} {{formattedSkillCost(6)}} SKILL
                    </b-form-select-option>
                  </b-form-select>
                </div>
                <div class="d-flex justify-content-center mt-3">
                  <b-button
                          variant="primary"
                          @click="onForgeSpecialWeapon(true)"
                          :disabled="!canForgeWithSkill || isForging">
                    <span v-if="!isForging" class="gtag-link-others">
                      {{$t('blacksmith.forge')}} ({{forgeCostSkill}} SKILL)
                    </span>
                    <span v-else class="gtag-link-others">
                      {{$t('blacksmith.forging')}}
                    </span>
                  </b-button>
                  <b-button
                          class="ml-2"
                          variant="primary"
                          @click="onForgeSpecialWeapon()"
                          :disabled="!canForgeWithShards || isForging">
                    <span v-if="!isForging" class="gtag-link-others">
                      {{$t('blacksmith.forge')}} ({{forgeCostShards}} {{$t('blacksmith.shards')}})
                    </span>
                    <span v-else class="gtag-link-others">
                      {{$t('blacksmith.forging')}}
                    </span>
                  </b-button>
                </div>
              </div>
              <div class="d-flex top-border-forge mt-3 justify-content-center" v-if="!isEventWeaponOrdered && !isEventWeaponForged && !hasSupplyLeft">
                <h5 class="mt-3">{{$t('blacksmith.soldOut')}}</h5>
              </div>
              <div class="d-flex flex-column align-items-center mt-3 top-border-forge" v-if="isEventWeaponOrdered && !isForging && !isEventWeaponForged">
                <h5 class="mt-2">{{$t('blacksmith.specialWeaponOrdered')}}</h5>
                <b-button
                        variant="primary"
                        @click="onClaimSpecialWeapon()"
                        :disabled="isClaiming">
                  <span v-if="!isClaiming" class="gtag-link-others">
                    {{$t('blacksmith.claim')}}
                  </span>
                  <span v-else class="gtag-link-others">
                    {{$t('blacksmith.claiming')}}
                  </span>
                </b-button>
              </div>
              <div class="d-flex flex-column align-items-center mt-3 top-border-forge" v-if="isEventWeaponForged && !isClaiming">
                <h5 class="mt-2">{{$t('blacksmith.specialWeaponClaimed')}}</h5>
                <div class="weapon-icon-wrapper mt-2">
                  <weapon-icon v-if="forgedWeapon" :weapon="forgedWeapon" />
                </div>
              </div>
            </div>
          </div>
        </b-tab>
        <b-tab :title="$t('blacksmith.shards')">
          <div class="d-flex justify-content-center mt-3" v-if="isLoading">
            <h4>{{$t('blacksmith.loading')}} <img class="spinner" src="../../assets/loadingSpinner.svg" /></h4>
          </div>
          <div v-if="!isLoading">
            <div class="mt-2">
              <b-row class="mr-1">
                <b-col><strong>{{$t('blacksmith.name')}}</strong></b-col>
                <b-col><strong>{{$t('blacksmith.status')}}</strong></b-col>
                <b-col><strong>{{$t('blacksmith.balance')}}</strong></b-col>
              </b-row>
              <div class="scrollable mt-1">
                <b-row class="bordered" v-for="id in activeSpecialWeaponEventsIds" :key="id" :value="id">
                  <b-col>{{specialWeaponEvents[id] && specialWeaponEvents[id].name}}</b-col>
                  <b-col>{{$t('blacksmith.live')}}</b-col>
                  <b-col><img class="shard-icon" :src="eventShardImg" /> {{shardsSupply[id]}}</b-col>
                </b-row>
                <b-row class="bordered" v-for="id in inactiveSpecialWeaponEventsIds" :key="id" :value="id">
                  <b-col>{{specialWeaponEvents[id] && specialWeaponEvents[id].name}}</b-col>
                  <b-col>{{$t('blacksmith.ended')}}</b-col>
                  <b-col><img class="shard-icon" :src="eventShardImg" /> {{shardsSupply[id]}}</b-col>
                </b-row>
              </div>
            </div>
            <div class="mt-3 top-border-shards">
              <h4 class="mt-2">{{$t('blacksmith.convert')}}</h4>
              <div class="d-flex align-items-center">
                <h5 class="mb-0">{{$t('blacksmith.from')}}:</h5>
                <b-form-select class="w-25 ml-1" size="sm"
                  v-model="selectedConvertFromId">
                  <b-form-select-option v-for="id in allEventsIds.filter(id => id !== selectedConvertToId)" :key="id" :value="id">
                    {{specialWeaponEvents[id] && specialWeaponEvents[id].name}}
                  </b-form-select-option>
                </b-form-select>
                <h5 class="ml-3 mb-0">{{$t('blacksmith.to')}}:</h5>
                <b-form-select class="w-25 ml-1" size="sm"
                  v-model="selectedConvertToId">
                  <b-form-select-option v-for="id in activeSpecialWeaponEventsIds.filter(id => id !== selectedConvertFromId)" :key="id" :value="id">
                    {{specialWeaponEvents[id] && specialWeaponEvents[id].name}}
                  </b-form-select-option>
                </b-form-select>
                <h5 class="ml-3 mb-0">{{$t('blacksmith.amount')}}:</h5>
                <b-input size="sm" type="number" class="form-control w-25 ml-1" v-model="convertAmount" min="0"
                  :max="selectedConvertFromId >= 0 ? shardsSupply[selectedConvertFromId] : ''"></b-input>
              </div>
              <div class="d-flex justify-content-center">
                <h5 class="mt-3" v-if="specialWeaponEvents[selectedConvertToId]">
                  {{$t('blacksmith.youWillReceive')}} {{convertOutputAmount}} {{specialWeaponEvents[selectedConvertToId].name}} {{$t('blacksmith.shards')}}.
                </h5>
              </div>
              <div class="d-flex justify-content-center mt-3">
                <b-button
                        variant="primary"
                        @click="onConvertShards()"
                        :disabled="!canConvert || isConverting">
                  <span v-if="!isConverting" class="gtag-link-others">
                    {{$t('blacksmith.convert')}} ({{convertAmount}} {{$t('blacksmith.shards')}})
                  </span>
                  <span v-else class="gtag-link-others">
                    {{$t('blacksmith.converting')}}
                  </span>
                </b-button>
              </div>
            </div>
            <div class="mt-3 top-border-shards">
              <div class="d-flex align-items-center">
                <h4 class="mt-2">{{$t('blacksmith.stakingRewards')}}</h4>
                <b-icon-question-circle class="centered-icon ml-1" scale="1.1" v-tooltip.bottom="$t('blacksmith.stakingRewardsTooltip')"/>
              </div>
              <div class="d-flex flex-column align-items-center">
                <h5><img class="shard-icon" :src="generalShardImg" /> {{shardsStakingRewards}}</h5>
                <div class="d-flex mt-2 align-items-center justify-content-center w-100">
                  <h5 class="ml-3 mb-0">{{$t('blacksmith.claimInto')}}:</h5>
                  <b-form-select class="w-25 ml-1" size="sm" :disabled="!activeSpecialWeaponEventsIds.length"
                    v-model="claimRewardsIntoId">
                    <b-form-select-option v-for="id in activeSpecialWeaponEventsIds.filter(id => id !== selectedConvertFromId)" :key="id" :value="id">
                      {{specialWeaponEvents[id] && specialWeaponEvents[id].name}}
                    </b-form-select-option>
                  </b-form-select>
                  <h5 class="ml-3 mb-0">{{$t('blacksmith.amount')}}:</h5>
                  <b-input size="sm" type="number" class="form-control w-25 ml-1" step="1" v-model="claimRewardsAmount" min="0"
                    :max="Math.floor(+shardsStakingRewards)"></b-input>
                </div>
                <h5 v-if="!activeSpecialWeaponEventsIds.length" class="d-flex justify-content-center mt-3">{{$t('blacksmith.noActiveEvents')}}</h5>
                <b-button
                        class="mt-3"
                        variant="primary"
                        @click="onClaimStakingRewards()"
                        :disabled="!canClaimStakingRewards || isClaimingStakingRewards"
                        v-if="activeSpecialWeaponEventsIds.length">
                  <span v-if="!isClaimingStakingRewards" class="gtag-link-others">
                    {{$t('blacksmith.claim')}}
                  </span>
                  <span v-if="isClaimingStakingRewards" class="gtag-link-others">
                    {{$t('blacksmith.claiming')}}
                  </span>
                </b-button>
              </div>
            </div>
          </div>
        </b-tab>
      </b-tabs>
    </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import weaponEvents from '../../../special-weapons.json';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import { IState, IWeapon } from '@/interfaces';
import { Accessors } from 'vue/types/options';
import Events from '../../events';
import { secondsToDDHHMMSS } from '@/utils/date-time';
import eventShard from '../../assets/special-weapons/eventShard.png';
import generalShard from '../../assets/special-weapons/generalShard.png';
import forgingGif from '../../assets/special-weapons/forging.gif';
import WeaponIcon from '../WeaponIcon.vue';
import { fromWeiEther, toBN } from '@/utils/common';

interface SpecialWeaponEventInfo {
  eventsDetails: Record<string, Record<string, any>>;
}

type StoreMappedState = Pick<IState,'activeSpecialWeaponEventsIds' | 'inactiveSpecialWeaponEventsIds' |
'specialWeaponEvents' | 'specialWeaponEventId' | 'shardsSupply' | 'ownedWeaponIds' |'skillBalance' | 'skillRewards'>;

interface StoreMappedGetters {
  weaponsWithIds(weaponIds: (string | number)[]): IWeapon[];
}

interface StoreMappedActions {
  fetchSpecialWeaponEvents(): Promise<void>;
  fetchForgeCosts(): Promise<number[]>;
  fetchShardsConvertDenominator(): Promise<number>;
  convertShards({ eventFromId, eventToId, amount }: { eventFromId: number, eventToId: number, amount: number }): Promise<void>;
  orderSpecialWeapon({ eventId, orderOption, orderWithSkill}: { eventId: number, orderOption: number, orderWithSkill: boolean}): Promise<void>;
  forgeSpecialWeapon(eventId: number): Promise<void>;
  fetchEventTotalOrderedCount(eventId: number): Promise<void>;
  fetchShardsStakingRewards(): Promise<string>;
  claimShardsStakingRewards({ eventId, amount}: { eventId: number, amount: number}): Promise<void>;
}

interface StoreMappedMutations {
  updateSpecialWeaponEventId(e: Event): void;
}

interface Data {
  images: any;
  selectedSpecialWeaponEventId: number;
  showModal: boolean;
  forgeOption: number;
  forgeCosts: number[];
  endsIn: number;
  updateEndTime: ReturnType<typeof setInterval> | null;
  orderedCountInterval: ReturnType<typeof setInterval> | null;
  convertAmount: number;
  selectedConvertFromId: number;
  selectedConvertToId: number;
  isConverting: boolean;
  isForging: boolean;
  isClaiming: boolean;
  shardsCostDenominator: number;
  shardsStakingRewards: string;
  isClaimingStakingRewards: boolean;
  claimRewardsIntoId: number;
  claimRewardsAmount: number;
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      images: require.context('../../assets/special-weapons/', false, /\.png$/),
      selectedSpecialWeaponEventId: 0,
      forgeOption: 1,
      showModal: false,
      forgeCosts: [],
      endsIn: 0,
      updateEndTime: null,
      orderedCountInterval: null,
      convertAmount: 0,
      selectedConvertFromId: -1,
      selectedConvertToId: -1,
      isConverting: false,
      isForging: false,
      isClaiming: false,
      shardsCostDenominator: 0,
      shardsStakingRewards: '',
      isClaimingStakingRewards: false,
      claimRewardsIntoId: 0,
      claimRewardsAmount: 0,
      isLoading: false
    } as Data;
  },

  components: {
    WeaponIcon
  },

  computed: {
    ...(mapState([
      'activeSpecialWeaponEventsIds',
      'inactiveSpecialWeaponEventsIds',
      'specialWeaponEvents',
      'specialWeaponEventId',
      'shardsSupply',
      'ownedWeaponIds',
      'skillBalance',
      'skillRewards'
    ]) as Accessors<StoreMappedState>),
    ...(mapGetters(['weaponsWithIds']) as Accessors<StoreMappedGetters>),

    eventDetails(): string {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return '';
      return (weaponEvents as SpecialWeaponEventInfo).eventsDetails[this.specialWeaponEvents[this.selectedSpecialWeaponEventId].name].details;
    },

    eventPartnerWebsite(): string {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return '';
      return (weaponEvents as SpecialWeaponEventInfo).eventsDetails[this.specialWeaponEvents[this.selectedSpecialWeaponEventId].name].website;
    },

    eventNote(): string {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return '';
      return (weaponEvents as SpecialWeaponEventInfo).eventsDetails[this.specialWeaponEvents[this.selectedSpecialWeaponEventId].name].note;
    },

    eventWeaponImgPath(): string {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return '';
      const fileName = (weaponEvents as SpecialWeaponEventInfo).eventsDetails[this.specialWeaponEvents[this.selectedSpecialWeaponEventId].name].logo;
      return this.imgPath(fileName);
    },

    forgeCostShards(): number {
      return this.forgeCosts && this.forgeCosts[this.forgeOption - 1];
    },

    forgeCostSkill(): number {
      return this.forgeCosts && +this.formattedSkillCost(this.forgeOption + 3);
    },

    canForgeWithShards(): boolean {
      return !!this.selectedSpecialWeaponEventId &&
        this.shardsSupply[this.selectedSpecialWeaponEventId] >= this.forgeCostShards &&
        this.endsIn > 0;
    },

    canForgeWithSkill(): boolean {
      const cost = toBN(this.forgeCostSkill);
      const balance = toBN(+fromWeiEther(this.skillBalance) + +fromWeiEther(this.skillRewards));
      return !!this.selectedSpecialWeaponEventId &&
         balance.isGreaterThanOrEqualTo(cost) &&
        this.endsIn > 0;
    },

    canClaimStakingRewards(): boolean {
      return !!this.claimRewardsIntoId && +this.shardsStakingRewards >= 1 && +this.claimRewardsAmount <= +this.shardsStakingRewards;
    },

    hasSupplyLeft(): boolean {
      if(!+this.specialWeaponEvents[this.selectedSpecialWeaponEventId].supply) return true;
      return +this.specialWeaponEvents[this.selectedSpecialWeaponEventId].orderedCount< +this.specialWeaponEvents[this.selectedSpecialWeaponEventId].supply;
    },

    canConvert(): boolean {
      return this.selectedConvertFromId >= 0 &&
      this.selectedConvertToId >= 0 &&
      this.shardsSupply[this.selectedConvertFromId] >= this.convertAmount &&
      this.convertAmount > 0;
    },

    eventEndsIn(): string {
      return secondsToDDHHMMSS(this.endsIn);
    },

    partnerName(): string {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return '';
      return this.specialWeaponEvents[this.selectedSpecialWeaponEventId].name;
    },

    availableElement(): number {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return -1;
      return +this.specialWeaponEvents[this.selectedSpecialWeaponEventId].weaponElement;
    },

    isEventWeaponOrdered(): boolean {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return false;
      return this.specialWeaponEvents[this.selectedSpecialWeaponEventId].ordered;
    },

    isEventWeaponForged(): boolean {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return false;
      return this.specialWeaponEvents[this.selectedSpecialWeaponEventId].forged;
    },

    eventShardImg(): string {
      return eventShard;
    },

    generalShardImg(): string {
      return generalShard;
    },

    forgingGifSrc(): string {
      return forgingGif;
    },

    allEventsIds(): number[] {
      return this.activeSpecialWeaponEventsIds.concat(this.inactiveSpecialWeaponEventsIds);
    },

    convertOutputAmount(): number {
      if(!this.shardsCostDenominator) return 0;
      return +this.convertAmount === +this.shardsSupply[this.selectedConvertFromId] ?
        Math.ceil(this.convertAmount / this.shardsCostDenominator) :
        Math.floor(this.convertAmount / this.shardsCostDenominator);
    },

    forgedWeapon(): IWeapon | undefined {
      return this.weaponsWithIds(this.ownedWeaponIds).find(w => {
        return w && w.weaponType === this.selectedSpecialWeaponEventId;
      });
    },

    orderedCount(): number {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return 0;
      return +this.specialWeaponEvents[this.selectedSpecialWeaponEventId].orderedCount;
    },

    specialWeaponsSupply(): number {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return 0;
      return +this.specialWeaponEvents[this.selectedSpecialWeaponEventId].supply;
    },

    progressBarWidth(): string {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return '0%';
      return `${Math.round((
        +this.specialWeaponEvents[this.selectedSpecialWeaponEventId].orderedCount /
        +this.specialWeaponEvents[this.selectedSpecialWeaponEventId].supply) * 100
      )}%`;
    },

    inactiveEventsIdsWithUnclaimedOrders(): number[] {
      return this.inactiveSpecialWeaponEventsIds.filter(id => this.specialWeaponEvents[id].ordered && !this.specialWeaponEvents[id].forged);
    }
  },

  watch: {
    selectedSpecialWeaponEventId(newValue, oldValue) {
      if(newValue !== oldValue && this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) {
        this.endsIn = +(+this.specialWeaponEvents[this.selectedSpecialWeaponEventId].endTime - Date.now()/1000).toFixed(0);
      }
    }
  },

  methods: {
    ...mapActions(['fetchSpecialWeaponEvents', 'fetchForgeCosts', 'convertShards', 'fetchShardsConvertDenominator',
      'orderSpecialWeapon', 'forgeSpecialWeapon', 'fetchEventTotalOrderedCount', 'fetchShardsStakingRewards',
      'claimShardsStakingRewards']) as StoreMappedActions,
    ...mapMutations(['updateSpecialWeaponEventId']) as StoreMappedMutations,

    imgPath(img: string): string {
      return this.images('./' + img);
    },

    async onForgeSpecialWeapon(forgeWithSkill: boolean = false) {
      try {
        this.isForging = true;
        if(forgeWithSkill) {
          await this.orderSpecialWeapon({
            eventId: this.selectedSpecialWeaponEventId,
            orderOption: this.forgeOption,
            orderWithSkill: true
          });
        } else {
          await this.orderSpecialWeapon({
            eventId: this.selectedSpecialWeaponEventId,
            orderOption: this.forgeOption,
            orderWithSkill: false
          });
        }
      }
      finally {
        this.isForging = false;
      }
    },

    async onClaimSpecialWeapon() {
      try {
        this.isClaiming = true;
        await this.forgeSpecialWeapon(this.selectedSpecialWeaponEventId);
      }
      finally {
        this.isClaiming = false;
      }
    },

    async onConvertShards() {
      try {
        this.isConverting = true;
        await this.convertShards({
          eventFromId: this.selectedConvertFromId,
          eventToId: this.selectedConvertToId,
          amount: this.convertAmount
        });
        this.selectedConvertFromId = -1;
        this.selectedConvertToId = -1;
        this.convertAmount = 0;
      }
      finally {
        this.isConverting = false;
      }
    },

    async onClaimStakingRewards() {
      try {
        this.isClaimingStakingRewards = true;
        this.claimRewardsAmount = Math.floor(this.claimRewardsAmount);
        await this.claimShardsStakingRewards({
          eventId: this.claimRewardsIntoId,
          amount: Math.floor(this.claimRewardsAmount)
        });
      }
      finally {
        this.isClaimingStakingRewards = false;
      }
    },

    openPartnerWebsite() {
      window.open(this.eventPartnerWebsite, '_blank');
    },

    formattedSkillCost(orderOption: number): string {
      return toBN(this.forgeCosts[orderOption - 1]).div(1e18).toFixed(4);
    }
  },

  async mounted() {
    this.updateEndTime = setInterval(() => {
      if(this.endsIn > 0) {
        this.endsIn--;
      }
    }, 1000);
    this.orderedCountInterval = setInterval(async () => {
      if(this.selectedSpecialWeaponEventId) {
        await this.fetchEventTotalOrderedCount(this.selectedSpecialWeaponEventId);
      }
      this.shardsStakingRewards = toBN(await this.fetchShardsStakingRewards()).div(1e18).toFixed(4);
    }, 3000);
    Events.$on('show-special-forge-modal', async () => {
      this.showModal = true;
      try {
        this.isLoading = true;
        await this.fetchSpecialWeaponEvents();
        this.forgeCosts = await this.fetchForgeCosts();
        if(+this.specialWeaponEventId === 0 && (this.activeSpecialWeaponEventsIds.length > 0 || this.inactiveEventsIdsWithUnclaimedOrders.length > 0)) {
          this.selectedSpecialWeaponEventId = +this.activeSpecialWeaponEventsIds.concat(this.inactiveEventsIdsWithUnclaimedOrders)[0];
        }
        else {
          this.selectedSpecialWeaponEventId = +this.specialWeaponEventId;
        }
        this.shardsCostDenominator = await this.fetchShardsConvertDenominator();
      }
      finally {
        this.isLoading = false;
      }
    });
  },

  beforeDestroy() {
    if(this.updateEndTime) {
      clearInterval(this.updateEndTime);
    }
    if(this.orderedCountInterval) {
      clearInterval(this.orderedCountInterval);
    }
  }
});
</script>

<style scoped>
.weapon-img {
  max-height: 250px;
  max-width: max-content;
  align-self: center;
}
.info-div {
  padding: 2px;
  justify-content: space-evenly;
}
.top-border-forge {
  border-top: 1px solid #9e8a57;
}
.shard-icon {
  width: 0.6em;
  height: 1.15em;
}
.row.bordered {
  border-bottom: 1px solid #9e8a5780;
  border-radius: 3px;
}
.scrollable {
  overflow-y: scroll;
  overflow-x: hidden;
  max-height: 10em;
}
.scrollable .row:last-child {
  border-bottom: none;
}
.bottom-border {
  border-bottom: 2px solid #9e8a5780;
}
.top-border-shards {
  border-top: 2px solid #9e8a5780;
}
.weapon-icon-wrapper {
  width: 12em;
  height: 12em;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 5px;
  cursor: pointer;
  position: relative;
  overflow: visible;
}
</style>
