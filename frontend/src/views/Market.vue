<template>
  <div class="body main-font">
    <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
    <div class="row">
      <div class="col">
        <div class="self-buttons">
          <big-button
            class="button"
            mainText="Trade Weapons"
            @click="activeSell = 'weapon'"
          />

          <big-button
            class="button"
            mainText="Trade Characters"
            @click="activeSell = 'character'"
          />

          <big-button
            v-if="activeSell === 'weapon'"
            :disabled="!sellingWeapon"
            class="button"
            mainText="List Weapon"
            @click="addListingForNft()"
          />

          <big-button
            v-if="activeSell === 'character'"
            :disabled="!sellingCharacter"
            class="button"
            mainText="List Character"
            @click="addListingForNft()"
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
            v-model="sellingCharacter"
          />
        </div>
      </div>

      <div class="col">
        <input type="text" class="search" v-model="search" placeholder="Seller Address, NFT ID" />

        <div class="search-buttons">
          <big-button
            class="button"
            mainText="Search NFT"
            @click="searchListingsByNftId()"
          />

          <big-button
            class="button"
            mainText="Search Seller"
            @click="searchListingsBySeller()"
          />

          <big-button
            class="button"
            mainText="Search My NFTs"
            @click="searchOwnListings()"
          />
          <Hint class="hint" text="NFT stands for Non Fungible Token.
            <br>Weapons and Characters are NFTs of the ERC721 standard" />
        </div>

        <div class="search-results">
          <div v-for="result in searchResults" v-bind:key="result">
            <weapon-icon v-if="activeSell === 'weapon' && weapons[result]" :weapon="weapons[result]" />
            <CharacterArt v-if="activeSell === 'character' && characters[result]" :character="characters[result]" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import assert from 'assert';
import Vue from 'vue';
import BigButton from '../components/BigButton.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import CharacterArt from '../components/CharacterArt.vue';
import WeaponIcon from '../components/WeaponIcon.vue';
import Hint from '../components/Hint.vue';
import Web3 from 'web3';
import { mapActions, mapState } from 'vuex';
import { Accessors } from 'vue/types/options';
import { Contract, IState } from '../interfaces';
import { Characters, Weapons } from '../../../build/abi-interfaces';

type SellType = 'weapon' | 'character';
type WeaponId = string;
type CharacterId = string;

interface Data {
  activeSell: SellType;
  search: string;
  searchResults: CharacterId[] | WeaponId[];
  sellingCharacter: CharacterId | null;
  sellingWeapon: WeaponId | null;
  marketOutcome: string | null;
}

type StoreMappedState = Pick<IState, 'contracts' | 'defaultAccount' | 'weapons' | 'characters'>;

interface StoreMappedActions {
  fetchAllMarketNftIds(payload: { nftContractAddr: string }): Promise<string[]>;
  fetchMarketNftIdsBySeller(payload: { nftContractAddr: string, sellerAddr: string }): Promise<string[]>;
  fetchMarketNftPrice(payload: { nftContractAddr: string, tokenId: string | number }): Promise<string>;
  fetchMarketTax(payload: { nftContractAddr: string }): Promise<string>;
  addMarketListing(payload: { nftContractAddr: string, tokenId: string, price: string }): Promise<{ seller: string, nftID: string, price: string }>;
  changeMarketListingPrice(
    payload: { nftContractAddr: string, tokenId: string, newPrice: string }
  ): Promise<{ seller: string, nftID: string, newPrice: string }>;
  cancelMarketListing(payload: { nftContractAddr: string, tokenId: string }): Promise<{ seller: string, nftID: string }>;
  purchaseMarketListing(payload: { nftContractAddr: string, tokenId: string, maxPrice: string }): Promise<{ seller: string, nftID: string, price: string }>;

  fetchCharacters(characterIds: CharacterId[]): Promise<void>;
  fetchWeapons(weaponIds: WeaponId[]): Promise<void>;
}

