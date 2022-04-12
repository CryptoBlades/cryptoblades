<template>
  <div class="p-1">
    <h2 class="mt-3">{{ $t('admin.specialWeaponsManager.startNewEvent') }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-form-input v-model="newEvent.name" :placeholder="$t('admin.specialWeaponsManager.name')"/>
      <b-form-select class="mt-2 mb-2" v-model="newEvent.element">
        <b-form-select-option :value="undefined" disabled>
          {{ $t('admin.specialWeaponsManager.pleaseSelectElement') }}
        </b-form-select-option>
        <b-form-select-option v-for="element in elements" :key="element" :value="element">
          {{ $t(`admin.specialWeaponsManager.elements.${Element[element]}`) }}
        </b-form-select-option>
      </b-form-select>
      <b-form-input v-model="newEvent.period" type="number" number min="0"
                    :placeholder="$t('admin.specialWeaponsManager.periodInSeconds')"/>
      <b-form-input v-model="newEvent.supply" type="number" number min="0"
                    :placeholder="$t('admin.specialWeaponsManager.supply0Unlimited')"/>
      <b-form-input v-model="newEvent.art" :placeholder="$t('admin.specialWeaponsManager.artUrl')"/>
      <b-form-input v-model="newEvent.details" :placeholder="$t('admin.specialWeaponsManager.details')"/>
      <b-form-input v-model="newEvent.website" :placeholder="$t('admin.specialWeaponsManager.website')"/>
      <b-form-input v-model="newEvent.note" :placeholder="$t('admin.specialWeaponsManager.noteOptional')"/>
      <b-button @click="startNewSpecialWeaponsEvent()" :disabled="startNewSpecialWeaponsEventButtonDisabled"
                variant="primary" class="text-nowrap">
        {{ $t('admin.specialWeaponsManager.startNewEvent') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.specialWeaponsManager.findActiveSpecialWeaponsEvents') }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-button @click="getActiveEvents()" :disabled="isLoading" variant="primary"
                class="text-nowrap">
        {{ $t('admin.specialWeaponsManager.findActiveSpecialWeaponsEvents') }}
      </b-button>
      <table class="table text-white" v-if="activeSpecialWeaponsEvents.length">
        <thead>
        <tr>
          <th>{{ $t('admin.specialWeaponsManager.name') }}</th>
          <th>{{ $t('admin.specialWeaponsManager.id') }}</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="activeSpecialWeaponsEvent in activeSpecialWeaponsEvents" :key="activeSpecialWeaponsEvent.id">
          <td>{{ activeSpecialWeaponsEvent.name }}</td>
          <td>{{ activeSpecialWeaponsEvent.id }}</td>
        </tr>
        </tbody>
      </table>
    </div>
    <h2 class="mt-3">{{ $t('admin.specialWeaponsManager.setSpecialWeaponsEventProperty') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="selectedSpecialWeaponsEvent.id" :placeholder="$t('admin.specialWeaponsManager.id')"/>
      <b-form-select class="mt-2 mb-2"
                     v-model="selectedSpecialWeaponsEvent.selectedProperty">
        <b-form-select-option :value="undefined" disabled>
          {{ $t('admin.specialWeaponsManager.pleaseSelectProperty') }}
        </b-form-select-option>
        <b-form-select-option v-for="property in specialWeaponsEventProperties" :key="property" :value="property">
          {{ $t(`admin.specialWeaponsManager.property.${SpecialWeaponsEventProperty[property]}`) }}
        </b-form-select-option>
      </b-form-select>
      <b-form-input v-model="selectedSpecialWeaponsEvent.value"
                    :placeholder="$t('admin.specialWeaponsManager.propertyValue')"/>
      <b-button @click="setSpecialWeaponsEventProperty()" :disabled="setSpecialWeaponsEventPropertyButtonDisabled"
                variant="primary" class="text-nowrap">
        {{ $t('admin.specialWeaponsManager.setSpecialWeaponsEventProperty') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.specialWeaponsManager.addShards') }}</h2>
    <div class="d-flex align-items-center gap-3">
      <b-form-input v-model="newAddShardsUser.user" :placeholder="$t('admin.specialWeaponsManager.user')"/>
      <b-form-input v-model="newAddShardsUser.eventId" type="number" number min="0"
                    :placeholder="$t('admin.specialWeaponsManager.id')"/>
      <b-form-input v-model="newAddShardsUser.shardsAmount" type="number" number min="0"
                    :placeholder="$t('admin.specialWeaponsManager.shardsAmount')"/>
      <b-button @click="addShardsForUser()" :disabled="addShardsForUserButtonDisabled"
                variant="primary" class="text-nowrap">
        {{ $t('admin.specialWeaponsManager.addShards') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.specialWeaponsManager.incrementEventCountBeCareful') }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-button @click="incrementEventCountModal = !incrementEventCountModal" :disabled="isLoading" variant="primary"
                class="text-nowrap">
        {{ $t('admin.specialWeaponsManager.incrementEventCount') }}
      </b-button>
      <b-modal v-model="incrementEventCountModal" @ok.prevent="onIncrementEventCount" :ok-disabled="isLoading"
               :title="$t('admin.specialWeaponsManager.areYouSure')">
        {{ $t('admin.specialWeaponsManager.eventIncrementationIrreversibleInfo') }}
      </b-modal>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {isValidWeb3Address} from '../../../utils/common';

interface StoreMappedActions {
  startNewEvent(payload: { event: SpecialWeaponsEvent }): Promise<void>;

  getActiveSpecialWeaponsEvents(): Promise<SpecialWeaponsEvent[]>;

  setSpecialWeaponArt(payload: { eventId: number, art: string }): Promise<void>;

  setSpecialWeaponDetails(payload: { eventId: number, details: string }): Promise<void>;

  setSpecialWeaponWebsite(payload: { eventId: number, website: string }): Promise<void>;

  setSpecialWeaponNote(payload: { eventId: number, note: string }): Promise<void>;

  incrementEventCount(): Promise<void>;

  addShards(payload: { user: string, eventId: number, shardsAmount: number }): Promise<void>;
}

interface AddShards {
  user: string;
  eventId?: number;
  shardsAmount?: number;
}

enum SpecialWeaponsEventProperty {
  ART, DETAILS, WEBSITE, NOTE
}

interface SelectedSpecialWeaponsEvent {
  id?: number;
  selectedProperty?: SpecialWeaponsEventProperty;
  value: string;
}

enum Element {
  ALL = 100,
  FIRE = 0,
  WATER = 1,
  EARTH = 2,
  LIGHTNING = 3,
}

interface SpecialWeaponsEvent {
  id?: number;
  name?: string;
  element?: Element;
  period?: number;
  supply?: number;
  art?: string;
  details?: string;
  website?: string;
  note?: string;
}

interface Data {
  newEvent: SpecialWeaponsEvent;
  selectedSpecialWeaponsEvent: SelectedSpecialWeaponsEvent;
  activeSpecialWeaponsEvents: SpecialWeaponsEvent[];
  incrementEventCountModal: boolean;
  newAddShardsUser: AddShards;
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      newEvent: {
        name: '',
        element: undefined,
        period: undefined,
        supply: undefined,
        art: '',
        details: '',
        website: '',
        note: '',
      },
      elements: [Element.ALL, Element.FIRE, Element.WATER, Element.EARTH, Element.LIGHTNING],
      specialWeaponsEventProperties: [
        SpecialWeaponsEventProperty.ART,
        SpecialWeaponsEventProperty.DETAILS,
        SpecialWeaponsEventProperty.WEBSITE,
        SpecialWeaponsEventProperty.NOTE,
      ],
      selectedSpecialWeaponsEvent: {
        id: undefined,
        selectedProperty: undefined,
        value: '',
      },
      activeSpecialWeaponsEvents: [],
      incrementEventCountModal: false,
      newAddShardsUser: {
        user: '',
        eventId: undefined,
        shardsAmount: undefined,
      },
      isLoading: false,
      Element,
      SpecialWeaponsEventProperty,
    } as Data;
  },

  computed: {
    startNewSpecialWeaponsEventButtonDisabled(): boolean {
      return !this.newEvent.name
        || this.newEvent.element === undefined
        || this.newEvent.period === undefined
        || this.newEvent.supply === undefined
        || !this.newEvent.art
        || !this.newEvent.details
        || !this.newEvent.website
        || this.isLoading;
    },
    setSpecialWeaponsEventPropertyButtonDisabled(): boolean {
      return this.selectedSpecialWeaponsEvent.id === undefined
        || this.selectedSpecialWeaponsEvent.selectedProperty === undefined
        || !this.selectedSpecialWeaponsEvent.value
        || this.isLoading;
    },
    addShardsForUserButtonDisabled(): boolean {
      return !isValidWeb3Address(this.newAddShardsUser.user)
        || this.newAddShardsUser.eventId === undefined
        || this.newAddShardsUser.shardsAmount === undefined
        || this.isLoading;
    },
  },

  methods: {
    ...mapActions([
      'startNewEvent',
      'getActiveSpecialWeaponsEvents',
      'setSpecialWeaponArt',
      'setSpecialWeaponDetails',
      'setSpecialWeaponWebsite',
      'setSpecialWeaponNote',
      'incrementEventCount',
      'addShards',
    ]) as StoreMappedActions,

    async getActiveEvents() {
      try {
        this.isLoading = true;
        this.activeSpecialWeaponsEvents = await this.getActiveSpecialWeaponsEvents();
        console.log(this.activeSpecialWeaponsEvents);
      } finally {
        this.isLoading = false;
      }
    },

    async startNewSpecialWeaponsEvent() {
      this.isLoading = true;
      try {
        await this.startNewEvent({event: this.newEvent});
        this.newEvent = {
          name: '',
          element: undefined,
          period: undefined,
          supply: undefined,
          art: '',
          details: '',
          website: '',
          note: '',
        };
      } finally {
        this.isLoading = false;
      }
    },

    async setSpecialWeaponsEventProperty() {
      this.isLoading = true;
      try {
        switch (this.selectedSpecialWeaponsEvent.selectedProperty) {
        case SpecialWeaponsEventProperty.ART:
          await this.setSpecialWeaponArt({
            eventId: this.selectedSpecialWeaponsEvent.id,
            art: this.selectedSpecialWeaponsEvent.value,
          });
          break;
        case SpecialWeaponsEventProperty.DETAILS:
          await this.setSpecialWeaponDetails({
            eventId: this.selectedSpecialWeaponsEvent.id,
            details: this.selectedSpecialWeaponsEvent.value,
          });
          break;
        case SpecialWeaponsEventProperty.WEBSITE:
          await this.setSpecialWeaponWebsite({
            eventId: this.selectedSpecialWeaponsEvent.id,
            website: this.selectedSpecialWeaponsEvent.value,
          });
          break;
        case SpecialWeaponsEventProperty.NOTE:
          await this.setSpecialWeaponNote({
            eventId: this.selectedSpecialWeaponsEvent.id,
            note: this.selectedSpecialWeaponsEvent.value,
          });
          break;
        }
        this.selectedSpecialWeaponsEvent = {
          id: undefined,
          selectedProperty: undefined,
          value: '',
        };
      } finally {
        this.isLoading = false;
      }
    },

    async addShardsForUser() {
      this.isLoading = true;
      try {
        await this.addShards({
          user: this.newAddShardsUser.user,
          eventId: this.newAddShardsUser.eventId,
          shardsAmount: this.newAddShardsUser.shardsAmount,
        });
        this.newAddShardsUser = {
          user: '',
          eventId: undefined,
          shardsAmount: undefined,
        };
      } finally {
        this.isLoading = false;
      }
    },

    async onIncrementEventCount() {
      this.isLoading = true;
      try {
        await this.incrementEventCount();
      } finally {
        this.isLoading = false;
      }
    },
  }

});
</script>

<style scoped>
</style>
