<template>
  <div class = "body main-font">
    <div class = "pvp-container">
      <!-- here goes the stepper -->
    </div>

    <div class ="combat-container">
      <b-tabs justified content-class="mt-3" align="center">
        <b-tab
          :active="pvpArsenalFlag"
          :disabled="!pvpArsenalFlag"
        >
          <template #title>
            Arsenal Preparation
            <!-- <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" /> -->
          </template>
          <b-container fluid>
            <b-row>
              <b-col cols="5" class="weapon-selection">
                <div>
                  <div class="header-row weapon-header">
                    <h1>Choose your weapon</h1>
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
                  <b-button
                    v-if="selectedWeaponId"
                    variant="primary"
                    class="ml-3"
                    @click="selectedWeaponId = null"
                    id="gtag-link-others"
                    tagname="choose_weapon"
                  >
                      Choose New Weapon
                  </b-button>
                </div>
                <weapon-grid
                  v-if="!selectedWeaponId"
                  v-model="selectedWeaponId"
                  checkForDurability="true"
                />
              </b-col>
              <b-col cols="1">
              </b-col>
              <b-col cols="5" class = "character-container">
                <div>
                  <div class="header-row weapon-header">
                    <h1>Choose your character</h1>
                    <Hint
                      text="Your weapon multiplies your power<br>
                      <br>+Stats determine the multiplier
                      <br>Stat element match with character gives greater bonus"
                    />
                  </div>
                </div>
                <character-list
                  :value="currentCharacterId"
                  @input="setCurrentCharacter"
                />
              </b-col>
              <b-col cols="1">
                <big-button
                  class="encounter-button btn-styled"
                  :mainText="`X`"
                  v-tooltip=""
                  :disabled="(timeMinutes === 59 && timeSeconds >= 30) || waitingResults"
                  @click="findEnemies()"
                />
              </b-col>
            </b-row>
          </b-container>
        </b-tab>
        <b-tab
          :active="pvpQueueFlag"
          :disabled="!pvpQueueFlag"
        >
          <template #title>
            Find 'em
            <!-- <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" /> -->
          </template>

          <div
            class="text-center header-row weapon-header"
            v-if="!enemiesFound"
          >
            <h1> FINDING ENEMIES...</h1>
            <b-spinner type="grow" label="Spinning"></b-spinner>
            <b-spinner type="grow" label="Spinning"></b-spinner>
            <b-spinner type="grow" label="Spinning"></b-spinner>
          </div>

          <div
            class="text-center"
            v-if="enemiesFound"
          >
            <div>
              <div class="header-row weapon-header">
                <h1>DISPLAY ENEMIES HERE</h1>
                <!-- <Hint
                  text="Your weapon multiplies your power<br>
                  <br>+Stats determine the multiplier
                  <br>Stat element match with character gives greater bonus"
                /> -->
              </div>
            </div>
          </div>
        </b-tab>
        <b-tab
          :active="pvpArenaFlag"
          :disabled="!pvpArenaFlag"
        >
          <template #title>
            Arena
            <!-- <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" /> -->
          </template>
        </b-tab>
      </b-tabs>
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
      pvpArsenalFlag: true,
      pvpQueueFlag: false,
      pvpArenaFlag: false,
      enemiesFound: false,
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
    findEnemies(){
      this.pvpArsenalFlag = false;
      this.pvpQueueFlag = true;
      this.pvpArenaFlag = false;

      setTimeout(() => this.enemiesFound = true, 2000);
    },
    enterArena(){
      this.pvpArsenalFlag = false;
      this.pvpQueueFlag = false;
      this.pvpArenaFlag = true;
    },
    initiateCombat(){
      this.pvpArsenalFlag = false;
      this.pvpQueueFlag = false;
      this.pvpArenaFlag = false;
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

.pvp-container {
  display : flex;
  margin-bottom: 50px;
}

.combat-container {
  margin: 50px;
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

}

.weapon-container {

}

.fight-button {
  padding-left: 50px;
}

.enter-pvp {
  padding-bottom: 20px;
}

.leave-pvp {
  padding-top: 20px;
}


</style>
