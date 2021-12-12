<template>
  <b-modal class="centered-modal" v-model="showModal" button-size="lg" no-close-on-backdrop scrollable
           :title="'Order summary'" size="xl" @close="selectedShippingRate = undefined">
    <div class="cart-entries-container">
      <div class="cart-entry-container" v-for="cartEntry in cartEntries" :key="cartEntry.variant.external_id">
        <img class="variant-image flex-grow-1 m-2"
             :src="cartEntry.variant.files.find(file => isFileTypePreview(file)).preview_url"
             alt="">
        <div class="d-flex flex-column justify-content-center align-items-center flex-grow-1 w-50">
          <p>{{ cartEntry.variant.name }}</p>
          <div class="d-inline"><span>{{ $t('market.merchandise.price') }}: </span><span
            v-if="showFiatPrices">{{ cartEntry.variant.retail_price }} {{
              cartEntry.variant.currency
            }} / </span>
            <span><CurrencyConverter v-if="cartEntry.variant && cartEntry.variant.retail_price"
                                     :skill="fromWeiEther(toBN(usdToSkill(cartEntry)))"
                                     :show-value-in-skill-only="true"/></span></div>
        </div>
        <div class="flex-grow-1 m-2">
          <span>{{ cartEntry.quantity }}x</span>
        </div>
      </div>
    </div>
    <template #modal-footer>
      <div class="cart-footer">
        <div class="d-flex flex-column p-2">
          <span class="font-weight-bold">{{ $t('market.merchandise.shippingInformation') }}: </span>
          <span>{{ recipient.name }}</span>
          <span>{{ recipient.address1 }}</span>
          <span v-if="recipient.address2">{{ recipient.address2 }}</span>
          <span>{{ recipient.city }}, {{ recipient.country_code }}<span
            v-if="recipient.state_code">, {{ recipient.state_code }}</span></span>
          <span>{{ recipient.zip }}</span>
          <span>{{ recipient.phone }}</span>
          <span>{{ recipient.email }}</span>
          <span v-if="recipient.company">{{ recipient.company }}</span>
        </div>
        <div class="d-flex align-items-center w-50">
          <div v-if="cartEntries.length !== 0" class="costs-container w-100">
            <div class="d-flex flex-column">
              <span class="font-weight-bold">Shipping method: </span>
              <b-form-select class="mt-2 mb-2" v-model="selectedShippingRate" :disabled="areShippingRatesLoading" @change="calculateTotalPrice">
                <b-form-select-option :value="undefined">{{
                    areShippingRatesLoading ? $t('market.merchandise.loadingShippingOptions') : $t('market.merchandise.pleaseSelectAnOption')
                  }}
                </b-form-select-option>
                <b-form-select-option v-for="shippingRate in shippingRates" :key="shippingRate.id"
                                      :value="shippingRate"> {{ shippingRate.name }} - <span
                  v-if="showFiatPrices">{{ shippingRate.rate }} {{ shippingRate.currency }} / </span>
                  <CurrencyConverter :skill="fromWeiEther(toBN(calculateShippingPriceInSkill(shippingRate.rate)))"
                                     :show-value-in-skill-only="true"/>
                </b-form-select-option>
              </b-form-select>
            </div>
            <div>
              <span class="font-weight-bold">{{ $t('market.merchandise.total') }}: </span>
              <span v-if="showFiatPrices">{{ totalPrice.toFixed(2) }} {{
                  cartEntries[0].variant.currency
                }} / </span>
              <CurrencyConverter :skill="fromWeiEther(totalPriceInSkill)" :show-value-in-skill-only="true"/>
            </div>
            <span id="place-order-button-wrapper" class="d-inline-block">
              <b-button :disabled="!canAffordMerch() || !selectedShippingRate" variant="primary" size="lg" block
                        @click="confirmOrder">
                {{ $t('market.merchandise.placeOrder') }}
              </b-button>
            </span>
            <b-tooltip v-if="!canAffordMerch()" target="place-order-button-wrapper" variant="danger">
              {{ $t('market.merchandise.insufficientFunds') }}
            </b-tooltip>
            <b-tooltip v-else-if="!selectedShippingRate" target="place-order-button-wrapper">
              {{ $t('market.merchandise.pleaseSelectShippingMethod') }}
            </b-tooltip>
          </div>
        </div>
      </div>
    </template>
  </b-modal>
</template>

<script lang="ts">
import Vue from 'vue';
import {CartEntry, FileType} from '@/components/smart/VariantChoiceModal.vue';
import {OrderItem, Recipient} from '@/components/smart/ShippingInfoModal.vue';
import CurrencyConverter from '@/components/CurrencyConverter.vue';
import {fromWeiEther, toBN} from '@/utils/common';
import {mapActions, mapState} from 'vuex';
import api from '@/api';
import {MerchandiseOrder} from '@/components/smart/MerchandiseList.vue';

interface StoreMappedActions {
  currentSkillPrice(): Promise<string>;
}

export interface ShippingRate {
  currency: string;
  id: string;
  maxDeliveryDays: number;
  minDeliveryDays: number;
  name: string;
  rate: string;
}

