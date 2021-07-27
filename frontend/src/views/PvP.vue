<template>
  <div class = "body main-font">
    <div class="pvp-container">
        <big-button
            class="encounter-button btn-styled"
            :mainText="`ATTACK`"
            v-tooltip="'Cost x-amount of skill'"
            :disabled="(timeMinutes === 59 && timeSeconds >= 30) || waitingResults"
            @click="showAttackView()"
        />
        <big-button
            class="encounter-button btn-styled"
            :mainText="`DEFEND`"
            v-tooltip="'Cost x-amount of skill'"
            :disabled="(timeMinutes === 59 && timeSeconds >= 30) || waitingResults"
            @click="showDefendView()"
        />
    </div>
  <div>
    <character-list
            class = "select-char-weap col-md-2"
            :value="currentCharacterId"
            @click="showWeapons()"
          />
    <weapon-icon
            class = "select-char-weap col-md-2"
            :weapon="0"
             />
  </div>
  </div>
</template>

<script>
import BigButton from '../components/BigButton.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponIcon from '@/components/WeaponIcon.vue';
import { mapGetters, mapState} from 'vuex';

export default {

  data() {
    return {
      selectedWeaponId: null,
      error: null,
      waitingResults: false,
      resultsAvailable: false,
      fightResults: null,
      intervalSeconds: null,
      intervalMinutes: null,
      timeSeconds: null,
      timeMinutes: null,
      fightXpGain: 32,
      selectedWeapon: null,
    };
  },

  created() {
    this.intervalSeconds = setInterval(() => (this.timeSeconds = new Date().getSeconds()), 5000);
    this.intervalMinutes = setInterval(() => (this.timeMinutes = new Date().getMinutes()), 20000);
  },

  computed: {
    ...mapState(['currentCharacterId']),
    ...mapGetters([
      'getTargetsByCharacterIdAndWeaponId',
      'ownCharacters',
      'ownWeapons',
      'currentCharacter',
      'currentCharacterStamina',
      'getWeaponDurability',
      'fightGasOffset',
      'fightBaseline'
    ]),

    targets() {
      return this.getTargetsByCharacterIdAndWeaponId(this.currentCharacterId, this.selectedWeaponId);
    },

    isLoadingTargets() {
      return this.targets.length === 0 && this.currentCharacterId && this.selectedWeaponId;
    },

    selections() {
      return [this.currentCharacterId, this.selectedWeaponId];
    },

    updateResults() {
      return [this.fightResults, this.error];
    },
  },

  watch:{
    async selections([characterId, weaponId]) {
      if (!this.ownWeapons.find((weapon) => weapon.id === weaponId)) {
        this.selectedWeaponId = null;
      }
      await this.fetchTargets({ characterId, weaponId });
    },
  },

  methods:{

    getWeapons(){
      const selectedWeapon = this.ownWeapons.find((weapon) => weapon.id === this.selectedWeaponId);
      this.selectedWeapon = selectedWeapon;
    }
  },

  components: {
    BigButton,
    // WeaponGrid,
    CharacterList,
    WeaponIcon,
  },
};
</script>

<style>

.encounter-button {
  display: block;
  margin: 0 auto;
  height: 5em;
  width: 13em;
  position: relative;
  top: 3vw;
}

.pvp-container {
  display : flex;
  margin-bottom: 50px;
}

.select-char-weap {
  display:inline;
}


</style>
