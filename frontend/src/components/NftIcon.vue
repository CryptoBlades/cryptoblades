<template>
  <div v-bind:class="isDefault ? 'default-icon-wrapper' : 'nft-icon-wrapper'">
    <div v-if="isDefault" class="nft-default-icon">
      <img class="default-placeholder" v-if="nft.type === 'weapon'" src="../assets/placeholder/sword-placeholder-1.png"
        v-tooltip="'Weapons (2-5*)'"/>
      <div v-if="nft.type === 'weapon'" class="default-info">2-5*</div>

      <img class="default-placeholder" v-if="nft.type === 'junk'" src="../assets/bounty.png"
        v-tooltip="'Junk (1-5*)'" />
      <img class="default-trinket-placeholder" v-if="nft.type === 'trinket'" src="../assets/trinkets/trinket1.png"
        v-tooltip="'Trinket (1-5*)'" />
      <img class="default-placeholder" v-if="nft.type === 'secret'" src="../assets/secret.png"
        v-tooltip="'Secret (??)'" />
      <img class="default-dust-placeholder" v-if="nft.type === 'lbdust'" src="../assets/dusts/LesserDust.png"
        v-tooltip="'Lesser Dust'" />
      <img class="default-dust-placeholder" v-if="nft.type === '4bdust'" src="../assets/dusts/greaterDust.png"
        v-tooltip="'Greater Dust'" />
      <img class="default-dust-placeholder" v-if="nft.type === '5bdust'" src="../assets/dusts/powerfulDust.png"
        v-tooltip="'Powerful Dust'" />
    </div>

    <div v-if="!isDefault" class="nft-icon"
      v-tooltip="!isShop && { content: tooltipHtml , trigger: (isMobile() ? 'click' : 'hover') }"
      @mouseover="hover = !isMobile() || true"
      @mouseleave="hover = !isMobile()"
    >
      <!-- show nft with id: nftId of type: nftfType (contract address?)
        either load properties here or wherever the list of nfts is created and pass in nft object-->
      <div v-if="nft.type === 'shield'" class="nft-details glow-container" ref="el" :class="['glow-' + (nft.stars || 0)]">
        <img class="placeholder-shield" src="../assets/shield1.png" v-if="!isShop && nft.id < 10000" />
        <img class="placeholder-shield" src="../assets/shield2.png" v-if="!isShop && nft.id >= 10000 && nft.id < 25000" />
        <img class="placeholder-shield" src="../assets/shield2.png" v-if="isShop" />

        <div v-if="!isShop" class="trait">
          <span :class="nft.element.toLowerCase() + '-icon'"></span>
          <b-icon v-if="favorite" class="favorite-star" icon="star-fill" variant="warning" />
        </div>

        <span v-if="isShop" class="nft-supply">Supply left: {{totalShieldSupply}}</span>
        <div v-if="!isShop" class="id">ID {{ nft.id }}</div>

        <div v-if="!isShop" class="stats">
          <div v-if="nft.stat1Value">
            <span :class="nft.stat1.toLowerCase() + '-icon'" class="mr-1 icon"></span>
            <span :class="nft.stat1.toLowerCase()">{{ nft.stat1 }} +{{ nft.stat1Value }}</span>
          </div>
          <div v-if="nft.stat2Value">
            <span :class="nft.stat2.toLowerCase() + '-icon'" class="mr-1 icon"></span>
            <span :class="nft.stat2.toLowerCase()">{{ nft.stat2 }} +{{ nft.stat2Value }}</span>
          </div>
          <div v-if="nft.stat3Value">
            <span :class="nft.stat3.toLowerCase() + '-icon'" class="mr-1 icon"></span>
            <span :class="nft.stat3.toLowerCase()">{{ nft.stat3 }} +{{ nft.stat3Value }}</span>
          </div>
        </div>
      </div>

      <div v-if="nft.type === 'weapon'" class="nft-details glow-container" ref="el" :class="['glow-' + (nft.stars || 0)]">
          <img class="placeholder-shield" src="../assets/placeholder/sword-placeholder-3.png" />
          <div v-if="!isShop" class="id">ID {{ nft.id }}</div>

          <div v-if="!isShop" class="stats">
          <div v-if="nft.stat1Value">
            <span :class="nft.stat1.toLowerCase() + '-icon'" class="mr-1 icon"></span>
            <span :class="nft.stat1.toLowerCase()">{{ nft.stat1 }} +{{ nft.stat1Value }}</span>
          </div>
          <div v-if="nft.stat2Value">
            <span :class="nft.stat2.toLowerCase() + '-icon'" class="mr-1 icon"></span>
            <span :class="nft.stat2.toLowerCase()">{{ nft.stat2 }} +{{ nft.stat2Value }}</span>
          </div>
          <div v-if="nft.stat3Value">
            <span :class="nft.stat3.toLowerCase() + '-icon'" class="mr-1 icon"></span>
            <span :class="nft.stat3.toLowerCase()">{{ nft.stat3 }} +{{ nft.stat3Value }}</span>
          </div>
        </div>
      </div>

      <div v-if="nft.type === 'dustLb'" class="nft-details">
        <img class="placeholder-dust" src="../assets/dusts/LesserDust.png" />
        <div v-if="!isShop" class="amount">Amount {{ nft.amount }}</div>
      </div>

      <div v-if="nft.type === 'dust4b'" class="nft-details">
        <img class="placeholder-dust" src="../assets/dusts/greaterDust.png" />
        <div v-if="!isShop" class="amount">Amount {{ nft.amount }}</div>
      </div>

      <div v-if="nft.type === 'dust5b'" class="nft-details">
        <img class="placeholder-dust" src="../assets/dusts/powerfulDust.png" />
        <div v-if="!isShop" class="amount">Amount {{ nft.amount }}</div>
      </div>

      <div v-if="nft.type === 'trinket'" class="nft-details glow-container" ref="el" :class="['glow-' + (nft.stars || 0)]">
        <img class="placeholder-trinket" :src="getTrinketArt(nft.id)" />
        <div v-if="!isShop" class="id">ID {{ nft.id }}</div>
      </div>

      <div v-if="nft.type === 'junk'" class="nft-details glow-container" ref="el" :class="['glow-' + (nft.stars || 0)]">
        <img class="placeholder-junk" :src="getJunkArt(nft.id)" />
        <div v-if="!isShop" class="id">ID {{ nft.id }}</div>
      </div>

      <div v-if="nft.type === 'keybox'" class="nft-details">
        <img class="placeholder-keybox" src="../assets/bounty.png" />
        <div v-if="!isShop" class="id">ID {{ nft.id }}</div>
      </div>

      <div v-if="nft.type !== 'shield' && nft.type !== 'trinket' && nft.type !== 'junk' && nft.type !== 'keybox' && nft.type !== 'weapon'
        && nft.type !== 'dustLb' && nft.type !== 'dust4b' && nft.type !== 'dust5b'" class="nft-details">
        <img class="placeholder-consumable" :src="nft.image.startsWith('http') ? nft.image : imgPath(nft.image)"/>
        <span v-if="isShop" class="nft-supply">Owned: {{this.quantityOwned}}</span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions } from 'vuex';
