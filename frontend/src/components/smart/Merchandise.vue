<template>
  <div>
    <MerchandiseCart :cartEntries="cartEntries"/>
    <MerchandiseList/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import MerchandiseList from '@/components/smart/MerchandiseList.vue';
import MerchandiseCart from '@/components/smart/MerchandiseCart.vue';
import {CartEntry} from '@/components/smart/VariantChoiceModal.vue';

interface Data {
  cartEntries: CartEntry[];
}

export default Vue.extend({
  components: {
    MerchandiseList, MerchandiseCart
  },

  data() {
    return {
      cartEntries: [],
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
      if(duplicatedEntry) {
        const entryIndex = this.cartEntries.indexOf(duplicatedEntry);
        this.cartEntries.splice(entryIndex, 1);
      }
      this.cartEntries.push(cartEntry);
      console.log(this.cartEntries);
    });
  }

});
</script>

<style>


</style>