export default Vue.extend({
  components: { BigButton, CharacterList, CharacterArt, WeaponGrid, WeaponIcon, Hint },

  data() {
    return {
      activeSell: 'weapon',
      search: '',
      searchResults: [],
      sellingCharacter: null,
      sellingWeapon: null,
      marketOutcome: null,
    } as Data;
  },

  computed: {
    ...(mapState(['contracts', 'defaultAccount', 'weapons', 'characters']) as Accessors<StoreMappedState>),

    Weapons(): Contract<Weapons> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Weapons!;
    },

    Characters(): Contract<Characters> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Characters!;
    },

    contractAddress(): string {
      return this.activeSell === 'weapon'
        ? this.Weapons.options.address
        : this.Characters.options.address;
    },

    sellingNftId(): WeaponId | CharacterId | null {
      return this.activeSell === 'weapon' ? this.sellingWeapon : this.sellingCharacter;
    }
  },

  methods: {
    ...(mapActions([
      'fetchAllMarketNftIds',
      'fetchMarketNftIdsBySeller',
      'fetchMarketNftPrice',
      'fetchMarketTax',
      'addMarketListing',
      'changeMarketListingPrice',
      'cancelMarketListing',
      'purchaseMarketListing',

      'fetchCharacters',
      'fetchWeapons',
    ]) as StoreMappedActions),

    async lookupNftPrice(nftId: WeaponId | CharacterId) {
      if(!this.contractAddress) return;

      return await this.fetchMarketNftPrice({
        nftContractAddr: this.contractAddress,
        tokenId: nftId,
      });
    },

    async addListingForNft() {
      if(!this.sellingNftId) return;

      const sellFor = prompt('How much SKILL do you want to list this '+this.activeSell+' for?', '0');
      if(!sellFor) return;

      const val = +sellFor;
      if(isNaN(val)) return;

      this.sellingCharacter = null;
      this.sellingWeapon = null;

      const results = await this.addMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.sellingNftId,
        price: this.convertSkillToWei(sellFor)
      });

      this.marketOutcome = 'Successfully listed '
        +this.activeSell+' '+results.nftID+' for '+this.convertWeiToSkill(results.price);
    },

    async updateNftListingPrice() {
      if(!this.sellingNftId) return;

      const sellFor = prompt('How much SKILL should this '+this.activeSell+' cost?', '0');
      if(!sellFor) return;

      const val = +sellFor;
      if(isNaN(val)) return;

      this.sellingCharacter = null;
      this.sellingWeapon = null;

      const results = await this.changeMarketListingPrice({
        nftContractAddr: this.contractAddress,
        tokenId: this.sellingNftId,
        newPrice: this.convertSkillToWei(sellFor)
      });

      this.marketOutcome = 'Successfully changed price for '
        +this.activeSell+' '+results.nftID+' to '+this.convertWeiToSkill(results.newPrice);
    },

    async purchaseNft(nftId: WeaponId | CharacterId) {
      const price = await this.lookupNftPrice(nftId);
      if(!price) return;

      const results = await this.purchaseMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: nftId,
        maxPrice: price
      });

      this.marketOutcome = 'Successfully purchased '
        +this.activeSell+' '+results.nftID+' for '+this.convertWeiToSkill(results.price)
          +' from '+results.seller;
    },

    async cancelNftListing() {
      if(!this.sellingNftId) return;

      const results = await this.cancelMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.sellingNftId,
      });

      this.marketOutcome = 'Successfully taken '
        +this.activeSell+' '+results.nftID+' off the market.';
    },

    async searchListingsByNftId() {
      //const price = lookupNftPrice(this.search);
      // incomplete
      this.searchResults = [];
    },

    async searchListingsBySeller() {
      const result = await this.fetchMarketNftIdsBySeller({
        nftContractAddr: this.contractAddress,
        sellerAddr: this.search,
      });
      console.log(result);
      this.searchResults = result;
    },

    async searchOwnListings() {
      if(!this.defaultAccount) {
        this.searchResults = [];
        return;
      }

      const result = await this.fetchMarketNftIdsBySeller({
        nftContractAddr: this.contractAddress,
        sellerAddr: this.defaultAccount,
      });
      console.log(result);
      this.searchResults = result;
    },

    convertWeiToSkill(wei: string) {
      return Web3.utils.fromWei(
        wei,
        'ether'
      );
    },
    convertSkillToWei(skill: string) {
      return Web3.utils.toWei(
        skill,
        'ether'
      );
    },
  },

  watch: {
    activeSell(newActiveSell: Data['activeSell'], oldActiveSell: Data['activeSell']) {
      if(newActiveSell === oldActiveSell) return;

      switch(newActiveSell) {
      case 'weapon': this.sellingCharacter = null; break;
      case 'character': this.sellingWeapon = null; break;
      }
    },

    async searchResults(newSearchResults: Data['searchResults']) {
      await (
        this.activeSell === 'weapon'
          ? this.fetchWeapons(newSearchResults)
          : this.fetchCharacters(newSearchResults)
      );
    }
  },

  mounted() {
    assert.ok(this.contracts.Weapons && this.contracts.Characters, 'Expected required contracts to be available');
  },
});
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