import { getJunkArt } from '../junk-arts-placeholder';
import { getTrinketArt } from '../trinket-arts-placeholder';

export default {
  props: ['nft', 'isDefault', 'isShop', 'favorite'],
  async created() {

  },
  computed: {
    tooltipHtml() {
      if(!this.nft) return '';
      if(this.nft.type === 'dustLb') return 'Lesser Dust';
      if(this.nft.type === 'dust4b') return 'Greater Dust';
      if(this.nft.type === 'dust5b') return 'Powerful Dust';

      const wrapInSpan = (spanClass, text) => {
        return `<span class="${spanClass.toLowerCase()}">${text}</span><span class="${spanClass.toLowerCase()+'-icon'}"></span>`;
      };

      let ttHtml = `
        ${this.nft.type[0].toUpperCase() + this.nft.type.slice(1)}
        <br>
        ID: ${this.nft.id}
        <br>
        ${Array(this.nft.stars !== null && this.nft.stars !== undefined && this.nft.stars + 1 || 0).fill('★').join('')}
      `;
      if(this.nft.level > 0) {
        ttHtml += `<br>Level ${this.nft.level + 1}`;
      }

      if(this.nft.element) {
        ttHtml += `<br>Element: ${wrapInSpan(this.nft.element, this.nft.element)}`;
      }
      return ttHtml;
    }
  },

  data() {
    return {
      totalShieldSupply: 0,
      fetchSupplyInterval: 0,
      quantityOwned: 0,
      images: require.context('../assets/elements/', false, /\.png$/)
    };
  },

  methods: {
    getJunkArt,
    getTrinketArt,
    ...mapActions(['fetchTotalShieldSupply', 'fetchTotalRenameTags', 'fetchTotalWeaponRenameTags',
      'fetchTotalCharacterFireTraitChanges', 'fetchTotalCharacterEarthTraitChanges',
      'fetchTotalCharacterWaterTraitChanges', 'fetchTotalCharacterLightningTraitChanges',
      'fetchTotalSmokeBombsOwned', 'fetchTotalExpScrollsOwned']),

    imgPath(img) {
      return this.images('./' + img);
    }
  },

  async mounted() {
    if(this.nft.type === 'shield') {
      this.totalShieldSupply = 25000 - (await this.fetchTotalShieldSupply());
      this.fetchSupplyInterval = setInterval(async () => {
        this.totalShieldSupply = 25000 - (await this.fetchTotalShieldSupply());
      }, 3000);
    } else if(this.nft.type === 'CharacterRenameTag' || this.nft.type === 'CharacterRenameTagDeal') {
      this.quantityOwned = await this.fetchTotalRenameTags();
      this.fetchSupplyInterval = setInterval(async () => {
        this.quantityOwned = await this.fetchTotalRenameTags();
      }, 3000);
    } else if(this.nft.type === 'WeaponRenameTag' || this.nft.type === 'WeaponRenameTagDeal') {
      this.quantityOwned = await this.fetchTotalWeaponRenameTags();
      this.fetchSupplyInterval = setInterval(async () => {
        this.quantityOwned = await this.fetchTotalWeaponRenameTags();
      }, 3000);
    } else if(this.nft.type === 'CharacterFireTraitChange') {
      this.quantityOwned = await this.fetchTotalCharacterFireTraitChanges();
      this.fetchSupplyInterval = setInterval(async () => {
        this.quantityOwned = await this.fetchTotalCharacterFireTraitChanges();
      }, 3000);
    } else if(this.nft.type === 'CharacterEarthTraitChange') {
      this.quantityOwned = await this.fetchTotalCharacterEarthTraitChanges();
      this.fetchSupplyInterval = setInterval(async () => {
        this.quantityOwned = await this.fetchTotalCharacterEarthTraitChanges();
      }, 3000);
    } else if(this.nft.type === 'CharacterWaterTraitChange') {
      this.quantityOwned = await this.fetchTotalCharacterWaterTraitChanges();
      this.fetchSupplyInterval = setInterval(async () => {
        this.quantityOwned = await this.fetchTotalCharacterWaterTraitChanges();
      }, 3000);
    } else if(this.nft.type === 'CharacterLightningTraitChange') {
      this.quantityOwned = await this.fetchTotalCharacterLightningTraitChanges();
      this.fetchSupplyInterval = setInterval(async () => {
        this.quantityOwned = await this.fetchTotalCharacterLightningTraitChanges();
      }, 3000);
    } else if(this.nft.type === 'SmokeBomb10') {
      this.quantityOwned = await this.fetchTotalSmokeBombsOwned();
      this.fetchSupplyInterval = setInterval(async () => {
        this.quantityOwned = await this.fetchTotalSmokeBombsOwned();
      }, 3000);
    } else if(this.nft.type === 'ExpScroll') {
      this.quantityOwned = await this.fetchTotalExpScrollsOwned();
      this.fetchSupplyInterval = setInterval(async () => {
        this.quantityOwned = await this.fetchTotalExpScrollsOwned();
      }, 3000);
    }
  },

  beforeDestroy() {
    clearInterval(this.fetchSupplyInterval);
  }
};
</script>

