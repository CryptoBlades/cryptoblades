<template>
<div>
    <div
      v-if="!isEquipContainer && shield === null"
      :class="`${setListClassForNoShield(shield)}`"
      @click="updateShieldDetails(null)">
        <img
          class="inventory-shield-content"
          src="../../assets/shield-disabled.svg"/>
    </div>
    <div
      v-if="isEquipContainer && shield === null"
      class= "unselected-equipped-shield"
      @click="updateShieldDetails(null)">
        <img
          class="inventory-equipped-shield-content"
          src="../../assets/shield-disabled.svg"/>
    </div>
    <div
      v-if="!isEquipContainer && shield !== null"
      :class="`${setListClassForShield(shield.id)}`"
      @click="updateShieldDetails(shield.id)">
      <div>
        <div
            v-if="shield.stars >=0 || shield.stars <=2"
            id="inventory-shield-trait-1">
              <span>
                <img
                  class="inventory-shield-trait-img"
                  :src="getElementIcon(shield.stat1Type)"/>
                    <span :class="getElementColor(shield.stat1Type)">{{shield.stat1}}</span>
                    <span class="inventory-shield-trait-value">{{shield.stat1Value}}</span>
              </span>
        </div>
        <div
            v-if="shield.stars >= 3"
            id="inventory-shield-trait-2">
              <span>
                <img
                  class="inventory-shield-trait-img"
                  :src="getElementIcon(shield.stat2Type)"/>
                    <span :class="getElementColor(shield.stat2Type)">{{shield.stat2}}</span>
                    <span class="inventory-shield-trait-value">{{shield.stat2Value}}</span>
              </span>
        </div>
        <div
            v-if="shield.stars === 4"
            id="inventory-shield-trait-3">
              <span>
                <img
                  class="inventory-shield-trait-img"
                  :src="getElementIcon(shield.stat3Type)"/>
                    <span :class="getElementColor(shield.stat3Type)">{{shield.stat3}}</span>
                    <span class="inventory-shield-trait-value">{{shield.stat3Value}}</span>
              </span>
        </div>

        <span :class="`${setShieldPvPStatus(shield.id)}`"></span>
        <shield-element
              id="inventory-shield-element"
              :trait="`${getShieldElementNum(shield.element)}`">
        </shield-element>
        <span id="inventory-shield-stars">{{shield.stars + 1}}&#9733;</span>
        <img
            class="inventory-shield-content"
            :src="getShieldArt(shield.id)"/>
      </div>
    </div>

    <div
      v-if="isEquipContainer && shield !== null"
      class="unselected-equipped-shield"
      >
        <div
          v-if="shield.stars >=0 || shield.stars <=2"
          id="inventory-equipped-shield-trait-1">
            <span>
              <img
                class="inventory-equipped-shield-trait-img"
                :src="getElementIcon(shield.stat1Type)"/>
                  <span :class="getElementColor(shield.stat1Type)">{{shield.stat1}}</span>
                  <span class="inventory-equipped-shield-trait-value">{{shield.stat1Value}}</span>
            </span>
        </div>
        <div
          v-if="shield.stars >= 3"
          id="inventory-equipped-shield-trait-2">
            <span>
              <img
                class="inventory-equipped-shield-trait-img"
                :src="getElementIcon(shield.stat2Type)"/>
                  <span :class="getElementColor(shield.stat2Type)">{{shield.stat2}}</span>
                  <span class="inventory-equipped-shield-trait-value">{{shield.stat2Value}}</span>
            </span>
        </div>
        <div
          v-if="shield.stars === 4"
          id="inventory-equipped-shield-trait-3">
            <span>
              <img
                class="inventory-equipped-shield-trait-img"
                :src="getElementIcon(shield.stat3Type)"/>
                  <span :class="getElementColor(shield.stat3Type)">{{shield.stat3}}</span>
                  <span class="inventory-equipped-shield-trait-value">{{shield.stat3Value}}</span>
            </span>
        </div>

        <shield-element
              id="inventory-equipped-shield-element"
              :trait="`${getShieldElementNum(shield.element)}`">
        </shield-element>
        <span id="inventory-equipped-shield-stars">{{shield.stars + 1}}&#9733;</span>
        <img
          class="inventory-equipped-shield-content"
          :src="getShieldArt(shield.id)"/>
    </div>

</div>
</template>

<script>

import { mapMutations, mapState } from 'vuex';
import foundersShield from '../../assets/shield1.png';
import legendaryShield from '../../assets/shield2.png';
import fireIcon  from '../../assets/elements/fire.png';
import earthIcon  from '../../assets/elements/earth.png';
import lightningIcon  from '../../assets/elements/lightning.png';
import waterIcon  from '../../assets/elements/water.png';
import Element from './Element.vue';

