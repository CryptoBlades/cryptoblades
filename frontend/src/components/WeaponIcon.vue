<template>
  <div
    class="weapon-icon"
    v-bind:class="[(getWeaponDurability(weapon.id) === 0 ? 'no-durability' : '')]"
    @mouseover="hover = !isMobile() || true"
    @mouseleave="hover = !isMobile()"
  >

    <div class="glow-container" ref="el" :class="selected ? 'selected-border' : ['glow-' + (weapon.stars || 0)]">
      <div class="animation" v-bind:class="showCosmetics ? 'weapon-animation-applied-' + getWeaponCosmetic(weapon.id) : ''"/>
      <img v-bind:class="showCosmetics ? 'weapon-cosmetic-applied-' + getWeaponCosmetic(weapon.id) : ''"
        class="placeholder" :src="weapon.weaponType > 0 ? specialWeaponArts[weapon.weaponType] : getWeaponArt(weapon)"/>

      <div class="d-flex flex-column align-items-end stars-flex" :class="!hasNftOptions ? 'stars-flex-extend' : ''">
        <div>
          <b-icon v-for="s in weapon.stars+1"  :key="s" class="star-stat" icon="star-fill" variant="warning" />
        </div>
        <div v-if="selected">
          <span class="rounded-check"></span>
        </div>
      </div>

      <div class="favorite">
        <span v-if="favorite" class="favorite-weapon"></span>
      </div>
      <div class="weapon-details" :style="weapon.lowStarBurnPoints > 0
        || weapon.fourStarBurnPoints > 0
        || weapon.fiveStarBurnPoints > 0
        ? 'margin-top: -20px' : 'margin-top: 0px'">

        <div class="name">
          <div>
            <div class="id-number">{{$t('weaponIcon.id')}}: #{{ weapon.id }}</div>
            <span span>{{ getCleanWeaponName(weapon.id, weapon.stars).toUpperCase() }}</span>
          </div>
          <span class="icon-trait" :class="weapon.element.toLowerCase() + '-icon'"></span>
          <span class="battle-p">Battle Power: {{weapon.stat1Value + weapon.stat2Value + weapon.stat3Value}}</span>
        </div>
        <div>
          <div class="small-durability-bar"
            :style="`--durabilityReady: ${(getWeaponDurability(weapon.id)/maxDurability)*100}%;`"
            v-tooltip.bottom="`
              ${$t('weaponIcon.durability')} ${getWeaponDurability(weapon.id)}/${maxDurability}<br>
              ${getWeaponDurability(weapon.id) === maxDurability ?
              $t('weaponIcon.durabilityTooltipFull') : `${$t('weaponIcon.durabilityTooltip')} ${timeUntilWeaponHasMaxDurability(weapon.id)}` }
              `">
          </div>
        </div>
        <div class="bonus-pows">
          <div v-if="weapon.lowStarBurnPoints > 0">LB: {{ weapon.lowStarBurnPoints }}</div>
          <div v-if="weapon.fourStarBurnPoints > 0">4B: {{ weapon.fourStarBurnPoints }}</div>
          <div v-if="weapon.fiveStarBurnPoints > 0">5B: {{ weapon.fiveStarBurnPoints }}</div>
        </div>
      </div>
    </div>
    <div class="rarity-label" :class="['rarity-' + (weapon.stars || 0)]">{{setRarity(weapon.stars)}}</div>
    <div class="stats">
      <div v-if="weapon.stat1Value">
        <span :class="weapon.stat1.toLowerCase() + '-icon'" class="mr-1 icon"></span>
        <span :class="weapon.stat1.toLowerCase()">{{ weapon.stat1Value }}</span>
      </div>
      <div v-if="weapon.stat2Value">
        <span :class="weapon.stat2.toLowerCase() + '-icon'" class="mr-1 icon"></span>
        <span :class="weapon.stat2.toLowerCase()">{{ weapon.stat2Value }}</span>
      </div>
      <div v-if="weapon.stat3Value">
        <span :class="weapon.stat3.toLowerCase() + '-icon'" class="mr-1 icon"></span>
        <span :class="weapon.stat3.toLowerCase()">{{ weapon.stat3Value }}</span>
      </div>
    </div>

  </div>
</template>

<script>
import { getWeaponArt } from '../weapon-arts-placeholder';
import '@/mixins/general';
import { Stat1PercentForChar,
  Stat2PercentForChar,
  Stat3PercentForChar
} from '../interfaces';
import Events from '@/events';

import { mapGetters, mapState } from 'vuex';
import { getCleanName } from '../rename-censor';

export default {
  props: ['weapon', 'favorite', 'selected', 'hasNftOptions'],
  computed: {
    ...mapState(['maxDurability']),
    ...mapState('specialWeaponsManager',
      ([
        'specialWeaponArts',
      ])),
    ...mapGetters([
      'currentCharacter',
      'timeUntilWeaponHasMaxDurability',
      'getWeaponName',
      'getWeaponCosmetic',
      'getWeaponDurability',
    ]),
    tooltipHtml() {
      if(!this.weapon) return '';

      const wrapInSpan = (spanClass, text) => {
        return `<span class="${spanClass.toLowerCase()}">${text}</span><span class="${spanClass.toLowerCase()+'-icon'}"></span>`;
      };

      const wrapInSpanTextOnly = (spanClass, text) => {
        return `<span class="${spanClass.toLowerCase()}">${text}</span>`;
      };

      let ttHtml = `
        ID: ${this.weapon.id}
        <br>
        ${Array(this.weapon.stars + 1).fill('★').join('')}
      `;
      if(this.weapon.level > 0) {
        ttHtml += `<br>Level ${this.weapon.level + 1}`;
      }

      if(this.weapon.element) {
        ttHtml += `<br>Element: ${wrapInSpan(this.weapon.element, this.weapon.element)}`;
      }
      const avg = [];
      if(this.weapon.stat1Value) {
        avg.push(this.weapon.stat1Value);
        ttHtml += `<br>${wrapInSpan(this.weapon.stat1, this.weapon.stat1)}: +${this.weapon.stat1Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat1PercentForChar(this.weapon, +this.currentCharacter.trait)+'%')
          })`;
        }
      }

      if(this.weapon.stat2Value) {
        avg.push(this.weapon.stat2Value);
        ttHtml += `<br>${wrapInSpan(this.weapon.stat2, this.weapon.stat2)}: +${this.weapon.stat2Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat2PercentForChar(this.weapon, +this.currentCharacter.trait)+'%')
          })`;
        }
      }

      if(this.weapon.stat3Value) {
        avg.push(this.weapon.stat3Value);
        ttHtml += `<br>${wrapInSpan(this.weapon.stat3, this.weapon.stat3)}: +${this.weapon.stat3Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat3PercentForChar(this.weapon, +this.currentCharacter.trait)+'%')
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

      if(this.weapon.lowStarBurnPoints > 0) {
        ttHtml += `<br>LB: ${this.weapon.lowStarBurnPoints}/100`;
      }

      if(this.weapon.fourStarBurnPoints > 0) {
        ttHtml += `<br>4B: ${this.weapon.fourStarBurnPoints}/25`;
      }

      if(this.weapon.fiveStarBurnPoints > 0) {
        ttHtml += `<br>5B: ${this.weapon.fiveStarBurnPoints}/10`;
      }

      if(this.weapon.bonusPower > 0) {
        ttHtml += `<br>${this.$t('weaponIcon.bonusPower')} ${this.weapon.bonusPower}`;
      }

      return ttHtml;
    }
  },

  data() {
    return {
      hover: false,
      showCosmetics: true,
    };
  },

  methods: {
    getWeaponArt,
    setRarity(rarity){
      if(rarity === 0) return 'Normal';
      if(rarity === 1) return 'Rare';
      if(rarity === 2) return 'Unique';
      if(rarity === 3) return 'Legendary';
      if(rarity === 4) return 'Mythical';
    },
    getCleanWeaponName(id, stars) {
      return getCleanName(this.getWeaponName(id, stars));
    },

    checkStorage() {
      this.showCosmetics = localStorage.getItem('showCosmetics') !== 'false';
    },
  },
  mounted() {
    this.checkStorage();
    Events.$on('setting:showCosmetics', () => this.checkStorage());
  }
};