<style scoped>
.nft-icon {
  height: 100%;
  width: 100%;
  position: relative;
  background: rgba(255, 255, 255, 0.1);
}
.nft-default-icon{
  height: 100%;
  width: 100%;
  position: relative;
  background: rgba(255, 255, 255, 0.1);
  border: 2px solid #9e8a57;
}

.default-info {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  text-align: center;
}

.nft-icon-wrapper {
  width: 12em;
  height: 12em;
}
.default-icon-wrapper {
  width: 8em;
  height: 8em;
  margin: 5px;
}
.default-placeholder {
  max-width: 100px;
  max-height: 100px;
  margin-left: 12px;
  margin-top: 8px;
  transform: scale(1);
}
.default-dust-placeholder {
  max-width: 100px;
  max-height: 100px;
  margin-left: 12px;
  margin-top: 20px;
  transform: scale(1.5);
}
.default-trinket-placeholder{
  max-width: 100px;
  max-height: 100px;
  margin-left: 12px;
  margin-top: 8px;
  transform: scale(1.75);
}
.placeholder-weapon {
  max-width: 180px;
  max-height: 180px;
  margin-left: 10px;
  margin-top: 5px;
  transform: scale(0.7);
}

.placeholder-shield {
  max-width: 160px;
  max-height: 200px;
  margin-top: -10px;
}

