<template>
  <div>
    <MerchandiseCart :cartEntries="cartEntries" :isOrderLoading="isOrderLoading" :showFiatPrices="showFiatPrices"/>
    <MerchandiseList :isOrderLoading="isOrderLoading"/>
    <b-modal ref="order-complete-modal" ok-only no-close-on-backdrop hide-header-close
             :title="$t('market.merchandise.orderCompleted', {orderNumber})">
      <p>{{ $t('market.merchandise.thankYouForShopping') }}</p>
      <span>{{ $t('market.merchandise.yourShippingMethod') }}: </span>
      <p class="font-weight-bold">{{ shipping }}</p>
      <p>{{ $t('market.merchandise.checkYourEmail') }}</p>
    </b-modal>
    <OrderSummaryModal :showFiatPrices="showFiatPrices"/>
    <ShippingInfoModal/>
    <VariantChoiceModal :showFiatPrices="showFiatPrices"/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import MerchandiseList from '@/components/smart/MerchandiseList.vue';
import MerchandiseCart from '@/components/smart/MerchandiseCart.vue';
import VariantChoiceModal, {CartEntry} from '@/components/smart/VariantChoiceModal.vue';
import {BModal} from 'bootstrap-vue';
import OrderSummaryModal from '@/components/smart/OrderSummaryModal.vue';
import ShippingInfoModal from '@/components/smart/ShippingInfoModal.vue';
import {mapGetters, mapMutations} from 'vuex';
import {Accessors} from 'vue/types/options';

interface StoreMappedMutations {
  clearCartEntries(): void;
}

interface StoreMappedGetters {
  getCartEntries: CartEntry[];
}

interface Data {
  cartEntries: CartEntry[];
  orderNumber: number;
  shipping: string;
  isOrderLoading: boolean;
  showFiatPrices: boolean;
}

export default Vue.extend({
  components: {
    MerchandiseList, MerchandiseCart, OrderSummaryModal, ShippingInfoModal, VariantChoiceModal
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
    ...mapMutations(['clearCartEntries']) as StoreMappedMutations,
    isCartEntryDuplicated(cartEntry: CartEntry) {
      return this.cartEntries.find(entry => entry.variant.id === cartEntry.variant.id);
    },
  },

  computed: {
    ...mapGetters(['getCartEntries']) as Accessors<StoreMappedGetters>,
  },

  mounted() {
    this.cartEntries = this.getCartEntries;
    this.$root.$on('order-complete-modal', (orderNumber: number, shipping: string) => {
      const modal = this.$refs['order-complete-modal'] as BModal;
      if (modal) {
        if (orderNumber) {
          this.orderNumber = orderNumber;
          this.shipping = shipping;
          this.clearCartEntries();
          this.cartEntries = this.getCartEntries;
          modal.show();
        } else {
          modal.hide();
        }
      }
    });
    this.$root.$on('merchandise-order-loading', (isOrderLoading: boolean) => {
      this.isOrderLoading = isOrderLoading;
    });
    this.$root.$on('toggle-fiat-prices', () => {
      this.showFiatPrices = !this.showFiatPrices;
      if (this.showFiatPrices) localStorage.setItem('showFiatPrices', 'true');
      else localStorage.setItem('showFiatPrices', 'false');
    });
  }

});
</script>

<style>


</style>
