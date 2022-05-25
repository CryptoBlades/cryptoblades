<template>
  <b-popover
    :target="'weapon-'+weapon.id"
    :placement="isMobile() ? 'auto' : placement"
    style="z-index:999"
    class="weapon-popover"
    triggers="hover">
    <div class="weapon-popover-body">
      <img :src="getWeaponArt(weapon)">
      <div class="details">
        <span class="rarity" :class="'rarity-'+weapon.stars">{{getWeaponRarity(weapon.stars)}}</span>
        <h5>{{getCleanWeaponName(weapon.id, weapon.stars).toUpperCase()}}</h5>
        <div class="trait-star">
           <div class="trait">
              <div class="d-flex align-items-center traits">
                <span :class="weapon.element.toLowerCase() + '-icon'"></span>
                <span class="trait-name">Battle Power: {{ weapon.stat1Value + weapon.stat2Value + weapon.stat3Value}}</span>
                <span>|</span>
                <span class="stars" v-for="star in weapon.stars+1" :key="star">&#9733;</span>
              </div>
            </div>
        </div>
        <div class="pb-2 pt-2">
          <div class="small-durability-bar"
          :style="`--durabilityReady: ${(getWeaponDurability(weapon.id)/maxDurability)*100}%;`"
          v-tooltip.bottom="`${$t('weaponIcon.durability')} ${getWeaponDurability(weapon.id)}/${maxDurability}<br>
            ${$t('weaponIcon.durabilityTooltip')} ${timeUntilWeaponHasMaxDurability(weapon.id)}`"></div>
        </div>
        <div class="stats">
          <div v-if="weapon.stat1Value">
            <span :class="weapon.stat1.toLowerCase() + '-icon'" class="mr-1 icon"></span> &nbsp;
            <span :class="weapon.stat1.toLowerCase()">{{ weapon.stat1 }} +{{ weapon.stat1Value }}</span>
          </div>
          <div v-if="weapon.stat2Value">
            <span :class="weapon.stat2.toLowerCase() + '-icon'" class="mr-1 icon"></span> &nbsp;
            <span :class="weapon.stat2.toLowerCase()">{{ weapon.stat2 }} +{{ weapon.stat2Value }}</span>
          </div>
          <div v-if="weapon.stat3Value">
            <span :class="weapon.stat3.toLowerCase() + '-icon'" class="mr-1 icon"></span> &nbsp;
            <span :class="weapon.stat3.toLowerCase()">{{ weapon.stat3 }} +{{ weapon.stat3Value }}</span>
          </div>
        </div>
        <div class="bunos-power">
          <div v-if="weapon.lowStarBurnPoints > 0">
            <span class="bonus-power-icon mr-1 icon"></span> &nbsp;
            <span>LB: {{weapon.lowStarBurnPoints}}</span>
          </div>
          <div v-if="weapon.fourStarBurnPoints > 0">
            <span class="bonus-power-icon mr-1 icon"></span> &nbsp;
            <span>4B: {{weapon.fourStarBurnPoints}}</span>
          </div>
          <div v-if="weapon.fiveStarBurnPoints > 0">
            <span class="bonus-power-icon mr-1 icon"></span> &nbsp;
            <span>5B: {{weapon.fiveStarBurnPoints}}</span>
          </div>
        </div>
      </div>
    </div>
  </b-popover>
</template>

<script>
import { getWeaponArt } from '../weapon-arts-placeholder';
import { getWeaponRarity } from '../weapon-element';
import { getCleanName } from '../rename-censor';


import { mapGetters, mapState } from 'vuex';

export default {
  props: ['weapon', 'placement'],
  methods: {
    getWeaponArt,
    getWeaponRarity,
    getCleanWeaponName(id, stars) {
      return getCleanName(this.getWeaponName(id, stars));
    },
  },
  computed:{
    ...mapState(['maxDurability']),
    ...mapGetters([
      'getWeaponDurability',
      'timeUntilWeaponHasMaxDurability',
      'getWeaponName',
    ]),
  },
};
</script>
<style scoped>
  .weapon-popover-body{
    padding: 20px;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .weapon-popover-body > img{
    height: 7em;
    width: 7em;
    margin-bottom: 20px;
  }

  .weapon-popover-body > .details > .rarity{
    color: #fff;
    padding: 2px 10px;
    font-family: Roboto;
    border-radius: 3px;
    font-size: 12px;
  }

  .weapon-popover-body > .details{
    align-self: flex-start;
  }


  .bunos-power > div > span{
    color: rgba(255, 255, 255, 0.534);
    font-size: 13px;
    font-family: Roboto;
  }

  .small-durability-bar {
    position: relative;
    height: 3px;
    width: 100%;
    /* margin: 0 auto; */
    background : linear-gradient(to right, rgb(236, 75, 75) var(--durabilityReady), rgba(255, 255, 255, 0.1) 0);
  }
  .weapon-popover-body > .details > h5{
    font-family: Trajan;
    color: #fff;
    margin-top: 10px;
  }

  .trait-star{
    color: #fff;
  }

  .trait-star > div > div > span:nth-child(2){
    color: #fff;
    margin-left:10px;
    font-family: Roboto;
  }

   .trait-star > div > div > span:nth-child(3){
    color: rgba(255, 255, 255, 0.384);
    padding: 0px 10px;
  }


  .trait-star > div > div > span.stars{
    color: #EDCD90;
    font-size: 15px;
  }

  .stats > div > span:nth-child(2){
    color: rgba(255, 255, 255, 0.685);
    font-family: Roboto;
    font-size: 12px;
  }

  .popover{
    background-color: rgb(15, 15, 15);
    border: 1px solid rgba(255, 255, 255, 0.39);
    border-radius: 10px;
    width: 22em;
    margin-left: -500px;
    margin-top: -45px;
  }

  .popover{
    animation: fadeUp 0.4s ease-in-out;
  }

  @keyframes fadeUp {
    0%{
      margin-top: 0px;
      opacity: 0;
    }
    100%{
      margin-top: -45px;
      opacity: 1;
    }
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




  @media all and (max-width: 600px) {
  .popover{
      background-color: rgb(15, 15, 15);
      border: 1px solid rgba(255, 255, 255, 0.39);
      border-radius: 10px;
      width: 22em;
      margin: auto;
    }
  }

</style>