export default {
  props: ['shield', 'inPvP', 'isEquipContainer'],

  computed: {
    ...mapState(['pvp','currentShieldId']),
  },

  methods:{
    ...mapMutations([
      'setCurrentShield',
      'updateIsShieldInArena'
    ]),

    setListClassForShield(shieldId){
      if (shieldId === this.currentShieldId){
        return 'selected-shield';
      }

      else return 'unselected-shield';
    },

    setListClassForNoShield(shieldId){
      if(shieldId === this.currentShieldId){
        return 'selected-shield';
      }

      else return 'unselected-shield';
    },

    getShieldArt(shieldId) {
      if(shieldId <= 10000){
        return foundersShield;
      }
      else if (shieldId > 10000 || shieldId <= 25000){
        return legendaryShield;
      }
      else{
        return '';
      }
    },

    setShieldPvPStatus(shieldId){
      this.$store.dispatch('fetchParticipatingShields');

      if(this.pvp.participatingShields.includes(shieldId.toString())){
        return 'shield-in-pvp';
      }
      else return 'shield-not-in-pvp';

    },

    getElementIcon(statType){
      if (statType === 0){
        return fireIcon;
      }
      else if (statType === 1){
        return earthIcon;
      }
      else if (statType === 2){
        return lightningIcon;
      }
      else if (statType === 3){
        return waterIcon;
      }
      else
        return '';
    },

    getElementColor(statType){
      if (statType === 0){
        return 'inventory-shield-trait-label-fire';
      }
      else if (statType === 1){
        return 'inventory-shield-trait-label-earth';
      }
      else if (statType === 2){
        return 'inventory-shield-trait-label-lightning';
      }
      else if (statType === 3){
        return 'inventory-shield-trait-label-water';
      }
      else
        return 'inventory-shield-trait-label-pwr';
    },

    async updateShieldDetails(shieldID){
      this.setCurrentShield(shieldID);

      if(shieldID === null){
        this.updateIsShieldInArena({isShieldInArena: false});
      }

      if(shieldID !== null){
        await this.$store.dispatch('fetchIsShieldInArena', {shieldID});
      }
    },
    getShieldElementNum(shieldElement){
      if(shieldElement.toUpperCase() === 'FIRE'){
        return '0';
      }
      else if (shieldElement.toUpperCase() === 'EARTH'){
        return '1';
      }
      else if (shieldElement.toUpperCase() === 'LIGHTNING'){
        return '2';
      }
      else if (shieldElement.toUpperCase() === 'WATER'){
        return '3';
      }
    },
  },

  components: {
    'shield-element': Element
  }

};
</script>

<style>
.no-equipped-shield {
  font-size: 15px;
  text-align: center;

}

.selected-shield {
  background: transparent;
  border: 1px dashed #968332;
  border-radius: 10%;
  height: 90px;
  width: 90px;
  margin: 10px auto;
}

.selected-shield:hover{
  cursor: pointer;
}

.unselected-shield {
  background: transparent;
  border: 1px none transparent;
  border-radius: 10%;
  height: 90px;
  width: 90px;
  margin: 10px auto;
}

.unselected-equipped-shield {
  background: transparent;
  height: 80px;
  width: 80px;
}

.unselected-shield:hover {
  cursor: pointer;
}

.inventory-shield-content {
  background: transparent;
  border: 2px solid #968332;
  border-radius: 10%;
  height: 80px;
  width: 80px;
  margin: 3px auto;
}

.inventory-equipped-shield-content {
  background: transparent;
  height: 70px;
  width: 70px;
  margin: auto;
}

.inventory-shield-trait-img {
  height: 20px;
  width: 20px;
}

.inventory-equipped-shield-trait-img {
  height: 15px;
  width: 15px;
}

.inventory-shield-trait-label-fire{
  margin-right: 5px;
  color: red;
}

.inventory-shield-trait-label-earth{
  margin-right: 5px;
  color: green;
}

.inventory-shield-trait-label-lightning{
  margin-right: 5px;
  color: yellow;
}

.inventory-shield-trait-label-water{
  margin-right: 5px;
  color: cyan;
}

.inventory-shield-trait-label-pwr{
  margin-right: 5px;
  color: white;
}

.inventory-shield-trait-value, .inventory-equipped-shield-trait-value {
  color: white;
}

#inventory-shield-trait-1 {
  position: absolute;
  margin-left: 5px;
  top: 15px;
}


#inventory-shield-trait-2 {
  position: absolute;
  margin-left: 5px;
  top: 35px;
}

#inventory-shield-trait-3 {
  position: absolute;
  margin-left: 5px;
  top: 55px;
}

#inventory-equipped-shield-trait-1 {
  font-size: 15px;
  position: absolute;
}

#inventory-equipped-shield-trait-2 {
  font-size: 15px;
  position: absolute;
  top: 25px;
}

#inventory-equipped-shield-trait-3 {
  font-size: 15px;
  position: absolute;
  top: 44px;
}

#inventory-shield-element {
  position: absolute;
  margin-left: 5px;
  top: 65px;
}

#inventory-equipped-shield-element {
  position: absolute;
  margin-left: -10px;
  top: 55px;
}

#inventory-shield-stars {
  position: absolute;
  margin-left: 55px;
  top: 70px;
  color: #fff;
}

#inventory-equipped-shield-stars {
  position: absolute;
  margin-left: 45px;
  top: 55px;
  color: #fff;
}

/* PvP Status Styles */
.shield-in-pvp {
    color: white;
    height: 20px;
    width: 75px;
    background-color: rgb(187, 33, 0);
    border-radius: 10%;
    transform: rotate(30deg);
    position: absolute;
    top: 30%;
}

.shield-in-pvp::before {
  content: "IN PVP";
}
</style>
