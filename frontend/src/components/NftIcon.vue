<template>
  <div v-bind:class="isDefault ? 'default-icon-wrapper' : 'nft-icon-wrapper'">
    <div v-if="isDefault" class="nft-default-icon">
      <img class="default-placeholder" v-if="nft.type === 'weapon'" src="../assets/placeholder/sword-placeholder-1.png"
        v-tooltip="$t('nftIcon.weaponTooltip', {stars: stars || '2-5'})"/>
      <div v-if="nft.type === 'weapon'" class="default-info">{{stars || '2-5'}}*</div>
      <img class="default-junk-placeholder" v-if="nft.type === 'junk'" src="../assets/junk/junk3.png"
        v-tooltip="$t('nftIcon.junkTooltip', {stars: stars || '1-5'})" />
      <div v-if="nft.type === 'junk'" class="default-info">{{stars || '1-5'}}*</div>
      <img class="default-trinket-placeholder" v-if="nft.type === 'trinket'" src="../assets/trinkets/trinket1.png"
        v-tooltip="$t('nftIcon.trinketTooltip', {stars: stars || '1-5'})" />
      <div v-if="nft.type === 'trinket'" class="default-info">{{stars || '1-5'}}*</div>
      <img class="default-shield-placeholder" v-if="nft.type === 'shield'" src="../assets/shield2.png"
        v-tooltip="$t('nftIcon.shieldTooltip', {stars: stars || '1-5'})" />
      <div v-if="nft.type === 'shield'" class="default-info">{{stars || '1-5'}}*</div>
      <img class="default-placeholder" v-if="nft.type === 'secret'" src="../assets/secret.png"
        v-tooltip="$t('nftIcon.secretTooltip')" />
      <img class="default-dust-placeholder" v-if="nft.type === 'lbdust'" src="../assets/dusts/lesserDust.png"
        v-tooltip="$t('nftIcon.lesserDust')" />
      <img class="default-dust-placeholder" v-if="nft.type === '4bdust'" src="../assets/dusts/greaterDust.png"
        v-tooltip="$t('nftIcon.greaterDust')" />
      <img class="default-dust-placeholder" v-if="nft.type === '5bdust'" src="../assets/dusts/powerfulDust.png"
        v-tooltip="$t('nftIcon.powerfulDust')" />
      <img class="default-dust-placeholder" v-if="nft.type === 'soul'" src="../assets/dusts/soulDust.png"
           v-tooltip="$t('nftIcon.soul')" />
    </div>

    <div v-if="!isDefault" class="nft-icon"
      v-tooltip="{ content: tooltipHtml , trigger: (isMobile() ? 'click' : 'hover') }"
      @mouseover="hover = !isMobile() || true"
      @mouseleave="hover = !isMobile()"
    >
      <!-- show nft with id: nftId of type: nftfType (contract address?)
        either load properties here or wherever the list of nfts is created and pass in nft object-->
      <div v-if="nft.type === 'shield'" class="nft-details glow-container" ref="el" :class="['glow-' + (nft.stars || 0)]">
        <img class="placeholder-shield" src="../assets/shield1.png" v-if="nft.id < 10000" />
        <img class="placeholder-shield" src="../assets/shield2.png" v-if="nft.id >= 10000 && nft.id < 25000" />

        <div class="trait">
          <span :class="nft.element.toLowerCase() + '-icon'"></span>
          <b-icon v-if="favorite" class="favorite-star" icon="star-fill" variant="warning" />
        </div>

        <div class="id">{{$t('nftIcon.id')}} {{ nft.id }}</div>

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

      <div v-if="nft.type === 't1land' || nft.type === 't2land' || nft.type === 't3land'
      || nft.type === 'claimT2Land' || nft.type === 'claimT3Land' " class="nft-details glow-container"
        ref="el" :class="['glow-' + (nft.stars || 0)]">
        <img class="placeholder-land" src="../assets/t1-frame.png" v-if="nft.type === 't1land'" />
        <img class="placeholder-land" src="../assets/t2-frame.png" v-if="nft.type === 't2land'" />
        <img class="placeholder-land" src="../assets/t3-frame.png" v-if="nft.type === 't3land'" />
        <img class="placeholder-land" src="../assets/t2-frame.png" v-if="nft.type === 'claimT2Land'" />
        <img class="placeholder-land" src="../assets/t3-frame.png" v-if="nft.type === 'claimT3Land'" />

        <span class="nft-supply">Chunk Id: {{nft.chunkId}}</span>
        <span v-if="nft.type === 'claimT2Land'" class="nft-supply">Lands to claim: {{ totalT2LandsToClaim }} </span>
        <span v-if="nft.type === 'claimT3Land'" class="nft-supply">Lands to claim: {{ totalT3LandsToClaim }}</span>
      </div>
      <div v-if="nft.type === 'weapon' || nft.type === 'WeaponCosmetic'" class="nft-details glow-container" ref="el" :class="['glow-' + (nft.stars || 0)]">
          <img class="placeholder-weapon" :src="nft.weaponType > 0 ? specialWeaponArts[nft.weaponType] : getWeaponArt(nft)" />

          <div class="trait">
            <span :class="nft.element.toLowerCase() + '-icon'"></span>
            <b-icon v-if="favorite" class="favorite-star" icon="star-fill" variant="warning" />
          </div>

          <div class="name">
            {{ getCleanWeaponName(nft.id, nft.stars) }}
          </div>

          <div class="id">{{$t('nftIcon.id')}} {{ nft.id }}</div>

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

      <div v-if="nft.type === 'CharacterCosmetic'" class="nft-details glow-container"
        v-bind:class="['character-cosmetic-applied-' + nft.id, 'character-animation-applied-' + nft.id]">
        <div class="animation" />
        <img class="placeholder" src="../assets/placeholder/chara-0.png" />
      </div>

      <div v-if="nft.type === 'dustLb'" class="nft-details">
        <img class="placeholder-dust" src="../assets/dusts/lesserDust.png" />
        <div class="amount">{{$t('nftIcon.amount')}} {{ nft.amount }}</div>
      </div>

      <div v-if="nft.type === 'dust4b'" class="nft-details">
        <img class="placeholder-dust" src="../assets/dusts/greaterDust.png" />
        <div class="amount">{{$t('nftIcon.amount')}} {{ nft.amount }}</div>
      </div>

      <div v-if="nft.type === 'dust5b'" class="nft-details">
        <img class="placeholder-dust" src="../assets/dusts/powerfulDust.png" />
        <div class="amount">{{$t('nftIcon.amount')}} {{ nft.amount }}</div>
      </div>

      <div v-if="nft.type === 'soul'" class="nft-details">
        <img class="placeholder-dust" src="../assets/dusts/soulDust.png" />
        <div class="amount">{{$t('nftIcon.amount')}} {{ nft.amount }}</div>
      </div>

      <div v-if="nft.type === 'trinket'" class="nft-details glow-container" ref="el" :class="['glow-' + (nft.stars || 0)]">
        <img class="placeholder-trinket" :src="getTrinketArt(nft.id)" />
        <div class="id">{{$t('nftIcon.id')}} {{ nft.id }}</div>
      </div>

      <div v-if="nft.type === 'junk'" class="nft-details glow-container" ref="el" :class="['glow-' + (nft.stars || 0)]">
        <img class="placeholder-junk" :src="getJunkArt(nft.id)" />
        <div class="id">{{$t('nftIcon.id')}} {{ nft.id }}</div>
      </div>

      <div v-if="nft.type === 'keybox'" class="nft-details">
        <img class="placeholder-keybox" src="../assets/bounty.png" />
        <div class="id">{{$t('nftIcon.id')}} {{ nft.id }}</div>
      </div>

      <div v-if="nft.type !== 'shield' && nft.type !== 'trinket' && nft.type !== 'junk' && nft.type !== 'keybox' && nft.type !== 'weapon'
        && nft.type !== 'dustLb' && nft.type !== 'dust4b' && nft.type !== 'dust5b' && nft.type !== 'soul' && nft.type !== 'WeaponCosmetic'
        && nft.type !== 'CharacterCosmetic' && nft.type !== 't1land' && nft.type !== 't2land' && nft.type !== 't3land'
        && nft.type !== 'claimT2Land' && nft.type !== 'claimT3Land'"
        class="nft-details">
        <img v-if="nft.image" class="placeholder-consumable" :src="nft.image.startsWith('http') ? nft.image : imgPath(nft.image)"/>
      </div>
    </div>
  </div>
