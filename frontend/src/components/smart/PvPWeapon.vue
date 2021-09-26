<template>
<div>

    <div
      v-if="!isEquipContainer && weapon === null"
      :class="`${setListClassForNoWeapon(weapon, currentWeaponId)}`"
      @click="updateWeaponDetails(null)">
        <img
          class="inventory-weapon-content"
          src="../../assets/drop-weapon.svg"/>
    </div>
    <div
      v-if="isEquipContainer && weapon === null"
      class= "unselected-equipped-weapon"
      @click="updateWeaponDetails(null)">
        <img
          class="inventory-equipped-weapon-content"
          src="../../assets/drop-weapon.svg"/>
    </div>
    <div
      v-if="!isEquipContainer && weapon !== null"
      :class="`${setListClassForWeapon(weapon.id,currentWeaponId)}`"
      @click="updateWeaponDetails(weapon.id)">
      <div>
          <div
            v-if="weapon.stars >=0 || weapon.stars <=2"
            id="inventory-weapon-trait-1">
              <span>
                <img
                  class="inventory-weapon-trait-img"
                  :src="getElementIcon(weapon.stat1Type)"/>
                    <span :class="getElementColor(weapon.stat1Type)">{{weapon.stat1}}</span>
                    <span class="inventory-weapon-trait-value">{{weapon.stat1Value}}</span>
              </span>
          </div>
          <div
            v-if="weapon.stars === 3"
            id="inventory-weapon-trait-2">
              <span>
                <img
                  class="inventory-weapon-trait-img"
                  :src="getElementIcon(weapon.stat2Type)"/>
                    <span :class="getElementColor(weapon.stat2Type)">{{weapon.stat2}}</span>
                    <span class="inventory-weapon-trait-value">{{weapon.stat2Value}}</span>
              </span>
          </div>
          <div
            v-if="weapon.stars === 4"
            id="inventory-weapon-trait-3">
              <span>
                <img
                  class="inventory-weapon-trait-img"
                  :src="getElementIcon(weapon.stat3Type)"/>
                    <span :class="getElementColor(weapon.stat3Type)">{{weapon.stat3}}</span>
                    <span class="inventory-weapon-trait-value">{{weapon.stat3Value}}</span>
              </span>
          </div>

          <span :class="`${setWeaponPvPStatus(weapon.id)}`"></span>
            <weapon-element
              id="inventory-weapon-element"
              :trait="`${getWeaponElementNum(weapon.element)}`">
            </weapon-element>
          <img
            class="inventory-weapon-content"
            :src="getWeaponArt(weapon)"/>
      </div>
    </div>
    <div
      v-if="isEquipContainer && weapon !== null"
      class="unselected-equipped-weapon"
      >
        <div
          v-if="weapon.stars >=0 || weapon.stars <=2"
          id="inventory-equipped-weapon-trait-1">
            <span>
              <img
                class="inventory-equipped-weapon-trait-img"
                :src="getElementIcon(weapon.stat1Type)"/>
                  <span :class="getElementColor(weapon.stat1Type)">{{weapon.stat1}}</span>
                  <span class="inventory-equipped-weapon-trait-value">{{weapon.stat1Value}}</span>
            </span>
        </div>
        <div
          v-if="weapon.stars === 3"
          id="inventory-equipped-weapon-trait-2">
            <span>
              <img
                class="inventory-equipped-weapon-trait-img"
                :src="getElementIcon(weapon.stat2Type)"/>
                  <span :class="getElementColor(weapon.stat2Type)">{{weapon.stat2}}</span>
                  <span class="inventory-equipped-weapon-trait-value">{{weapon.stat2Value}}</span>
            </span>
        </div>
        <div
          v-if="weapon.stars === 4"
          id="inventory-equipped-weapon-trait-3">
            <span>
              <img
                class="inventory-equipped-weapon-trait-img"
                :src="getElementIcon(weapon.stat3Type)"/>
                  <span :class="getElementColor(weapon.stat3Type)">{{weapon.stat3}}</span>
                  <span class="inventory-equipped-weapon-trait-value">{{weapon.stat3Value}}</span>
            </span>
        </div>

        <weapon-element
              id="inventory-equipped-weapon-element"
              :trait="`${getWeaponElementNum(weapon.element)}`">
        </weapon-element>
        <img
          class="inventory-equipped-weapon-content"
          :src="getWeaponArt(weapon)"/>
    </div>
</div>
</template>

<script>
import { mapMutations, mapState } from 'vuex';
import { getWeaponArt } from '../../weapon-arts-placeholder';
import fireIcon  from '../../assets/elements/fire.png';
import earthIcon  from '../../assets/elements/earth.png';
import lightningIcon  from '../../assets/elements/lightning.png';
import waterIcon  from '../../assets/elements/water.png';
import Element from './Element.vue';

