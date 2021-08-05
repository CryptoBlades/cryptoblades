<template>
  <div v-bind:class="isDefault ? 'default-icon-wrapper' : 'nft-icon-wrapper'">

    <div v-if="!isDefault" class="nft-icon">
      <!-- show nft with id: nftId of type: nftfType (contract address?)
        either load properties here or wherever the list of nfts is created and pass in nft object-->
      <div v-if="nft.nftType === 'shield'" class="nft-details">
        <img class="placeholder-shield" src="../assets/shield1.png"/>
        <span v-if="isShop" class="nft-supply">Supply left: {{totalShieldSupply}}</span>
        <div v-if="!isShop" class="id">ID {{ nft.nftId }}</div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions } from 'vuex';
export default {
  props: ['nft', 'isDefault', 'isShop'],

  data() {
    return {
      totalShieldSupply: 0,
      fetchSupplyInterval: 0,
    };
  },

  methods: {
    ...mapActions(['fetchTotalShieldSupply']),
  },

  mounted() {
    if(this.nft.nftType === 'shield') {
      this.fetchSupplyInterval = setInterval(async () => {
        this.totalShieldSupply = 10000 - (await this.fetchTotalShieldSupply());
      }, 3000);
    }
  },

  beforeDestroy() {
    clearInterval(this.fetchSupplyInterval);
  }
};
</script>

<style>
.nft-icon {
  height: 100%;
  width: 100%;
  position: relative;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid #9e8a57;
}
.nft-icon-wrapper {
  width: 12em;
  height: 12em;
}
.default-icon-wrapper {
  width: 8em;
  height: 8em;
  margin: 5px;
}
.default-placeholder {
  max-width: 100px;
  max-height: 100px;
  margin-left: 12px;
  margin-top: 8px;
  transform: scale(1);
}
.placeholder-weapon {
  max-width: 180px;
  max-height: 180px;
  margin-left: 10px;
  margin-top: 5px;
  transform: scale(0.7);
}

.placeholder-shield {
  max-width: 160px;
  max-height: 200px;
  margin-top: -10px;
}

.nft-supply {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
}

.nft-details {
  text-align: center;
}

.trait, .id {
  position: absolute;
}

.id {
  top: 8px;
  right: 10px;
  font-style: italic;
}

.trait {
  top: 10px;
  left: 10px;
}
</style>