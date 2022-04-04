<template>
  <div class="p-1">
    <h2 class="mt-3">{{ $t('admin.blacksmith.setFlatPriceOfItem') }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-form-select class="mt-2 mb-2" v-model="selectedNonSeriesItem.id">
        <b-form-select-option :value="undefined" disabled>
          {{ $t('admin.blacksmith.pleaseSelectNonSeriesItem') }}
        </b-form-select-option>
        <b-form-select-option v-for="nonSeriesItem in nonSeriesItems" :key="nonSeriesItem" :value="nonSeriesItem">
          {{ $t(`admin.blacksmith.nonSeriesItem.${NonSeriesItem[nonSeriesItem]}`) }}
        </b-form-select-option>
      </b-form-select>
      <b-form-input v-model="selectedNonSeriesItem.price" :placeholder="$t('admin.blacksmith.nonSeriesItemPrice')"/>
      <b-button @click="setPriceOfNonSeriesItem()" :disabled="setFlatPriceOfItemButtonDisabled" variant="primary"
                class="text-nowrap">
        {{ $t('admin.blacksmith.setFlatPriceOfItem') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.blacksmith.setFlatPriceOfItemSeries') }}</h2>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';

enum NonSeriesItem {
  ITEM_WEAPON_RENAME = 1,
  ITEM_CHARACTER_RENAME,
  ITEM_CHARACTER_TRAITCHANGE_FIRE,
  ITEM_CHARACTER_TRAITCHANGE_EARTH,
  ITEM_CHARACTER_TRAITCHANGE_WATER,
  ITEM_CHARACTER_TRAITCHANGE_LIGHTNING,
  ITEM_SHIELD = 9,
}

enum SeriesItem {
  ITEM_COSMETIC_WEAPON = 7,
  ITEM_COSMETIC_CHARACTER = 8,
}

interface SelectedNonSeriesItem {
  id?: NonSeriesItem;
  price?: number;
}

interface SelectedSeriesItem {
  id?: SeriesItem;
  indices: WeaponCosmetic[] | CharacterCosmetic[];
  prices: number[];
}

enum WeaponCosmetic {
  GRAYSCALE = 1,
  CONTRAST,
  SEPIA,
  INVERT,
  BLUR,
  FIRE_GLOW,
  EARTH_GLOW,
  LIGHTNING_GLOW,
  WATER_GLOW,
  RAINBOW_GLOW,
  DARK_GLOW,
  GHOST,
  POLICE,
  NEON_BORDER,
  ROTATING_NEON_BORDER,
  DIAMOND_BORDER,
  GOLD_BORDER,
  SILVER_BORDER,
  BRONZE_BORDER,
}

enum CharacterCosmetic {
  GRAYSCALE = 1,
  CONTRAST,
  SEPIA,
  INVERT,
  BLUR,
  FIRE_GLOW,
  EARTH_GLOW,
  LIGHTNING_GLOW,
  WATER_GLOW,
  RAINBOW_GLOW,
  DARK_GLOW,
  GHOST,
  POLICE,
  NEON_BORDER,
  DIAMOND_BORDER,
  GOLD_BORDER,
  SILVER_BORDER,
  BRONZE_BORDER,
}

interface StoreMappedActions {
  setFlatPriceOfItem(payload: { itemIndex: NonSeriesItem, price: number }): Promise<void>;

  setFlatPriceOfItemSeries(payload: { itemIndex: SeriesItem, indices: WeaponCosmetic[] | CharacterCosmetic[], prices: number[] }): Promise<void>;
}

interface Data {
  selectedNonSeriesItem: SelectedNonSeriesItem;
  selectedSeriesItem: SelectedSeriesItem;
  nonSeriesItems: NonSeriesItem[];
  seriesItems: SeriesItem[];
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      selectedNonSeriesItem: {
        id: undefined,
        price: undefined,
      },
      selectedSeriesItem: {
        id: undefined,
        indices: [],
        prices: [],
      },
      nonSeriesItems: [
        NonSeriesItem.ITEM_WEAPON_RENAME,
        NonSeriesItem.ITEM_CHARACTER_RENAME,
        NonSeriesItem.ITEM_CHARACTER_TRAITCHANGE_FIRE,
        NonSeriesItem.ITEM_CHARACTER_TRAITCHANGE_EARTH,
        NonSeriesItem.ITEM_CHARACTER_TRAITCHANGE_WATER,
        NonSeriesItem.ITEM_CHARACTER_TRAITCHANGE_LIGHTNING,
        NonSeriesItem.ITEM_SHIELD,
      ],
      seriesItems: [
        SeriesItem.ITEM_COSMETIC_WEAPON,
        SeriesItem.ITEM_COSMETIC_CHARACTER,
      ],
      weaponCosmetics: [
        WeaponCosmetic.GRAYSCALE,
        WeaponCosmetic.CONTRAST,
        WeaponCosmetic.SEPIA,
        WeaponCosmetic.INVERT,
        WeaponCosmetic.BLUR,
        WeaponCosmetic.FIRE_GLOW,
        WeaponCosmetic.EARTH_GLOW,
        WeaponCosmetic.LIGHTNING_GLOW,
        WeaponCosmetic.WATER_GLOW,
        WeaponCosmetic.RAINBOW_GLOW,
        WeaponCosmetic.DARK_GLOW,
        WeaponCosmetic.GHOST,
        WeaponCosmetic.POLICE,
        WeaponCosmetic.NEON_BORDER,
        WeaponCosmetic.ROTATING_NEON_BORDER,
        WeaponCosmetic.DIAMOND_BORDER,
        WeaponCosmetic.GOLD_BORDER,
        WeaponCosmetic.SILVER_BORDER,
        WeaponCosmetic.BRONZE_BORDER,
      ],
      characterCosmetics: [
        CharacterCosmetic.GRAYSCALE,
        CharacterCosmetic.CONTRAST,
        CharacterCosmetic.SEPIA,
        CharacterCosmetic.INVERT,
        CharacterCosmetic.BLUR,
        CharacterCosmetic.FIRE_GLOW,
        CharacterCosmetic.EARTH_GLOW,
        CharacterCosmetic.LIGHTNING_GLOW,
        CharacterCosmetic.WATER_GLOW,
        CharacterCosmetic.RAINBOW_GLOW,
        CharacterCosmetic.DARK_GLOW,
        CharacterCosmetic.GHOST,
        CharacterCosmetic.POLICE,
        CharacterCosmetic.NEON_BORDER,
        CharacterCosmetic.DIAMOND_BORDER,
        CharacterCosmetic.GOLD_BORDER,
        CharacterCosmetic.SILVER_BORDER,
        CharacterCosmetic.BRONZE_BORDER,
      ],
      isLoading: false,
      SeriesItem,
      NonSeriesItem,
      WeaponCosmetic,
      CharacterCosmetic,
    } as Data;
  },

  computed: {
    setFlatPriceOfItemButtonDisabled(): boolean {
      return this.selectedNonSeriesItem.id === undefined
        || this.selectedNonSeriesItem.price === undefined
        || this.isLoading;
    },
  },

  methods: {
    ...mapActions([
      'setFlatPriceOfItem',
      'setFlatPriceOfItemSeries',
    ]) as StoreMappedActions,

    async setPriceOfNonSeriesItem() {
      if (this.setFlatPriceOfItemButtonDisabled) return;
      try {
        this.isLoading = true;
        await this.setFlatPriceOfItem({
          itemIndex: this.selectedNonSeriesItem.id,
          price: this.selectedNonSeriesItem.price
        });
        this.selectedNonSeriesItem.id = undefined;
        this.selectedNonSeriesItem.price = undefined;
      } finally {
        this.isLoading = false;
      }
    },

    clearInputs() {
      this.selectedNonSeriesItem.id = undefined;
      this.selectedNonSeriesItem.price = undefined;
    }
  },
});
</script>

<style scoped>
</style>
