<template>
  <div>
        <span class="arena-header-label">Tier </span> {{getArenaTier}}<br>
        <span class="arena-header-label">Arena Cost </span> {{getEntryWager}}<br>
        <span class="arena-header-label">Duel Cost</span> {{getDuelCost}}<br>
        <span class="arena-header-label">Wagered Skill </span> {{getWageredSkill}}<br>
        <button
              class="arena-button"
              v-text="getArenaButtonText"
              @click="arenaAction"/><br>
  </div>
</template>

<script>
import BN from 'bignumber.js';
import { mapActions, mapGetters, mapState, mapMutations } from 'vuex';
import PvPConstants from '../../utils/constants/pvp-constants';

export default {

  data(){
    return {
      pvpState: null,
      enterArenaText: PvPConstants.ENTER_ARENA_TEXT,
      goToArenaText: PvPConstants.GO_TO_ARENA_TEXT,
    };
  },
  computed: {
    ...mapState(['currentCharacterId','currentWeaponId','pvp']),
    ...mapGetters([
      'getCharacterName',
      'currentWeapon',
      'currentCharacter',
      'currentShield']),

    getEntryWager(){
      const entryWager = new BN(this.pvp.entryWager).div(new BN(10).pow(18)).toFixed(4);
      return entryWager;
    },

    getWageredSkill(){
      const wageredSkill = new BN(this.pvp.wageredSkill).div(new BN(10).pow(18)).toFixed(4);
      return wageredSkill;
    },

    getArenaTier(){
      const arenaTier = this.pvp.arenaTier;
      return arenaTier;
    },
    getDuelCost(){
      const duelCost = new BN(this.pvp.duelCost).div(new BN(10).pow(18)).toFixed(4);
      return duelCost;
    },
    getArenaButtonText(){
      if(this.pvp.isCharacterInArena){
        return this.goToArenaText;
      }
      else
        return this.enterArenaText;
    }
  },

  methods: {
    ...mapActions(['enterArena']),
    ...mapMutations(['setCurrentPvPCharacter']),

    enterArena(){
      this.$store.dispatch('enterArena',
        {characterID: this.currentCharacterId,
          weaponID: this.currentWeaponId,
          shieldID: 0,
          useShield: false});
    },

    goTo(){
      this.$store.dispatch('fetchArenaPage', {page: '1'});
      this.$store.dispatch('fetchParticipatingCharacters');
      this.setCurrentPvPCharacter(this.currentCharacterId);
    },

    arenaAction(){
      if(this.pvp.isCharacterInArena){
        this.goTo();
      }
      else
        this.enterArena();
    }
  }
};
</script>

<style>

.arena-header-label {
  font-size: 12px;
  color: #968332;
}

.arena-button {
  color:#968332;
  font-weight: bold;
  background-color: #3a3935;
}

.arena-button:hover {
  text-shadow: 0 0 10px black, 0 0 20px #fff;
  cursor: pointer;
}

</style>
