<template>
  <div>
    <span
      v-bind:id="getWeaponElement"
      v-if="type === weapon_nft"/>
    <span
      v-bind:id="getCharacterElement"
      v-if="type === character_nft"/>
    <span
      v-bind:id="getShieldElement"
      v-if="type === shield_nft"/>
  </div>
</template>

<script>
import Weapons from '../../utils/constants/mocked-weapons';
import PvPConstants from '../../utils/constants/pvp-constants';

export default {
  props:{
    nftId: Number,
    type: String,
  },
  data(){
    return {
      character_nft:PvPConstants.CHARACTER_NFT,
      weapon_nft:PvPConstants.WEAPON_NFT,
      shield_nft:PvPConstants.SHIELD_NFT,
    };
  },
  computed: {
    getWeaponElement(){
      let searchedElement;
      const nftId = this.nftId;

      Object.entries(Weapons).map(function(weaponsArray) {
        weaponsArray[1].forEach(weapon => {
          if(nftId === weapon.id){
            searchedElement = weapon.element;
          }
        });
      });

      if(searchedElement === PvPConstants.FIRE_ELEMENT){
        return 'fire-element';
      }
      else if (searchedElement === PvPConstants.EARTH_ELEMENT){
        return 'earth-element';
      }
      else if (searchedElement === PvPConstants.LIGHTNING_ELEMENT){
        return 'lightning-element';
      }
      else if (searchedElement === PvPConstants.WATER_ELEMENT){
        return 'water-element';
      }

      return '';
    },
    getCharacterElement(){
      return '';
    },
    getShieldElement(){
      return '';
    },
  }
};
</script>

<style>
/* Element Style */
#fire-element {
  content: url("../../assets/elements/fire.png");
  border: 1px solid #968332;
  border-radius: 50%;
  height: 30px;
  width: 30px;
}

#earth-element {
  content: url("../../assets/elements/earth.png");
  border: 1px solid #968332;
  border-radius: 50%;
  height: 30px;
  width: 30px;
}

#lightning-element {
  content: url("../../assets/elements/lightning.png");
  border: 1px solid #968332;
  border-radius: 50%;
  height: 30px;
  width: 30px;
}

#water-element {
  content: url("../../assets/elements/water.png");
  border: 1px solid #968332;
  border-radius: 50%;
  height: 30px;
  width: 30px;
}
/* Element Style */
</style>
