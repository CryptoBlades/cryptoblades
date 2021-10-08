<template>
  <div>
    <div class="row mt-3 justify-content-center">
        <h3> Bridge for your NFTs - Transfer NFTs to another chain </h3>
    </div>
    <div class="row mt-3">
      <div class="col">
        <div class="d-flex flex-row justify-content-center">

          <div class="p-2">
            <b-button
              variant="primary"
              @click="nftType = 'weapon'; displayStorage = false; selectedNftId = null"  class="gtag-link-others" tagname="show_weapons_bridge">
              Show Weapons
              </b-button>
          </div>

          <div class="p-2">
            <b-button
              variant="primary"
              @click="nftType = 'character'; displayStorage = false; selectedNftId = null"  class="gtag-link-others" tagname="show_characters_bridge">
              Show Characters
              </b-button>
          </div>

          <div class="p-2">
            <b-button
              variant="primary"
              @click="nftType = 'shield'; displayStorage = false; selectedNftId = null"  class="gtag-link-others" tagname="show_shields_bridget">
              Show Shields
              </b-button>
          </div>

          <div class="p-2">
            <b-button
              :disabled="selectedNftId == null"
              variant="primary"
              @click="transferToStorage()"  class="gtag-link-others" tagname="click_transfer_bridge">Transfer NFT to storage</b-button>
          </div>

          <div class="p-2">
            <b-button
              variant="primary"
              @click="displayStorage = true; showStorage()"  class="gtag-link-others" tagname="click_transfer_bridge">Show Storage</b-button>
          </div>

          <div class="p-2">
            <b-button
              :disabled="!displayStorage"
              variant="primary"
              @click="withdrawItem()"  class="gtag-link-others" tagname="click_transfer_bridge">Withdraw from Storage</b-button>
          </div>

          <div class="p-2">
            <b-button
              :disabled="!displayStorage"
              variant="primary"
              @click="displayStorage; requestBridge()"  class="gtag-link-others" tagname="click_transfer_bridge">Request Transfer</b-button>
          </div>

        </div>
      </div>
    </div>

    <div class="sell-grid" v-if="!displayStorage">
      <div class="sell-grid" v-if="nftType === 'weapon'">
      <weapon-grid
          v-model="selectedNftId"
          :showReforgedWeaponsDefVal="false"
          :showFavoriteWeaponsDefVal="false"
          :canFavorite="false"
          :weaponIds="allSearchResults"
        />
      </div>

      <div class="sell-grid" v-if="nftType === 'character'">
        <character-list
          :showFilters="true"
          v-model="selectedNftId"
        />
      </div>

      <div class="sell-grid" v-if="nftType === 'shield'">
        <nft-list
          :isShop="false"
          v-model="selectedNftId"
          :canFavorite="false"
        />
      </div>
    </div>


    <div class="sell-grid" v-if="displayStorage">
      <h3>Your stored NFTs</h3>
      {{selectedStorageType}}
      <select class="form-control" v-model="selectedStorageType" @change="getStoredIds">
        <option v-for="x in ['Weapons', 'Characters', 'Shields']" :value="x" :key="x">{{ x || 'Any' }}</option>
      </select>

    <div v-if="selectedStorageType == 'Weapons'">
    <weapon-grid
        v-model="selectedNftId"
        :showReforgedWeaponsDefVal="false"
        :showFavoriteWeaponsDefVal="false"
        :showReforgedToggle="false"
        :showFavoriteToggle="false"
        :canFavorite="false"
        :weaponIds="storedNftsIds"
        :showGivenWeaponIds="true"
      />
    </div>
    <div v-if="selectedStorageType == 'Characters'">
      <character-list
        :showFilters="false"
        v-model="selectedNftId"
        :showGivenCharacterIds="true"
        :characterIds="storedNftsIds"
      />
    </div>
    <div v-if="selectedStorageType == 'Shields'">
      <nft-list
        :isShop="false"
        v-model="selectedNftId"
        :canFavorite="false"
        :nftIdTypes="storedNftsIds"
      />
    </div>
    </div>
  </div>
</template>
<script lang="ts">
import Vue from 'vue';
import { mapActions, mapGetters } from 'vuex';
import { isNftType, Nft, allNftTypes } from '../interfaces/Nft';
import { Accessors } from 'vue/types/options';
import { Contract, Contracts } from '@/interfaces';
//import BigButton from '../components/BigButton.vue';
import { NftIdType } from '@/components/smart/NftList.vue';
import { Characters, Shields, Weapons } from '../../../build/abi-interfaces';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import NftList from '../components/smart/NftList.vue';
import { fromWeiEther } from '@/utils/common';
import BigNumber from 'bignumber.js';
//import CurrencyConverter from '../components/CurrencyConverter.vue';

