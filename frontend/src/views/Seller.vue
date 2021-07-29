<template>
  <div class="body main-font">
    <div v-if="loading">
      Loading data...
    </div>
    <div v-else>
      Seller's page
      Seller's NFTs:
      <!-- <ul>
        <li v-for="(item, index) in items" :key="index">{{ item}}</li>
      </ul> -->
      <weapon-grid
        :weaponIds="items"
        :showGivenWeaponIds="true">
      </weapon-grid>
    </div>
  </div>
</template>

<script>
import Vue from 'vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
// import { market_blockchain as useBlockchain } from './../feature-flags'; TODO

export default Vue.extend({
  components: { WeaponGrid },
  data() {
    return {
      seller: '',
      type: 'weapons',
      items: [],
      loading: true
    };
  },
  computed: {
    Weapons() {
      return this.contracts.Weapons;
    },
    Characters() {
      return this.contracts.Characters;
    },
    ...(mapState([
      'defaultAccount', 'weapons', 'characters', 'ownedCharacterIds', 'ownedWeaponIds'
    ])),

    ...(mapGetters([
      'contracts', 'ownCharacters'
    ])),
  },

  watch:{
    $route: {
      async handler () {
        this.fetchData();
      },
      immediate: true
    }
  },

  methods: {
    ...(mapActions(['fetchMarketNftIdsBySeller' ])),

    async fetchData () {
      const route = this.$route;
      const sellerAddress = route.params.sellerAddress;
      this.items = await this.searchListingsBySellerThroughChain(sellerAddress);
      console.warn(this.items);
      this.loading = false;
    },

    async searchListingsBySellerThroughChain(sellerAddr){
      const nftContractAddr = this.type === 'weapons' ? this.Weapons.options.address : this.Characters.options.address;
      return await this.fetchMarketNftIdsBySeller({
        nftContractAddr,
        sellerAddr
      });
    }
  }
});
</script>
