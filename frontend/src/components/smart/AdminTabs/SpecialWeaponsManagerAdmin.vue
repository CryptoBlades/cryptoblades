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
      <b-form-input v-model="newEvent.logo" :placeholder="$t('admin.specialWeaponsManager.logoUrl')"/>
      <b-form-input v-model="newEvent.details" :placeholder="$t('admin.specialWeaponsManager.details')"/>
      <b-form-input v-model="newEvent.website" :placeholder="$t('admin.specialWeaponsManager.website')"/>
      <b-form-input v-model="newEvent.note" :placeholder="$t('admin.specialWeaponsManager.noteOptional')"/>
      <b-button @click="startNewSpecialWeaponsEvent()" :disabled="startNewSpecialWeaponsEventButtonDisabled"
                variant="primary" class="text-nowrap">
        {{ $t('admin.specialWeaponsManager.startNewEvent') }}
      </b-button>
    </div>
    <!--    <h2 class="mt-3">{{ $t('admin.cryptoblades.setWeaponMintValueCurrent', {cents: currentWeaponMintValue}) }}</h2>-->
    <!--    <div class="d-flex align-items-center gap-3 flex-wrap">-->
    <!--      <b-form-input v-model="newWeaponMintValue" type="number" number-->
    <!--                    :placeholder="$t('admin.cryptoblades.newValueInCents')"/>-->
    <!--      <b-button @click="setNewWeaponMintValue()" :disabled="setWeaponMintValueButtonDisabled" variant="primary"-->
    <!--                class="text-nowrap">-->
    <!--        {{ $t('admin.cryptoblades.setWeaponMintValue') }}-->
    <!--      </b-button>-->
    <!--    </div>-->
    <!--    <h2 class="mt-2">{{ $t('admin.cryptoblades.setFightXpGainCurrentDefault32', {xpGain: currentFightXpGain}) }}</h2>-->
    <!--    <div class="d-flex align-items-center gap-3">-->
    <!--      <b-form-input v-model="newFightXpGain" :placeholder="$t('admin.cryptoblades.fightXpGain')" number type="number"/>-->
    <!--      <b-button @click="setNewFightXpGain()" :disabled="setNewFightXpGainButtonDisabled"-->
    <!--                variant="primary" class="text-nowrap">-->
    <!--        {{ $t('admin.cryptoblades.setFightXpGain') }}-->
    <!--      </b-button>-->
    <!--    </div>-->
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';

interface StoreMappedActions {
  startNewEvent(payload: { event: SpecialWeaponsEvent }): Promise<void>;
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
  logo?: string;
  details?: string;
  website?: string;
  note?: string;
}

interface Data {
  newEvent: SpecialWeaponsEvent;
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
        logo: '',
        details: '',
        website: '',
        note: '',
      },
      elements: [Element.ALL, Element.FIRE, Element.WATER, Element.EARTH, Element.LIGHTNING],
      isLoading: false,
      Element,
    } as Data;
  },

  computed: {
    startNewSpecialWeaponsEventButtonDisabled(): boolean {
      return !this.newEvent.name
        || this.newEvent.element === undefined
        || this.newEvent.period === undefined
        || this.newEvent.supply === undefined
        || !this.newEvent.logo
        || !this.newEvent.details
        || !this.newEvent.website
        || this.isLoading;
    }
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
          logo: '',
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
