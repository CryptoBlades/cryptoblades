<template>
  <div class="inventory-container">
        <b-row class="inventory-header-text">
            <b-col>
              <span v-if="getCurrentTab === 0" v-text="`${inventoryTabNames[getCurrentTab].name.toUpperCase()}`+ ' ' + inventoryHeaderText"/>
              <span v-if="getCurrentTab === 1" v-text="`${inventoryTabNames[getCurrentTab].name.toUpperCase()}`+ ' ' + inventoryHeaderText"/>
            </b-col>
        </b-row>
        <b-row v-if="getCurrentTab === 0">
              <b-col v-if="this.ownWeapons.length > 0">
                <span class="inventory-filter-header"> ELEMENT </span>
                <b-row>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('ALL',weaponFilter.element)}`"
                      @click="setWeaponElementFilter('ALL')">
                      <span class="weapon-filter" >ALL</span>
                    </span>
                  </b-col>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('Fire',weaponFilter.element)}`"
                      @click="setWeaponElementFilter('Fire')">
                      <img class="weapon-filter" src="../../assets/elements/fire.png"/>
                    </span>
                  </b-col>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('Earth',weaponFilter.element)}`"
                      @click="setWeaponElementFilter('Earth')">
                      <img class="weapon-filter" src="../../assets/elements/earth.png"/>
                    </span>
                  </b-col>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('Lightning',weaponFilter.element)}`"
                      @click="setWeaponElementFilter('Lightning')">
                      <img class="weapon-filter" src="../../assets/elements/lightning.png"/>
                    </span>
                  </b-col>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('Water',weaponFilter.element)}`"
                      @click="setWeaponElementFilter('Water')">
                      <img class="weapon-filter" src="../../assets/elements/water.png"/>
                    </span>
                  </b-col>
                </b-row>
                <span class="inventory-filter-header"> STAR </span>
                <b-row>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(-1, weaponFilter.stars)}`"
                      @click="setWeaponStarFilter(-1)">
                      <span class="weapon-filter">ALL</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(0, weaponFilter.stars)}`"
                      @click="setWeaponStarFilter(0)">
                      <span class="weapon-filter">1&#9733;</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(1, weaponFilter.stars)}`"
                      @click="setWeaponStarFilter(1)">
                      <span class="weapon-filter">2&#9733;</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(2, weaponFilter.stars)}`"
                      @click="setWeaponStarFilter(2)">
                      <span class="weapon-filter">3&#9733;</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(3, weaponFilter.stars)}`"
                      @click="setWeaponStarFilter(3)">
                      <span class="weapon-filter">4&#9733;</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(4, weaponFilter.stars)}`"
                      @click="setWeaponStarFilter(4)">
                      <span class="weapon-filter">5&#9733;</span>
                    </span>
                  </b-col>
                </b-row>
                <b-row>
                  <b-col>
                        <pvp-weapon
                          :weapon="null"
                          :currentWeaponId="currentWeaponId"
                          :inPvP="false"
                          :isEquipContainer="false"></pvp-weapon>
                  </b-col>
                  <b-col
                    v-for="weapon in getFilteredWeapons"
                    :key="weapon.id">
                        <pvp-weapon
                          :weapon="weapon"
                          :currentWeaponId="currentWeaponId"
                          :inPvP="false"
                          :isEquipContainer="false"></pvp-weapon>
                  </b-col>
                </b-row>
              </b-col>

              <b-col v-if="this.ownWeapons.length <= 0">
                You do not have any weapons.
              </b-col>
        </b-row>
        <b-row v-if="getCurrentTab === 1">
              <b-col v-if="this.ownShields.length > 0">
                <span class="inventory-filter-header"> ELEMENT </span>
                <b-row>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('ALL',shieldFilter.element)}`"
                      @click="setShieldElementFilter('ALL')">
                      <span class="weapon-filter" >ALL</span>
                    </span>
                  </b-col>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('Fire',shieldFilter.element)}`"
                      @click="setShieldElementFilter('Fire')">
                      <img class="weapon-filter" src="../../assets/elements/fire.png"/>
                    </span>
                  </b-col>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('Earth',shieldFilter.element)}`"
                      @click="setShieldElementFilter('Earth')">
                      <img class="weapon-filter" src="../../assets/elements/earth.png"/>
                    </span>
                  </b-col>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('Lightning',shieldFilter.element)}`"
                      @click="setShieldElementFilter('Lightning')">
                      <img class="weapon-filter" src="../../assets/elements/lightning.png"/>
                    </span>
                  </b-col>
                  <b-col>
                    <span
                      :class="`${setClassListForShieldAndWeaponElementFilter('Water',shieldFilter.element)}`"
                      @click="setShieldElementFilter('Water')">
                      <img class="weapon-filter" src="../../assets/elements/water.png"/>
                    </span>
                  </b-col>
                </b-row>
                <span class="inventory-filter-header"> STAR </span>
                <b-row>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(-1, shieldFilter.stars)}`"
                      @click="setShieldStarFilter(-1)">
                      <span class="weapon-filter">ALL</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(0, shieldFilter.stars)}`"
                      @click="setShieldStarFilter(0)">
                      <span class="weapon-filter">1&#9733;</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(1, shieldFilter.stars)}`"
                      @click="setShieldStarFilter(1)">
                      <span class="weapon-filter">2&#9733;</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(2, shieldFilter.stars)}`"
                      @click="setShieldStarFilter(2)">
                      <span class="weapon-filter">3&#9733;</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(3, shieldFilter.stars)}`"
                      @click="setShieldStarFilter(3)">
                      <span class="weapon-filter">4&#9733;</span>
                    </span>
                  </b-col>
                  <b-col cols="2">
                    <span
                      :class="`${setClassListForShieldAndWeaponStarFilter(4, shieldFilter.stars)}`"
                      @click="setShieldStarFilter(4)">
                      <span class="weapon-filter">5&#9733;</span>
                    </span>
                  </b-col>
                </b-row>
                <b-row>
                  <b-col>
                    <pvp-shield
                        :shield="null"
                        :inPvP="false"
                        :isEquipContainer="false"></pvp-shield>
                  </b-col>
                  <b-col
                    v-for="shield in getFilteredShields"
                    :key="shield.id">
                      <pvp-shield
                        :shield="shield"
                        :inPvP="false"
                        :isEquipContainer="false"></pvp-shield>
                  </b-col>
                </b-row>
              </b-col>

              <b-col v-if="this.ownShields.length <= 0">
                <div>
                  You do not have any shields.
                </div>
              </b-col>
        </b-row>
  </div>