interface StoreMappedGetters {
  contracts: Contracts;
  weaponsWithIds(ids: (string | number)[]): Nft[];
  nftsWithIdType(nftIdType: NftIdType[]): Nft[];
  shieldsWithIds(ids: string[]): Nft[];
  charactersWithIds(ids: (string | number)[]): Nft[];
  ownCharacters: any[];
}
interface StoreMappedActions {
  fetchShields(shieldIds: (string | number)[]): Promise<void>;
  fetchWeapons(weaponIds: (string | number)[]): Promise<void>;
  fetchCharacters(characterIds: (string | number)[]): Promise<void>;
  checkMarketItemOwnership(payload: {
    nftContractAddr: string;
    tokenId: string | number;
  }): Promise<string>;
  fetchMarketNftPrice(payload: {
    nftContractAddr: string;
    tokenId: string | number;
  }): Promise<string>;
  purchaseMarketListing(payload: {
    nftContractAddr: string;
    tokenId: string;
    maxPrice: string;
  }): Promise<{ seller: string; nftID: string; price: string }>;
  fetchAllMarketNftIds(payload: { nftContractAddr: string }): Promise<string[]>;
  storeItem(payload: {
    nftContractAddr: string;
    tokenId: string}): Promise<void>;
  getStorageItemIds(payload: {
    nftContractAddr: string;}): Promise<string[]>;
  getNumberOfStoragedItems(payload: {
    nftContractAddr: string;}): Promise<string>;
  withdrawFromStorage(payload: {
    nftContractAddr: string;
    tokenId: string}): Promise<void>;
}

export default Vue.extend({
  props: {
    nftTypeProp: {
      type: String,
      validator(type) {
        return isNftType(type);
      },
    },
    nftIdProp: {
      type: String,
    },
  },

  data() {
    return {
      weapon: null as Nft | null,
      character: null as Nft | null,
      shield: null as Nft | null,
      allNftTypes,
      ownerAddress: '',
      nftType: '',
      nftId: '',
      nftPrice: '',
      activeType : 'weapon',
      selectedNftId: '',
      storedNftsIds: [],
      selectedStorageType: 'Weapons',
      displayStorage: false,
    };
  },

  computed: {
    ...(mapGetters([
      'contracts',
      'weaponsWithIds',
      'nftsWithIdType',
      'shieldsWithIds',
      'charactersWithIds',
      'ownCharacters',
    ]) as Accessors<StoreMappedGetters>),

    isKnownNftType(): boolean {
      return isNftType(this.nftType);
    },

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

    Shields(): Contract<Shields> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Shields!;
    },

    contractAddress(): string {
      return this.nftType === 'weapon'
        ? this.Weapons.options.address
        : this.nftType === 'character'
          ? this.Characters.options.address
          : this.Shields.options.address;
    },
    canPurchase(): boolean {
      return this.ownCharacters.length < 4;
    },
  },

  methods: {
    ...(mapActions([
      'fetchShields',
      'fetchWeapons',
      'fetchCharacters',
      'checkMarketItemOwnership',
      'fetchMarketNftPrice',
      'purchaseMarketListing',
      'fetchAllMarketNftIds',
      'storeItem',
      'getStorageItemIds',
      'getNumberOfStoragedItems',
      'withdrawFromStorage'
    ]) as StoreMappedActions),
    async requestBridge(){

    },
    async withdrawItem(){
      const res = await this.withdrawFromStorage({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
      });
      console.log(res);
    },
    async getStoredIds(){
      if(this.selectedStorageType === 'Weapons')this.nftType = 'weapon';
      if(this.selectedStorageType === 'Characters')this.nftType = 'character';
      if(this.selectedStorageType === 'Characters')this.nftType = 'character';
      const results: any = await this.getStorageItemIds({
        nftContractAddr: this.contractAddress,
      });
      this.storedNftsIds = results;
      console.log('results: ', results);
    },
    async showStorage(){
      this.activeType = 'storage';
      const getNumberOfStoragedItems = await this.getNumberOfStoragedItems({nftContractAddr: this.contractAddress,});
      console.log(getNumberOfStoragedItems);
      const storedItemIds: any = await this.getStorageItemIds({
        nftContractAddr: this.contractAddress,
      });
      console.log('results: ', storedItemIds);
      this.storedNftsIds = storedItemIds;
    },
    async transferToStorage(){
      const res = await this.storeItem({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId});

      console.log('results: ', res);

    },
    displayCharacter(): void {
      this.character = this.charactersWithIds([this.nftId]).filter(Boolean)[0];
    },
    displayWeapon(): void {
      this.weapon = this.weaponsWithIds([this.nftId]).filter(Boolean)[0];
    },
    displayShield(): void {
      this.shield = this.shieldsWithIds([this.nftId]).filter(Boolean)[0];
    },
    capitalizeText(text: string) {
      return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
    },
    async fetchOwnerAddress() {
      if (this.nftId) {
        this.ownerAddress = await this.checkMarketItemOwnership({
          nftContractAddr: this.contractAddress,
          tokenId: this.nftId,
        });
      }
    },
    async searchForNft() {
      if (this.nftId) {
        this.clearNfts();
        if (this.nftType === 'character') {
          await this.fetchCharacters([this.nftId]);
          this.displayCharacter();
        } else if (this.nftType === 'weapon') {
          await this.fetchWeapons([this.nftId]);
          this.displayWeapon();
        } else if (this.nftType === 'shield') {
          await this.fetchShields([this.nftId]);
          this.displayShield();
        }
        await this.fetchOwnerAddress();
        await this.fetchNftPrices();
        this.switchPath();
      } else {
        this.clearNfts();
      }
    },
    switchPath() {
      const oldPath = (this as any).$router.currentRoute.path;
      const newPath = `/nft-display/${this.nftType}/${this.nftId}`;
      if (oldPath !== newPath) {
        (this as any).$router.push(newPath);
      }
    },
    clearNfts() {
      this.character = null;
      this.weapon = null;
      this.shield = null;
      this.ownerAddress = '';
    },
    copyNftUrl() {
      const dummy = document.createElement('input'),
        text = window.location.href;
      document.body.appendChild(dummy);
      dummy.value = text;
      dummy.select();
      document.execCommand('copy');
      document.body.removeChild(dummy);
    },
    convertWeiToSkill(wei: string): string {
      return fromWeiEther(wei);
    },
    maxPrecisionSkill(listedPrice: string): string {
      return this.convertStringToDecimal(
        this.convertWeiToSkill(listedPrice),
        8
      );
    },
    convertStringToDecimal(val: string, maxDecimals: number) {
      return new BigNumber(val).toFixed(maxDecimals);
    },
    async purchaseNft() {
      if (this.nftId === null) return;

      const price = await this.lookupNftPrice(this.nftId);
      if (!price) return;

      const skillChainPrice = this.convertStringToDecimal(
        this.convertWeiToSkill(price),
        2
      );
      const skillUIPrice = this.convertStringToDecimal(
        this.nftPriceInSkill(),
        2
      );

      if (skillChainPrice !== skillUIPrice) {
        (this as any).$dialog.notify.error(
          'The price of the listing has changed. Please refresh listing and try again'
        );
        return;
      }

      await this.purchaseMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.nftId,
        maxPrice: price,
      });

      await this.fetchAllMarketNftIds({
        nftContractAddr: this.contractAddress,
      });
      await this.fetchOwnerAddress();
    },
    async lookupNftPrice(id: string) {
      if (!this.contractAddress) return;

      return await this.fetchMarketNftPrice({
        nftContractAddr: this.contractAddress,
        tokenId: id,
      });
    },
    async fetchNftPrices() {
      if (!this.contractAddress) return;

      this.nftPrice = '';
      const price = await this.lookupNftPrice(this.nftId);
      if (price) {
        this.nftPrice = price;
      }
    },
    nftPriceInSkill() {
      return this.convertWeiToSkill(this.nftPrice);
    },
  },

  mounted() {
    if (this.nftTypeProp && this.nftIdProp) {
      this.nftType = this.nftTypeProp;
      this.nftId = this.nftIdProp;
      this.searchForNft();
    } else {
      this.nftType = 'weapon';
    }
  },

  components: {
    WeaponGrid,
    CharacterList,
    NftList,
  },
});
</script>

