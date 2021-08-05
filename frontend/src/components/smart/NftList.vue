<template>
  <div>
    <div class="centered-text-div" v-if="isShop && (!nfts || nfts.length === 0)">
      <span>Nothing to buy at this time</span>
    </div>
    <ul class="nft-grid">
      <li class="nft" v-for="nft in nfts" :key="nft.nftType + nft.nftId">
        <nft-icon :nft="nft" :isShop="isShop"/>
        <b-button
          variant="primary"
          class="shop-button"
          @click="onShieldBuy()"
          v-if="isShop">
          <span class="gtag-link-others" tagname="forge_weapon">
            Buy ({{ nft.nftPrice }} SKILL)
          </span>
        </b-button>
      </li>
    </ul>
  </div>
</template>

<script lang="ts">
import { mapActions } from 'vuex';
import NftIcon from '../NftIcon.vue';
export default {
  props: ['nfts', 'isShop'],
  components: {
    NftIcon
  },

  methods: {
    ...mapActions(['purchaseShield']),

    async onShieldBuy() {
      await this.purchaseShield();
    }
  }
};
</script>

<style>
.nft-grid {
  list-style-type: none;
  justify-content: center;
  margin: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 12em);
  gap: 0.5em;
}
.nft {
  width: 12em;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 5px;
  cursor: pointer;
  position: relative;
  overflow: hidden;
}

.centered-text-div {
  text-align: center;
}

.shop-button {
  position: relative;
  width: 12rem;
}
</style>