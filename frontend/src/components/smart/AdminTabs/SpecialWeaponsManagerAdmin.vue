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
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';

interface StoreMappedActions {
  startNewEvent(payload: { event: SpecialWeaponsEvent }): Promise<void>;
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
  },

  methods: {
    ...mapActions([
      'startNewEvent',
    ]) as StoreMappedActions,
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
    }
  }

});
</script>

<style scoped>
</style>
