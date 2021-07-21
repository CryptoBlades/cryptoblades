<template>
  <div class="body main-font">

    <b-tabs justified>
      <b-tab @click="clearData();browseTabActive = true">
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
                  @click="searchAllCharacterListings(currentPage - 1)"  class="gtag-link-others" tagname="browse_characters">Browse Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllWeaponListings(currentPage - 1)"  class="gtag-link-others" tagname="browse_weapons">Browse Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="buyableNftSelected"
                  @click="purchaseNft()"  class="gtag-link-others" tagname="confirm_purchase">Purchase</b-button>
              </div>

              <div class="col"></div>
            </div>

            <div class="search-results">
              <b-pagination class="customPagination"
                v-visible="allSearchResults && allSearchResults.length > 0"
                align="center" v-model="currentPage"
                :total-rows="allListingsAmount"
                :per-page="activeType === 'weapon' ? weaponShowLimit : characterShowLimit"
                first-number
                last-number
                v-on:click.native="(activeType == 'weapon' && searchAllWeaponListings(currentPage - 1)) ||
                  searchAllCharacterListings(currentPage - 1)"
              ></b-pagination>

              <weapon-grid
                v-on:weapon-filters-changed="searchAllWeaponListings(0)"
                v-if="activeType === 'weapon'"
                :showGivenWeaponIds="true"
                :weaponIds="allSearchResults"
                :showLimit="weaponShowLimit"
                :showReforgedToggle="false"
                :canFavorite="false"
                :isMarket="true"
                v-model="selectedNftId">

                <template #above="{ weapon: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </weapon-grid>

              <character-list
                v-on:character-filters-changed="searchAllCharacterListings(0)"
                v-if="activeType === 'character'"
                :showFilters="true"
                :showGivenCharacterIds="true"
                :characterIds="allSearchResults"
                :showLimit="characterShowLimit"
                :isMarket="true"
                v-model="selectedNftId">

                <template #above="{ character: { id } }">
                  <div class="token-price">
                    <span class="d-block text-center" v-if="nftPricesById[id]">
                      {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                    </span>
                    <span class="d-block text-center" v-else>Loading price...</span>
                  </div>
                </template>

              </character-list>

              <b-pagination class="customPagination"
                v-if="allSearchResults && allSearchResults.length > 0"
                align="center" v-model="currentPage"
                :total-rows="allListingsAmount"
                :per-page="activeType === 'weapon' ? weaponShowLimit : characterShowLimit"
                first-number
                last-number
                v-on:click.native="(activeType == 'weapon' && searchAllWeaponListings(currentPage - 1)) ||
                  searchAllCharacterListings(currentPage - 1)"
              ></b-pagination>
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

      <b-tab @click="clearData(),browseTabActive = false">
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
                  @click="searchListingsByNftId('character')"  class="gtag-link-others" tagname="search_character_id">Search Character ID</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('weapon')"  class="gtag-link-others" tagname="search_weapon_id">Search Weapon ID</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('weapon')"  class="gtag-link-others" tagname="weapons_seller">Weapons by Seller</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('character')"  class="gtag-link-others" tagname="characters_seller">Characters by Seller</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('weapon')"  class="gtag-link-others" tagname="search_own_weapons">Search My Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('character')"  class="gtag-link-others" tagname="search_own_characters">Search My Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="buyableNftSelected"
                  @click="purchaseNft()"  class="gtag-link-others" tagname="confirm_purchase">Purchase</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  @click="updateNftListingPrice()"  class="gtag-link-others" tagname="change_price">Change Price</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  v-tooltip="'Cancelled sales cannot be re-listed for 24 hours!'"
                  @click="cancelNftListing()"  class="gtag-link-others" tagname="cancel_listing">Cancel Listing</b-button>
              </div>
            </div>

            <div class="search-results">
              <weapon-grid
                v-if="activeType === 'weapon'"
                :showGivenWeaponIds="true"
                :showReforgedToggle="false"
                :canFavorite="false"
                :weaponIds="searchResults"
                :isMarket="true"
                v-model="selectedNftId">

                <template #above="{ weapon: { id } }">
                  <span class="d-block text-center" v-if="nftPricesById[id]">
                    <strong>Price</strong>: {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                  </span>
                  <span class="d-block text-center" v-else>Loading price...</span>
                </template>

              </weapon-grid>

              <character-list
                :showFilters="true"
                v-if="activeType === 'character'"
                :showGivenCharacterIds="true"
                :characterIds="searchResults"
                :isMarket="true"
                v-model="selectedNftId">

                <template #above="{ character: { id } }">
                  <div class="token-price">
                    <span class="d-block text-center" v-if="nftPricesById[id]">
                      {{ convertWeiToSkill(nftPricesById[id]) | maxDecimals(2) }} SKILL
                    </span>
                    <span class="d-block text-center" v-else>Loading price...</span>
                  </div>
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

      <b-tab @click="clearData();loadMarketTaxes();browseTabActive = false">
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
                  @click="activeType = 'weapon'"  class="gtag-link-others" tagname="show_weapons_market">Show Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="activeType = 'character'"  class="gtag-link-others" tagname="show_characters_market">Show Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="activeType === 'weapon'"
                   class="gtag-link-others" tagname="add_listing_weapon"
                  :disabled="selectedNftId === null || selectedNftOnCooldown"
                  @click="showListingSetupModal()">List Weapon <b-icon-question-circle :hidden=!weaponMarketTax
                  v-tooltip.bottom="weaponMarketTax + '% tax (paid by the buyer) will be added to the final price.'"/></b-button>
                <b-button
                  variant="primary"
                  v-if="activeType === 'character'"
                  :disabled="selectedNftId === null || selectedNftOnCooldown"
                   class="gtag-link-others" tagname="add_listing_character"
                  @click="showListingSetupModal()">List Character <b-icon-question-circle :hidden=!characterMarketTax
                  v-tooltip.bottom="characterMarketTax + '% tax (paid by the buyer) will be added to the final price.'"/></b-button>

                <b-modal class="centered-modal" ref="listing-setup-modal"
                  @ok="addListingForNft">
                  <template #modal-title>
                    Sell {{activeType}}
                  </template>
                  <b-form-input type="number" :max="10000"
                    class="modal-input" v-model="listingSellPrice" placeholder="Sell Price (SKILL)" />

                  <span v-if="listingSellPrice">Do you want to sell your {{activeType}} for {{Math.min(+listingSellPrice, 10000)}} SKILL?</span>
                </b-modal>
              </div>

              <div class="col">
              </div>

              <div class="col">
              </div>

              <div class="col">
              </div>
            </div>

            <div class="sell-grid" v-if="activeType === 'weapon'">
              <weapon-grid
                v-model="selectedNftId"
                :showReforgedToggle="false"
                :canFavorite="false"
              />
            </div>

            <div class="sell-grid" v-if="activeType === 'character'">
              <character-list
                :showFilters="true"
                v-model="selectedNftId"
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
import { mapActions, mapGetters, mapState } from 'vuex';
import { Accessors } from 'vue/types/options';
import { Contract, Contracts, IState } from '../interfaces';
import { Characters, Weapons } from '../../../build/abi-interfaces';
import BigNumber from 'bignumber.js';
import { BModal } from 'bootstrap-vue';

type SellType = 'weapon' | 'character';
type WeaponId = string;
type CharacterId = string;
type NftId = WeaponId | CharacterId;

interface Data {
  activeType: SellType;
  search: string;
  searchResults: CharacterId[] | WeaponId[];
  allSearchResults: CharacterId[] | WeaponId[];
  searchResultsOwned: boolean;
  selectedNftId: NftId | null;
  marketOutcome: string | null;
  waitingMarketOutcome: boolean;
  nftPricesById: Record<string, string>;
  characterMarketTax: string;
  weaponMarketTax: string ;  characterShowLimit: number;
  weaponShowLimit: number;
  allListingsAmount: number;
  currentPage: number;
  browseTabActive: boolean;
  listingSellPrice: string;
}

type StoreMappedState = Pick<IState, 'defaultAccount' | 'weapons' | 'characters' | 'ownedCharacterIds' | 'ownedWeaponIds'>;

const defaultLimit = 40;

interface StoreMappedGetters {
  contracts: Contracts;
}

interface StoreMappedActions {
  fetchAllMarketNftIds(payload: { nftContractAddr: string }): Promise<string[]>;
  fetchAllMarketCharacterNftIdsPage(payload: {
    nftContractAddr: string, limit: number, pageNumber: number, trait: number, minLevel: number, maxLevel: number
  }): Promise<string[]>;
  fetchAllMarketWeaponNftIdsPage(payload: { nftContractAddr: string, limit: number, pageNumber: number, trait: number, stars: number }): Promise<string[]>;
  fetchNumberOfWeaponListings(payload: { nftContractAddr: string, trait: number, stars: number }): Promise<number>;
  fetchNumberOfCharacterListings(payload: { nftContractAddr: string, trait: number, minLevel: number, maxLevel: number}): Promise<number>;
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
      activeType: 'weapon',
      search: '',
      searchResults: [],
      allSearchResults: [],
      searchResultsOwned: false,
      selectedNftId: null,
      marketOutcome: null,
      waitingMarketOutcome: false,
      nftPricesById: {},
      characterMarketTax: '',
      weaponMarketTax: '',
      characterShowLimit: 40,
      weaponShowLimit: 60,
      allListingsAmount: 0,
      currentPage: 1,
      browseTabActive: true,
      listingSellPrice: ''
    } as Data;
  },

  computed: {
    ...(mapState([
      'defaultAccount', 'weapons', 'characters', 'ownedCharacterIds', 'ownedWeaponIds'
    ]) as Accessors<StoreMappedState>),
    ...(mapGetters([
      'contracts'
    ]) as Accessors<StoreMappedGetters>),
    ...mapGetters(['transferCooldownOfWeaponId', 'transferCooldownOfCharacterId']),

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
      return this.activeType === 'weapon'
        ? this.Weapons.options.address
        : this.Characters.options.address;
    },

    buyableNftSelected(): boolean {
      return this.selectedNftId !== null
        && !this.searchResultsOwned;
    },

    ownListedNftSelected(): boolean {
      return this.selectedNftId !== null
        && this.searchResultsOwned;
    },

    selectedNftOnCooldown(): boolean {
      return this.selectedNftId !== null
      && (this.activeType === 'weapon'
        ? (this.transferCooldownOfWeaponId(+this.selectedNftId) > 0)
        : (this.transferCooldownOfCharacterId(+this.selectedNftId) > 0));
    }
  },

  methods: {
    ...(mapActions([
      'fetchAllMarketNftIds',
      'fetchAllMarketCharacterNftIdsPage',
      'fetchAllMarketWeaponNftIdsPage',
      'fetchNumberOfWeaponListings',
      'fetchNumberOfCharacterListings',
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

    clearData() {
      this.activeType = 'weapon';
      this.search = '';
      this.searchResults = [];
      this.allSearchResults = [];
      this.searchResultsOwned = false;
      this.selectedNftId = null;
      this.marketOutcome = null;
      this.waitingMarketOutcome = false;
      this.nftPricesById = {};
      this.allListingsAmount = 0;
      this.currentPage = 1;
      this.listingSellPrice = '';
    },

    async loadMarketTaxes() {
      if(!this.characterMarketTax) {
        const tax = await this.getMarketTax(this.Characters.options.address) as string;
        this.characterMarketTax = this.convertMarketTax(tax);
      }
      if(!this.weaponMarketTax) {
        const tax = await this.getMarketTax(this.Weapons.options.address) as string;
        this.weaponMarketTax = this.convertMarketTax(tax);
      }
    },

    convertMarketTax(tax: string): string {
      return new BigNumber(tax).div(new BigNumber(2).pow(64)).multipliedBy(100).integerValue(BigNumber.ROUND_CEIL).toString();
    },

    async getMarketTax(contractAddress: string) {
      if(!contractAddress) return;

      return await this.fetchMarketTax({
        nftContractAddr: contractAddress,
      });
    },

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
      if(this.selectedNftId === null) return;
      if(!this.listingSellPrice) return;

      const val = Math.min(+this.listingSellPrice, 10000);
      if(val <= 0 || !val || isNaN(val)) return;

      this.waitingMarketOutcome = true;

      const results = await this.addMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        price: this.convertSkillToWei(this.listingSellPrice),
      });

      this.selectedNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully listed '
        +this.activeType+' '+results.nftID+' for '+this.convertWeiToSkill(results.price)+' SKILL';
    },

    async updateNftListingPrice() {

      this.marketOutcome = null;
      if(this.selectedNftId === null) return;


      const sellFor = await (this as any).$dialog.prompt({ title: `Sell ${this.activeType}`, text: 'Sell Price (SKILL)' });
      if(!sellFor) return;

      const val = +sellFor;
      if(val <= 0 || !val || isNaN(val)) return;

      this.waitingMarketOutcome = true;

      const results = await this.changeMarketListingPrice({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        newPrice: this.convertSkillToWei(sellFor)
      });

      this.selectedNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully changed price for '
        +this.activeType+' '+results.nftID+' to '+this.convertWeiToSkill(results.newPrice)+' SKILL';
    },

    async purchaseNft() {
      this.marketOutcome = null;
      if(this.selectedNftId === null) return;

      const price = await this.lookupNftPrice(this.selectedNftId);
      if(!price) return;

      const skillChainPrice = this.convertStringToDecimal(this.convertWeiToSkill(price), 2);
      const skillUIPrice = this.convertStringToDecimal(this.convertWeiToSkill(this.nftPricesById[this.selectedNftId]), 2);

      if(skillChainPrice !== skillUIPrice) {
        (this as any).$dialog.notify.error('The price of the listing has changed. Please refresh listing and try again');
        return;
      }

      this.waitingMarketOutcome = true;

      const results: any = await this.purchaseMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        maxPrice: price
      });

      const results2: any  = await this.fetchAllMarketNftIds({
        nftContractAddr: this.contractAddress
      });

      this.allSearchResults = results2;

      this.allSearchResults = Array.from(this.allSearchResults).filter((x: any) => x.id !== this.selectedNftId);

      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully purchased '
        +this.activeType+' '+results.nftID+' for '+this.convertWeiToSkill(results.price)+' SKILL'
          +' from '+results.seller;
    },

    async cancelNftListing() {
      this.marketOutcome = null;

      if(this.selectedNftId === null) return;

      this.waitingMarketOutcome = true;

      const results = await this.cancelMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
      });

      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully taken '
        +this.activeType+' '+results.nftID+' off the market.';

      await this.searchOwnListings(this.activeType);
    },

    async searchAllCharacterListings(page: number) {
      this.activeType = 'character';
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;
      this.currentPage = page + 1;

      const url = new URL('https://api.cryptoblades.io/static/market/character');
      const params = {
        element: '' + this.characterTraitFilter(),
        minLevel: '' + this.characterMinLevelFilter(),
        maxLevel: '' + this.characterMaxLevelFilter(),
        sortBy: '' + this.characterPriceOrder() ? 'price' : '',
        sortDir: '' + this.characterPriceOrder(),
        pageSize: '' + (this.characterShowLimit || defaultLimit),
        pageNum: '' + page,
      };

      url.search = new URLSearchParams(params).toString();

      const charactersData = await fetch(url.toString());
      const characters = await charactersData.json();

      // searchResultsOwned does not mesh with this function
      // will need per-result checking of it, OR filtering out own NFTs
      //this.searchResultsOwned = nftSeller === this.defaultAccount;
      this.searchResultsOwned = false; // temp
      this.allListingsAmount = characters.page.total;
      this.allSearchResults = characters.idResults;

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchAllWeaponListings(page: number) {
      this.activeType = 'weapon';
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;
      this.currentPage = page + 1;

      const url = new URL('https://api.cryptoblades.io/static/market/weapon');
      const params = {
        element: '' + this.weaponTraitFilter(),
        minStars: '' + this.weaponStarFilter(),
        maxStars: '' + this.weaponStarFilter(),
        sortBy: '' + this.weaponPriceOrder() ? 'price' : '',
        sortDir: '' + this.weaponPriceOrder(),
        pageSize: '' + (this.weaponShowLimit || defaultLimit),
        pageNum: '' + page,
      };

      url.search = new URLSearchParams(params).toString();

      const weaponsData = await fetch(url.toString());
      const weapons = await weaponsData.json();

      // searchResultsOwned does not mesh with this function
      // will need per-result checking of it, OR filtering out own NFTs
      //this.searchResultsOwned = nftSeller === this.defaultAccount;
      this.searchResultsOwned = false; // temp
      this.allListingsAmount = weapons.page.total;
      this.allSearchResults = weapons.idResults;

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchListingsByNftId(type: SellType) {
      this.activeType = type;
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

    async searchListingsBySeller(type: SellType) {
      this.activeType = type;
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;

      try {
        const results = this.activeType === 'weapon' ?
          await this.searchWeaponListingsBySeller(this.search):
          await this.searchCharacterListingsBySeller(this.search);
        this.searchResults = results;
      } catch {
        this.searchResultsOwned = false;
        this.waitingMarketOutcome = false;
        this.searchResults = [];
      }

      this.searchResultsOwned = false;
      this.waitingMarketOutcome = false;
    },

    async searchOwnListings(type: SellType) {
      this.marketOutcome = null;
      this.activeType = type;

      if(!this.defaultAccount) {
        this.searchResults = [];
        return;
      }

      this.waitingMarketOutcome = true;

      const results = this.activeType === 'weapon' ?
        await this.searchWeaponListingsBySeller(this.defaultAccount) :
        await this.searchCharacterListingsBySeller(this.defaultAccount);

      this.searchResultsOwned = true;
      this.waitingMarketOutcome = false;
      this.searchResults = results;
    },

    async searchCharacterListingsBySeller(sellerAddress: string): Promise<string[]>{
      const url = new URL('https://api.cryptoblades.io/static/market/character');
      const params = {
        element: '' + this.characterTraitFilter(),
        minLevel: '' + this.characterMinLevelFilter(),
        maxLevel: '' + this.characterMaxLevelFilter(),
        sortBy: '' + this.characterPriceOrder() ? 'price' : '',
        sortDir: '' + this.characterPriceOrder(),
        sellerAddress: '' + sellerAddress,
      };

      url.search = new URLSearchParams(params).toString();

      const charactersData = await fetch(url.toString());
      const characters = await charactersData.json();
      return characters.idResults;
    },

    async searchWeaponListingsBySeller(sellerAddress: string): Promise<string[]>{
      const url = new URL('https://api.cryptoblades.io/static/market/weapon');
      const params = {
        element: '' + this.weaponTraitFilter(),
        minStars: '' + this.weaponStarFilter(),
        maxStars: '' + this.weaponStarFilter(),
        sortBy: '' + this.weaponPriceOrder() ? 'price' : '',
        sortDir: '' + this.weaponPriceOrder(),
        pageSize: '' + (this.weaponShowLimit || defaultLimit),
        sellerAddress: '' + sellerAddress,
      };

      url.search = new URLSearchParams(params).toString();

      const weaponsData = await fetch(url.toString());
      const weapons = await weaponsData.json();
      return weapons.idResults;
    },

    showListingSetupModal() {
      this.clearInputs();
      (this.$refs['listing-setup-modal'] as BModal).show();
    },

    clearInputs() {
      this.listingSellPrice = '';
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

    characterMinLevelFilter(): number {
      return sessionStorage.getItem('character-levelfilter') ? +(sessionStorage.getItem('character-levelfilter') as string) - 1 : 0;
    },

    characterMaxLevelFilter(): number {
      return sessionStorage.getItem('character-levelfilter') ? +(sessionStorage.getItem('character-levelfilter') as string) + 8 : 255;
    },

    characterTraitFilter(): string {
      return sessionStorage.getItem('character-elementfilter') ? (sessionStorage.getItem('character-elementfilter') as string).toLowerCase() : '';
    },

    characterPriceOrder(): string {
      return sessionStorage.getItem('character-price-order') ? (sessionStorage.getItem('character-price-order') as string) : '';
    },

    weaponTraitFilter(): string {
      return sessionStorage.getItem('weapon-elementfilter') ? (sessionStorage.getItem('weapon-elementfilter') as string).toLowerCase() : '';
    },

    weaponStarFilter(): number {
      return sessionStorage.getItem('weapon-starfilter') ? +(sessionStorage.getItem('weapon-starfilter') as string) : 0;
    },

    weaponPriceOrder(): string {
      return sessionStorage.getItem('weapon-price-order') ? (sessionStorage.getItem('weapon-price-order') as string) : '';
    },

    convertStringToDecimal(val: string, maxDecimals: number) {
      return new BigNumber(val).toFixed(maxDecimals);
    }
  },

  watch: {

    async searchResults(nftIds: CharacterId[] | WeaponId[]) {
      this.selectedNftId = null;

      await this.fetchNftPrices(nftIds);
    },

    async allSearchResults(nftIds: CharacterId[] | WeaponId[]) {
      this.selectedNftId = null;

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

.modal-input {
  margin-bottom: 5px;
  margin-top: 5px;
}

</style>
