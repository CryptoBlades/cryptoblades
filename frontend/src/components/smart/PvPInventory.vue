<template>
  <div>
        <b-row class="inventory-header-container">
            <b-col>
              <span v-if="getCurrentTab === 0" v-text="`${inventoryTabNames[getCurrentTab].name.toUpperCase()}`+ ' ' + inventoryHeaderText"/>
              <span v-if="getCurrentTab === 1" v-text="`${inventoryTabNames[getCurrentTab].name.toUpperCase()}`+ ' ' + inventoryHeaderText"/>
            </b-col>
        </b-row>
        <b-row v-if="getCurrentTab === 0" class="inventory-weapon-container">
              <b-col v-if="this.ownWeapons.length > 0">
                <b-row>
                  <b-col
                    v-for="weapon in ownWeapons"
                    :key="weapon.id">
                    <div
                      :class="`${setListClassForWeapon(weapon.id,currentWeaponId)}`"
                      @click="setCurrentWeapon(weapon.id)">
                      <div>
                        <span :class="`${setWeaponPvPStatus(weapon.id)}`"></span>
                        <img
                          class="inventory-weapon-content"
                          :src="getWeaponArt(weapon)"/>
                      </div>
                    </div>
                  </b-col>
                </b-row>
              </b-col>

              <b-col v-if="this.ownWeapons.length <= 0">
                You do not have any weapons.
              </b-col>
        </b-row>
        <b-row v-if="getCurrentTab === 1" class="inventory-shield-container">
              <b-col v-if="this.ownShields.length > 0">
                <b-row>
                  <b-col
                    v-for="shield in ownShields"
                    :key="shield.id">
                    <div
                      :class="`${setListClassForShield(shield.id,currentShield.id)}`"
                      @click="setCurrentShield(shield.id)">
                      <div>
                        <img
                          class="inventory-weapon-content"
                          :src="getShieldArt(shield.id)"/>
                      </div>
                    </div>
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
import { getWeaponArt } from '../../weapon-arts-placeholder';
import foundersShield from '../../assets/shield1.png';
import legendaryShield from '../../assets/shield2.png';
import PvPConstants from '../../utils/constants/pvp-constants';

export default {

  data(){
    return {
      inventoryHeaderTextHint: PvPConstants.INVENTORY_HEADER_TEXT_HINT,
      inventoryHeaderText: PvPConstants.INVENTORY_HEADER_TEXT,
    };
  },

  computed: {
    ...mapState(['currentWeaponId','pvp']),
    ...mapGetters([
      'getInventoryState',
      'getCurrentTab',
      'ownWeapons',
      'ownShields',
      'currentShield',
    ]),

    inventoryTabNames(){
      return this.getInventoryState;
    },
  },

  methods: {
    ...mapMutations([
      'setCurrentWeapon',
      'setCurrentShield',
    ]),

    getWeaponArt,

    setListClassForWeapon(weaponId,currentWeaponId){
      if (weaponId === currentWeaponId){
        return 'selected-weapon';
      }

      else return 'unselected-weapon';
    },

    setListClassForShield(shieldId,currentShieldId){
      if (shieldId === currentShieldId){
        return 'selected-shield';
      }

      else return 'unselected-shield';
    },

    setWeaponPvPStatus(weaponID){
      this.$store.dispatch('fetchParticipatingWeapons');

      if(this.pvp.participatingWeapons.includes(weaponID.toString())){
        return 'weapon-in-pvp';
      }
      else return 'weapon-not-in-pvp';

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

  },

  created(){
    if(this.ownShields.length > 0){
      this.setCurrentShield(this.ownShields[0].id);
    }
  }

};
</script>

<style>

.inventory-header-container {
  font-weight: bold;
  text-align: center;
  color: white;
}

/* PvP Inventory Styles */


.inventory-weapon-container {
  text-align: center;
}

.inventory-shield-container {
  text-align: center;
}

.selected-weapon {
  background: transparent;
  border: 1px dashed #968332;
  border-radius: 10%;
  height: 60px;
  width: 60px;
  margin: 10px auto;
}

.selected-weapon:hover{
  cursor: pointer;
}

.unselected-weapon {
  background: transparent;
  border: 1px none transparent;
  border-radius: 10%;
  height: 60px;
  width: 60px;
  margin: 10px auto;
}

.unselected-weapon:hover {
  cursor: pointer;
}

.selected-shield {
  background: transparent;
  border: 1px dashed #968332;
  border-radius: 10%;
  height: 60px;
  width: 60px;
  margin: 10px auto;
}

.selected-shield:hover{
  cursor: pointer;
}

.unselected-shield {
  background: transparent;
  border: 1px none transparent;
  border-radius: 10%;
  height: 60px;
  width: 60px;
  margin: 10px auto;
}

.unselected-shield:hover{
  cursor: pointer;
}

.inventory-weapon-content {
  background: transparent;
  border: 2px solid #968332;
  border-radius: 10%;
  height: 50px;
  width: 50px;
  margin: 3px auto;
}

#inventory-weapon-content-dashed {
  background: transparent;
  border: 1px dashed #968332;
  border-radius: 10%;
  height: 50px;
  width: 50px;
  margin: 10px auto;
}

/* PvP Inventory Styles */

/* PvP Status Styles */
.weapon-in-pvp {
    color: white;
    height: 20px;
    width: 50px;
    background-color: rgb(187, 33, 0);
    border-radius: 10%;
    transform: rotate(30deg);
    position: absolute;
    left: 30%;
    top: 20%;
    z-index: 100;
}

.weapon-in-pvp::before {
  content: "IN PVP";
}
/* PvP Status Styles */
</style>
