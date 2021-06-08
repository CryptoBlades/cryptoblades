<template>
  <div class="body main-font">
    <div class="row">
      <div class="col">
        <div class="self-buttons">
          <big-button
            class="button"
            mainText="Sell Weapons"
            @click="activeSell = 'weapons'"
          />

          <big-button
            class="button"
            mainText="Sell Characters"
            @click="activeSell = 'characters'"
          />

          <big-button
            v-if="activeSell === 'weapons'"
            :disabled="!sellingWeapon"
            class="button"
            mainText="List Weapon"
            @click="listWeapon()"
          />

          <big-button
            v-if="activeSell === 'characters'"
            :disabled="!sellingCharacter"
            class="button"
            mainText="List Character"
            @click="listCharacter()"
          />
        </div>

        <div class="sell-grid" v-if="activeSell === 'weapons'">
          <weapon-grid
            v-model="sellingWeapon"
          />
        </div>

        <div class="sell-grid" v-if="activeSell === 'characters'">
          <character-list
            :value="sellingCharacter"
            @input="selectCharacterForSelling"
          />
        </div>
      </div>

      <div class="col">
        <input type="text" class="search" v-model="search" placeholder="Seller ID, NFT ID" />

        <div class="search-buttons">
          <big-button
            class="button"
            mainText="Search NFT"
            @click="searchNFT()"
          />

          <big-button
            class="button"
            mainText="Search Seller"
            @click="searchSeller()"
          />

          <big-button
            class="button"
            mainText="Search Mine"
            @click="searchMine()"
          />
        </div>

        <div class="search-results">
          <div v-for="result in searchResults" v-bind:key="result">
            {{ result }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import BigButton from '../components/BigButton.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import { mapActions, mapState } from 'vuex';

export default {
  components: { BigButton, CharacterList, WeaponGrid },

  data() {
    return {
      activeSell: 'weapons',
      search: '',
      searchResults: [],
      sellingCharacter: null,
      sellingWeapon: null,
    };
  },

  computed: {
    ...mapState(['contracts']),
  },

  methods: {
    ...mapActions([
      'fetchAllMarketNftIds', // nftContractAddr // returns bignumber array
      'fetchMarketNftIdsBySeller', // nftContractAddr, sellerAddr // returns bignumber array
      'fetchMarketNftPrice', // nftContractAddr, tokenId // returns wei
      'fetchMarketTax', // nftContractAddr // returns fixed64x64
      'addMarketListing', // nftContractAddr, tokenId, price // event unimplemented
      'changeMarketListngPrice', // nftContractAddr, tokenId, newPrice // event unimplemented
      'cancelMarketListing', // nftContractAddr, tokenId // event unimplemented
      'purchaseMarketListing', // nftContractAddr, tokenId, maxPrice // event unimplemented
    ]),

    selectCharacterForSelling(characterId) {
      this.sellingCharacter = characterId;
    },

    async listCharacter() {
      const character = this.sellingCharacter;
      this.sellingCharacter = null;

      const sellFor = prompt('How much SKILL do you want to list this character for?', '0');
      if(!sellFor) return;

      const val = +sellFor;
      if(isNaN(val)) return;

      console.log('sell', character, sellFor);
    },

    async listWeapon() {
      const weapon = this.sellingWeapon;
      this.sellingWeapon = null;

      const sellFor = prompt('How much SKILL do you want to list this weapon for?', '0');
      if(!sellFor) return;

      const val = +sellFor;
      if(isNaN(val)) return;

      console.log('sell', weapon, sellFor);
    },

    async searchNFT() {
      const result = await this.fetchMarketNftPrice({
        nftContractAddr: this.contracts.Weapons.options.address,
        tokenId: this.search,
      });
      console.log(result);
      return result;
    },

    searchSeller() {

    },

    searchMine() {

    }
  },
};
</script>

<style scoped>
.body {
  margin-top: 10px;
}

.row {
  display: flex;
  flex-direction: row;
}

.col {
  flex: 1;
}

.button + .button {
  margin-left: 10px;
}

.search {
  width: 100%;
}

.search-buttons, .self-buttons {
  margin-top: 10px;
  display: flex;
  justify-content: space-around;
}

.sell-grid {
  display: flex;
  justify-content: center;
  flex-direction: column;
}
</style>