<style scoped>
.encounter-button {
  display: block;
  margin: 2px auto;
  height: 5em;
  width: 20em;
  position: relative;
}

.character-list {
  transform: scale(1.5);
}

.nft-list,
.weapon-grid {
  transform: scale(2);
}

/deep/ .weapon-grid {
  justify-items: center;
}

.search-button {
  width: 100%;
}

.search-input-id,
.search-input-type {
  margin-top: 5px;
  width: 22em;
}

.copy-url-button,
.search-button {
  margin-top: 30px;
}

.nft-display {
  height: auto;
}

.search-result-section {
  padding-top: 100px;
}

.search-section {
  border-right: 1px solid #9e8a57;
}

.result-row-section,
.search-row-section {
  flex-direction: column;
  align-content: center;
}

.result-row-section {
  align-items: center;
}

.owned-by,
.info-text {
  text-align: center;
}

.owned-by {
  margin-top: 150px;
  word-break: break-all;
  padding-left: 20px;
  padding-right: 20px;
}

.search-input-section {
  display: flex;
  justify-content: space-evenly;
}

.m-top-negative-5 {
  margin-top: -5px;
}

.disabled-button {
  opacity: 0.65;
}

@media (max-width: 576px) {
  .nft-list,
  .weapon-grid,
  .character-list {
    transform: scale(1);
  }

  .nft-list,
  .weapon-grid {
    padding-left: 0;
  }
  .owned-by {
    margin-top: 50px;
  }
}
</style>