</template>

<script>
import {mapGetters, mapState} from 'vuex';
import { getJunkArt } from '../junk-arts-placeholder';
import { getTrinketArt } from '../trinket-arts-placeholder';
import { getCleanName } from '../rename-censor';
import { getWeaponArt } from '../weapon-arts-placeholder';
import { Stat1PercentForChar, Stat2PercentForChar, Stat3PercentForChar } from '../interfaces';

export default {
  props: ['nft', 'isDefault', 'favorite', 'stars'],
  async created() {

  },
  computed: {
    ...mapState(['specialWeaponArts']),
    ...mapGetters(['getWeaponName', 'currentCharacter',]),
    tooltipHtml() {
      if(!this.nft) return '';
      if(this.nft.type === 'dustLb') return this.$t('nftIcon.lesserDust');
      if(this.nft.type === 'dust4b') return this.$t('nftIcon.greaterDust');
      if(this.nft.type === 'dust5b') return this.$t('nftIcon.powerfulDust');
      if(this.nft.type === 'soul') return this.$t('nftIcon.soul');
      if(this.nft.type === 't1') return this.$t('nftIcon.lesserDust');
      if(this.nft.type.includes('land')) return this.$t('nftIcon.land', {tier : this.nft.tier});

      const wrapInSpan = (spanClass, text) => {
        return `<span class="${spanClass.toLowerCase()}">${text}</span><span class="${spanClass.toLowerCase()+'-icon'}"></span>`;
      };

      const wrapInSpanTextOnly = (spanClass, text) => {
        return `<span class="${spanClass.toLowerCase()}">${text}</span>`;
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

      const avg = [];
      if(this.nft.stat1Value) {
        avg.push(this.nft.stat1Value);
        ttHtml += `<br>${wrapInSpan(this.nft.stat1, this.nft.stat1)}: +${this.nft.stat1Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat1PercentForChar(this.nft, +this.currentCharacter.trait)+'%')
          })`;
        }
      }

      if(this.nft.stat2Value) {
        avg.push(this.nft.stat2Value);
        ttHtml += `<br>${wrapInSpan(this.nft.stat2, this.nft.stat2)}: +${this.nft.stat2Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat2PercentForChar(this.nft, +this.currentCharacter.trait)+'%')
          })`;
        }
      }

      if(this.nft.stat3Value) {
        avg.push(this.nft.stat3Value);
        ttHtml += `<br>${wrapInSpan(this.nft.stat3, this.nft.stat3)}: +${this.nft.stat3Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat3PercentForChar(this.nft, +this.currentCharacter.trait)+'%')
          })`;
        }
      }

      if(avg.length > 0) {
        let totalStats = 0;
        avg.forEach(function (stat) {
          totalStats += stat;
        });
        ttHtml += `<br>${wrapInSpan('summary-text', this.$t('weaponGrid.average') + ': +' + (totalStats / avg.length).toFixed(2))}`;
      }

      return ttHtml;
    }
  },

  data() {
    return {
      totalShieldSupply: 0,
      totalT1LandSupply: 0,
      totalT2LandSupply: 0,
      totalT3LandSupply: 0,
      totalT2LandsToClaim: 0,
      totalT3LandsToClaim: 0,
      fetchSupplyInterval: 0,
      quantityOwned: 0,
      images: require.context('../assets/elements/', false, /\.png$/)
    };
  },

  methods: {
    getWeaponArt,
    getJunkArt,
    getTrinketArt,

    imgPath(img) {
      return this.images('./' + img);
    },

    getCleanWeaponName(id, stars) {
      return getCleanName(this.getWeaponName(id, stars));
    }
  },
};
</script>

