<template>
  <div class = "body main-font">

    <div class ="combat-container">
      <b-tabs justified content-class="mt-3" align="center">
        <b-tab
              :active="pvpArsenalFlag"
              :disabled="!pvpArsenalFlag">
        <template #title>
          Arsenal Preparation
          <!-- <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" /> -->
        </template>
            <div class="find-button">
                <big-button
                      class="btn-styled"
                      :mainText="`X`"
                      v-tooltip=""
                      :disabled="(timeMinutes === 59 && timeSeconds >= 30) || waitingResults"
                      @click="stakeSkill()">
                </big-button>

                <b-modal class="centered-modal" ref="stake-skill-for-pvp"
                  @ok="findEnemies()">
                  <template #modal-title>
                    PAY UP CRYPTOKNIGHT!
                  </template>
                  <b-form-input type="number" :max="10000"
                    class="modal-input" placeholder="Skill to stake for PvP" />
                </b-modal>

            </div>
              <b-col cols="6" class = "character-selection">
                  <div>
                      <div class="header-row character-header">
                      <h1>CHARACTER</h1>
                      </div>
                          <b-tabs justified content-class="mt-3" align="center">
                            <b-tab v-for="character in getCharacterList(1)" :key="character.id" class="drag-el">
                              <template #title>
                                  {{character.name}}
                              </template>
                              <b-row>
                              <b-col cols="4">
                                <img
                                  class="inventory-slot"
                                  alt="Helmet">
                                <img
                                  class="inventory-slot"
                                  alt="Armor">
                                <img
                                  class="inventory-slot"
                                  alt="Boots">
                              </b-col>
                              <b-col cols="4">
                                <img
                                  class="character-card"
                                  :src="character.img">
                              </b-col>
                              <b-col cols="4">
                                <img
                                  class="inventory-slot"
                                  alt="?">
                                <img
                                  class="inventory-slot"
                                  alt="Sword">
                                <img
                                  class="inventory-slot"
                                  alt="Shield">
                              </b-col>
                              </b-row>
                            </b-tab>
                          </b-tabs>
                  </div>
              <b-col cols="6" class="weapon-selection">
                  <div>
                      <div class="header-row inventory-header">
                      <h1>INVENTORY</h1>
                      </div>
                          <b-tabs justified content-class="mt-3" align="center">
                            <b-tab v-for="inventory in getInventoryList(1)" :key="inventory.id" class="drag-el">
                              <template #title>
                                  {{inventory.name}}
                              </template>
                              <b-row>
                              <b-col cols="3">
                              </b-col>
                              <b-col cols="6">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                  <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                  <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                              </b-col>
                              <b-col cols="3">
                              </b-col>
                              </b-row>
                            </b-tab>
                          </b-tabs>
                  </div>
          :active="pvpQueueFlag"
          :disabled="!pvpQueueFlag"
        >
            Find 'em
            <!-- <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" /> -->
          </template>
          <div
            v-if="!enemiesFound"
          >
            <h1> FINDING ENEMIES...</h1>
            <b-spinner type="grow" label="Spinning"></b-spinner>
            <b-spinner type="grow" label="Spinning"></b-spinner>
            <b-spinner type="grow" label="Spinning"></b-spinner>
          </div>
          <div
            v-if="enemiesFound"
          >
            <div>
              <div class="header-row weapon-header">
                  text="Your weapon multiplies your power<br>
                  <br>+Stats determine the multiplier
                  <br>Stat element match with character gives greater bonus"
              </div>
            </div>
          </div>
          :active="pvpArenaFlag"
          :disabled="!pvpArenaFlag"
        >
            Arena
            <!-- <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" /> -->
          </template>