.placeholder-trinket {
  max-width: 160px;
  max-height: 200px;
  margin-top: 10px;
  transform: scale(1.4);
}

.placeholder-junk {
  max-width: 160px;
  max-height: 200px;
  margin-top: 10px;
  transform: scale(1.4);
}

.placeholder-keybox {
  max-width: 160px;
  max-height: 200px;
  margin-top: 40px;
  margin-left: 5px;
  transform: scale(1.2);
}

.placeholder-dust {
  max-width: 160px;
  max-height: 200px;
  margin-top: 40px;
  margin-left: 5px;
}

.placeholder-consumable {
  height: 100%;
  transform: scale(0.7);
}

.nft-supply {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
}

.nft-details {
  text-align: center;
  height: 100%;
}

.trait, .id, .stats, .amount {
  position: absolute;
}

.id {
  top: 8px;
  right: 10px;
  font-style: italic;
}

.amount {
  bottom: 5px;
  left: 0;
  right: 0;
  text-align: center;
}

.trait {
  top: 10px;
  left: 10px;
}

.stats {
  top: 35px;
  left: 10px;
}

.favorite-star {
  position: absolute;
  margin-left: 5px;
}

.glow-container {
  height: 100%;
  width: 100%;
}

.glow-container {
  border-radius: 5px;
  z-index: 540;
}

.glow-0 {
  animation: none;
}

.glow-1 {
  animation: glow-1 2000ms ease-out infinite alternate;
}

.glow-2 {
  animation: glow-2 2000ms ease-out infinite alternate;
}

.glow-3 {
  animation: glow-3 2000ms ease-out infinite alternate;
}

.glow-4 {
  animation: glow-4 2000ms ease-out infinite alternate;
}

@keyframes glow-1 {
  0% {
    box-shadow: inset 0 0 10px rgba(0, 162, 255, 0.5);
  }
  100% {
    box-shadow: inset 0 0 15px rgba(0, 162, 255, 0.5);
  }
}

@keyframes glow-2 {
  0% {
    box-shadow: inset 0 0 10px rgba(125, 0, 125, 0.5);
  }
  100% {
    box-shadow: inset 0 0 20px rgba(125, 0, 125, 0.5);
  }
}

@keyframes glow-3 {
  0% {
    box-shadow: inset 0 0 10px rgba(255, 102, 0, 0.3);
  }
  100% {
    box-shadow: inset 0 0 25px rgba(255, 102, 0, 0.3);
  }
}

@keyframes glow-4 {
  0% {
    box-shadow: inset 0 0 10px rgba(125, 0, 0, 0.5);
  }
  100% {
    box-shadow: inset 0 0 30px rgba(125, 0, 0, 0.5);
  }
}
</style>
