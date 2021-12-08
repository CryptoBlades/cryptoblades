<template>
  <div>
    <MerchandiseCart :cartEntries="cartEntries" :isOrderLoading="isOrderLoading" :showFiatPrices="showFiatPrices"/>
    <MerchandiseList :isOrderLoading="isOrderLoading" :showFiatPrices="showFiatPrices"/>
    <b-modal ref="order-complete-modal" ok-only no-close-on-backdrop hide-header-close
             :title="$t('market.merchandise.orderCompleted', {orderNumber})">
      <p>{{ $t('market.merchandise.thankYouForShopping') }}</p>
      <span>{{ $t('market.merchandise.yourShippingMethod') }}: </span>
      <p class="font-weight-bold">{{ shipping }}</p>
      <p>{{ $t('market.merchandise.checkYourEmail') }}</p>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import MerchandiseList from '@/components/smart/MerchandiseList.vue';
import MerchandiseCart from '@/components/smart/MerchandiseCart.vue';
import {CartEntry} from '@/components/smart/VariantChoiceModal.vue';
import {BModal} from 'bootstrap-vue';

interface Data {
  cartEntries: CartEntry[];
  orderNumber: number;
  shipping: string;
  isOrderLoading: boolean;
  showFiatPrices: boolean;
}

export default Vue.extend({
  components: {
    MerchandiseList, MerchandiseCart
  },

  data() {
    return {
      cartEntries: [],
      orderNumber: 0,
      shipping: '',
      isOrderLoading: false,
      showFiatPrices: true,
    } as Data;
  },

  methods: {
    isCartEntryDuplicated(cartEntry: CartEntry) {
      return this.cartEntries.find(entry => entry.variant.id === cartEntry.variant.id);
    },
  },

  mounted() {
    this.$root.$on('add-to-cart', (cartEntry: CartEntry) => {
      const duplicatedEntry = this.cartEntries.find(entry => entry.variant.id === cartEntry.variant.id);
      if (duplicatedEntry) {
        const entryIndex = this.cartEntries.indexOf(duplicatedEntry);
        this.cartEntries.splice(entryIndex, 1);
      }
      this.cartEntries.push(cartEntry);
    });
    this.$root.$on('order-complete-modal', (orderNumber: number, shipping: string) => {
      const modal = this.$refs['order-complete-modal'] as BModal;
      if (modal) {
        if (orderNumber) {
          this.orderNumber = orderNumber;
          this.shipping = shipping;
          this.cartEntries = [];
          modal.show();
        } else {
          modal.hide();
        }
      }
    });
    this.$root.$on('merchandise-order-loading', (isOrderLoading: boolean) => {
      this.isOrderLoading = isOrderLoading;
    });
  }

});
</script>

<style>


</style>
