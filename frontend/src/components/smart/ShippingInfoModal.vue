<template>
  <b-modal class="centered-modal" ref="merchandise-address-modal" @ok="buyItem" :ok-title="'Submit order'"
           :ok-disabled="false" button-size="lg">
    <template #modal-title>
      Delivery Address
    </template>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.first_name" placeholder="First name"/>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.last_name" placeholder="Last name"/>
    <b-form-input type="email"
                  class="mt-2 mb-2" v-model="recipient.email" placeholder="Email"/>
    <b-form-input type="tel"
                  class="mt-2 mb-2" v-model="recipient.phone" placeholder="Phone"/>
    <b-form-select
      class="mt-2 mb-2" v-model="selectedCountry" @change="countryChanged">
      <b-form-select-option :value="undefined">Please select an option</b-form-select-option>
      <b-form-select-option v-for="country in countries" :key="country.code" :value="country">{{
          country.name
        }}
      </b-form-select-option>
    </b-form-select>
    <b-form-select
      class="mt-2 mb-2" v-if="selectedCountry && selectedCountry.states && selectedCountry.states.length !== 0"
      v-model="selectedState">
      <b-form-select-option :value="undefined">Please select an option</b-form-select-option>
      <b-form-select-option v-for="state in selectedCountry.states" :key="state.code" :value="state">{{
          state.name
        }}
      </b-form-select-option>
    </b-form-select>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.address1" placeholder="Address line 1"/>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.address2" placeholder="Address line 2"/>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.city" placeholder="City"/>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.zip" placeholder="Zip Code"/>
  </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import api from '@/api';
import {BModal} from 'bootstrap-vue';
import {MerchandiseOrder} from '@/components/smart/MerchandiseList.vue';

export interface Recipient {
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  country: string;
  state?: string;
  address1: string;
  address2?: string;
  city: string;
  zip: string;
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

interface Data {
  selectedCountry?: Country;
  selectedState?: State;
  countries: Country[];
  recipient: Recipient;
}

export default Vue.extend({
  data() {
    return {
      selectedCountry: undefined,
      selectedState: undefined,
      countries: [],
      recipient: {} as Recipient,
    } as Data;
  },

  // props: {
  //   recipient: {
  //     type: Object as PropType<Recipient>,
  //   },
  // },

  computed: {
    //TODO: Rework this
    // disablePlaceOrderButton() {
    //   return !this.$data.recipient.name || !this.$data.recipient.phone || !this.$data.recipient.email
    //     || !this.$data.recipient.address1 || !this.$data.recipient.city || !this.$data.recipient.zip
    //     || !this.$data.recipient.countryCode;
    // }
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

    async buyItem() {
      if (!this.selectedCountry) return;
      this.recipient.country = this.selectedCountry.code;
      this.recipient.state = this.selectedState?.code;
      const merchandiseOrder: MerchandiseOrder = {
        recipient: this.recipient,
        items: [
          {
            sync_variant_id: 2799351521,
            product_id: '612a5910aa37e7',
            quantity: 1
          }
        ]
      };
      // await this.purchaseMerchandise({id: this.selectedProduct.id, price: this.selectedProduct.price, amount: 1})
      //   .then(async () => {
      //
      //   });
      // this.recipient = {} as Recipient;
      await api.createMerchandiseOrder(merchandiseOrder);
      (this.$refs['merchandise-address-modal'] as BModal).hide();
    },
  },

  async mounted() {
    await this.fetchCountries();
    this.$root.$on('merchandise-address-modal', (open: boolean) => {
      const modal = this.$refs['merchandise-address-modal'] as BModal;
      if (modal) {
        if (open) {
          modal.show();
        } else {
          modal.hide();
        }
      }
    });
  }
});
</script>

<style>

</style>
