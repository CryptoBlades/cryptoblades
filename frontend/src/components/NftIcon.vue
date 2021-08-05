<template>
  <div v-bind:class="isDefault ? 'default-icon-wrapper' : 'nft-icon-wrapper'">

    <div v-if="!isDefault" class="nft-icon"
      v-tooltip="{ content: tooltipHtml , trigger: (isMobile() ? 'click' : 'hover') }"
      @mouseover="hover = !isMobile() || true"
      @mouseleave="hover = !isMobile()"
    >
      <!-- show nft with id: nftId of type: nftfType (contract address?)
        either load properties here or wherever the list of nfts is created and pass in nft object-->
      <div v-if="nft.nftType === 'shield'" class="nft-details glow-container" ref="el" :class="['glow-' + (nft.stars || 0)]">
        <img class="placeholder-shield" src="../assets/shield1.png"/>

        <div v-if="!isShop" class="trait">
          <span :class="nft.element.toLowerCase() + '-icon'"></span>
          <!-- <b-icon v-if="favorite" class="favorite-star" icon="star-fill" variant="warning" /> -->
        </div>

        <span v-if="isShop" class="nft-supply">Supply left: {{totalShieldSupply}}</span>
        <div v-if="!isShop" class="id">ID {{ nft.nftId }}</div>

        <div class="stats">
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
    </div>
  </div>
</template>

<script>
import { mapActions } from 'vuex';
export default {
  props: ['nft', 'isDefault', 'isShop'],

  computed: {
    tooltipHtml() {
      if(!this.nft) return '';

      const wrapInSpan = (spanClass, text) => {
        return `<span class="${spanClass.toLowerCase()}">${text}</span><span class="${spanClass.toLowerCase()+'-icon'}"></span>`;
      };

      let ttHtml = `
        ID: ${this.nft.id}
        <br>
        ${Array(this.nft.stars + 1).fill('★').join('')}
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
    };
  },

  methods: {
    ...mapActions(['fetchTotalShieldSupply']),
  },

  mounted() {
    if(this.nft.nftType === 'shield') {
      this.fetchSupplyInterval = setInterval(async () => {
        this.totalShieldSupply = 10000 - (await this.fetchTotalShieldSupply());
      }, 3000);
    }
  },

  beforeDestroy() {
    clearInterval(this.fetchSupplyInterval);
  }
};
</script>

<style>
.nft-icon {
  height: 100%;
  width: 100%;
  position: relative;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid #9e8a57;
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

.nft-supply {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
}

.nft-details {
  text-align: center;
}

.trait, .id, .stats {
  position: absolute;
}

.id {
  top: 8px;
  right: 10px;
  font-style: italic;
}

.trait {
  top: 10px;
  left: 10px;
}

.stats {
  top: 35px;
  left: 10px;
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
  animation: glow-4 2000ms ease-out infinite alternate;
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
</style>