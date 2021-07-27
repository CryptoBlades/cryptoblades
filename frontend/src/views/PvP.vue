<template>
  <div class = "body main-font">
    <div class = "pvp-container">
        <big-button
            v-if="!battleFlag"
            class="encounter-button btn-styled"
            :mainText="`ATTACK`"
            v-tooltip="'Cost x-amount of skill'"
            :disabled="(timeMinutes === 59 && timeSeconds >= 30) || waitingResults"
            @click="showAttackView()"
        />
        <big-button
            v-if="!battleFlag"
            class="encounter-button btn-styled"
            :mainText="`DEFEND`"
            v-tooltip="'Cost x-amount of skill'"
            :disabled="(timeMinutes === 59 && timeSeconds >= 30) || waitingResults"
            @click="showDefendView()"
        />

    </div>
    <div class ="combat-container" v-if="characterFlag">
        <div class="weapon-container weapon-selection" v-if="weaponFlag">
          <div class="col">
                <div class="header-row weapon-header">
                <h1>Choose a weapon</h1>
                <Hint
                text="Your weapon multiplies your power<br>
                <br>+Stats determine the multiplier
                <br>Stat element match with character gives greater bonus"
                />
                </div>
          </div>
          <div v-if="selectedWeaponId" class="weapon-icon-wrapper">
              <weapon-icon
                  class = "select-char-weap"
                  :weapon="selectedWeapon"
           />
        <b-button v-if="selectedWeaponId" variant="primary" class="ml-3" @click="selectedWeaponId = null" id="gtag-link-others" tagname="choose_weapon">
                  Choose New Weapon
        </b-button>
              </div>
              <weapon-grid
                  v-if="!selectedWeaponId"
                  v-model="selectedWeaponId"
                  checkForDurability="true" />

        </div>

        <div class= "fight-button" v-if="battleFlag">
            <div class="enter-pvp">
              <big-button
                  v-if="battleFlag"
                  class="encounter-button btn-styled"
                  :mainText="`ENTER`"
                  v-tooltip="'Cost x-amount of skill'"
                  :disabled="(timeMinutes === 59 && timeSeconds >= 30) || waitingResults"
                  @click="showAttackView()"
              />
            </div>
            <div class="leave-pvp">
              <big-button
                  v-if="battleFlag"
                  class="encounter-button btn-styled back-button"
                  :mainText="`LEAVE`"
                  v-tooltip="'Go back to choose battle mode'"
                  :disabled="(timeMinutes === 59 && timeSeconds >= 30) || waitingResults"
                  @click="showChooseBattleMode()"
               />
            </div>
        </div>

        <div class = "character-container">
          <character-list
            :value="currentCharacterId"
            @input="setCurrentCharacter"
          />
        </div>

    </div>
  </div>
</template>

<script>
import BigButton from '../components/BigButton.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
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
      weaponFlag: false,
      characterFlag: false,
      battleFlag: false,
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
    },
    showAttackView(){
      this.characterFlag = true;
      this.weaponFlag = true;

      this.battleFlag = true;
    },

    showDefendView(){
      this.characterFlag = true;
      this.weaponFlag = true;

      this.battleFlag = true;
    },

    showChooseBattleMode(){
      this.characterFlag = false;
      this.weaponFlag = false;

      this.battleFlag = false;
    },
  },



  components: {
    BigButton,
    WeaponGrid,
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

.back-button {
  justify-content: right;
}

.pvp-container {
  display : flex;
  margin-bottom: 50px;
}

.combat-container {
  display:flex;
  margin-top: 50px;
}

.header-row {
  display: flex;
  align-items: center;
}


.header-row h1 {
  margin-left: 10px;
  margin-bottom: 5px;
}

.header-row .hint {
  font-size: 2em;
}

.weapon-selection {
  border-right : 1px solid #9e8a57;
  padding-left: 1vw;
  padding-right: 1vw;
}

.weapon-header {
    justify-content: center;
    margin-bottom: 20px;
    margin-top: 20px;
}

.weapon-icon-wrapper {
  background: rgba(255, 255, 255, 0.1);
  width: 12em;
  height: 12em;
}

.character-container {
  flex:30%
}

.weapon-container {
  flex:30%
}

.fight-button {
  padding-left: 50px;
  flex:20%
}

.enter-pvp {
  padding-bottom: 20px;
}

.leave-pvp {
  padding-top: 20px;
}


</style>
