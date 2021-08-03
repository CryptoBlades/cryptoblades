<template>
  <div>
    <ul class="nft-grid">
      <li class="nft" v-for="nft in nfts" :key="nft.nftType + nft.nftId">
        <nft-icon :nft="nft"/>
      </li>
    </ul>
  </div>
</template>

<script lang="ts">
import NftIcon from '../NftIcon.vue';

export default {
  props: ['nfts'],
  components: {
    NftIcon
  },
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
</style>
