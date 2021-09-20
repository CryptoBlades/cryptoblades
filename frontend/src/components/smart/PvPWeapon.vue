<template>
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
</template>

<script>
import { mapMutations, mapState } from 'vuex';
import { getWeaponArt } from '../../weapon-arts-placeholder';

export default {

  props: ['weapon','currentWeaponId','inPvP'],

  computed: {
    ...mapState(['pvp']),
  },

  methods: {
    ...mapMutations(['setCurrentWeapon']),

    getWeaponArt,

    setListClassForWeapon(weaponId,currentWeaponId){
      if (weaponId === currentWeaponId){
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
  }
};
</script>

<style>
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

.inventory-weapon-content {
  background: transparent;
  border: 2px solid #968332;
  border-radius: 10%;
  height: 50px;
  width: 50px;
  margin: 3px auto;
}

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
