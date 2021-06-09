<template>
  <div class="body main-font">
    <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
    <div class="row">
      <div class="col">
        <div class="self-buttons">
          <big-button
            class="button"
            mainText="Trade Weapons"
            @click="setActiveSell('weapon')"
          />

          <big-button
            class="button"
            mainText="Trade Characters"
            @click="setActiveSell('character')"
          />

          <big-button
            v-if="activeSell === 'weapon'"
            :disabled="!sellingWeapon"
            class="button"
            mainText="List Weapon"
            @click="listNFT()"
          />

          <big-button
            v-if="activeSell === 'character'"
            :disabled="!sellingCharacter"
            class="button"
            mainText="List Character"
            @click="listNFT()"
          />
          <Hint class="hint" text="When you list an NFT for sale, it is transferred to the
            <br>market until someone buys it or you cancel the sale" />
        </div>

        <div class="sell-grid" v-if="activeSell === 'weapon'">
          <weapon-grid
            v-model="sellingWeapon"
          />
        </div>

        <div class="sell-grid" v-if="activeSell === 'character'">
          <character-list
            :value="sellingCharacter"
            @input="selectCharacterForSelling"
          />
        </div>
      </div>

      <div class="col">
        <input type="text" class="search" v-model="search" placeholder="Seller Address, NFT ID" />

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
            mainText="Search My NFTs"
            @click="searchMine()"
          />
          <Hint class="hint" text="NFT stands for Non Fungible Token.
            <br>Weapons and Characters are NFTs of the ERC721 standard" />
        </div>

        <div class="search-results">
          <div v-for="result in searchResults" v-bind:key="result">
            {
              <weapon-icon v-if="activeSell === 'weapon'" :weapon="lookupWeapon(result)" />
              <CharacterArt v-if="activeSell === 'character'" :character="lookupCharacter(result)" />
            }
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
import CharacterArt from '../components/CharacterArt.vue';
import WeaponIcon from '../components/WeaponIcon.vue';
import Hint from '../components/Hint.vue';
import Web3 from 'web3';
import { mapActions, mapState } from 'vuex';
import { characterFromContract, weaponFromContract } from '../contract-models';

export default {
  components: { BigButton, CharacterList, CharacterArt, WeaponGrid, WeaponIcon, Hint },

  data() {
    return {
      activeSell: 'weapon',
      search: '',
      searchResults: [],
      contractAddress: null, // set in mounted
      sellingCharacter: null,
      sellingWeapon: null,
      marketOutcome: null,
    };
  },

  computed: {
    ...mapState(['contracts', 'defaultAccount']),
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

    setActiveSell(to) {
      this.activeSell = to;
      this.contractAddress = this.activeSell === 'weapon'
        ? this.contracts.Weapons.options.address
        : this.contracts.Characters.options.address;
    },

    getNFT_ID() {
      return this.activeSell === 'weapon' ? this.sellingWeapon : this.sellingCharacter;
    },

    async lookupWeapon(weaponId) {
      // the fetch in state fucks with the player's list so i copied out the necessary part
      console.log('HERE BE WEAPONID '+weaponId);
      return weaponFromContract(
        weaponId,
        await this.contracts.Weapons.methods.get('' + weaponId).call({ from: this.defaultAccount })
      );
    },

    async lookupCharacter(characterId) {
      // the fetch in state fucks with the player's list so i copied out the necessary part
      return characterFromContract(
        characterId,
        await this.contracts.Characters.methods.get('' + characterId).call({ from: this.defaultAccount })
      );
    },

    async lookupNFTPrice(nftId) {
      return await this.fetchMarketNftPrice({
        nftContractAddr: this.contractAddress,
        tokenId: nftId,
      });
    },

    async listNFT() {

      const sellFor = prompt('How much SKILL do you want to list this '+this.activeSell+' for?', '0');
      if(!sellFor) return;

      const val = +sellFor;
      if(isNaN(val)) return;

      this.sellingCharacter = null;
      this.sellingWeapon = null;

      const results = await this.addMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.getNFT_ID(),
        price: this.convertSkillToWei(sellFor)
      });

      if(!results[0])
        this.marketOutcome = 'Successfully listed '
        +this.activeSell+' '+results[1]+' for '+this.convertWeiToSkill(results[2]);
    },

    async repriceNFT() {

      const sellFor = prompt('How much SKILL should this '+this.activeSell+' cost?', '0');
      if(!sellFor) return;

      const val = +sellFor;
      if(isNaN(val)) return;

      this.sellingCharacter = null;
      this.sellingWeapon = null;

      const results = await this.changeMarketListingPrice({
        nftContractAddr: this.contractAddress,
        tokenId: this.getNFT_ID(),
        price: this.convertSkillToWei(sellFor)
      });

      if(!results[0])
        this.marketOutcome = 'Successfully changed price for '
        +this.activeSell+' '+results[1]+' to '+this.convertWeiToSkill(results[2]);
    },

    async purchaseNFT(nftId) {

      const price = this.lookupNFTPrice(nftId);

      const results = await this.purchaseMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.getNFT_ID(),
        maxPrice: price
      });

      if(!results[0])
        this.marketOutcome = 'Successfully purchased '
        +this.activeSell+' '+results[1]+' for '+this.convertWeiToSkill(results[2])
          +' from '+results[0];
    },

    async cancelNFTListing() {

      const results = await this.cancelMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.getNFT_ID(),
      });

      if(!results[0])
        this.marketOutcome = 'Successfully taken '
        +this.activeSell+' '+results[1]+' off the market.';
    },

    async searchNFT() {
      //const price = lookupNFTPrice(this.search);
      // incomplete
    },

    async searchSeller() {
      const result = await this.fetchMarketNftIdsBySeller({
        nftContractAddr: this.contractAddress,
        sellerAddr: this.search,
      });
      console.log(result);
      return result;
    },

    async searchMine() {
      const result = await this.fetchMarketNftIdsBySeller({
        nftContractAddr: this.contractAddress,
        sellerAddr: this.defaultAccount,
      });
      console.log(result);
      return result;
    },

    convertWeiToSkill(wei) {
      return Web3.utils.fromWei(
        wei,
        'ether'
      );
    },
    convertSkillToWei(wei) {
      return Web3.utils.toWei(
        wei,
        'ether'
      );
    },
  },
  mounted() {
    this.contractAddress = this.contracts.Weapons.options.address;
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

.hint {
  font-size: 2em;
}

.outcome {
  margin: auto;
  text-align: center;
  font-size: 1em;
}

</style>
