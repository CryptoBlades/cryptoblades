<template>
  <div>
        <span class="fighter-combat-details-label">Arena Cost</span> {{getEntryWager}}<br>
        <span class="fighter-combat-details-label">Arena Checks</span><br>
        <span>Character</span>
        <span v-if="!pvp.isCharacterInArena" class="ready"></span>
        <span v-if="pvp.isCharacterInArena" class="not-ready"></span><br>
        <span>Weapon</span>
        <span v-if="!pvp.isWeaponInArena" class="ready"></span>
        <span v-if="pvp.isWeaponInArena" class="not-ready"></span><br>
        <span>Shield (Optional)</span>
        <span v-if="!pvp.isShieldInArena" class="ready"></span>
        <span v-if="pvp.isShieldInArena" class="not-ready"></span><br>
        <b-modal id="enterArenaErrorModal" title="STOP RIGHT THERE!" ok-only>
                <span class="enter-arena-error-label">Weapon Error: </span>
                <span class="enter-arena-error-value" v-text="this.weaponErrorMessage"></span><br>
                <span class="enter-arena-error-label">Shield Error: </span>
                <span class="enter-arena-error-value" v-text="this.shieldErrorMessage"></span><br>
        </b-modal>
        <div class="arena-button">
          <span
            v-text="getArenaButtonText"
            @click="arenaAction"/><br>
        </div>
        <div class="view-stats-arena-details-container">
          <span
            @click="openStats()">VIEW STATS</span>
        </div>
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
      canEnterArena: false,
      weaponErrorMessage: 'No issues here',
      shieldErrorMessage: 'No issues here'
    };
  },
  computed: {
    ...mapState(['currentCharacterId','currentWeaponId','pvp']),
    ...mapGetters([
      'getCharacterName',
      'currentWeapon',
      'currentCharacter',
      'currentShield',
      'ownShields',
      'ownWeapons']),

    getEntryWager(){
      const entryWager = new BN(this.pvp.entryWager).div(new BN(10).pow(18)).toFixed(4);
      return entryWager;
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
    ...mapMutations([
      'setCurrentPvPCharacter',
      'updateIsShieldInArena',
      'updateShowStats',
      'updateIsLoading'
    ]),

    openStats(){
      this.updateShowStats(true);
    },

    async enterArena(){
      this.updateIsLoading(true);
      let canEnterArena = false;
      this.weaponErrorMessage = '';
      this.shieldErrorMessage = '';

      if (this.pvp.isWeaponInArena && this.currentWeapon !== null){
        this.weaponErrorMessage += 'Weapon ';
        canEnterArena = false;
      }
      if (this.pvp.isShieldInArena && this.currentShield !== null){
        this.shieldErrorMessage += 'Shield ';
        canEnterArena = false;
      }
      if (this.currentShield !== null && !canEnterArena && this.shieldErrorMessage !== ''){
        this.shieldErrorMessage += 'is already in arena.';
      }
      if (this.currentWeapon !== null && !canEnterArena && this.weaponErrorMessage !== ''){
        this.weaponErrorMessage += 'is already in arena.';
      }
      if(this.shieldErrorMessage === ''){
        this.shieldErrorMessage = 'No issues here.';
      }
      if(this.weaponErrorMessage === ''){
        this.weaponErrorMessage = 'No issues here.';
      }
      if (this.currentWeapon === null &&
               this.ownWeapons.length >= 1 &&
               this.pvp.isWeaponInArena){
        this.weaponErrorMessage = 'Please select a weapon.';
        canEnterArena = false;
      }
      if (this.currentShield === null &&
               this.ownShields.length >= 1 &&
               this.pvp.isShieldInArena){
        this.shieldErrorMessage = 'Please select a shield.';
        canEnterArena = false;
      }
      if(!this.pvp.isCharacterInArena &&
         !this.pvp.isWeaponInArena &&
         !this.pvp.isShieldInArena){
        canEnterArena = true;
      }

      if (this.currentShield === null && this.currentWeapon === null && !canEnterArena){
        this.errorMessage = 'Please select a weapon and a shield.';
        this.$bvModal.show('enterArenaErrorModal');
      }

      if(this.currentShield && canEnterArena){
        await this.$store.dispatch('enterArena',
          {characterID: this.currentCharacterId,
            weaponID: this.currentWeaponId,
            shieldID: this.currentShield.id,
            useShield: true});
        await Promise.all([
          this.$store.dispatch('fetchIsCharacterInArena',{characterID: this.currentCharacterId}),
          this.$store.dispatch('fetchIsWeaponInArena',{ weaponID: this.currentWeaponId }),
          this.$store.dispatch('fetchIsShieldInArena', { shieldID: this.currentShield.id })
        ]);
      }
      else if (this.currentShield === null && canEnterArena){
        await this.$store.dispatch('enterArena',
          {characterID: this.currentCharacterId,
            weaponID: this.currentWeaponId,
            shieldID: 0,
            useShield: false});
        await Promise.all([
          this.$store.dispatch('fetchIsCharacterInArena',{characterID: this.currentCharacterId}),
          this.$store.dispatch('fetchIsWeaponInArena',{ weaponID: this.currentWeaponId }),
          this.updateIsShieldInArena({ isShieldInArena: false })
        ]);
      }
      else if (!canEnterArena){
        this.$bvModal.show('enterArenaErrorModal');
      }
      this.updateIsLoading(false);
    },

    async goTo(){
      this.setCurrentPvPCharacter(this.currentCharacterId);

      await Promise.all([
        this.$store.dispatch('updatePvPDetails', {characterID: this.currentCharacterId}),
        this.$store.dispatch('fetchArenaPage', {page: '1'})
      ]);
    },

    arenaAction(){
      if(this.pvp.isCharacterInArena){
        this.goTo();
      }
      else{
        this.enterArena();
      }
    }
  }
};
</script>

<style>

.arena-button {
  height: auto;
  width: 150px;
  color:#968332;
  font-weight: bolder;
  border: 1px solid #968332;
  border-radius: 5%;
  box-shadow: 0 0 10px #fff;
  background-color: #252525;
  margin-top: 10px;
  text-align: center;
}

.arena-button:hover {
  cursor: pointer;
}

.ready::after {
  content: '\2713';
  color: greenyellow;
}

.not-ready::after {
  content: '\2613';
  color: red;
}

.enter-arena-error-label {
  font-size: 15px;
  color: #968332;
  font-weight: bolder;
  letter-spacing: 1px;
}

.enter-arena-error-value {
  font-size: 15px;
  color: #fff;
  font-weight: bold;
}

.view-stats-arena-details-container {
  height: auto;
  width: 150px;
  color:#968332;
  font-weight: bolder;
  border: 1px solid #968332;
  border-radius: 5%;
  box-shadow: 0 0 10px #fff;
  background-color: #252525;
  margin-top: 10px;
  text-align: center;
  cursor: pointer;
}

</style>
