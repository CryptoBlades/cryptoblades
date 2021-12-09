<template>
  <b-modal class="centered-modal" v-model="showModal" @ok="addToCart"
           :ok-title="$t('market.merchandise.addToCart')"
           :ok-disabled="false" button-size="lg" size="xl" scrollable>
    <template #modal-title>
      {{ $t('market.merchandise.chooseVariant') }}
    </template>
    <div class="variant-container">
      <div class="p-2" v-if="selectedVariant">
        <img class="preview" :src="selectedVariant.files.find(file => isFileTypePreview(file)).preview_url" alt=""/>
      </div>
      <div class="p-2 w-100" v-if="selectedVariant">
        <div class="thumbnail-list pb-2">
          <div v-for="variant in variants" :key="variant.id">
            <img class="thumbnail" :class="selectedVariant === variant ? 'thumbnail-selected' : null"
                 v-b-tooltip="variant.name" :src="variant.files.find(file => isFileTypePreview(file)).thumbnail_url"
                 alt=""
                 @click="selectVariant(variant)"/>
          </div>
        </div>
        <p>{{ $t('market.merchandise.variant') }}: {{ selectedVariant.name }}</p>
        <span v-if="showFiatPrices">{{ selectedVariant.retail_price.toLocaleString() }} {{
            selectedVariant.currency
          }} / </span>
        <span v-if="selectedVariant">
          <CurrencyConverter :skill="fromWeiEther(retailPriceInSkill)"
                             :show-value-in-skill-only="true"/>
        </span>
        <div class="quantity-display mt-3">
          <div class="input-group-prepend">
            <b-button class="btn-primary" type="button" :disabled="isMinusButtonDisabled" @click="subtractQuantity"><i
              class="fas fa-minus"></i></b-button>
          </div>
          <b-input type="number" readonly class="form-control" :value="quantity" min="1"></b-input>
          <div class="input-group-append">
            <b-button class="btn-primary" type="button" @click="addQuantity"><i class="fas fa-plus"></i></b-button>
          </div>
        </div>
        <span>{{ $t('market.merchandise.totalPrice') }}: </span>
        <span v-if="showFiatPrices">{{ totalPrice.toLocaleString() }} {{
            selectedVariant.currency
          }} / </span>
        <span v-if="selectedVariant">
          <CurrencyConverter :skill="fromWeiEther(totalPriceInSkill)"
                             :show-value-in-skill-only="true"/>
        </span>
      </div>
    </div>
  </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import api from '@/api';
import {Product} from '@/components/smart/MerchandiseList.vue';
import CurrencyConverter from '@/components/CurrencyConverter.vue';
import {fromWeiEther} from '@/utils/common';
import {mapActions} from 'vuex';

export interface CartEntry {
  product: Product;
  variant: Variant;
  quantity: number;
}

export interface ProductDetails {
  sync_product: Product;
  sync_variants: Variant[];
}

export interface Variant {
  id: number;
  external_id: string;
  name: string;
  synced: boolean;
  variant_id: number;
  warehouse_product_variant_id?: number;
  retail_price: string;
  sku: string;
  currency: string;
  product: {
    variant_id: number;
    product_id: number;
    image: string;
    name: string;
  };
  files: File[];
}

interface File {
  id: number;
  type: FileType;
  hash: string;
  filename: string;
  mime_type: string;
  size: number;
  width: number;
  height: number;
  dpi: number;
  status: string;
  created: number;
  thumbnail_url: string;
  preview_url: string;
  visible: boolean;
}

export enum FileType {
  DEFAULT = 'default',
  PREVIEW = 'preview',
}

interface StoreMappedActions {
  currentSkillPrice(): Promise<string>;
}

interface Data {
  variants: Variant[];
  selectedVariant?: Variant;
  product?: Product;
  quantity: number;
  retailPriceInSkill: number;
  totalPrice: number;
  totalPriceInSkill: number;
  skillPrice: number;
  showModal: boolean;
}

export default Vue.extend({
  components: {CurrencyConverter},
  data() {
    return {
      variants: [],
      selectedVariant: undefined,
      product: undefined,
      quantity: 1,
      retailPriceInSkill: 0,
      totalPrice: 0,
      totalPriceInSkill: 0,
      skillPrice: 0,
      showModal: false,
    } as Data;
  },

  props: {
    showFiatPrices: {
      type: Boolean,
    }
  },

  computed: {
    isMinusButtonDisabled() {
      return this.$data.quantity <= 1;
    },
  },

  methods: {
    ...mapActions(['currentSkillPrice']) as StoreMappedActions,
    fromWeiEther,
    async fetchVariants(productId: number) {
      const response = await api.getMerchandiseProductVariants(productId);
      if (response.code !== 200) {
        return;
      }
      this.variants = response.result.sync_variants;
    },
    addToCart() {
      if (!this.product || !this.selectedVariant) return;

      const cartEntry = {
        product: this.product,
        variant: this.selectedVariant,
        quantity: this.quantity,
      } as CartEntry;

      this.$root.$emit('add-to-cart', cartEntry);
      this.quantity = 1;
    },
    isFileTypePreview(file: File) {
      return file.type === FileType.PREVIEW;
    },
    selectVariant(variant: Variant) {
      this.selectedVariant = variant;
      this.calculateTotalPrice();
    },
    subtractQuantity() {
      this.quantity--;
      this.calculateTotalPrice();
    },
    addQuantity() {
      this.quantity++;
      this.calculateTotalPrice();
    },
    calculateTotalPrice() {
      if (!this.selectedVariant) return;
      this.totalPrice = +this.selectedVariant.retail_price * this.quantity;
      this.calculateTotalSkillPrice();
    },
    calculateTotalSkillPrice() {
      if (!this.selectedVariant) return;
      this.retailPriceInSkill = +this.selectedVariant.retail_price * this.skillPrice;
      this.totalPriceInSkill = this.retailPriceInSkill * this.quantity;
    },
    usdToSkill(cartEntry: CartEntry) {
      if (!cartEntry?.variant) return;
      return +cartEntry.variant.retail_price * this.skillPrice;
    },
  },

  async mounted() {
    this.$root.$on('merchandise-variant-modal', async (product: Product) => {
      this.product = product;
      if (this.product) {
        this.skillPrice = +await this.currentSkillPrice();
        await this.fetchVariants(this.product.id);
        this.selectedVariant = this.variants[0];
        this.calculateTotalPrice();
        this.showModal = true;
      } else {
        this.variants = [];
        this.selectedVariant = undefined;
        this.showModal = false;
      }
    });
  }
});
</script>

<style>

.thumbnail-list {
  display: flex;
  flex-wrap: wrap;
  gap: 1em;
  align-content: flex-start;
}

.thumbnail {
  width: 100px !important;
  object-fit: scale-down;
}

.thumbnail:hover {
  cursor: pointer;
}

.thumbnail-selected {
  outline: 2px solid #00a8ff;
}

.preview {
  max-width: 100%;
  object-fit: scale-down;
}

.quantity-display {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 50%;
  gap: 0.5em;
}

.variant-container {
  display: flex;
}

@media (max-width: 576px) {
  .variant-container {
    flex-direction: column;
  }
}
</style>
