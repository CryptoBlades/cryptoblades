<template>
  <div>
    Arena Type{{this.arenaType}}
    Entry Wager{{this.entryWager}}
    Wagered Skill {{this.wageredSkill}}
    Arena Tier {{this.arenaTier}}
    Participating Characters {{this.participatingCharacters}}
    Duel Cost {{this.duelCost}}

  </div>
</template>

<script>
import { mapGetters, mapState } from 'vuex';
import BN from 'bignumber.js';

export default {

  data(){
    return {
      pvpState: null,
      arenaType: 0,
      entryWager: 0,
      wageredSkill: 0,
      arenaTier: 0,
      participatingCharacters: null,
      duelCost: 0,
    };
  },
  computed: {
    ...mapState(['currentCharacterId','currentWeaponId']),
    ...mapGetters(['getPvPState', 'currentShield']),
  },

  methods: {

    setArenaDetailsForChar(){
      this.$store.dispatch('fetchArenaType');
      this.$store.dispatch('fetchEntryWager',{characterID: this.currentCharacterId});
      this.$store.dispatch('fetchArenaTier',{characterID: this.currentCharacterId});
      // this.$store.dispatch('fetchWageredSkill',{characterID: this.currentCharacterId});
      this.$store.dispatch('fetchParticipatingCharacters');
      this.$store.dispatch('fetchDuelCost',{characterID: this.currentCharacterId});
      this.$store.dispatch('fetchIsAttackerWithinDecisionTime',{characterID: this.currentCharacterId});
      this.$store.dispatch('fetchIsCharacterAttackable',{characterID: this.currentCharacterId});
      this.$store.dispatch('fetchIsCharacterInArena',{characterID: this.currentCharacterId});
    },

    setArenaDetailsForWeapon(){
      this.$store.dispatch('fetchIsWeaponInArena',{weaponID: this.currentWeaponId});
    },

    setArenaDetailsForShield(){
      this.$store.dispatch('fetchIsShieldInArena',{shieldID: this.currentShield.id});
    },

  },

  mounted(){
    console.log('I am called');

    this.setArenaDetailsForChar();
    this.setArenaDetailsForWeapon();
    this.setArenaDetailsForShield();

    this.pvpState = this.getPvPState;

    this.arenaType = this.pvpState.type;

    this.entryWager = new BN(this.pvpState.entryWager).div(new BN(10).pow(18)).toFixed(4);

    this.wageredSkill = new BN(this.pvpState.wageredSkill).div(new BN(10).pow(18).toFixed(4));

    this.arenaTier = this.pvpState.arenaTier;

    this.duelCost = new BN(this.pvpState.duelCost).div(new BN(10).pow(18).toFixed(4));
  }

};
</script>
