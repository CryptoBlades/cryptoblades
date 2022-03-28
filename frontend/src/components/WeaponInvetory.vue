<template>
  <div class="weapon-icon"
    v-bind:class="[(getWeaponDurability(weapon.id) === 0 ? 'no-durability' : '')]"
    v-tooltip="{
      content: tooltipHtml ,
      trigger: (isMobile() ? 'click' : 'hover')
    }"
    @mouseover="hover = !isMobile() || true"
    @mouseleave="hover = !isMobile()"
  >

    <div class="loading-container" v-if="!allLoaded">
      <i class="fas fa-spinner fa-spin"></i>
    </div>

    <!-- adventure selected weapon display  (MOBILE VIEW)-->
    <div class="displayed-weapon" v-if="displayType === 'adventure' && isMobile()">
        <div :class="'weapon-img img-adventure frame-'+ (weapon.stars || 0)">
          <!-- WEAPON ID -->
          <div class="id">{{$t('weaponIcon.id')}} {{ weapon.id }}</div>

          <!-- below use of weapon.id is for test purpose, should be replaced with getWeaponCosmetic(weapon.id) -->
          <img v-if="showPlaceholder" v-bind:class="showCosmetics ? ' weapon-cosmetic-applied-'
          + getWeaponCosmetic(weapon.id) : ''"
            class="placeholder" :src="getWeaponArt(weapon)" />
          <!-- element icon -->
          <span :class="weapon.element.toLowerCase() + '-icon'"></span>
        </div>
    </div>


    <!-- adventure selected weapon display  (DESKTOP VIEW)-->
    <div v-if="displayType === 'adventure' && !isMobile()" class="glow-container" ref="el">
      <div class="weapon-flex">
        <div :class="'weapon-img-desktop frame-'+ (weapon.stars || 0)">
            <!-- WEAPON ID -->
          <div class="id">{{$t('weaponIcon.id')}} {{ weapon.id }}</div>
          <img v-if="showPlaceholder" class="placeholder" :src="getWeaponArt(weapon)" />
        </div>
        <div class="weapon-details">

            <!-- FAVORITE -->
            <b-icon v-if="favorite" class="favorite-star" icon="star-fill" variant="warning" />

            <!-- WEAPON NAME -->
            <div class="name-desktop">
              {{ (getCleanWeaponName(weapon.id, weapon.stars)).toUpperCase()}}
            </div>

            <!-- DURABILITY BAR -->
            <div class="mt-1 mb-1">
              <div class="small-durability-bar"
              :style="`--durabilityReady: ${(getWeaponDurability(weapon.id)/maxDurability)*100}%;`"
              v-tooltip.bottom="`${$t('weaponIcon.durability')} ${getWeaponDurability(weapon.id)}/${maxDurability}<br>
                ${$t('weaponIcon.durabilityTooltip')} ${timeUntilWeaponHasMaxDurability(weapon.id)}`"></div>
            </div>

            <!-- STAR -->
            <div class="trait">
              <div class="d-flex align-items-center traits">
                <span :class="weapon.element.toLowerCase() + '-icon'"></span>
                <span class="trait-name">{{weapon.element.toUpperCase()}}</span>
              </div>
              <div>
                <div class="stats">
                  <div v-if="weapon.stat1Value">
                    <span :class="weapon.stat1.toLowerCase() + '-icon'" class="mr-1 icon"></span>
                    <span :class="weapon.stat1.toLowerCase()">{{ weapon.stat1 }} +{{ weapon.stat1Value }}</span>
                  </div>
                  <div v-if="weapon.stat2Value">
                    <span :class="weapon.stat2.toLowerCase() + '-icon'" class="mr-1 icon"></span>
                    <span :class="weapon.stat2.toLowerCase()">{{ weapon.stat2 }} +{{ weapon.stat2Value }}</span>
                  </div>
                  <div v-if="weapon.stat3Value">
                    <span :class="weapon.stat3.toLowerCase() + '-icon'" class="mr-1 icon"></span>
                    <span :class="weapon.stat3.toLowerCase()">{{ weapon.stat3 }} +{{ weapon.stat3Value }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- WEAPON STATS -->
            <div class="bonus-power">
              <div v-if="weapon.lowStarBurnPoints > 0"><span>{{ weapon.lowStarBurnPoints }} LB</span></div>
              <div v-if="weapon.fourStarBurnPoints > 0"><span>{{ weapon.fourStarBurnPoints }} 4B</span></div>
              <div v-if="weapon.fiveStarBurnPoints > 0"><span>{{ weapon.fiveStarBurnPoints }} 5B</span></div>
            </div>
        </div>
      </div>
    </div>


    <!-- inventory selected weapon list display -->
    <div v-if="displayType === 'inventory'" class="glow-container" ref="el">
      <div class="weapon-flex">
        <div :class="'weapon-img frame-'+ (weapon.stars || 0)">
            <!-- WEAPON ID -->
          <div class="id">{{$t('weaponIcon.id')}} {{ weapon.id }}</div>
          <img v-if="showPlaceholder" class="placeholder" :src="getWeaponArt(weapon)" />
        </div>
        <div class="weapon-details">

            <!-- FAVORITE -->
            <b-icon v-if="favorite" class="favorite-star" icon="star-fill" variant="warning" />

            <!-- WEAPON NAME -->
            <div class="name">
              {{ (getCleanWeaponName(weapon.id, weapon.stars)).toUpperCase()}}
            </div>

            <!-- STAR -->
            <div class="trait">
              <div class="d-flex align-items-center traits">
                <span :class="weapon.element.toLowerCase() + '-icon'"></span>
                <span class="trait-name">{{weapon.element.toUpperCase()}}</span>
              </div>
              <div>
                <div class="stats">
                  <div v-if="weapon.stat1Value">
                    <span :class="weapon.stat1.toLowerCase() + '-icon'" class="mr-1 icon"></span>
                    <span :class="weapon.stat1.toLowerCase()">{{ weapon.stat1 }} +{{ weapon.stat1Value }}</span>
                  </div>
                  <div v-if="weapon.stat2Value">
                    <span :class="weapon.stat2.toLowerCase() + '-icon'" class="mr-1 icon"></span>
                    <span :class="weapon.stat2.toLowerCase()">{{ weapon.stat2 }} +{{ weapon.stat2Value }}</span>
                  </div>
                  <div v-if="weapon.stat3Value">
                    <span :class="weapon.stat3.toLowerCase() + '-icon'" class="mr-1 icon"></span>
                    <span :class="weapon.stat3.toLowerCase()">{{ weapon.stat3 }} +{{ weapon.stat3Value }}</span>
                  </div>
                </div>
              </div>
            </div>

              <!-- DURABILITY BAR -->
            <div>
              <div class="small-durability-bar"
              :style="`--durabilityReady: ${(getWeaponDurability(weapon.id)/maxDurability)*100}%;`"
              v-tooltip.bottom="`${$t('weaponIcon.durability')} ${getWeaponDurability(weapon.id)}/${maxDurability}<br>
                ${$t('weaponIcon.durabilityTooltip')} ${timeUntilWeaponHasMaxDurability(weapon.id)}`"></div>
            </div>

            <!-- WEAPON STATS -->
            <div class="bonus-power">
              <div v-if="weapon.lowStarBurnPoints > 0"><span>{{ weapon.lowStarBurnPoints }} LB</span></div>
              <div v-if="weapon.fourStarBurnPoints > 0"><span>{{ weapon.fourStarBurnPoints }} 4B</span></div>
              <div v-if="weapon.fiveStarBurnPoints > 0"><span>{{ weapon.fiveStarBurnPoints }} 5B</span></div>
            </div>
        </div>
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

import { mapGetters, mapState } from 'vuex';
import { getCleanName } from '../rename-censor';

export default {
  props: ['weapon', 'favorite', 'displayType'],

  computed: {
    ...mapState(['maxDurability']),
    ...mapGetters([
      'currentCharacter',
      'getWeaponDurability',
      'timeUntilWeaponHasMaxDurability',
      'getWeaponName',
      'getWeaponCosmetic'
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
      allLoaded: false,
      allLoadStarted: false,
      loadCount: 0,
      loadCountTotal: 0,
      showPlaceholder: false
    };
  },

  methods: {
    getWeaponArt,
    getCleanWeaponName(id, stars) {
      return getCleanName(this.getWeaponName(id, stars));
    },
    checkStorage() {
      this.showCosmetics = localStorage.getItem('showCosmetics') !== 'false';
    },
  },
  mounted() {
    this.checkStorage();
    if(localStorage.getItem('useGraphics') === 'false') {
      this.allLoaded = true;
      this.showPlaceholder = true;
      return;
    }

    this.init();
    this.animate();
  }
};

</script>

<style scoped>

.weapon-icon {
  height: 100%;
  width: 100%;
  position: relative;
  overflow: hidden;
}

.glow-container {
  height: 100%;
  width: 100%;
}

.glow-container {
  border-radius: 5px;
  z-index: 540;
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

.frame-0{
    animation: none;
}

.frame-1{
  border: 1px solid  rgba(0, 162, 255, 0.5) !important;
}

.frame-2{
   border: 1px solid rgba(125, 0, 125, 0.5) !important;
}

.frame-3{
   border: 1px solid rgba(255, 102, 0, 0.3) !important;
}

.frame-4{
   border: 1px solid rgba(125, 0, 0, 0.5) !important;
}


.no-durability {
  opacity: 0.6;
}


.weapon-flex{
  display: flex;
  flex-direction: row;
  justify-content: center;
  align-items: center;
}

.weapon-img-desktop {
  background-color: rgba(0, 0, 0, 0.213);
  border-radius: 10px;
  border: rgb(3, 141, 21) 1px solid;
}

.weapon-img{
  background-color: rgba(0, 0, 0, 0.213);
  border-radius: 10px;
  border: rgb(3, 141, 21) 1px solid;
}

.weapon-details{
  display: flex;
  justify-content: center;
  flex-direction: column;
  padding: 10px 20px;
  flex-grow: 1;
}

.weapon-img > img{
  max-width: 100px;
  min-width: 100px;
  min-height: 100px;
  max-height: 100px;
}

.weapon-img-desktop > img{
  max-width: 70px;
  min-width: 70px;
  min-height: 70px;
  max-height: 70px;
}

.trait-name{
  color:#fff;
  font-size: 11px;
  padding-right: 10px;
  border-right: 1px solid rgba(255, 255, 255, 0.261);
}

.name {
  font-size: 17px;
  color: #fff;
  font-size: 0.9em;
  text-align: left;
  text-transform: capitalize !important;
  font-weight: 800;
}

.name-desktop {
  font-size: 17px;
  color: #fff;
  font-size: 1em;
  text-align: left;
  text-transform: capitalize !important;
  font-weight: 800;
  font-family: Trajan;
}



.id {
  position: absolute;
  top: 8px;
  left: 10px;
  font-style: normal;
  font-size: 12px;
  color: #fff;
}


.trait {
  display: flex;
  align-items: center;
}

.trait .traits{
  margin-right: 10px;
  padding: 5px 0px;
}

.stats {
  display: flex;
  align-items: center;
  font-size: 11px;
}

.btn-equip{
  border-radius: 3px !important;
  padding: 2px 15px;
  font-size: 11px;
  background-color: rgba(255, 255, 255, 0.275);
  width: fit-content;
  color: #fff;
  border: none !important;
  margin-top: 10px;
}


.bonus-power {
  font-size: 0.6em;
  text-align: right;
}

.small-durability-bar {
  position: relative;
  height: 3px;
  width: 100%;
  margin: 0 auto;
  background : linear-gradient(to right, rgb(236, 75, 75) var(--durabilityReady), rgba(255, 255, 255, 0.1) 0);
}


@media all and (max-width: 600px) {
  .img-adventure > img{
    max-width: 70px;
    min-width: 70px;
    min-height: 70px;
    max-height: 70px;
  }

  .img-adventure > span{
    position: absolute;
    bottom:10px;
    right:10px;
  }

  .img-adventure{
    border-radius: 7px;
  }
}

</style>