</template>

<script>
import { mapGetters, mapMutations, mapState } from 'vuex';
import PvPConstants from '../../utils/constants/pvp-constants';
import PvPWeapon from '../smart/PvPWeapon.vue';
import PvPShield from '../smart/PvPShield.vue';

export default {

  data(){
    return {
      inventoryHeaderTextHint: PvPConstants.INVENTORY_HEADER_TEXT_HINT,
      inventoryHeaderText: PvPConstants.INVENTORY_HEADER_TEXT,
    };
  },

  computed: {
    ...mapState(['currentWeaponId','pvp','weaponFilter','shieldFilter']),
    ...mapGetters([
      'getInventoryState',
      'getCurrentTab',
      'ownWeapons',
      'filteredWeapons',
      'filteredShields',
      'ownShields',
      'currentShield',
    ]),

    getFilteredWeapons(){
      return this.filteredWeapons;
    },

    getFilteredShields(){
      return this.filteredShields;
    },

    inventoryTabNames(){
      return this.getInventoryState;
    },
  },

  methods:{
    ...mapMutations([
      'setWeaponElementFilter',
      'setWeaponStarFilter',
      'setShieldElementFilter',
      'setShieldStarFilter'
    ]),

    setClassListForShieldAndWeaponElementFilter(elementFilter , currentElement){
      if(elementFilter.toUpperCase() === currentElement.toUpperCase()){
        return 'selected-element-filter';
      }
      else return 'unselected-element-filter';
    },

    setClassListForShieldAndWeaponStarFilter(starFilter , currentStar){
      if(starFilter === currentStar){
        return 'selected-element-filter';
      }
      else return 'unselected-element-filter';
    },
  },

  components:{
    'pvp-weapon': PvPWeapon,
    'pvp-shield' : PvPShield
  }

};
</script>

<style>

.inventory-container {
  height: auto;
  width: auto;
  font-weight: bold;
  text-align: center;
  color: white;
}

.inventory-header-text {
  font-size: 20px;
  font-weight: bolder;
  color: #968332;
}

.inventory-filter-header {
  font-size: 15px;
  font-weight: bolder;
  color: #fff;
}

.weapon-filter {
  height: 20px;
  width: 20px;
  cursor: pointer;
}

.selected-element-filter {
  border: 2px solid #968332;
  box-shadow: 0 0 10px #fff;
  border-radius: 50%;
}

</style>
