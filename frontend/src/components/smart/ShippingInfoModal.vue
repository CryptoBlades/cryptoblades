<template>
  <b-modal class="centered-modal" @ok="buyItem" v-model="showModal"
           :ok-title="$t('market.merchandise.continue')" :title="$t('market.merchandise.deliveryAddress')"
           :ok-disabled="!shippingInformationComplete"
           button-size="lg" no-close-on-backdrop>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.name" :placeholder="$t('market.merchandise.fullName')"/>
    <b-form-input type="email" :state="emailState"
                  class="mt-2 mb-2" v-model="recipient.email" :placeholder="$t('market.merchandise.email')"/>
    <b-form-input type="tel"
                  class="mt-2 mb-2" v-model="recipient.phone" :placeholder="$t('market.merchandise.phone')"/>
    <b-form-select
      class="mt-2 mb-2" v-model="selectedCountry" @change="countryChanged">
      <b-form-select-option :value="undefined" disabled>{{
          $t('market.merchandise.pleaseSelectACountry')
        }}
      </b-form-select-option>
      <b-form-select-option v-for="country in countries" :key="country.code" :value="country">{{
          country.name
        }}
      </b-form-select-option>
    </b-form-select>
    <b-form-select
      class="mt-2 mb-2" v-if="selectedCountry && selectedCountry.states && selectedCountry.states.length !== 0"
      v-model="selectedState">
      <b-form-select-option :value="undefined" disabled>{{
          $t('market.merchandise.pleaseSelectAState')
        }}
      </b-form-select-option>
      <b-form-select-option v-for="state in selectedCountry.states" :key="state.code" :value="state">{{
          state.name
        }}
      </b-form-select-option>
    </b-form-select>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.address1" :placeholder="$t('market.merchandise.addressLine1')"/>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.address2" :placeholder="$t('market.merchandise.addressLine2')"/>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.city" :placeholder="$t('market.merchandise.city')"/>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.zip" :placeholder="$t('market.merchandise.zipCode')"/>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.company"
                  :placeholder="$t('market.merchandise.companyOptional')"/>
  </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import api from '@/api';
import {CartEntry} from '@/components/smart/VariantChoiceModal.vue';

export interface Recipient {
  name: string;
  email: string;
  phone: string;
  country_code: string;
  state_code?: string;
  address1: string;
  address2?: string;
  city: string;
  zip: string;
  company?: string;
}

export interface Country {
  name: string;
  code: string;
  states?: State[];
}

export interface State {
  name: string;
  code: string;
}

export interface OrderItem {
  external_variant_id: string;
  product_id: string;
  quantity: number;
}

interface Data {
  selectedCountry?: Country;
  selectedState?: State;
  countries: Country[];
  recipient: Recipient;
  cartEntries: CartEntry[];
  totalPriceInSkill: number;
  showModal: boolean;
}

export default Vue.extend({
  data() {
    return {
      selectedCountry: undefined,
      selectedState: undefined,
      countries: [],
      recipient: {} as Recipient,
      cartEntries: [],
      totalPriceInSkill: 0,
      showModal: false,
    } as Data;
  },

  computed: {
    emailState() {
      return this.$data.recipient.email && this.$data.recipient.email.includes('@');
    },
    shippingInformationComplete(): boolean {
      return this.$data.recipient.name
        && this.$data.recipient.email
        && this.$data.recipient.phone
        && (this.$data.selectedCountry && (!this.$data.selectedCountry.states || this.$data.selectedCountry.states.length === 0)
          || (this.$data.selectedCountry && this.$data.selectedCountry.states && this.$data.selectedCountry.states.length !== 0 && this.$data.selectedState))
        && this.$data.recipient.address1
        && this.$data.recipient.city
        && !!this.$data.recipient.zip;
    }
  },

  methods: {
    countryChanged() {
      this.selectedState = undefined;
    },

    async fetchCountries() {
      const response = await api.getMerchandiseCountries();
      if (response.code !== 200) {
        return;
      }
      this.countries = response.result;
    },

    async buyItem(bvModalEvt: Event) {
      bvModalEvt.preventDefault();
      if (!this.selectedCountry) return;
      this.recipient.country_code = this.selectedCountry.code;
      this.recipient.state_code = this.selectedState?.code;
      this.$root.$emit('order-summary-modal', this.recipient, this.cartEntries);
    },
  },

  async mounted() {
    await this.fetchCountries();
    this.$root.$on('merchandise-address-modal', (totalPriceInSkill: number, cartEntries: CartEntry[]) => {
      if (totalPriceInSkill) {
        this.totalPriceInSkill = totalPriceInSkill;
        this.cartEntries = cartEntries;
        this.showModal = true;
      } else {
        this.showModal = false;
      }
    });
  }
});
</script>

<style>

</style>
