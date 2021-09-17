<template>
  <div>
    <div class="row row-cols-2 nft-display">
      <div class="col-12 col-md-4 search-section">
        <div class="row search-row-section">
          <div class="col">
            <h1>Search for NFT</h1>
          </div>
          <div class="col">
            <div class="row search-input-section">
              <input
                class="form-control search search-input-id"
                type="text"
                v-model="nftId"
                placeholder="NFT ID"
                @keyup.enter="searchForNft"
              />
              <select class="form-control search-input-type" v-model="nftType">
                <option v-for="x in allNftTypes" :value="x" :key="x">
                  {{ capitalizeText(x) || "Weapon" }}
                </option>
              </select>
            </div>
          </div>

          <div class="col">
            <big-button
              class="encounter-button btn-styled search-button"
              :mainText="`Search`"
              @click="searchForNft"
            />
          </div>
        </div>
      </div>

      <div class="col-12 col-md-8 search-result-section">
        <div class="row result-row-section">
          <weapon-grid
            v-if="this.weapon"
            class="weapon-grid"
            :weaponIds="[this.weapon.id]"
            :showGivenWeaponIds="true"
            :showReforgedToggle="false"
            :showReforgedWeaponsDefVal="false"
            :showFavoriteToggle="false"
            :showFavoriteWeaponsDefVal="false"
            :canFavorite="false"
            :newWeapon="true"
          >
            <template #above="{ weapon: { id } }">
              <div
                class="
                  d-flex
                  flex-column
                  align-items-center
                  justify-content-center
                  m-top-negative-5
                "
              >
                <span
                  class="d-block text-center fix-h24"
                  v-if="nftPriceInSkill() !== '0'"
                >
                  <span
                    v-tooltip.top="{
                      content: maxPrecisionSkill(nftPrice),
                      trigger: isMobile() ? 'click' : 'hover',
                    }"
                    @mouseover="hover = !isMobile() || true"
                    @mouseleave="hover = !isMobile()"
                  >
                    <strong>Price</strong>:
                    <CurrencyConverter :skill="nftPriceInSkill()" />
                  </span>
                </span>
                <b-button
                  v-if="nftPriceInSkill() !== '0'"
                  @click="
                    nftId = id;
                    purchaseNft();
                  "
                  variant="primary"
                  class="gtag-link-others"
                >
                  Purchase
                </b-button>
              </div>
            </template>
          </weapon-grid>

          <character-list
            v-else-if="character"
            class="character-list"
            :characterIds="[this.character.id]"
            :showGivenCharacterIds="true"
            :isMarket="nftPriceInSkill() !== '0'"
            :nftDisplay="true"
          >
            <template #above="{ character: { id } }">
              <div
                class="
                  token-price
                  d-flex
                  flex-column
                  align-items-center
                  justify-content-center
                  m-top-negative-50
                "
              >
                <span
                  class="d-block text-center fix-h24"
                  v-if="nftPriceInSkill() !== '0'"
                >
                  <span
                    v-tooltip.top="{
                      content: maxPrecisionSkill(nftPrice),
                      trigger: isMobile() ? 'click' : 'hover',
                    }"
                    @mouseover="hover = !isMobile() || true"
                    @mouseleave="hover = !isMobile()"
                  >
                    <CurrencyConverter :skill="nftPriceInSkill()" />
                  </span>
                </span>

                <b-button
                  v-if="nftPriceInSkill() !== '0'"
                  @click="
                    selectedNftId = id;
                    canPurchase && purchaseNft();
                  "
                  variant="primary"
                  v-bind:class="[!canPurchase ? 'disabled-button' : '']"
                  class="gtag-link-others"
                  tagname="confirm_purchase"
                >
                  Purchase
                  <b-icon-question-circle
                    v-if="!canPurchase"
                    v-tooltip.bottom="
                      'You already have max amount of characters (4).'
                    "
                  />
                </b-button>
              </div>
            </template>
          </character-list>

          <nft-list
            v-else-if="shield"
            class="nft-list"
            :nftIdTypes="[{ id: shield.id, type: shield.type }]"
            :showGivenNftIdTypes="true"
            :isReward="true"
          >
            <template #above="{ nft: { id } }">
              <div
                class="
                  d-flex
                  flex-column
                  align-items-center
                  justify-content-center
                  m-top-negative-5
                "
              >
                <span
                  class="d-block text-center fix-h24"
                  v-if="nftPriceInSkill() !== '0'"
                >
                  <span
                    v-tooltip.top="{
                      content: maxPrecisionSkill(nftPrice),
                      trigger: isMobile() ? 'click' : 'hover',
                    }"
                    @mouseover="hover = !isMobile() || true"
                    @mouseleave="hover = !isMobile()"
                  >
                    <strong>Price</strong>:
                    <CurrencyConverter :skill="nftPriceInSkill()" />
                  </span>
                </span>
                <b-button
                  v-if="nftPriceInSkill() !== '0'"
                  @click="
                    selectedNftId = id;
                    purchaseNft();
                  "
                  variant="primary"
                  class="gtag-link-others"
                >
                  Purchase
                </b-button>
              </div>
            </template>
          </nft-list>

          <h3 v-else class="info-text">
            NFT search result will be displayed here
          </h3>

          <h3 class="owned-by" v-if="ownerAddress">
            Owned by: {{ ownerAddress }}
          </h3>

          <big-button
            v-if="ownerAddress"
            class="encounter-button btn-styled copy-url-button"
            :mainText="`Copy URL`"
            @click="copyNftUrl"
          />
        </div>
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
import BigButton from '../components/BigButton.vue';
import { NftIdType } from '@/components/smart/NftList.vue';
import { Characters, Shields, Weapons } from '../../../build/abi-interfaces';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import NftList from '../components/smart/NftList.vue';
import { fromWeiEther } from '@/utils/common';
import BigNumber from 'bignumber.js';
import CurrencyConverter from '../components/CurrencyConverter.vue';

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
    ]) as StoreMappedActions),
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
    BigButton,
    WeaponGrid,
    CharacterList,
    NftList,
    CurrencyConverter,
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

.copy-url-button {
  width: 40%;
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
</style>
