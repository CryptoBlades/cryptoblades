<template>
  <div>
    <div class="text-center" v-if="(products.length === 0)">
      <span>Nothing to buy at this time</span>
    </div>
    <ul class="product-grid">
      <li class="product" v-for="product in productsForPage" :key="product.id">
        <div class="d-flex flex-column w-100 h-100 align-items-center">
          <img class="product-img" :src="product.thumbnail_url" alt=""/>
          <div class="text-center font-weight-bold">
            {{ product.name }}
          </div>
<!--          <span v-if="product.lowestPrice" class="starting_at mb-1 mt-2">Starting at {{ product.lowestPrice }}</span>-->
        </div>
        <b-button
          variant="primary"
          class="shop-button"
          @click="openChooseVariantModal(product)">
          <span>Choose variant</span>
        </b-button>
      </li>
    </ul>
    <b-pagination
      v-if="products.length !== 0"
      class="customPagination"
      v-model="currentPage"
      :total-rows="products.length"
      :per-page="perPage"
      align="center"
    />
    <ShippingInfoModal/>
    <VariantChoiceModal/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {fromWeiEther} from '@/utils/common';
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
  currentPage: number;
  perPage: number;
}

interface StoreMappedActions {
  getItemPrice(payload: { id: number }): Promise<number>;
}

export default Vue.extend({
  components: {
    ShippingInfoModal, VariantChoiceModal
  },

  data() {
    return {
      products: [],
      selectedProduct: undefined,
      isLoading: false,
      currentPage: 1,
      perPage: 30,
    } as Data;
  },

  computed: {
    rows() {
      return this.$data.products.length;
    },
    productsForPage() {
      return this.$data.products.slice(
        (this.$data.currentPage - 1) * this.$data.perPage,
        this.$data.currentPage * this.$data.perPage,
      );
    }
  },

  methods: {
    ...mapActions(['getItemPrice']) as StoreMappedActions,
    fromWeiEther,

    async fetchProducts() {
      const response = await api.getMerchandiseProducts();
      if (response.code !== 200) {
        return;
      }
      this.products = response.result;
      // const promises = this.products.map(product => api.getMerchandiseProductVariants(product.id));
      // console.log(promises);
      // Promise.all(promises).then(values => {
      //   values.forEach(value => {
      //     const product = this.products.find(product => value.result.sync_product.id === product.id);
      //     if (product) {
      //       product.lowestPrice = Math.min(...value.result.sync_variants.map(variant => +variant.retail_price));
      //     }
      //   });
      //   console.log(this.products.map(product => product.lowestPrice));
      // });
      // for (const product of this.products) {
      //   const response = await api.getMerchandiseProductVariants(product.id);
      //   console.log(response);
      //   const prices = response.result.sync_variants.map(variant => +variant.retail_price);
      //   console.log(prices);
      //   product.lowestPrice = Math.min(...prices);
      //   console.log(Math.min(...prices));
      // }
      // for (const product of this.products) {
      // product.price = await this.getItemPrice({id: product.id});
      // }
    },

    async openChooseVariantModal(product: Product) {
      this.selectedProduct = product;
      this.$root.$emit('merchandise-variant-modal', this.selectedProduct);
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

/*.starting_at {*/
/*  font-size: 13px;*/
/*}*/

</style>
