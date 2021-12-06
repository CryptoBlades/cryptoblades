<template>
  <b-modal class="centered-modal" ref="merchandise-address-modal" @ok="buyItem" :ok-title="'Submit order'"
           :ok-disabled="disablePlaceOrderButton" button-size="lg">
    <template #modal-title>
      Delivery Address
    </template>
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.name" placeholder="Full name"/>
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
    <b-form-input type="text"
                  class="mt-2 mb-2" v-model="recipient.company" placeholder="Company (optional)"/>
  </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import api from '@/api';
import {BModal} from 'bootstrap-vue';
import {MerchandiseOrder} from '@/components/smart/MerchandiseList.vue';
import {CartEntry} from '@/components/smart/VariantChoiceModal.vue';
import {mapActions} from 'vuex';
import BigNumber from 'bignumber.js';

export interface Recipient {
  name: string;
  email: string;
  phone: string;
  country: string;
  state?: string;
  address1: string;
  address2?: string;
  city: string;
  zip: string;
  company: string;
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

interface OrderItem {
  sync_variant_id: number;
  product_id: string;
  quantity: number;
}

interface StoreMappedActions {
  purchaseMerchandise(payload: { ids: number[], amounts: number[], totalPrice: BigNumber }): Promise<number>;
}

interface Data {
  selectedCountry?: Country;
  selectedState?: State;
  countries: Country[];
  recipient: Recipient;
  cartEntries: CartEntry[];
  totalPriceInSkill: number;
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
    } as Data;
  },

  computed: {
    disablePlaceOrderButton() {
      return !this.$data.recipient.name
        || !this.$data.recipient.email
        || !this.$data.recipient.phone
        || !this.$data.selectedCountry
        || (this.$data.selectedCountry.states && this.$data.selectedCountry.states.length !== 0 && !this.$data.selectedState)
        || !this.$data.recipient.address1
        || !this.$data.recipient.city
        || !this.$data.recipient.zip;
    }
  },

  methods: {
    ...mapActions(['purchaseMerchandise']) as StoreMappedActions,
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
      this.$root.$emit('merchandise-order-loading', true);
      this.recipient.country = this.selectedCountry.code;
      this.recipient.state = this.selectedState?.code;
      const orderItems = this.cartEntries.map(cartEntry => {
        return {
          sync_variant_id: cartEntry.variant.id,
          quantity: cartEntry.quantity
        } as OrderItem;
      });
      const merchandiseOrder: MerchandiseOrder = {
        recipient: this.recipient,
        items: orderItems
      };

      this.$root.$emit('merchandise-cart-modal', false);
      console.log('transaction starting');
      try {
        // await this.purchaseMerchandise({
        //   ids: merchandiseOrder.items.map(item => item.sync_variant_id),
        //   amounts: merchandiseOrder.items.map(item => item.quantity),
        //   totalPrice: toBN(this.totalPriceInSkill),
        // });
        await setTimeout(() => {
        }, 2000);
        const apiResponse = await api.createMerchandiseOrder(merchandiseOrder);
        this.$root.$emit('order-complete-modal', apiResponse.result.id, apiResponse.result.shipping_service_name);
      } catch (e) {
        console.error(e);
      } finally {
        this.$root.$emit('merchandise-order-loading', false);
      }
    },
  },

  async mounted() {
    await this.fetchCountries();
    this.$root.$on('merchandise-address-modal', (totalPriceInSkill: number, cartEntries: CartEntry[]) => {
      const modal = this.$refs['merchandise-address-modal'] as BModal;
      if (modal) {
        if (totalPriceInSkill) {
          this.totalPriceInSkill = totalPriceInSkill;
          this.cartEntries = cartEntries;
          modal.show();
        } else {
          console.log('hide address');
          modal.hide();
        }
      }
    });
  }
});
</script>

<style>

</style>