</script>

<style scoped>
@import '../styles/weapon-cosmetics.css';
.rounded-check{
  content: url('../assets/check-round.svg');
  height: 1.5em;
  width: 1.5em;
  z-index: 3;
  right: -3px;
  top: 25px;
  position: absolute;
}

.small-durability-bar {
  position: relative;
  top: -5px;
  height: 4px;
  width: 100%;
  margin: 0 auto;
  border-radius: 2px;
  background : linear-gradient(to right, rgb(236, 75, 75) var(--durabilityReady), rgba(255, 255, 255, 0.1) 0);
}

.weapon-icon {
  height: 100%;
  width: 100%;
  position: relative;
  overflow: visible;
}

.stats > div{
  font-size: 13px;
  font-family: Roboto;
}

.stats > div > span:nth-child(2){
  color: rgba(255, 255, 255, 0.719);
  font-family: Roboto;
}

.glow-container {
  height: 100%;
  width: 100%;
  border-radius: 5px;
  z-index: 540;
  padding: 5px 25px;
  background: rgb(0, 14, 41);
}

.glow-container > img{
  margin-top: 10px;
}

.loading-container {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  z-index: 541;
  padding: 0;
}

.id, .trait, .stats {
  position: absolute;
}

.rarity-label{
  color: #fff;
  padding: 2px 15px;
  position: absolute;
  left: 15px;
  top: 10px !important;
  font-size: 12px;
  border-radius: 3px;
  font-family: Roboto;
}

