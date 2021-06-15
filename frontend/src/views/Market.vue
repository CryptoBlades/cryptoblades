<template>
  <div class="body main-font">

    <b-tabs justified>
      <b-tab>
        <template #title>
          Browse NFTs
          <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" />
        </template>

        <div class="row mt-3">
          <div class="col">

            <div class="row button-row">
              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllListingsByType('character')">Browse Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllListingsByType('weapon')">Browse Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="buyableNftSelected"
                  @click="purchaseNft()">Purchase</b-button>
              </div>

              <div class="col"></div>
            </div>

            <div class="search-results">
              <span v-if="allSearchResults.length >= 40"><h4>More than 40 results, try using the filters</h4></span>
              <weapon-grid
                v-if="activeSearch === 'weapon'"
                :showGivenWeaponIds="true"
                :weaponIds="allSearchResults"
                v-model="selectedSearchNftId">

                <template #above="{ weapon: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </weapon-grid>

              <character-list
                v-if="activeSearch === 'character'"
                :showGivenCharacterIds="true"
                :characterIds="allSearchResults"
                v-model="selectedSearchNftId">

                <template #above="{ character: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </character-list>
            </div>

          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              Loading...
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab>
        <template #title>
          Search NFTs
          <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" />
        </template>

        <div class="row mt-3">
          <div class="col">
            <div class="row">
              <div class="col"></div>
              <div class="col">
                <input class="form-control search" type="text" v-model.trim="search" placeholder="Seller Address, NFT ID" />
              </div>
              <div class="col"></div>
            </div>

            <div class="row buttons-row mt-3">
              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('character')">Search Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('weapon')">Search Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller()">Search Seller</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('weapon')">Search My Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('character')">Search My Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="buyableNftSelected"
                  @click="purchaseNft()">Purchase</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  @click="updateNftListingPrice()">Change Price</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  @click="cancelNftListing()">Cancel Listing</b-button>
              </div>
            </div>

            <div class="search-results">
              <weapon-grid
                v-if="activeSearch === 'weapon'"
                :showGivenWeaponIds="true"
                :weaponIds="searchResults"
                v-model="selectedSearchNftId">

                <template #above="{ weapon: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </weapon-grid>

              <character-list
                v-if="activeSearch === 'character'"
                :showGivenCharacterIds="true"
                :characterIds="searchResults"
                v-model="selectedSearchNftId">

                <template #above="{ character: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </character-list>
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              Loading...
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab>
        <template #title>
          List NFTs
          <hint class="hint" text="When you list an NFT for sale, it is transferred to the<br>market until someone buys it or you cancel the sale" />
        </template>

        <div class="row mt-3">
          <div class="col">
            <div class="row button-row">
              <div class="col">
                <b-button
                  variant="primary"
                  @click="activeSell = 'weapon'">Show Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="activeSell = 'character'">Show Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="activeSell === 'weapon'"
                  :disabled="selectedSellingNftId === null"
                  @click="addListingForNft()">List Weapon</b-button>
                <b-button
                  variant="primary"
                  v-if="activeSell === 'character'"
                  :disabled="selectedSellingNftId === null"
                  @click="addListingForNft()">List Character</b-button>
              </div>

              <div class="col">
              </div>

              <div class="col">
              </div>

              <div class="col">
              </div>
            </div>

            <div class="sell-grid" v-if="activeSell === 'weapon'">
              <weapon-grid
                v-model="selectedSellingNftId"
              />
            </div>

            <div class="sell-grid" v-if="activeSell === 'character'">
              <character-list
                v-model="selectedSellingNftId"
              />
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              Loading...
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>
    </b-tabs>
  </div>
</template>

<script lang="ts">
import assert from 'assert';
import Vue from 'vue';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import Hint from '../components/Hint.vue';
import Web3 from 'web3';
import { mapActions, mapState } from 'vuex';
import { Accessors } from 'vue/types/options';
import { Contract, IState } from '../interfaces';
import { Characters, Weapons } from '../../../build/abi-interfaces';
import BigNumber from 'bignumber.js';

type SellType = 'weapon' | 'character';
type WeaponId = string;
type CharacterId = string;
type NftId = WeaponId | CharacterId;

interface Data {
  activeSell: SellType;
  activeSearch: SellType;
  search: string;
  searchResults: CharacterId[] | WeaponId[];
  allSearchResults: CharacterId[] | WeaponId[];
  searchResultsOwned: boolean;
  selectedSellingNftId: NftId | null;
  marketOutcome: string | null;
  waitingMarketOutcome: boolean;
  selectedSearchNftId: NftId | null;
  nftPricesById: Record<string, string>;
}

