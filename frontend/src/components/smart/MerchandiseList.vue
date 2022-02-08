<template>
  <div>
    <div class="text-center" v-if="products.length === 0">
      <span>{{ $t('market.merchandise.nothingToBuyAtThisTime') }}</span>
    </div>
    <ul class="product-grid">
      <li class="product" v-for="product in productsForPage" :key="product.id">
        <div class="d-flex flex-column w-100 h-100 align-items-center">
          <img class="product-img" :src="product.thumbnail_url" alt=""/>
          <div class="text-center font-weight-bold p-1">
            {{ product.name }}
          </div>
        </div>
        <b-button
          variant="primary"
          class="shop-button"
          :disabled="isOrderLoading || isVariantModalLoading"
          @click="openChooseVariantModal(product)">
          <span>{{ $t('market.merchandise.chooseVariant') }}</span>
          <i v-if="isOrderLoading || isVariantModalLoading" class="fas fa-spinner fa-spin"></i>
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
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {fromWeiEther} from '@/utils/common';
import api from '@/api';
import {Recipient} from '@/components/smart/ShippingInfoModal.vue';

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
  shipping?: string;
  wallet?: string;
  currentChain?: string;
}

export interface Item {
  external_variant_id: string;
  product_id: string;
  quantity: number;
}

interface Data {
  products: Product[];
  selectedProduct?: Product;
  isVariantModalLoading: boolean;
  currentPage: number;
  perPage: number;
  offset: number;
  limit: number;
}

interface StoreMappedActions {
  getItemPrice(payload: { id: number }): Promise<number>;

  currentSkillPrice(): Promise<string>;
}

export default Vue.extend({
  components: {},

  data() {
    return {
      products: [],
      selectedProduct: undefined,
      isVariantModalLoading: false,
      currentPage: 1,
      perPage: 30,
      offset: 0,
      limit: 100,
    } as Data;
  },

  props: {
    isOrderLoading: {
      type: Boolean,
    }
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
    ...mapActions(['getItemPrice', 'currentSkillPrice']) as StoreMappedActions,
    fromWeiEther,

    async fetchProducts() {
      let result = [];
      do {
        const response = await api.getMerchandiseProducts(this.limit, this.offset);
        if (response.code !== 200) {
          return;
        }
        result = response.result;
        this.products.push(...result);
        this.offset += 100;
      } while (result.length === 100);
    },

    async fetchVariants(productId: number) {
      const response = await api.getMerchandiseProductVariants(productId);
      if (response.code !== 200) {
        return;
      }
      return response.result.sync_variants;
    },

    async openChooseVariantModal(product: Product) {
      try {
        this.isVariantModalLoading = true;
        this.selectedProduct = product;
        const variants = await this.fetchVariants(product.id);
        const skillPrice = +await this.currentSkillPrice();
        this.$root.$emit('merchandise-variant-modal', this.selectedProduct, variants, skillPrice);
      } finally {
        this.isVariantModalLoading = false;
      }
    },
    isMobile() {
      return screen.width <= 576;
    },
  },

  async mounted() {
    if (this.isMobile()) {
      this.perPage = 10;
    }
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
