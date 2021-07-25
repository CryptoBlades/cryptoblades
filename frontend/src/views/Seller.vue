<template>
  <div class="body main-font">
    Seller's page
    Seller's NFTs:
    <ul>
      <li v-for="(item, index) in items" :key="index">{{ item}}</li>
    </ul>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import { Accessors } from 'vue/types/options';
import { Weapons, Characters } from '../../../build/abi-interfaces';
import { Contract, Contracts, IState } from '../interfaces';

interface StoreMappedGetters {
  contracts: Contracts;
}

interface StoreMappedActions {
  fetchMarketNftIdsBySeller(payload: { nftContractAddr: string, sellerAddr: string }): Promise<string[]>;
}

interface Data {
  seller: string,
  items: string[]
}

type StoreMappedState = Pick<IState, 'weapons' | 'characters'>;

export default Vue.extend({
  components: {},
  async mounted () {
    const route = (this as any).$route;
    this.seller = route.params.walletId;
    await this.searchListingsBySellerThroughChain();
  },
  data() {
    return {
      seller: '',
      items: []
    } as Data;
  },

  computed: {
    Weapons(): Contract<Weapons> {
      return this.contracts.Weapons!;
    },
    Characters(): Contract<Characters> {
      return this.contracts.Characters!;
    },
    ...(mapState([
      'defaultAccount', 'weapons', 'characters', 'ownedCharacterIds', 'ownedWeaponIds'
    ]) as Accessors<StoreMappedState>),

    ...(mapGetters([
      'contracts', 'ownCharacters'
    ]) as Accessors<StoreMappedGetters>),
  },

  methods: {
    ...(mapActions([
      'fetchMarketNftIdsBySeller'
    ]) as StoreMappedActions),

    async searchListingsBySellerThroughChain(){
      this.items = await this.fetchMarketNftIdsBySeller({
        nftContractAddr: this.Weapons.options.address, // || this.Characters.options.address
        sellerAddr: this.seller
      });
    },

  }
});
</script>