type StoreMappedState = Pick<IState, 'contracts' | 'defaultAccount' | 'weapons' | 'characters' | 'ownedCharacterIds' | 'ownedWeaponIds'>;

interface StoreMappedActions {
  fetchAllMarketNftIds(payload: { nftContractAddr: string }): Promise<string[]>;
  fetchMarketNftIdsBySeller(payload: { nftContractAddr: string, sellerAddr: string }): Promise<string[]>;
  fetchMarketNftPrice(payload: { nftContractAddr: string, tokenId: string | number }): Promise<string>;
  fetchMarketTax(payload: { nftContractAddr: string }): Promise<string>;
  checkMarketItemOwnership(payload: { nftContractAddr: string, tokenId: string | number}): Promise<string>;
  addMarketListing(payload: { nftContractAddr: string, tokenId: string, price: string }): Promise<{ seller: string, nftID: string, price: string }>;
  changeMarketListingPrice(
    payload: { nftContractAddr: string, tokenId: string, newPrice: string }
  ): Promise<{ seller: string, nftID: string, newPrice: string }>;
  cancelMarketListing(payload: { nftContractAddr: string, tokenId: string }): Promise<{ seller: string, nftID: string }>;
  purchaseMarketListing(payload: { nftContractAddr: string, tokenId: string, maxPrice: string }): Promise<{ seller: string, nftID: string, price: string }>;
  fetchSellerOfNft(payload: { nftContractAddr: string, tokenId: string }): Promise<string>;
}

