<template>
  <div class="inventory-container">
        <b-row>
            <b-col>
              <span v-if="getCurrentTab === 0" v-text="`${inventoryTabNames[getCurrentTab].name.toUpperCase()}`+ ' ' + inventoryHeaderText"/>
              <span v-if="getCurrentTab === 1" v-text="`${inventoryTabNames[getCurrentTab].name.toUpperCase()}`+ ' ' + inventoryHeaderText"/>
            </b-col>
        </b-row>
        <b-row v-if="getCurrentTab === 0">
              <b-col v-if="this.ownWeapons.length > 0">
                <b-row>
                  <b-col
                    v-for="weapon in ownWeapons"
                    :key="weapon.id">
                        <pvp-weapon
                          :weapon="weapon"
                          :currentWeaponId="currentWeaponId"
                          :inPvP="false"></pvp-weapon>
                  </b-col>
                </b-row>
              </b-col>

              <b-col v-if="this.ownWeapons.length <= 0">
                You do not have any weapons.
              </b-col>
        </b-row>
        <b-row v-if="getCurrentTab === 1">
              <b-col v-if="this.ownShields.length > 0">
                <b-row>
                  <b-col
                    v-for="shield in ownShields"
                    :key="shield.id">
                      <pvp-shield
                        :shield="shield"
                        :currentShieldId="currentShield.id"
                        :inPvP="false"></pvp-shield>
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
import { mapGetters, mapState } from 'vuex';
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

  components:{
    'pvp-weapon': PvPWeapon,
    'pvp-shield' : PvPShield
  }

};
</script>

<style>

.inventory-container {
  font-weight: bold;
  text-align: center;
  color: white;
}

</style>
