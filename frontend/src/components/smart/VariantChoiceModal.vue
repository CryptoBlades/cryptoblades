<template>
  <b-modal class="centered-modal" ref="merchandise-variant-modal" @ok="addToCart" :ok-title="'Add to cart'"
           :ok-disabled="false" button-size="lg" size="xl">
    <template #modal-title>
      Shop Prototype
    </template>
    <div class="d-flex">
      <div class="p-2" v-if="selectedVariant">
        <img class="preview" :src="selectedVariant.files.find(file => isFileTypePreview(file)).preview_url" alt=""/>
      </div>
      <div class="p-2" v-if="selectedVariant">
        <div class="thumbnail-list pb-2">
          <div v-for="variant in variants" :key="variant.id">
            <img class="thumbnail" :class="selectedVariant === variant ? 'thumbnail-selected' : null"
                 v-b-tooltip="variant.name" :src="variant.files.find(file => isFileTypePreview(file)).thumbnail_url"
                 alt=""
                 @click="selectVariant(variant)"/>
          </div>
        </div>
        <p>Variant: {{ selectedVariant.name }}</p>
        <p>{{ selectedVariant.retail_price.toLocaleString() }} {{ selectedVariant.currency }}</p>
        <div class="quantity-display">
          <div class="input-group-prepend">
            <b-button class="btn-primary" type="button" :disabled="isMinusButtonDisabled" @click="subtractQuantity"><i class="fas fa-minus"></i></b-button>
          </div>
          <b-input type="number" readonly class="form-control" :value="quantity" min="1"></b-input>
          <div class="input-group-append">
            <b-button class="btn-primary" type="button" @click="addQuantity"><i class="fas fa-plus"></i></b-button>
          </div>
        </div>
        <p>Total price: {{ totalPrice.toLocaleString() }} {{ selectedVariant.currency }}</p>
      </div>
    </div>
  </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import api from '@/api';
import {BModal} from 'bootstrap-vue';
import {Product} from '@/components/smart/MerchandiseList.vue';

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

interface Data {
  variants: Variant[];
  selectedVariant?: Variant;
  product?: Product;
  quantity: number;
  totalPrice: number;
}

export default Vue.extend({
  data() {
    return {
      variants: [],
      selectedVariant: undefined,
      product: undefined,
      quantity: 1,
      totalPrice: 0,
    } as Data;
  },

  computed: {
    //TODO: Rework this
    // disablePlaceOrderButton() {
    //   return !this.$data.recipient.name || !this.$data.recipient.phone || !this.$data.recipient.email
    //     || !this.$data.recipient.address1 || !this.$data.recipient.city || !this.$data.recipient.zip
    //     || !this.$data.recipient.countryCode;
    // }
    isMinusButtonDisabled() {
      return this.$data.quantity <= 1;
    },
  },

  methods: {
    async fetchVariants(productId: number) {
      const response = await api.getMerchandiseProductVariants(productId);
      if (response.code !== 200) {
        return;
      }
      this.variants = response.result.sync_variants;
      console.log(this.variants);
    },
    addToCart() {
      if(!this.product || !this.selectedVariant) return;

      const cartEntry = {
        product: this.product,
        variant: this.selectedVariant,
        quantity: this.quantity,
      } as CartEntry;
      console.log(cartEntry);

      this.$root.$emit('add-to-cart', cartEntry);
      this.quantity = 1;
    },
    isFileTypePreview(file: File) {
      return file.type === FileType.PREVIEW;
    },
    selectVariant(variant: Variant) {
      this.selectedVariant = variant;
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
      if(!this.selectedVariant) return;
      this.totalPrice = +this.selectedVariant.retail_price * this.quantity;
    }
  },

  async mounted() {
    this.$root.$on('merchandise-variant-modal', async (product: Product) => {
      this.product = product;
      const modal = this.$refs['merchandise-variant-modal'] as BModal;
      if (modal) {
        if (this.product) {
          await this.fetchVariants(this.product.id);
          this.selectedVariant = this.variants[0];
          this.calculateTotalPrice();
          modal.show();
        } else {
          this.variants = [];
          modal.hide();
        }
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
  width: 500px;
  object-fit: scale-down;
}

.quantity-display {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 50%;
  gap: 0.5em;
}
</style>
