<template>
  <div>
    <div class="text-center" v-if="(products.length === 0)">
      <span>Nothing to buy at this time</span>
    </div>
    <ul class="product-grid">
      <li class="product" v-for="product in products" :key="product.id">
        <img class="product-img" :src="product.thumbnail_url" alt=""/>
        <div class="text-center">{{ product.name }}</div>
        <b-button
          variant="primary"
          class="shop-button"
          @click="openAddress(product)">
          <span>Buy (<CurrencyConverter v-if="product.price" :skill="fromWeiEther(+product.price)"
                                        :showValueInSkillOnly="true" :minDecimals="1"/>)</span>
        </b-button>
      </li>
    </ul>

    <ShippingInfoModal/>
    <VariantChoiceModal/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {fromWeiEther} from '@/utils/common';
import CurrencyConverter from '../../components/CurrencyConverter.vue';
import api from '@/api';
import ShippingInfoModal, {Recipient} from '@/components/smart/ShippingInfoModal.vue';
import VariantChoiceModal from '@/components/smart/VariantChoiceModal.vue';

export interface Product {
  id: number;
  external_id: string;
  name: string;
  variants: number;
  synced: number;
  thumbnail_url: string;
  is_ignored: boolean;
}

export interface MerchandiseOrder {
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
  isLoading: boolean;
}

interface StoreMappedActions {
  purchaseMerchandise(payload: { id: number, price: number, amount: number }): Promise<number>;

  getItemPrice(payload: { id: number }): Promise<number>;
}

export default Vue.extend({
  components: {
    CurrencyConverter, ShippingInfoModal, VariantChoiceModal
  },

  data() {
    return {
      products: [],
      selectedProduct: undefined,
      isLoading: false,
    } as Data;
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
      // for (const product of this.products) {
      // product.price = await this.getItemPrice({id: product.id});
      // }
    },

    async openAddress(product: Product) {
      this.selectedProduct = product;
      // this.$root.$emit('merchandise-address-modal', true);
      this.$root.$emit('merchandise-variant-modal', this.selectedProduct);
      // (this.$refs['merchandise-address-modal'] as BModal).show();
    },
  },

  async mounted() {
    await this.fetchProducts();
  },
});
</script>

<style>

.product-img {
  width: 8em;
  height: 8em;
  margin: 0.5rem;
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

.shop-button {
  position: relative;
  width: 12rem;
}

</style>
