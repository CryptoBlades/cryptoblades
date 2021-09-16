<template>
  <div>
    <span
      :id="`${setIdForElement()}`"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import PvPConstants from '../../utils/constants/pvp-constants';

export default {

  props:{
    trait: String
  },

  computed: {
    ...mapGetters(['currentCharacter']),
  },

  methods:{

    setIdForElement(){
      if(this.trait === PvPConstants.FIRE_ELEMENT){
        return 'fire-element';
      }
      else if(this.trait === PvPConstants.EARTH_ELEMENT){
        return 'earth-element';
      }
      else if(this.trait === PvPConstants.LIGHTNING_ELEMENT){
        return 'lightning-element';
      }
      else if(this.trait === PvPConstants.WATER_ELEMENT){
        return 'water-element';
      }
      else return '';
    },
  },

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
  background: black;
}

#earth-element {
  content: url("../../assets/elements/earth.png");
  border: 1px solid #968332;
  border-radius: 50%;
  height: 30px;
  width: 30px;
  background: black;
}

#lightning-element {
  content: url("../../assets/elements/lightning.png");
  border: 1px solid #968332;
  border-radius: 50%;
  height: 30px;
  width: 30px;
  background: black;
}

#water-element {
  content: url("../../assets/elements/water.png");
  border: 1px solid #968332;
  border-radius: 50%;
  height: 30px;
  width: 30px;
  background: black;
}
/* Element Style */
</style>
