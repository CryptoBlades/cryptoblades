<template>
  <div class="d-flex justify-content-end m-3">
    <b-button variant="primary" class="shop-button" @click="openCartModal">Your cart ({{cartEntries.length}})</b-button>

    <b-modal class="centered-modal" ref="merchandise-cart-modal" :ok-title="'Add to cart'"
             :ok-disabled="false" button-size="lg" size="xl" scrollable>
      <template #modal-title>
        Your Cart
      </template>
      <template #modal-footer>
        Total: {{ totalPrice }} MXN
      </template>
      <div v-if="cartEntries.length === 0">
        <h3>Nothing in cart</h3>
      </div>
      <div v-else class="cart-entries-container">
        <div class="cart-entry-container" v-for="cartEntry in cartEntries" :key="cartEntry.variant.external_id">
          <img class="variant-image flex-grow-1"
               :src="cartEntry.variant.files.find(file => isFileTypePreview(file)).preview_url"
               alt="">
          <div class="d-flex flex-column justify-content-center align-items-center flex-grow-1 w-50">
            <p>{{ cartEntry.variant.name }}</p>
            <p>Price: {{ cartEntry.variant.retail_price }} {{ cartEntry.variant.currency }}</p>
          </div>
          <div class="quantity-display flex-grow-1">
            <div class="input-group-prepend">
              <b-button class="btn-primary" type="button" :disabled="isMinusButtonDisabled(cartEntry)"
                        @click="subtractQuantity(cartEntry)"><i class="fas fa-minus"></i></b-button>
            </div>
            <b-input type="number" readonly class="form-control" :value="cartEntry.quantity" min="1"></b-input>
            <div class="input-group-append">
              <b-button class="btn-primary" type="button" @click="addQuantity(cartEntry)"><i class="fas fa-plus"></i>
              </b-button>
            </div>
            <b-button class="btn-danger" type="button" @click="removeCartEntry(cartEntry)"><i class="fas fa-trash"></i>
            </b-button>
          </div>
        </div>
      </div>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {BModal} from 'bootstrap-vue';
import {PropType} from 'vue/types/options';
import {CartEntry, FileType} from '@/components/smart/VariantChoiceModal.vue';

interface Data {
  totalPrice: number;
}

export default Vue.extend({
  data() {
    return {
      totalPrice: 0,
    } as Data;
  },

  props: {
    cartEntries: {
      type: Array as PropType<CartEntry[]>,
      required: true
    }
  },

  methods: {
    openCartModal() {
      this.$root.$emit('merchandise-cart-modal', true);
    },
    isFileTypePreview(file: File) {
      return file.type === FileType.PREVIEW;
    },
    subtractQuantity(cartEntry: CartEntry) {
      cartEntry.quantity--;
      this.calculateTotalPrice();
    },
    addQuantity(cartEntry: CartEntry) {
      cartEntry.quantity++;
      this.calculateTotalPrice();
    },
    calculateTotalPrice() {
      this.totalPrice = this.cartEntries.map(cartEntry => +cartEntry.variant.retail_price * cartEntry.quantity)
        .reduce((a, b) => a + b, 0);
    },
    isMinusButtonDisabled(cartEntry: CartEntry) {
      return cartEntry.quantity <= 1;
    },
    removeCartEntry(cartEntry: CartEntry) {
      this.cartEntries.splice(this.cartEntries.indexOf(cartEntry), 1);
    }
  },

  async mounted() {
    this.$root.$on('merchandise-cart-modal', async (open: boolean) => {
      this.calculateTotalPrice();
      const modal = this.$refs['merchandise-cart-modal'] as BModal;
      if (modal) {
        if (open) {
          modal.show();
        } else {
          modal.hide();
        }
      }
    });
  },
});
</script>

<style>
.variant-image {
  max-width: 200px;
}

.cart-entry-container {
  display: flex;
  justify-content: space-around;
  border-bottom: 1px solid #6c5f38;
  border-top: 1px solid #6c5f38;
}

.cart-entries-container {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
</style>