import { mapActions, mapGetters, mapState} from 'vuex';
import img1 from '../assets/placeholder/chara-0.png';
import img2 from '../assets/placeholder/chara-1.png';
import img3 from '../assets/placeholder/chara-2.png';
import img4 from '../assets/placeholder/chara-3.png';
import weap1 from '../assets/placeholder/sword-placeholder-0.png';
import weap2 from '../assets/placeholder/sword-placeholder-1.png';
import weap3 from '../assets/placeholder/sword-placeholder-2.png';
import weap4 from '../assets/placeholder/sword-placeholder-3.png';
import {BModal} from 'bootstrap-vue';
      weap1,
      weap2,
      weap3,
      weap4,
      interval: 0,
    // async selections([characterId, weaponId]) {
    //   if (!this.ownWeapons.find((weapon) => weapon.id === weaponId)) {
    //     this.selectedWeaponId = null;
    //   }
    //   await this.fetchTargets({ characterId, weaponId });
    // },
    ...mapActions(['fetchTargets']),
    },
    stakeSkill(){
      this.$refs['stake-skill-for-pvp'].show();
    getCharacterList(){
      const characters = [
        {id: '0', name: 'Tirasthu Lithuir', img: img1},
        {id: '1', name: 'Voir Ghuru', img: img2},
        {id: '2', name: 'Tutu Whykie', img: img3},
        {id: '3', name: 'Poli Truiy', img: img4},
      ];

      return characters;
    },
    getInventoryList(){
      const characters = [
        {id: '0', name: 'Sword', img: img1},
        {id: '1', name: 'Shield', img: img2},
        {id: '2', name: 'Helmet', img: img3},
        {id: '3', name: 'Boot', img: img4},
        {id: '4', name: 'Armor', img: img1},
        {id: '5', name: 'Others', img: img2},
        {id: '6', name: '?', img: img3},
      ];
      return characters;
    }
  },
    BModal,
.character-card{
  min-width: 200px;
  min-height: 300px;
  max-height: 300px;
  max-width: 200px;
  border : 1px solid #9e8a57;
}

.inventory-slot{
  min-width: 60px;
  min-height: 60px;
  max-height: 60px;
  max-width: 60px;
  border : 1px solid #9e8a57;
  display:block;
  margin-left: auto;
  margin-right: auto;
  margin-top: 10px;
  margin-bottom: 10px;
}

.inventory-box{
  min-width: 60px;
  min-height: 60px;
  max-height: 60px;
  max-width: 60px;
  border : 1px solid #9e8a57;
  margin: 10px;
}

.find-button {
  width: 3em;
.character-selection {
  border-right : 1px solid #9e8a57;
}

    justify-content: center;
    margin-bottom: 20px;
    margin-top: 20px;
}

.inventory-header{
    justify-content: center;
    margin-bottom: 20px;
    margin-top: 20px;
}

