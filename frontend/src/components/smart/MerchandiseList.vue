<template>
  <div>
    <div class="centered-text-div" v-if="(!products || products.length === 0)">
      <span>Nothing to buy at this time</span>
    </div>
    <ul class="product-grid">
      <li class="product"
      v-for="product in products" :key="product.id">
        <img class="product-img" :src="product.thumbnail_url" />
        <div class="product-name">{{ product.name }}</div>
        <b-button
          :disabled="!product.price"
          variant="primary"
          class="shop-button"
          @click="openAddress(product)">
          <span>
            Buy (<CurrencyConverter v-if="product.price" :skill="convertWeiToSkill(+product.price)" :showValueInSkillOnly="true" :minDecimals="1"/>)
          </span>
        </b-button>
      </li>
    </ul>

    <b-modal class="centered-modal" ref="merchandise-address-modal" @ok="buyItem">
      <template #modal-title>
        Delivery Address
      </template>

      <b-form-input type="text"
        class="modal-input" v-model="recipient.name" placeholder="Name" />
      <b-form-input type="number"
        class="modal-input" v-model="recipient.phone" placeholder="Phone" />
      <b-form-input type="email"
        class="modal-input" v-model="recipient.email" placeholder="Email" />
      <b-form-input type="text"
        class="modal-input" v-model="recipient.address1" placeholder="Address" />
      <b-form-input type="text"
        class="modal-input" v-model="recipient.city" placeholder="City" />
      <b-form-input type="text"
        class="modal-input" v-model="recipient.zip" placeholder="Zip Code" />
      <b-form-select
        class="modal-input" v-model="recipient.country_code" :options="countries"
        text-field="name" value-field="code"></b-form-select>
        {{ selected_country }}
      <b-form-select
        class="modal-input" v-model="recipient.state_code" :options="states" value-field="code" text-field="name"></b-form-select>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import axios from 'axios';
import { mapActions } from 'vuex';
import { fromWeiEther } from '@/utils/common';
import CurrencyConverter from '../../components/CurrencyConverter.vue';

interface Product {
  id: number,
  name: string,
  thumbnail_url: string,
  price?: number
}

interface Recipient {
  name: string;
  address1: string;
  city: string;
  state_code: string;
  country_code: string;
  zip: string;
  phone: string;
  email: string;
}

interface Country {
  name: string;
  code: string;
  states?: string;
}

interface Data {
  products: Product[];
  selected_product: Product | undefined;
  selected_country: Country | undefined;
  selected_state: string;
  countries: Country[];
  recipient: Recipient;
}

interface StoreMappedActions {
  getItemPrice(payload: {id: number}): Promise<number>;
  purchaseMerchandise(payload: {id: number, price: number, amount: number}): Promise<number>;
}

export default Vue.extend({
  components: {
    CurrencyConverter
  },

  data() {
    return {
      products: [],
      selected_product: undefined,
      selected_country: undefined,
      selected_state: '',
      countries: [],
      recipient: {
        name: 'Bob',
        address1: 'Baker Street 2B',
        city: 'London',
        state_code: 'AL',
        country_code: 'US',
        zip: '12345',
        phone: '5512345678',
        email: 'example@email.com'
      } as Recipient,
    } as Data;
  },

  computed: {
    states() {
      return this.countries.find(country => country.code === this.recipient.country_code)?.states;
    }
  },

  methods: {
    ...mapActions(['getItemPrice', 'purchaseMerchandise']) as StoreMappedActions,

    async fetchProducts() {
      const response = await axios.get('http://localhost:2400/products');
      this.products = response.data?.result;
      for (const product of this.products) {
        product.price = await this.getItemPrice({id: product.id});
      }
      console.log(this.products);
    },

    async fetchCountries() {
      const response = await axios.get('http://localhost:2400/countries');
      this.countries = response.data?.result;
    },

    async openAddress(product: Product) {
      this.$refs['merchandise-address-modal'].show();
      this.selected_product = product;
    },

    async buyItem() {
      if(!this.selected_product) return;
      const printful_payload = {
        recipient: this.recipient,
        items: [
          {
            sync_variant_id: this.selected_product.id,
            quantity: 1
          }
        ]
      };

      if(!this.selected_product.price) return;
      await this.purchaseMerchandise({id: this.selected_product.id, price: this.selected_product.price, amount: 1});

      const response = await axios.post('http://localhost:2400/create_order', printful_payload);
      console.log(response);
    },

    convertWeiToSkill(wei: string) {
      return fromWeiEther(wei);
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
}

.centered-text-div {
  text-align: center;
}

.shop-button {
  position: relative;
  width: 12rem;
}

.row.filters {
   justify-content: center;
   width: 100%;
   max-width: 900px;
   margin: 0 auto;
   align-content: center;
   border-bottom: 0.2px solid rgba(102, 80, 80, 0.1);
   margin-bottom: 20px;
}
.dropdown-elem {
  margin-bottom: 20px;
  max-width: 300px;
  width: 100%;
}

.show-favorite {
  margin-left: 15px;
  display: flex;
  flex-direction: row;
  align-self: center;
}
.show-favorite-checkbox {
  margin-left: 5px;
}

.clear-filters-button {
  align-self: flex-end;
  height: fit-content;
}

.clear-filters-button {
  display: flex;
  flex-direction: row;
  align-self: center;
}

.above-wrapper {
  padding: 0.1rem;
}

.product.selected {
  outline: solid currentcolor 2px;
}


@media (max-width: 576px) {
  .weapon-grid {
    justify-content: center;
    margin-top: 10px;
  }

  .show-favorite {
    width: 100%;
    justify-content: center;
    margin-bottom: 15px;
  }

  .clear-filters-button {
    width: 100%;
    display: flex;
    flex-direction: row;
    align-self: center;
    text-align: center;
    justify-content: center;
    margin: 0 auto;
  }

  .ml-3 {
    margin-left: 0 !important;
  }
}

/* Needed to adjust weapon list */
@media all and (max-width: 767.98px) {
  .weapon-grid {
    padding-left: 2em;
    justify-content: center;
  }
  .stars-elem {
  margin-bottom: 20px;
  max-width: 500px;
  width: 100%;
}
  li.weapon {
    display: inline-block;
    margin: auto;
  }
}

.sold {
    height: 40px;
    width: 230px;
    background-color: rgb(187, 33, 0);
    transform: rotate(15deg);
    left: -20px;
    position: absolute;
    top: 110px;
    z-index: 100;
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

.fix-h24 {
  height: 24px;
}

.modal-input {
  margin-bottom: 5px;
  margin-top: 5px;
}

</style>
