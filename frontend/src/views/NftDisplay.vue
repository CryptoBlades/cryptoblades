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
          </weapon-grid>

          <character-list
            v-else-if="character"
            class="character-list"
            :characterIds="[this.character.id]"
            :showGivenCharacterIds="true"
            :nftDisplay="true"
          >
          </character-list>

          <nft-list
            v-else-if="shield"
            class="nft-list"
            :nftIdTypes="[{ id: shield.id, type: shield.type }]"
            :showGivenNftIdTypes="true"
            :isReward="true"
          >
          </nft-list>

          <h3 v-else class="info-text">
            NFT search result will be displayed here
          </h3>

          <div class="btn-section">
          <div
            v-if="nftPrice && nftPrice !== '0' && (shield||weapon||character)"
            class="purchase-section"
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
              <a :href="marketLink" target="_blank" rel="noopener noreferrer">
                <big-button
                class="encounter-button btn-styled purchase-button"
                variant="primary"
                :mainText="`Buy on Bazaar!`"
                >
              </big-button>
            </a>
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

    marketLink(): string{
      return `${process.env.VUE_APP_BAZAAR_URL || 'https://bazaar.market/'}buy/${this.nftType}?id=${this.nftId}`;
    },

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

.purchase-section{
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding-top: 50px;
}
.purchase-section > span{
  font-size: 32px;
}
.character-list {
  transform: scale(1.5);
}
.nft-list,
.weapon-grid {
  transform: scale(2);
}

::v-deep .weapon-grid {
  justify-items: center;
  padding: 30px 0;
  margin: 10px 0;
}
::v-deep .character-list {
  padding: 40px 0;
  margin: 10px 0;
}
::v-deep .nft-list {
  padding: 40px 0;
  margin: 10px 0;
}
.search-button {
  width: 22em;
}
.purchase-section * {
  width: 100%;
}

.search-input-id,
.search-input-type {
  margin-top: 5px;
  width: 22em;
}

.search-button {
  margin-top: 30px;
}

.copy-url-button{
  margin-top: 10px;
}

.btn-section{
  margin-top:20px;
  display: flex;
  flex-direction: column;
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

.info-text {
  text-align: center;
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
    transform: scale(1.25);
  }

  .nft-list,
  .weapon-grid {
    padding-left: 0;
  }
  .copy-url-button {
    margin-top: 10px;
  }
}
</style>