export default Vue.extend({
  components: { CharacterList, WeaponGrid, Hint },

  data() {
    return {
      activeSell: 'weapon',
      activeSearch: 'weapon',
      search: '',
      searchResults: [],
      allSearchResults: [],
      searchResultsOwned: false,
      selectedSellingNftId: null,
      marketOutcome: null,
      waitingMarketOutcome: false,
      selectedSearchNftId: null,
      nftPricesById: {},
    } as Data;
  },

  computed: {
    ...(mapState([
      'contracts', 'defaultAccount', 'weapons', 'characters', 'ownedCharacterIds', 'ownedWeaponIds'
    ]) as Accessors<StoreMappedState>),

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

    buyableNftSelected(): boolean {
      return this.selectedSearchNftId !== null
        && !this.searchResultsOwned;
    },

    ownListedNftSelected(): boolean {
      return this.selectedSearchNftId !== null
        && this.searchResultsOwned;
    }
  },

  methods: {
    ...(mapActions([
      'fetchAllMarketNftIds',
      'fetchMarketNftIdsBySeller',
      'fetchMarketNftPrice',
      'fetchMarketTax',
      'checkMarketItemOwnership',
      'addMarketListing',
      'changeMarketListingPrice',
      'cancelMarketListing',
      'purchaseMarketListing',
      'fetchSellerOfNft',
    ]) as StoreMappedActions),

    async lookupNftPrice(nftId: NftId) {
      if(!this.contractAddress) return;

      return await this.fetchMarketNftPrice({
        nftContractAddr: this.contractAddress,
        tokenId: nftId,
      });
    },

    async fetchNftPrices(nftIds: NftId[]) {
      if(!this.contractAddress) return;

      await Promise.all(nftIds.map(async nftId => {
        const price = (await this.lookupNftPrice(nftId))!;

        void price;
        this.nftPricesById[nftId] = price;
      }));
    },

    async addListingForNft() {
      this.marketOutcome = null;
      if(this.selectedSellingNftId === null) return;

      const sellFor = await (this as any).$dialog.prompt({ title: `Sell ${this.activeSell}`, text: 'Sell Price (SKILL)' });
      if(!sellFor) return;

      const val = +sellFor;
      if(val <= 0 || !val || isNaN(val)) return;

      this.waitingMarketOutcome = true;

      const results = await this.addMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedSellingNftId,
        price: this.convertSkillToWei(sellFor)
      });

      this.selectedSellingNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully listed '
        +this.activeSell+' '+results.nftID+' for '+this.convertWeiToSkill(results.price)+' SKILL';
    },

    async updateNftListingPrice() {

      this.marketOutcome = null;
      if(this.selectedSearchNftId === null) return;


      const sellFor = await (this as any).$dialog.prompt({ title: `Sell ${this.activeSell}`, text: 'Sell Price (SKILL)' });
      if(!sellFor) return;

      const val = +sellFor;
      if(val <= 0 || !val || isNaN(val)) return;

      this.waitingMarketOutcome = true;

      const results = await this.changeMarketListingPrice({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedSearchNftId,
        newPrice: this.convertSkillToWei(sellFor)
      });

      this.selectedSellingNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully changed price for '
        +this.activeSell+' '+results.nftID+' to '+this.convertWeiToSkill(results.newPrice)+' SKILL';
    },

    async purchaseNft() {
      this.marketOutcome = null;
      if(this.selectedSearchNftId === null) return;

      const price = await this.lookupNftPrice(this.selectedSearchNftId);
      if(!price) return;

      this.waitingMarketOutcome = true;

      const results = await this.purchaseMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedSearchNftId,
        maxPrice: price
      });

      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully purchased '
        +this.activeSell+' '+results.nftID+' for '+this.convertWeiToSkill(results.price)+' SKILL'
          +' from '+results.seller;
    },

    async cancelNftListing() {
      this.marketOutcome = null;

      if(this.selectedSearchNftId === null) return;

      this.waitingMarketOutcome = true;

      const results = await this.cancelMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedSearchNftId,
      });

      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully taken '
        +this.activeSell+' '+results.nftID+' off the market.';

      await this.searchOwnListings(this.activeSell);
    },

    async searchAllListingsByType(type: SellType) {
      this.activeSell = type; // this is required to refresh this.contractAddress
      this.activeSearch = type;
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;

      let results = await this.fetchAllMarketNftIds({
        nftContractAddr: this.contractAddress
      });

      if(results.length > 40) // temp hard limit
        results = results.slice(0,40);

      // searchResultsOwned does not mesh with this function
      // will need per-result checking of it, OR filtering out own NFTs
      //this.searchResultsOwned = nftSeller === this.defaultAccount;
      this.searchResultsOwned = false; // temp
      this.allSearchResults = results;

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchListingsByNftId(type: SellType) {
      this.activeSearch = type;
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;

      const nftSeller = await this.fetchSellerOfNft({
        nftContractAddr: this.contractAddress,
        tokenId: this.search
      });
      this.searchResultsOwned = nftSeller === this.defaultAccount;

      const price = await this.lookupNftPrice(this.search);
      if(price !== '0') {
        this.searchResults = [this.search];
      } else {
        this.searchResults = [];
      }

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchListingsBySeller() {
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;

      try {
        const result = await this.fetchMarketNftIdsBySeller({
          nftContractAddr: this.contractAddress,
          sellerAddr: this.search,
        });

        this.searchResultsOwned = this.search === this.defaultAccount;
        this.waitingMarketOutcome = false;
        this.searchResults = result;

      } catch {
        this.searchResultsOwned = false;
        this.waitingMarketOutcome = false;
        this.searchResults = [];
      }
    },

    async searchOwnListings(type: SellType) {
      this.marketOutcome = null;
      this.activeSearch = type;

      if(!this.defaultAccount) {
        this.searchResults = [];
        return;
      }

      this.waitingMarketOutcome = true;

      const result = await this.fetchMarketNftIdsBySeller({
        nftContractAddr: this.contractAddress,
        sellerAddr: this.defaultAccount,
      });
      this.searchResultsOwned = true;
      this.waitingMarketOutcome = false;
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

      this.search = '';
      this.searchResults = [];
      this.selectedSearchNftId = null;
      this.selectedSellingNftId = null;
    },

    async searchResults(nftIds: CharacterId[] | WeaponId[]) {
      this.selectedSearchNftId = null;

      await this.fetchNftPrices(nftIds);
    },

    async allSearchResults(nftIds: CharacterId[] | WeaponId[]) {
      this.selectedSearchNftId = null;

      await this.fetchNftPrices(nftIds);
    }
  },

  filters: {
    maxDecimals(val: string, maxDecimals: number) {
      return new BigNumber(val).toFixed(maxDecimals);
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

.result-item {
  max-width: 12em;
}

.result-selected {
  outline: solid currentcolor 2px;
}

.sell-grid {
  display: flex;
  justify-content: center;
  flex-direction: column;
}

.outcome {
  margin: auto;
  text-align: center;
  font-size: 1em;
}

</style>
