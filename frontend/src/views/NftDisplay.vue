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
          />

          <character-list
            v-else-if="character"
            class="character-list"
            :characterIds="[this.character.id]"
            :showGivenCharacterIds="true"
          />

          <nft-list
            v-else-if="shield"
            class="nft-list"
            :nftIdTypes="[{ id: shield.id, type: shield.type }]"
            :showGivenNftIdTypes="true"
            :isReward="true"
          />

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

interface StoreMappedGetters {
  contracts: Contracts;
  weaponsWithIds(ids: (string | number)[]): Nft[];
  nftsWithIdType(nftIdType: NftIdType[]): Nft[];
  shieldsWithIds(ids: string[]): Nft[];
  charactersWithIds(ids: (string | number)[]): Nft[];
}
interface StoreMappedActions {
  fetchShields(shieldIds: (string | number)[]): Promise<void>;
  fetchWeapons(weaponIds: (string | number)[]): Promise<void>;
  fetchCharacters(characterIds: (string | number)[]): Promise<void>;
  checkMarketItemOwnership(payload: {
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
    };
  },

  computed: {
    ...(mapGetters([
      'contracts',
      'weaponsWithIds',
      'nftsWithIdType',
      'shieldsWithIds',
      'charactersWithIds',
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
  },

  methods: {
    ...(mapActions([
      'fetchShields',
      'fetchWeapons',
      'fetchCharacters',
      'checkMarketItemOwnership',
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

  components: { BigButton, WeaponGrid, CharacterList, NftList },
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
  margin-top: 100px;
}

.search-input-section {
  display: flex;
  justify-content: space-evenly;
}
</style>