.stars-flex{
  position: absolute;
  top:27px;
  right: 20px;
}
.stars-flex-extend{
  top: 9px;
}

.battle-p{
  font-family: Roboto;
  font-size: 12px;
  color: #ffffffc7;
}

.icon-trait{
  font-size: 15px;
  margin-right: 5px;
}

.bonus-pows{
 display: flex;
 justify-content: space-between;
 margin-top: 8px;
}

.bonus-pows > div{
  font-family: Roboto;
  font-size: 10px;
  color: rgba(255, 255, 255, 0.548);
  border: 1px solid rgba(255, 255, 255, 0.384);
  padding: 2px 6px;
  border-radius: 5px;
}

.name > div{
  display: flex;
  flex-direction: column;
}

.name > div > div{
  font-family: Roboto;
}

.name > div > span{
  font-family: Oswald;
  white-space: nowrap;
  overflow: hidden;
  text-overflow:ellipsis;
  font-size: 0.87vw;
}

.name{
  margin-bottom: 10px;
}

.selected-border{
  border: 1px solid rgb(237, 205, 144);
}

.star-stat{
  height: 11px;
  width: 11px;
  margin-left: 2px;
}

.trait {
  top: 10px;
  left: 10px;
}

.favorite-star {
  position: absolute;
  margin-left: 110px;
}

.id {
  top: 8px;
  left: 15px;
  font-style: italic;
}

.stats {
  top: 40px;
  left: 15px;
}

.icon {
  display: inline-block;
  min-width: 18px;
}

.placeholder {
  max-width: 180px;
  max-height: 180px;
  margin: auto;
  display: block;

  transform: scale(0.7);
}

.weapon-details{
  display: flex;
  padding: 0px 15px;
  flex-direction: column;
  margin-top: -20px;
}

.favorite-weapon{
  content: url('../assets/blacksmith/favorite_icon.svg');
  height: 25px;
  width: 25px;
  position: absolute;
  right: -10px;
  top: -10px;
}

.name {
  bottom: 20px;
  left: 12%;
  right: 12%;
  font-size: 0.6vw;
  color: #fff;
  font-family: Roboto;
  text-align: left;
}

.glow-0 {
  animation: none;
  border: 1px solid rgba(245, 245, 245, 0.116);
}

.glow-1 {
  border: 1px solid rgba(0, 162, 255);
}

.glow-2 {
  border: 1px solid rgba(125, 0, 125);
}

.glow-3 {
  border: 1px solid rgba(255, 102, 0);
}

.glow-4 {
  border: 1px solid rgba(125, 0, 0);
}

.rarity-0 {
  background-color: rgb(85, 85, 85);
}

.rarity-1 {
  background-color: rgba(0, 162, 255);
}

.rarity-2 {
  background-color: rgba(125, 0, 125);
}

.rarity-3 {
  background-color: rgba(255, 102, 0);
}

.rarity-4 {
  background-color: rgba(125, 0, 0);
}


.no-durability {
  opacity: 0.6;
}

.bonus-power {
  position: absolute;
  bottom: 40px;
  right: 10%;
  font-size: 0.6em;
  text-align: right;
}

@media (max-width: 576px) {
  .name > div > span{
    font-family: Oswald;
    white-space: nowrap;
    overflow: hidden;
    text-overflow:ellipsis;
    font-size: 7em;
  }

  .name > div > div{
    font-size: 5em;
    color: rgba(255, 255, 255, 0.445);
  }

}


</style>
