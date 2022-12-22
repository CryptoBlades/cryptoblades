<template>
  <b-tab active :title="$t('Character.equipment')" title-item-class="character-wrapper"
         title-link-class="character-tab">
    <b-card-text class="character-text mb-4">{{ $t(`Character.equipmentText`) }}</b-card-text>
    <!-- Equipment -->
    <div class="equipment-wrapper">
      <div class="drops">
        <span>{{ $t('weapon') }}</span>
        <div class="weapon-info" v-if="equippedWeaponId !== undefined && equippedWeaponId !== null">
          <span class="unequip-tooltip">{{ $t('equip.unequipWeapon') }}</span>
          <div @click="removeWeapon()">
            <img src="@/assets/swithc-wep.png" alt="">
          </div>
          <weapon-grid
            class="weapon-grid"
            :weaponIds="[equippedWeaponId]"
            :showGivenWeaponIds="true"
            :showReforgedToggle="false"
            :showReforgedWeaponsDefVal="false"
            :showFavoriteToggle="false"
            :showFavoriteWeaponsDefVal="false"
            :canFavorite="false"
            :newWeapon="true"
            :noPagination="true"
          />
        </div>
        <div class="weapon-info" v-else>
          <div class="outline-box">
            <div>
              <div @click="selectWeapon()">
                <img src="@/assets/swithc-wep.png" alt="">
              </div>
            </div>
            <div>
              <p>{{ $t('equip.noWeapon') }}</p>
              <span>{{ $t('equip.equipWeapon') }}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="drops">
        <span>{{ $t('Shield') }}</span>
        <div class="weapon-info" v-if="equippedShieldId !== undefined && equippedShieldId !== null">
          <span class="unequip-tooltip">{{ $t('equip.unequipShield') }}</span>
          <div @click="removeShield()">
            <img src="@/assets/swithc-wep.png" alt="">
          </div>
          <nft-list
            class="nft-list"
            :nftIdTypes="[{ id: equippedShieldId, type: 'shield' }]"
            :showGivenNftIdTypes="true"
            :isReward="true"
          />
        </div>
        <div class="shieldButtonWrapper" v-else>
          <div class="outline-box">
            <div>
              <a tabindex="0" class="selectWeaponButton" id="shield-popover">
                <div class="placeholderImageWrapper">
                  <img src="@/assets/shieldPlaceholder.svg" alt="shield"/>
                </div>
                <b-popover ref="popover" target="shield-popover" triggers="click blur" placement="right"
                           custom-class="popoverWrapper">
                  <p class="popoverTitle">{{ $t('pvp.shields') }}</p>
                  <div v-if="ownedShieldIds.length !== 0" class="popoverGrid">
                    <pvp-shield
                      v-for="shield in ownedShieldsWithInformation"
                      :key="shield.shieldId"
                      :shield="shield.information"
                      :shieldId="shield.shieldId"
                      @click="selectShield(shield.shieldId)"
                    />
                  </div>
                  <div v-else class="noWeaponsOrShields">
                    {{ $t('pvp.noShields') }}
                  </div>
                </b-popover>
              </a>
            </div>
            <div>
              <p>{{ $t('equip.noShield') }}</p>
              <span>{{ $t('equip.equipShield') }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </b-tab>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions, mapGetters, mapState} from 'vuex';
import Events from '@/events';
import {shieldFromContract as formatShield} from '@/contract-models';
import PvPShield from '@/components/smart/PvPShield.vue';
import WeaponGrid from '@/components/smart/WeaponGrid.vue';
import NftList from '@/components/smart/NftList.vue';
import {ICharacter} from '@/interfaces';


interface Data {
  equippedWeapon: any;
  equippedWeaponId: number | string;
  equippedShield: any;
  equippedShieldId: number | string;
  ownedShieldsWithInformation: number[];
}

interface StoreMappedActions {
  fetchWeapon(payload: { weaponId: string | number }): Promise<void>;

  fetchShield(payload: { shieldId: string | number }): Promise<void>;

  equipWeapon(payload: { equipperId: string, itemId: number | string }): Promise<void>;

  equipShield(payload: { equipperId: string, itemId: number | string }): Promise<void>;

  unequipWeapon(payload: { equipperId: string }): Promise<void>;

  unequipShield(payload: { equipperId: string }): Promise<void>;

  fetchCharacterWeapon(characterId: string | number): Promise<number>;

  fetchCharacterShield(characterId: string | number): Promise<number>;

  getShield(payload: { shieldId: string | number }): Promise<string[]>;
}

interface StoredMappedGetters {
  getEquippedWeapon(payload: { characterId: string | number }): number;

  getEquippedShield(payload: { characterId: string | number }): number;
}