interface Data {
  showModal: boolean;
  cartEntries: CartEntry[];
  recipient: Recipient;
  skillPrice: number;
  totalPrice: number;
  totalPriceInSkill: number;
  isOrderLoading: boolean;
  areShippingRatesLoading: boolean;
  shippingMethod: string;
  shippingRates: ShippingRate[];
  selectedShippingRate?: ShippingRate;
}

export default Vue.extend({
  data() {
    return {
      showModal: false,
      cartEntries: [],
      recipient: {} as Recipient,
      skillPrice: 0,
      totalPrice: 0,
      totalPriceInSkill: 0,
      isOrderLoading: false,
      areShippingRatesLoading: false,
      shippingMethod: '',
      shippingRates: [],
      selectedShippingRate: undefined,
    } as Data;
  },

  props: {
    showFiatPrices: {
      type: Boolean
    },
  },

  components: {CurrencyConverter},
  computed: {
    ...mapState(['skillBalance']),
  },
  methods: {
    ...mapActions(['currentSkillPrice']) as StoreMappedActions,
    fromWeiEther,
    toBN,
    isFileTypePreview(file: File) {
      return file.type === FileType.PREVIEW;
    },
    usdToSkill(cartEntry: CartEntry) {
      if (!cartEntry?.variant) return;
      return +cartEntry.variant.retail_price * this.skillPrice;
    },
    async confirmOrder() {
      if (!this.selectedShippingRate) return;
      const orderItems = this.cartEntries.map(cartEntry => {
        return {
          external_variant_id: cartEntry.variant.external_id,
          quantity: cartEntry.quantity
        } as OrderItem;
      });
      const merchandiseOrder: MerchandiseOrder = {
        recipient: this.recipient,
        items: orderItems,
        shipping: this.selectedShippingRate.id,
      };

      console.log(merchandiseOrder);
      await api.createMerchandiseOrder(merchandiseOrder);
      // if (!this.selectedCountry) return;
      // this.$root.$emit('merchandise-order-loading', true);
      // this.recipient.country = this.selectedCountry.code;
      // this.recipient.state = this.selectedState?.code;
      // const orderItems = this.cartEntries.map(cartEntry => {
      //   return {
      //     sync_variant_id: cartEntry.variant.id,
      //     quantity: cartEntry.quantity
      //   } as OrderItem;
      // });
      // const merchandiseOrder: MerchandiseOrder = {
      //   recipient: this.recipient,
      //   items: orderItems
      // };
      //
      // this.$root.$emit('merchandise-cart-modal', false);
      // try {
      //   await this.purchaseMerchandise({
      //     ids: merchandiseOrder.items.map(item => item.sync_variant_id),
      //     amounts: merchandiseOrder.items.map(item => item.quantity),
      //     totalPrice: toBN(this.totalPriceInSkill),
      //   });
      //   const apiResponse = await api.createMerchandiseOrder(merchandiseOrder);
      //   this.$root.$emit('order-complete-modal', apiResponse.result.id, apiResponse.result.shipping_service_name);
      // } catch (e) {
      //   console.error(e);
      // } finally {
      //   this.$root.$emit('merchandise-order-loading', false);
      // }
    },
    getTotalCartPrice() {
      return this.cartEntries.map(cartEntry => +cartEntry.variant.retail_price * cartEntry.quantity)
        .reduce((a, b) => a + b, 0);
    },
    calculateShippingPriceInSkill(price: number) {
      return price * this.skillPrice;
    },
    calculateTotalPrice() {
      this.totalPrice = this.getTotalCartPrice() + this.getShippingPrice();
      this.totalPriceInSkill = this.totalPrice * this.skillPrice;
    },
    getShippingPrice() {
      return this.selectedShippingRate?.rate ? +this.selectedShippingRate.rate : 0;
    },

    canAffordMerch() {
      const cost = toBN(this.totalPriceInSkill);
      const balance = toBN(this.skillBalance);
      return balance.isGreaterThanOrEqualTo(cost);
    },

    async getShippingRates() {
      const orderItems = this.cartEntries.map(cartEntry => {
        return {
          external_variant_id: cartEntry.variant.external_id,
          quantity: cartEntry.quantity
        } as OrderItem;
      });
      const merchandiseOrder: MerchandiseOrder = {
        recipient: this.recipient,
        items: orderItems
      };
      const response = await api.getShippingRates(merchandiseOrder);
      if (response.code !== 200) {
        return;
      }
      this.shippingRates = response.result;
    }
  },

  async mounted() {
    this.$root.$on('order-summary-modal', async (recipient: Recipient, cartEntries: CartEntry[]) => {
      if (recipient) {
        this.cartEntries = cartEntries;
        this.recipient = recipient;
        this.showModal = true;
        this.skillPrice = +await this.currentSkillPrice();
        this.calculateTotalPrice();
        this.areShippingRatesLoading = true;
        await this.getShippingRates();
        this.areShippingRatesLoading = false;
        this.calculateTotalPrice();
      } else {
        this.showModal = false;
      }
    });
  }
});
</script>

<style>
.costs-container {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 0.5rem;
}
</style>
