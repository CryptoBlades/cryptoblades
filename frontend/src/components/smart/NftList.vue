import { Nft } from '@/views/Market.vue';
import { Nft } from '@/views/Market.vue';
<template>
  <div>
    <div class="centered-text-div" v-if="isShop && (!nfts || nfts.length === 0)">
      <span>Nothing to buy at this time</span>
    </div>
    <ul v-if="isShop" class="nft-grid">
      <li class="nft" v-for="nft in nfts" :key="nft.nftType + nft.nftId">
        <nft-icon :nft="nft" :isShop="isShop"/>
        <b-button
          variant="primary"
          class="shop-button"
          @click="onShieldBuy()"
          v-if="isShop">
          <span class="gtag-link-others" tagname="forge_weapon">
            Buy ({{ nft.nftPrice }} SKILL)
          </span>
        </b-button>
      </li>
    </ul>

    <ul v-if="!isShop" class="nft-grid">
      <li class="nft" v-for="nft in nonIgnoredNfts" :key="nft.nftType + nft.nftId">
        <nft-icon :nft="nft" :isShop="isShop"/>
        <b-button
          variant="primary"
          class="shop-button"
          @click="onShieldBuy()"
          v-if="isShop">
          <span class="gtag-link-others" tagname="forge_weapon">
            Buy ({{ nft.nftPrice }} SKILL)
          </span>
        </b-button>
      </li>
    </ul>
  </div>
</template>

<script lang="ts">
import { mapActions, mapGetters, mapState } from 'vuex';
import NftIcon from '../NftIcon.vue';
import { Nft } from '../../views/Market.vue';
import { PropType } from 'vue';

interface NftToDisplay {
  type: string;
  id: string;
}

interface Data {
  starFilter: string;
  elementFilter: string;
  favorites: Record<number, boolean>;
  priceSort: string;
  showFavoriteNfts: boolean;
}

const sorts = [
  { name: 'Any', dir: '' },
  { name: 'Price: Low -> High', dir: 1 },
  { name: 'Price: High -> Low', dir: -1 },
];

export default {
  props: {
    nfts: {
      type: Array as PropType<Nft[]>,
      default: [] as Nft[]
    },
    showGivenNfts: {
      type: Boolean,
      default: false,
    },
    isShop: {
      type: Boolean,
      default: false,
    },
    ignore: {
      // this forces Typescript to consider a prop a certain type
      // without us specifying a "type" property;
      // Vue's "type" property is not as flexible as we need it here
      validator(x: string | number | null) {
        void x;
        return true;
      },
      default: null,
    },
    showFavoriteNftsDefVal: {
      type: Boolean,
      default: true,
    },
    showLimit: {
      type: Number,
      default: 0,
    },
  },

  data() {
    return {
      starFilter: '',
      elementFilter: '',
      favorites: {},
      priceSort: '',
      sorts,
      showFavoriteNfts: this.showFavoriteNftsDefVal,
    } as Data;
  },

  components: {
    NftIcon
  },

  computed: {
    ...mapState(['ownedShieldIds']),
    ...mapGetters(['nftsWithIdType']),

    nftsToDisplay(): NftToDisplay[] {
      return this.nfts.map(nft => { console.log(nft.nftId + ' ' + nft.nftType); return { type: nft.nftType, id: nft.nftId }; });
    },

    displayNfts(): Nft[] {
      return this.nftsWithIdType(this.nftsToDisplay).filter(Boolean);
    },

    nonIgnoredNfts(): Nft[] {
      let items: Nft[] = [];
      this.displayNfts.forEach((x) => items.push(x));

      const allIgnore: string[] = [];
      if (this.ignore) {
        allIgnore.push((this.ignore || '').toString());
      }
      // if (!this.showFavoriteNfts) {
      //   for (const key in this.favorites) {
      //     allIgnore.push(key);
      //   }
      // }
      items = items.filter((x) => allIgnore.findIndex((y) => y === x.nftId.toString()) < 0);


      if (this.starFilter) {
        items = items.filter((x) => x.stars === +this.starFilter - 1);
      }

      if (this.elementFilter) {
        items = items.filter((x) => x.element?.includes(this.elementFilter));
      }

      // if (!this.showReforgedWeapons) {
      //   items = items.filter((x) => x.bonusPower === 0);
      // }

      if (this.showLimit > 0 && items.length > this.showLimit) {
        items = items.slice(0, this.showLimit);
      }

      const favoriteNfts: Nft[] = [];
      // for (const key in this.favorites) {
      //   const i = items.findIndex((y) => y.id === +key);
      //   if (i !== -1) {
      //     favoriteWeapons.push(items[i]);
      //     items.splice(i, 1);
      //   }
      // }

      return favoriteNfts.concat(items);
    },
  },

  methods: {
    ...mapActions(['purchaseShield']),

    async onShieldBuy() {
      await this.purchaseShield();
    }
  }
};
</script>

<style>
.nft-grid {
  list-style-type: none;
  justify-content: center;
  margin: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 12em);
  gap: 0.5em;
}
.nft {
  width: 12em;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 5px;
  cursor: pointer;
  position: relative;
  overflow: hidden;
}

.centered-text-div {
  text-align: center;
}

.shop-button {
  position: relative;
  width: 12rem;
}
</style>