export default Vue.extend({
  components: {'pvp-shield': PvPShield, WeaponGrid, NftList},
  props: {
    soulBalance: {
      type: Number,
      default: 0
    }
  },
  data(): Data {
    return {
      equippedWeapon: null,
      equippedWeaponId: '',
      equippedShield: null,
      equippedShieldId: '',
      ownedShieldsWithInformation: [],
    };
  },
  computed: {
    ...mapState([
      'ownedShieldIds',
      'currentCharacterId',
      'characters',
    ]),
    ...mapGetters([
      'getCharacterPower'
    ]),
    selectedCharacter(): ICharacter {
      return this.characters[this.currentCharacterId];
    },
  },
  methods: {
    ...mapActions([
      'fetchWeapon',
      'fetchShield',
      'equipWeapon',
      'equipShield',
      'unequipWeapon',
      'unequipShield',
      'fetchCharacterWeapon',
      'fetchCharacterShield',
      'getShield',
    ]) as StoreMappedActions,
    ...(mapGetters([
      'getEquippedWeapon',
      'getEquippedShield',
    ]) as StoredMappedGetters),

    async getShieldInformation(shieldId: number | string) {
      return formatShield(`${shieldId}`, await this.getShield(shieldId));
    },
    selectWeapon() {
      Events.$emit('weapon-inventory', true);
    },
    async removeWeapon() {
      await this.unequipWeapon({equipperId: this.currentCharacterId});
      this.equippedWeaponId = await this.fetchCharacterWeapon(this.currentCharacterId);
      //re-fetch weapon inventory
    },
    async selectShield(shieldId: number | string) {
      // todo
      await this.equipShield({equipperId: this.currentCharacterId as string, itemId: shieldId});
      //re-fetch shield inventory
    },
    async removeShield() {
      await this.unequipShield({equipperId: this.currentCharacterId});
      this.equippedShieldId = await this.fetchCharacterShield(this.currentCharacterId);
      //re-fetch shield inventory
    },
    async refreshData() {
      this.ownedShieldsWithInformation = await Promise.all(this.ownedShieldIds.map(async (shieldId: number | string) => {
        return {
          shieldId,
          information: await this.getShieldInformation(shieldId)
        };
      }));
      this.equippedWeaponId = await this.fetchCharacterWeapon(this.currentCharacterId);
      this.equippedShieldId = await this.fetchCharacterShield(this.currentCharacterId);
    }
  },
  watch: {
    async selectedCharacter(newValue) {
      if (newValue) {
        await this.refreshData();
      }
    },
  },
  async mounted() {
    console.log('mounted');
    await this.refreshData();
    Events.$on('chooseweapon', async (id: number) => {
      await this.equipWeapon({equipperId: this.currentCharacterId, itemId: id});
      await this.refreshData();
      //re-fetch weapon inventory
    });
  },

  beforeDestroy() {
    Events.$off('chooseweapon');
  }
});
</script>

<style lang="scss" scoped>
.weapon-icon-wrapper {
  background: rgba(255, 255, 255, 0.1);
  width: 12em;
  height: 12em;
  margin: 0 auto;
}

.weapon-info {
  display: flex;
  justify-content: space-between;
  flex-direction: column;
  align-items: center;
}

.weapon-info > div > p {
  color: #fff;
  margin: 0px;
}

.weapon-info > div > span {
  /* color: #fff; */
}

.weapon-info > div > img {
  width: 30px;
  cursor: pointer;
}

.drops {
  margin-top: 1em;
}

.drops-icons {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  width: 100%;
  padding: 0;
  overflow-y: hidden;
  overflow-x: hidden;
  /* border: 0.5px solid #1f1f1f; */
  /* height: 161px; */
}

.drops-icons > > > ul {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
}

.outline-box {
  display: flex;
  align-items: center;
  opacity: 0.5;
}

.outline-box > div:nth-child(1) {
  height: 70px;
  width: 70px;
  display: flex;
  justify-content: center;
  align-items: center;
  border: #ccae4f dashed 2px;
  border-radius: 5px;
}

.outline-box > div:nth-child(2) {
  padding-left: 20px;
}

.outline-box > div > p {
  margin: 0px;
  font-size: 15px;
  font-family: Roboto;
}

.outline-box > div > span {
  margin: 0px;
  font-size: 13px;
  font-family: Roboto;
}

.outline-box > div > div {
  cursor: pointer;
}

.outline-box > div > div > img {
  width: 30px;
}

.character-text {
  color: #7F8693;
}

.character-text input {
  background: #000E1D 0% 0% no-repeat padding-box;
  border: 1px solid #404857;
  border-radius: 3px;
  color: #fff;
  width: 53px;
  height: 32px;
  text-align: center;
}

.character-text button {
  background: #1E293C 0% 0% no-repeat padding-box;
  border: 1px solid #1E293C;
  border-radius: 3px;
  color: #fff;
  height: 32px;
}

.equipment-wrapper {
  display: flex;
  justify-content: space-evenly;
}

.selectWeaponButton {
  cursor: pointer;
}

/* Chrome, Safari, Edge, Opera */
.character-text input::-webkit-outer-spin-button,
.character-text input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

/* Firefox */
.character-text input[type=number] {
  -moz-appearance: textfield;
}

@media (max-width: 992px) {
  .weapon-info {
    flex-direction: column;
    align-items: center;

    > div > div {
      padding: 0 10px;
    }
  }

  .equipment-wrapper {
    flex-direction: column;
  }
}

p, li, span {
  font-family: 'Roboto';
}

.popoverWrapper {
  height: 450px;
  overflow-y: auto;
  min-width: max-content;
  padding: 0.5rem 0.5rem 1.5rem 0.5rem;
  background-color: black;
  border: 1px solid #cec198;
  box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);

  .popoverTitle {
    color: #cec198;
    font-size: 1.25rem;
    line-height: 1.75rem;
  }

  .popoverGrid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    grid-template-rows: repeat(4, 1fr);
    grid-column-gap: 1rem;
    grid-row-gap: 2rem;
    margin-top: 1rem;
  }
}

.unequip-tooltip {
  color: gray;
}

.noWeaponsOrShields {
  display: flex;
  margin: 0 auto;
  font-family: 'Roboto';
  color: #b4b0a7;
  font-size: 0.75rem;
  margin-top: 1rem;
}

</style>