<style scoped>
@import '../styles/weapon-cosmetics.css';
@import '../styles/character-cosmetics.css';
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
  background: rgba(4, 4, 4, 0.022);
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
  width: 5em;
  height: 5em;
  margin: 5px;
}
.default-placeholder {
  max-width: 50px;
  max-height: 50px;
  margin-left: 12px;
  margin-top: 8px;
  transform: scale(1);
}

.default-shield-placeholder {
  max-width: 150px;
  max-height: 130px;
  margin-left: 13px;
  margin-top: -9px;
}
.default-dust-placeholder {
  max-width: 70px;
  max-height: 70px;
  margin-left: 7px;
}
.default-trinket-placeholder{
  max-width: 65px;
  max-height: 65px;
  margin-left: 12px;
  margin-top: 8px;
  transform: scale(1.75);
}
.default-junk-placeholder{
  max-width: 50px;
  max-height: 50px;
  margin-left: 12px;
  margin-top: 12px;
  transform: scale(1.6);
}
.placeholder-weapon {
  max-width: 180px;
  max-height: 180px;
  margin-left: 10px;
  margin-top: 5px;
  transform: scale(0.7);
}

.placeholder {
  max-width: 180px;
  max-height: 180px;
  margin-left: 10px;
  margin-top: 5px;
  transform: scale(0.7);
}

.placeholder-shield {
  max-width: 80%;
  margin-top: -10px;
}

.placeholder-land {
  max-width: 80%;
  margin-top: 0.5rem;
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
  left: 30px;
  font-style: italic;
}

.name {
  position: absolute;
  bottom: 15px;
  left: 12%;
  right: 12%;
  font-size: 0.9em;
  text-align: center;
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
  box-shadow: inset 0 0 15px rgba(0, 162, 255, 0.5);
}

.glow-2 {
  box-shadow: inset 0 0 20px rgba(125, 0, 125, 0.5);
}

.glow-3 {
  box-shadow: inset 0 0 25px rgba(255, 102, 0, 0.3);
}

.glow-4 {
  box-shadow: inset 0 0 30px rgba(125, 0, 0, 0.5);
}

.animation {
  width: 100%;
  height: 100%;
}

.character-animation-applied-13 .animation {
  width: 0;
  height: 0;
}

.weapon-animation-applied-13 {
  width: 0;
  height: 0;
}
</style>
