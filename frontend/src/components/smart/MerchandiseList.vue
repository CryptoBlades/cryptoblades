<template>
  <div>
    <div class="centered-text-div" v-if="(!products || products.length === 0)">
      <span>Nothing to buy at this time</span>
    </div>
    <ul class="product-grid">
      <li class="product" v-for="product in products" :key="product.id">
        <img class="product-img" :src="product.thumbnail_url" alt=""/>
        <div class="product-name">{{ product.name }}</div>
        <b-button
          variant="primary"
          class="shop-button"
          @click="openAddress(product)">
          <span>Buy (<CurrencyConverter v-if="product.price" :skill="fromWeiEther(+product.price)"
                                        :showValueInSkillOnly="true" :minDecimals="1"/>)</span>
        </b-button>
      </li>
    </ul>

    <b-modal class="centered-modal" ref="merchandise-address-modal" @ok="buyItem" :ok-title="'Submit order'"
             :ok-disabled="false" button-size="lg">
      <template #modal-title>
        Delivery Address
      </template>
      <b-form-input type="text"
                    class="modal-input" v-model="recipient.first_name" placeholder="First name"/>
      <b-form-input type="text"
                    class="modal-input" v-model="recipient.last_name" placeholder="Last name"/>
      <b-form-input type="email"
                    class="modal-input" v-model="recipient.email" placeholder="Email"/>
      <b-form-input type="number"
                    class="modal-input" v-model="recipient.phone" placeholder="Phone"/>
      <b-form-select
        class="modal-input" v-model="selectedCountry" @change="countryChanged">
        <b-form-select-option :value="undefined">Please select an option</b-form-select-option>
        <b-form-select-option v-for="country in countries" :key="country.code" :value="country">{{
            country.name
          }}
        </b-form-select-option>
      </b-form-select>
      <b-form-select
        class="modal-input" v-if="selectedCountry && selectedCountry.states && selectedCountry.states.length !== 0"
        v-model="selectedState">
        <b-form-select-option :value="undefined">Please select an option</b-form-select-option>
        <b-form-select-option v-for="state in selectedCountry.states" :key="state.code" :value="state">{{
            state.name
          }}
        </b-form-select-option>
      </b-form-select>
      <b-form-input type="text"
                    class="modal-input" v-model="recipient.address1" placeholder="Address line 1"/>
      <b-form-input type="text"
                    class="modal-input" v-model="recipient.address2" placeholder="Address line 2"/>
      <b-form-input type="text"
                    class="modal-input" v-model="recipient.city" placeholder="City"/>
      <b-form-input type="text"
                    class="modal-input" v-model="recipient.zip" placeholder="Zip Code"/>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {fromWeiEther} from '@/utils/common';
import CurrencyConverter from '../../components/CurrencyConverter.vue';
import api from '@/api';

export interface Product {
  id: number;
  external_id: string;
  name: string;
  variants: number;
  synced: number;
  thumbnail_url: string;
  is_ignored: boolean;
}

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

export interface MerchandiseOrderData {
  recipient: Recipient;
  items: Item[];
}

export interface Item {
  sync_variant_id: number;
  product_id: string;
  quantity: number;
}

interface Data {
  products: Product[];
  selectedProduct?: Product;
  selectedCountry?: Country;
  selectedState?: State;
  countries: Country[];
  recipient: Recipient;
  isLoading: boolean;
}

interface StoreMappedActions {
  purchaseMerchandise(payload: { id: number, price: number, amount: number }): Promise<number>;

  getItemPrice(payload: { id: number }): Promise<number>;
}

export default Vue.extend({
  components: {
    CurrencyConverter
  },

  data() {
    return {
      products: [],
      selectedProduct: undefined,
      selectedCountry: undefined,
      selectedState: undefined,
      countries: [],
      recipient: {} as Recipient,
      isLoading: false,
    } as Data;
  },

  computed: {
    disablePlaceOrderButton() {
      return !this.$data.recipient.name || !this.$data.recipient.phone || !this.$data.recipient.email
        || !this.$data.recipient.address1 || !this.$data.recipient.city || !this.$data.recipient.zip
        || !this.$data.recipient.countryCode;
    }
  },

  methods: {
    ...mapActions(['getItemPrice', 'purchaseMerchandise']) as StoreMappedActions,
    fromWeiEther,

    countryChanged() {
      this.selectedState = undefined;
    },
    async fetchProducts() {
      const response = await api.getMerchandiseProducts();
      if (response.code !== 200) {
        return;
      }
      this.products = response.result;
      // for (const product of this.products) {
      // product.price = await this.getItemPrice({id: product.id});
      // }
    },

    async fetchCountries() {
      const response = await api.getMerchandiseCountries();
      if (response.code !== 200) {
        return;
      }
      this.countries = response.result;
    },

    openAddress(product: Product) {
      (this.$refs['merchandise-address-modal'] as any).show();
      this.selectedProduct = product;
    },

    async buyItem() {
      if (!this.selectedCountry) return;
      this.recipient.country = this.selectedCountry.code;
      this.recipient.state = this.selectedState?.code;
      const orderData: MerchandiseOrderData = {
        recipient: this.recipient,
        items: [
          {
            sync_variant_id: 2799351521,
            product_id: '612a5910aa37e7',
            quantity: 1
          }
        ]
      };
      this.isLoading = true;
      // await this.purchaseMerchandise({id: this.selectedProduct.id, price: this.selectedProduct.price, amount: 1})
      //   .then(async () => {
      //
      //   });
      this.isLoading = false;
      this.recipient = {} as Recipient;
      await api.createMerchandiseOrder(orderData);
    },
  },

  async mounted() {
    await this.fetchProducts();
    await this.fetchCountries();
  },


});
</script>

<style>

.product-img {
  width: 8em;
  height: 8em;
  margin: 5px;
  text-align: center;
}

.product-name {
  text-align: center;
}

.product-grid {
  list-style-type: none;
  justify-content: center;
  margin: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 12em);
  gap: 0.5em;
}

.product {
  width: 12em;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 5px;
  cursor: pointer;
  position: relative;
  overflow: hidden;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
}

.centered-text-div {
  text-align: center;
}

.shop-button {
  position: relative;
  width: 12rem;
}

.sold span {
  text-align: center;
  width: auto;
  color: white;
  display: block;
  font-size: 30px;
  font-weight: bold;
  line-height: 40px;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
  text-transform: uppercase;
}

.modal-input {
  margin-bottom: 5px;
  margin-top: 5px;
}

</style>
