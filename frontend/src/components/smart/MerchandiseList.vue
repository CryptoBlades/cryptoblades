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
          :disabled="!product.price || isLoading"
          variant="primary"
          class="shop-button"
          @click="openAddress(product)">
          <span>Buy (<CurrencyConverter v-if="product.price" :skill="fromWeiEther(+product.price)"
                                        :showValueInSkillOnly="true" :minDecimals="1"/>)</span>
        </b-button>
      </li>
    </ul>

    <b-modal class="centered-modal" ref="merchandise-address-modal" @ok="buyItem" :ok-title="'Submit order'"
             :ok-disabled="disableMerchOkButton" button-size="lg">
      <template #modal-title>
        Delivery Address
      </template>

      <b-form-input type="text"
                    class="modal-input" v-model="recipient.name" placeholder="Name"/>
      <b-form-input type="number"
                    class="modal-input" v-model="recipient.phone" placeholder="Phone"/>
      <b-form-input type="email"
                    class="modal-input" v-model="recipient.email" placeholder="Email"/>
      <b-form-input type="text"
                    class="modal-input" v-model="recipient.address1" placeholder="Address"/>
      <b-form-input type="text"
                    class="modal-input" v-model="recipient.city" placeholder="City"/>
      <b-form-input type="text"
                    class="modal-input" v-model="recipient.zip" placeholder="Zip Code"/>
      <b-form-select
        class="modal-input" v-model="recipient.countryCode" @change="fetchStates" :options="countries"
        text-field="name" value-field="code"></b-form-select>
      {{ selectedCountry }}
      <b-form-select
        class="modal-input" v-if="states.length !== 0" v-model="recipient.stateCode" :options="states"
        value-field="code" text-field="name"></b-form-select>
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
  id: number,
  name: string,
  thumbnail_url: string,
  price?: number
}

export interface Recipient {
  name: string;
  address1: string;
  city: string;
  stateCode?: string;
  countryCode: string;
  zip: string;
  phone: string;
  email: string;
}

export interface Country {
  name: string;
  code: string;
  states?: string[];
}

export interface MerchandiseOrderData {
  recipient: Recipient;
  items: MerchandiseItemData[];
}

export interface MerchandiseItemData {
  sync_variant_id: number;
  quantity: number;
}

interface Data {
  products: Product[];
  selectedProduct: Product | undefined;
  selectedCountry: Country | undefined;
  countries: Country[];
  states: string[];
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
      countries: [],
      states: [],
      recipient: {} as Recipient,
      isLoading: false,
    } as Data;
  },

  computed: {
    disableMerchOkButton() {
      return !this.$data.recipient.name || !this.$data.recipient.phone || !this.$data.recipient.email
        || !this.$data.recipient.address1 || !this.$data.recipient.city || !this.$data.recipient.zip
        || !this.$data.recipient.countryCode;
    }
  },

  methods: {
    ...mapActions(['getItemPrice', 'purchaseMerchandise']) as StoreMappedActions,
    fromWeiEther,

    async fetchProducts() {
      const response = await api.getMerchandiseProducts();
      if (response.code !== 200) {
        return;
      }
      this.products = response.result;
      for (const product of this.products) {
        product.price = await this.getItemPrice({id: product.id});
      }
    },

    async fetchCountries() {
      const response = await api.getMerchandiseCountries();
      if (response.code !== 200) {
        return;
      }
      this.countries = response.result;
      this.fetchStates();
    },

    fetchStates() {
      this.recipient.stateCode = undefined;
      this.states = this.countries.find((country: Country) => country.code === this.recipient.countryCode)?.states || [];
    },

    openAddress(product: Product) {
      (this.$refs['merchandise-address-modal'] as any).show();
      this.selectedProduct = product;
    },

    async buyItem() {
      if (!this.selectedProduct) return;
      const orderData: MerchandiseOrderData = {
        recipient: this.recipient,
        items: [
          {
            sync_variant_id: this.selectedProduct.id,
            quantity: 1
          }
        ]
      };
      if (!this.selectedProduct.price) return;
      this.isLoading = true;
      await this.purchaseMerchandise({id: this.selectedProduct.id, price: this.selectedProduct.price, amount: 1})
        .then(async () => {
          this.isLoading = false;
          this.recipient = {} as Recipient;
          await api.createMerchandiseOrder(orderData);
        });
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