.character-header {
          <b-container fluid>
            <b-row>
              <b-col cols="6" class = "character-selection">
                  <div>
                      <div class="header-row character-header">
                      <h1>CHARACTER</h1>
                      </div>
                          <b-tabs justified content-class="mt-3" align="center">
                            <b-tab v-for="character in getCharacterList(1)" :key="character.id" class="drag-el">
                              <template #title>
                                  {{character.name}}
                              </template>
                              <b-row>
                              <b-col cols="4">
                                <img
                                  class="inventory-slot"
                                  alt="Helmet">
                                <img
                                  class="inventory-slot"
                                  alt="Armor">
                                <img
                                  class="inventory-slot"
                                  alt="Boots">
                              </b-col>
                              <b-col cols="4">
                                <img
                                  class="character-card"
                                  :src="character.img">
                              </b-col>
                              <b-col cols="4">
                                <img
                                  class="inventory-slot"
                                  alt="?">
                                <img
                                  class="inventory-slot"
                                  alt="Sword">
                                <img
                                  class="inventory-slot"
                                  alt="Shield">
                              </b-col>
                              </b-row>
                            </b-tab>
                          </b-tabs>
                  </div>
              </b-col>
              <b-col cols="6" class="weapon-selection">
                  <div>
                      <div class="header-row inventory-header">
                      <h1>INVENTORY</h1>
                      </div>
                          <b-tabs justified content-class="mt-3" align="center">
                            <b-tab v-for="inventory in getInventoryList(1)" :key="inventory.id" class="drag-el">
                              <template #title>
                                  {{inventory.name}}
                              </template>
                              <b-row>
                              <b-col cols="3">
                              </b-col>
                              <b-col cols="6">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                  <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                  <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                                <img
                                  class="inventory-box"
                                  :alt="inventory.name">
                              </b-col>
                              <b-col cols="3">
                              </b-col>
                              </b-row>
                            </b-tab>
                          </b-tabs>
                  </div>
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
import { mapActions, mapGetters, mapState} from 'vuex';
import img1 from '../assets/placeholder/chara-0.png';
import img2 from '../assets/placeholder/chara-1.png';
import img3 from '../assets/placeholder/chara-2.png';
import img4 from '../assets/placeholder/chara-3.png';
import weap1 from '../assets/placeholder/sword-placeholder-0.png';
import weap2 from '../assets/placeholder/sword-placeholder-1.png';
import weap3 from '../assets/placeholder/sword-placeholder-2.png';
import weap4 from '../assets/placeholder/sword-placeholder-3.png';
import {BModal} from 'bootstrap-vue';

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
      weap1,
      weap2,
      weap3,
      weap4,
      interval: 0,
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
    // async selections([characterId, weaponId]) {
    //   if (!this.ownWeapons.find((weapon) => weapon.id === weaponId)) {
    //     this.selectedWeaponId = null;
    //   }
    //   await this.fetchTargets({ characterId, weaponId });
    // },
  },

  methods:{
    ...mapActions(['fetchTargets']),
    getWeapons(){
      const selectedWeapon = this.ownWeapons.find((weapon) => weapon.id === this.selectedWeaponId);
      this.selectedWeapon = selectedWeapon;
    },
    stakeSkill(){
      this.$refs['stake-skill-for-pvp'].show();
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
    getCharacterList(){
      const characters = [
        {id: '0', name: 'Tirasthu Lithuir', img: img1},
        {id: '1', name: 'Voir Ghuru', img: img2},
        {id: '2', name: 'Tutu Whykie', img: img3},
        {id: '3', name: 'Poli Truiy', img: img4},
      ];

      return characters;
    },
    getInventoryList(){
      const characters = [
        {id: '0', name: 'Sword', img: img1},
        {id: '1', name: 'Shield', img: img2},
        {id: '2', name: 'Helmet', img: img3},
        {id: '3', name: 'Boot', img: img4},
        {id: '4', name: 'Armor', img: img1},
        {id: '5', name: 'Others', img: img2},
        {id: '6', name: '?', img: img3},
      ];

      return characters;
    }
  },

  components: {
    BigButton,
    BModal,
  },
};
</script>

<style>

.character-card{
  min-width: 200px;
  min-height: 300px;
  max-height: 300px;
  max-width: 200px;
  border : 1px solid #9e8a57;
}

.inventory-slot{
  min-width: 60px;
  min-height: 60px;
  max-height: 60px;
  max-width: 60px;
  border : 1px solid #9e8a57;
  display:block;
  margin-left: auto;
  margin-right: auto;
  margin-top: 10px;
  margin-bottom: 10px;
}

.inventory-box{
  min-width: 60px;
  min-height: 60px;
  max-height: 60px;
  max-width: 60px;
  border : 1px solid #9e8a57;
  margin: 10px;
}

.find-button {
  display: block;
  margin: 0 auto;
  height: 5em;
  width: 3em;
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
  padding-left: 1vw;
  padding-right: 1vw;
}

.character-selection {
  border-right : 1px solid #9e8a57;
}

.weapon-header {
    justify-content: center;
    margin-bottom: 20px;
    margin-top: 20px;
}

.inventory-header{
    justify-content: center;
    margin-bottom: 20px;
    margin-top: 20px;
}

.character-header {
    justify-content: center;
    margin-bottom: 20px;
    margin-top: 20px;
}

.weapon-icon-wrapper {
  background: rgba(255, 255, 255, 0.1);
  width: 12em;
  height: 12em;
}


</style>
