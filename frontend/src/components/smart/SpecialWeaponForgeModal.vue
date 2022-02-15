<template>
  <b-modal v-model="showModal" hide-footer size="lg" class="centered-text-modal" ref="special-forge-modal" :title="$t('blacksmith.specialForge')">
      <b-tabs justified>
        <b-tab :title="$t('blacksmith.forge')">
          <div class="d-flex mt-3 align-items-center">
            <h5 class="mb-0">{{$t('blacksmith.specialEvent')}}:</h5>
            <b-form-select :disabled="!activeSpecialWeaponEventsIds.length" class="w-50 ml-1" size="sm"
              v-model="selectedSpecialWeaponEventId" :value="selectedSpecialWeaponEventId" @change="updateSpecialWeaponEventId($event)">
              <b-form-select-option v-for="id in activeSpecialWeaponEventsIds" :key="id" :value="id">
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
                  <h5 class="mb-0">Available elements:</h5>
                  <h5 v-if="availableElement === 100 || availableElement === 0" class="fire-icon ml-2 mb-0" />
                  <h5 v-if="availableElement === 100 || availableElement === 1" class="earth-icon mb-0" />
                  <h5 v-if="availableElement === 100 || availableElement === 2" class="lightning-icon mb-0" />
                  <h5 v-if="availableElement === 100 || availableElement === 3" class="water-icon mb-0 mr-2" />
                </div>
              </div>
              <div class="w-50 mb-3">
                <span>{{$t('blacksmith.endsIn')}}: {{eventEndsIn}}</span>
                <h4>{{partnerName}}</h4>
                <div class="mt-2">
                  <h5 class="text-justify">{{eventDetails}}</h5>
                  <a class="a-button" @click="openPartnerWebsite">{{eventPartnerWebsite}}</a>
                </div>
              </div>
            </div>
            <div class="d-flex mt-3 info-div justify-content-center" v-if="isForging">
              <img :src="forgingGifSrc" />
            </div>
            <div v-if="!eventWeaponOrdered && !eventWeaponForged">
              <div class="d-flex mt-3 align-items-center">
                <h5 class="mb-0">{{$t('blacksmith.forgeOption')}}:</h5>
                <b-form-select v-if="forgeCosts && forgeCosts.length > 0" :disabled="!activeSpecialWeaponEventsIds.length" class="w-50 ml-1" size="sm"
                  v-model="forgeOption" :value="selectedSpecialWeaponEventId" @change="updateSpecialWeaponEventId($event)">
                  <b-form-select-option :value="1">3-5* {{$t('blacksmith.for')}} {{forgeCosts[0]}} {{$t('blacksmith.shards')}}</b-form-select-option>
                  <b-form-select-option :value="2">4-5* {{$t('blacksmith.for')}} {{forgeCosts[1]}} {{$t('blacksmith.shards')}}</b-form-select-option>
                  <b-form-select-option :value="3">5* {{$t('blacksmith.for')}} {{forgeCosts[2]}} {{$t('blacksmith.shards')}}</b-form-select-option>
                </b-form-select>
              </div>
              <div class="d-flex justify-content-center mt-3">
                <b-button
                        variant="primary"
                        @click="onForgeSpecialWeapon()"
                        :disabled="!canForge || isForging">
                  <span v-if="!isForging" class="gtag-link-others">
                    {{$t('blacksmith.forge')}} ({{forgeCost}} {{$t('blacksmith.shards')}})
                  </span>
                  <span v-if="isForging" class="gtag-link-others">
                    {{$t('blacksmith.forging')}}
                  </span>
                </b-button>
              </div>
            </div>
            <div class="d-flex flex-column align-items-center mt-3" v-if="eventWeaponOrdered && !eventWeaponForged">
              <h5>{{$t('blacksmith.specialWeaponOrdered')}}</h5>
              <b-button
                      variant="primary"
                      @click="onClaimSpecialWeapon()"
                      :disabled="isClaiming">
                <span v-if="!isClaiming" class="gtag-link-others">
                  {{$t('blacksmith.claim')}}
                </span>
                <span v-if="isClaiming" class="gtag-link-others">
                  {{$t('blacksmith.claiming')}}
                </span>
              </b-button>
            </div>
            <div class="d-flex justify-content-center mt-3" v-if="eventWeaponForged">
              <h5>{{$t('blacksmith.specialWeaponClaimed')}}</h5>
            </div>
          </div>
        </b-tab>
        <b-tab :title="$t('blacksmith.shards')">
          <div>
            <strong>General shards:</strong> <img class="shard-icon" :src="generalShardImg" /> {{shardsSupply[0]}}
          </div>
          <div class="mt-2">
            <b-row class="mr-1">
              <b-col><strong>Name</strong></b-col>
              <b-col><strong>Status</strong></b-col>
              <b-col><strong>Balance</strong></b-col>
            </b-row>
            <div class="scrollable mt-1">
              <b-row class="bordered" v-for="id in activeSpecialWeaponEventsIds" :key="id" :value="id">
                <b-col>{{specialWeaponEvents[id] && specialWeaponEvents[id].name}}</b-col>
                <b-col>Live</b-col>
                <b-col><img class="shard-icon" :src="eventShardImg" /> {{shardsSupply[id]}}</b-col>
              </b-row>
              <b-row class="bordered" v-for="id in inactiveSpecialWeaponEventsIds" :key="id" :value="id">
                <b-col>{{specialWeaponEvents[id] && specialWeaponEvents[id].name}}</b-col>
                <b-col>Ended</b-col>
                <b-col><img class="shard-icon" :src="eventShardImg" /> {{shardsSupply[id]}}</b-col>
              </b-row>
            </div>
          </div>
          <div class="mt-3 top-border">
            <h4 class="mt-2">Convert</h4>
            <div class="d-flex align-items-center">
              <h5 class="mb-0">{{$t('blacksmith.from')}}:</h5>
              <b-form-select class="w-25 ml-1" size="sm"
                v-model="selectedConvertFromId" :value="selectedConvertFromId">
                <b-form-select-option v-if="selectedConvertToId !== 0" :key="0" :value="0">
                  {{$t('blacksmith.specialEventNone')}}
                </b-form-select-option>
                <b-form-select-option v-for="id in allEventsIds.filter(id => id !== selectedConvertToId)" :key="id" :value="id">
                  {{specialWeaponEvents[id] && specialWeaponEvents[id].name}}
                </b-form-select-option>
              </b-form-select>
              <h5 class="ml-3 mb-0">{{$t('blacksmith.to')}}:</h5>
              <b-form-select class="w-25 ml-1" size="sm"
                v-model="selectedConvertToId" :value="selectedConvertToId">
                <b-form-select-option v-if="selectedConvertFromId !== 0" :key="0" :value="0">
                  {{$t('blacksmith.specialEventNone')}}
                </b-form-select-option>
                <b-form-select-option v-for="id in activeSpecialWeaponEventsIds.filter(id => id !== selectedConvertFromId)" :key="id" :value="id">
                  {{specialWeaponEvents[id] && specialWeaponEvents[id].name}}
                </b-form-select-option>
              </b-form-select>
              <h5 class="ml-3 mb-0">{{$t('blacksmith.amount')}}:</h5>
              <b-input type="number" class="form-control w-25" v-model="convertAmount" min="0"
                :max="selectedConvertFromId >= 0 ? shardsSupply[selectedConvertFromId] : ''"></b-input>
            </div>
            <div class="d-flex justify-content-center">
              <h5 class="mt-3" v-if="specialWeaponEvents[selectedConvertToId]">
                {{$t('blacksmith.youWillReceive')}} {{convertOutputAmount}} {{specialWeaponEvents[selectedConvertToId].name}} {{$t('blacksmith.shards')}}.
              </h5>
              <h5 class="mt-3" v-if="selectedConvertToId === 0">
                {{$t('blacksmith.youWillReceive')}} {{convertOutputAmount}} {{$t('blacksmith.generalShards')}}.
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
                <span v-if="isConverting" class="gtag-link-others">
                  {{$t('blacksmith.converting')}}
                </span>
              </b-button>
            </div>
          </div>
        </b-tab>
      </b-tabs>
    </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import weaponEvents from '../../../special-weapons.json';
