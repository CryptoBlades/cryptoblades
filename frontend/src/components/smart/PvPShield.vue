<template>
    <div
      :class="`${setListClassForShield(shield.id,currentShieldId)}`"
      @click="setCurrentShield(shield.id)">
      <div>
        <span :class="`${setShieldPvPStatus(shield.id)}`"></span>
        <img
            class="inventory-shield-content"
            :src="getShieldArt(shield.id)"/>
      </div>
    </div>
</template>

<script>

import { mapMutations, mapState } from 'vuex';
import foundersShield from '../../assets/shield1.png';
import legendaryShield from '../../assets/shield2.png';

export default {
  props: ['shield','currentShieldId', 'inPvP'],

  computed: {
    ...mapState(['pvp']),
  },

  methods:{
    ...mapMutations([
      'setCurrentShield',
    ]),

    setListClassForShield(shieldId,currentShieldId){
      if (shieldId === currentShieldId){
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
  }
};
</script>

<style>
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

.inventory-shield-content {
  background: transparent;
  border: 2px solid #968332;
  border-radius: 10%;
  height: 50px;
  width: 50px;
  margin: 3px auto;
}

/* PvP Status Styles */
.shield-in-pvp {
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

.shield-in-pvp::before {
  content: "IN PVP";
}
/* PvP Status Styles */
</style>