export default {

  props: ['weapon','currentWeaponId','inPvP','isEquipContainer'],

  computed: {
    ...mapState(['pvp']),
  },

  methods: {
    ...mapMutations([
      'setCurrentWeapon',
      'updateIsWeaponInArena'
    ]),

    getWeaponArt,

    setListClassForWeapon(weaponId,currentWeaponId){
      if (weaponId === currentWeaponId){
        return 'selected-weapon';
      }
      else return 'unselected-weapon';
    },
    setListClassForNoWeapon(weaponId, currentWeaponId){
      if(weaponId === currentWeaponId){
        return 'selected-weapon';
      }
      else return 'unselected-weapon';
    },

    setWeaponPvPStatus(weaponID){
      this.$store.dispatch('fetchParticipatingWeapons');

      if(this.pvp.participatingWeapons.includes(weaponID.toString())){
        return 'weapon-in-pvp';
      }
      else return 'weapon-not-in-pvp';

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
        return 'inventory-weapon-trait-label-fire';
      }
      else if (statType === 1){
        return 'inventory-weapon-trait-label-earth';
      }
      else if (statType === 2){
        return 'inventory-weapon-trait-label-lightning';
      }
      else if (statType === 3){
        return 'inventory-weapon-trait-label-water';
      }
      else
        return 'inventory-weapon-trait-label-pwr';
    },

    async updateWeaponDetails(weaponID){
      this.setCurrentWeapon(weaponID);

      if(weaponID === null){
        this.updateIsWeaponInArena({isWeaponInArena: true});
      }

      if(weaponID !== null){
        await this.$store.dispatch('fetchIsWeaponInArena', { weaponID });
      }
    },
    getWeaponElementNum(weaponElement){
      if(weaponElement.toUpperCase() === 'FIRE'){
        return '0';
      }
      else if (weaponElement.toUpperCase() === 'EARTH'){
        return '1';
      }
      else if (weaponElement.toUpperCase() === 'LIGHTNING'){
        return '2';
      }
      else if (weaponElement.toUpperCase() === 'WATER'){
        return '3';
      }
    },
  },

  components:{
    'weapon-element': Element
  }
};
</script>

<style>
.selected-weapon {
  background: transparent;
  border: 1px dashed #968332;
  border-radius: 10%;
  height: 90px;
  width: 90px;
  margin: 10px auto;
}

.selected-weapon:hover{
  cursor: pointer;
}

.unselected-weapon {
  background: transparent;
  border: 1px none transparent;
  border-radius: 10%;
  height: 90px;
  width: 90px;
  margin: 10px auto;
}

.unselected-equipped-weapon {
  background: transparent;
  height: 80px;
  width: 80px;
}

.unselected-weapon:hover {
  cursor: pointer;
}

.inventory-weapon-content {
  background: transparent;
  border: 2px solid #968332;
  border-radius: 10%;
  height: 80px;
  width: 80px;
  margin: 3px auto;
}

.inventory-equipped-weapon-content {
  background: transparent;
  height: 70px;
  width: 70px;
  margin: auto;
}

.inventory-weapon-trait-img {
  height: 20px;
  width: 20px;
}

.inventory-equipped-weapon-trait-img {
  height: 15px;
  width: 15px;
}

.inventory-weapon-trait-label-fire{
  margin-right: 5px;
  color: red;
}

.inventory-weapon-trait-label-earth{
  margin-right: 5px;
  color: green;
}

.inventory-weapon-trait-label-lightning{
  margin-right: 5px;
  color: yellow;
}

.inventory-weapon-trait-label-water{
  margin-right: 5px;
  color: cyan;
}

.inventory-weapon-trait-label-pwr{
  margin-right: 5px;
  color: white;
}

.inventory-weapon-trait-value, .inventory-equipped-weapon-trait-value {
  color: white;
}

#inventory-weapon-trait-1 {
  position: absolute;
  margin-left: 5px;
  top: 15px;
}

#inventory-weapon-trait-2 {
  position: absolute;
  margin-left: 5px;
  top: 35px;
}

#inventory-weapon-trait-3 {
  position: absolute;
  margin-left: 5px;
  top: 55px;
}

#inventory-equipped-weapon-trait-1 {
  font-size: 15px;
  position: absolute;
}

#inventory-equipped-weapon-trait-2 {
  font-size: 15px;
  position: absolute;
  top: 25px;
}

#inventory-equipped-weapon-trait-3 {
  font-size: 15px;
  position: absolute;
  top: 44px;
}

#inventory-weapon-element {
  position: absolute;
  margin-left: 5px;
  top: 65px;
}

#inventory-equipped-weapon-element {
  position: absolute;
  margin-left: -10px;
  top: 55px;
}

/* PvP Status Styles */
.weapon-in-pvp {
    color: white;
    height: 20px;
    width: 75px;
    background-color: rgb(187, 33, 0);
    border-radius: 10%;
    transform: rotate(30deg);
    position: absolute;
    left: 28%;
    top: 30%;
}

.weapon-in-pvp::before {
  content: "IN PVP";
}
/* PvP Status Styles */
</style>