import { mapActions, mapMutations, mapState } from 'vuex';
import { IState } from '@/interfaces';
import { Accessors } from 'vue/types/options';
import Events from '../../events';
import { secondsToDDHHMMSS } from '@/utils/date-time';
import eventShard from '../../assets/special-weapons/eventShard.png';
import generalShard from '../../assets/special-weapons/generalShard.png';
import forgingGif from '../../assets/special-weapons/forging.gif';

interface SpecialWeaponEventInfo {
  eventsDetails: Record<string, Record<string, any>>;
}

type StoreMappedState = Pick<IState,'activeSpecialWeaponEventsIds' | 'inactiveSpecialWeaponEventsIds' |
'specialWeaponEvents' | 'specialWeaponEventId' | 'shardsSupply'>;

interface StoreMappedActions {
  fetchSpecialWeaponEvents(): Promise<void>;
  fetchForgeCosts(): Promise<number[]>;
  fetchShardsConvertDenominator(): Promise<number>;
  convertShards({ eventFromId, eventToId, amount }: { eventFromId: number, eventToId: number, amount: number }): Promise<void>;
  orderSpecialWeapon({ eventId, orderOption}: { eventId: number, orderOption: number}): Promise<void>;
  forgeSpecialWeapon(eventId: number): Promise<void>;
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
  convertAmount: number;
  selectedConvertFromId: number;
  selectedConvertToId: number;
  isConverting: boolean;
  isForging: boolean;
  isClaiming: boolean;
  shardsCostDenominator: number;
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
      convertAmount: 0,
      selectedConvertFromId: -1,
      selectedConvertToId: -1,
      isConverting: false,
      isForging: false,
      isClaiming: false,
      shardsCostDenominator: 0
    } as Data;
  },

  computed: {
    ...(mapState([
      'activeSpecialWeaponEventsIds',
      'inactiveSpecialWeaponEventsIds',
      'specialWeaponEvents',
      'specialWeaponEventId',
      'shardsSupply'
    ]) as Accessors<StoreMappedState>),

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

    forgeCost(): number {
      return this.forgeCosts && this.forgeCosts[this.forgeOption - 1];
    },

    canForge(): boolean {
      return !!this.selectedSpecialWeaponEventId && this.shardsSupply[this.selectedSpecialWeaponEventId] >= this.forgeCost && this.endsIn > 0;
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

    eventWeaponOrdered(): boolean {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return false;
      return this.specialWeaponEvents[this.selectedSpecialWeaponEventId].ordered;
    },

    eventWeaponForged(): boolean {
      if(!this.specialWeaponEvents[this.selectedSpecialWeaponEventId]) return false;
      console.log(this.specialWeaponEvents[this.selectedSpecialWeaponEventId]);
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
      return Math.ceil(this.convertAmount / this.shardsCostDenominator);
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
      'orderSpecialWeapon', 'forgeSpecialWeapon']) as StoreMappedActions,
    ...mapMutations(['updateSpecialWeaponEventId']) as StoreMappedMutations,

    imgPath(img: string): string {
      return this.images('./' + img);
    },

    async onForgeSpecialWeapon() {
      try {
        this.isForging = true;
        await this.orderSpecialWeapon({
          eventId: this.selectedSpecialWeaponEventId,
          orderOption: this.forgeOption
        });
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

    openPartnerWebsite() {
      window.open(this.eventPartnerWebsite, '_blank');
    },
  },

  async mounted() {
    this.updateEndTime = setInterval(() => {
      if(this.endsIn > 0) {
        this.endsIn--;
      }
    }, 1000);
    Events.$on('show-special-forge-modal', async () => {
      this.showModal = true;
      await this.fetchSpecialWeaponEvents();
      this.forgeCosts = await this.fetchForgeCosts();
      if(+this.specialWeaponEventId === 0 && this.activeSpecialWeaponEventsIds.length > 0) {
        this.selectedSpecialWeaponEventId = +this.activeSpecialWeaponEventsIds[0];
      }
      else {
        this.selectedSpecialWeaponEventId = +this.specialWeaponEventId;
      }
      this.shardsCostDenominator = await this.fetchShardsConvertDenominator();
    });
  },

  beforeDestroy() {
    if(this.updateEndTime) {
      clearInterval(this.updateEndTime);
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
  border-bottom: 1px solid #9e8a57;
  justify-content: space-evenly;
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
.top-border {
  border-top: 2px solid #9e8a5780;
}
</style>
