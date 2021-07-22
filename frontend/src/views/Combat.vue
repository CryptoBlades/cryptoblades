<template>
  <div class="body main-font">
    <div v-if="ownWeapons.length > 0 && ownCharacters.length > 0">
      <div class="row" v-if="error !== null">
        <div class="col error">Error: {{ error }}</div>
      </div>

      <div class="row" v-if="resultsAvailable">
        <div class="col">
          <CombatResults v-if="resultsAvailable" :results="fightResults" />
        </div>
      </div>

      <div class="row">
        <div class="col">
          <div class="message-box" v-if="!currentCharacter">You need to select a character to do battle.</div>

          <div class="message-box" v-if="currentCharacter && currentCharacterStamina < 40">You need 40 stamina to do battle.</div>

          <div class="message-box" v-if="timeMinutes === 59 && timeSeconds >= 30">You cannot do battle during the last 30 seconds of the hour. Stand fast!</div>
        </div>
      </div>

      <img src="../assets/divider7.png" class="info-divider enemy-divider" />

      <div class="row" v-if="currentCharacterStamina >= 40">
        <div class="col">
          <div class="row">
            <div class="col">
              <div class="waiting" v-if="waitingResults" margin="auto">
                <i class="fas fa-spinner fa-spin"></i>
                Waiting for fight results...
              </div>
            </div>
          </div>
          <div class="combat-enemy-container">
            <div class="col weapon-selection">
              <div class="header-row weapon-header">
                <h1>Choose a weapon</h1>
                <Hint
                  text="Your weapon multiplies your power<br>
                  <br>+Stats determine the multiplier
                  <br>Stat element match with character gives greater bonus"
                />
              </div>
              <div class="header-row">
                <div v-if="selectedWeaponId" class="weapon-icon-wrapper">
                  <weapon-icon class="weapon-icon" :weapon="selectedWeapon" />
                </div>
                <b-button v-if="selectedWeaponId" variant="primary" class="ml-3" @click="selectedWeaponId = null" id="gtag-link-others" tagname="choose_weapon">
                  Choose New Weapon
                </b-button>
              </div>

              <weapon-grid v-if="!selectedWeaponId" v-model="selectedWeaponId" />

            </div>
            <div class="row mb-3 flex-column enemy-container" v-if="targets.length > 0">
              <div class="row">
                <div class="col text-center">
                  <div class="combat-hints">
                    <span class="fire-icon" /> » <span class="earth-icon" /> » <span class="lightning-icon" /> » <span class="water-icon" /> »
                    <span class="fire-icon" />

                    <Hint
                      text="The elements affect power:<br>
                      <br>Character vs Enemy: bonus or penalty as shown above
                      <br>Character and Weapon match gives bonus"
                    />
                  </div>
                </div>
              </div>
              <div class="enemy-list">
                <div class="col-md-3 col-sm-12 col-xs-12 encounter" v-for="(e, i) in targets" :key="i">
                  <div class="encounter-container">

                  <div class="enemy-character">
                    <div class="encounter-element">
                        <span :class="getCharacterTrait(e.trait).toLowerCase() + '-icon'" />
                      </div>

                      <div class="mobile-divider mobile-img-adjustment">
                        <img class="mr-auto ml-auto enemy-img" :src="getEnemyArt(e.power)" alt="Enemy" />
                      </div>

                      <div class="encounter-power">
                        {{ e.power }} Power
                      </div>

                      <div class="xp-gain">
                        +{{getPotentialXp(e)}} XP
                      </div>
                  </div>

                  <div class="victory-chance">
                    {{ getWinChance(e.power, e.trait) }} Victory
                  </div>

                  <big-button
                    class="encounter-button btn-styled"
                    :mainText="`Fight!`"
                    v-tooltip="'Cost 40 stamina'"
                    :disabled="(timeMinutes === 59 && timeSeconds >= 30) || waitingResults"
                    @click="onClickEncounter(e)"
                  />

                  <p v-if="isLoadingTargets">Loading...</p>
                  </div>
                </div>
              </div>
          </div>
          </div>

        </div>
      </div>

      <div></div>
    </div>

    <div class="blank-slate" v-if="ownWeapons.length === 0 || ownCharacters.length === 0">
      <div v-if="ownWeapons.length === 0">You do not currently have any weapons. You can forge one at the Blacksmith.</div>

      <div v-if="ownCharacters.length === 0">You do not currently have any characters. You can recruit one at the Plaza.</div>
    </div>
  </div>
</template>

<script>
// import Character from "../components/Character.vue";
import BigButton from '../components/BigButton.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import { getEnemyArt } from '../enemy-art';
import { CharacterPower, CharacterTrait, GetTotalMultiplierForTrait, WeaponElement } from '../interfaces';
import Hint from '../components/Hint.vue';
import CombatResults from '../components/CombatResults.vue';
import Web3 from 'web3';
import BN from 'bignumber.js';
import WeaponIcon from '../components/WeaponIcon.vue';
import { mapActions, mapGetters, mapState, mapMutations } from 'vuex';

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

  watch: {
    async selections([characterId, weaponId]) {
      if (!this.ownWeapons.find((weapon) => weapon.id === weaponId)) {
        this.selectedWeaponId = null;
      }
      await this.fetchTargets({ characterId, weaponId });
    },

    async updateResults([fightResults, error]) {
      this.resultsAvailable = fightResults !== null;
      this.waitingResults = fightResults === null && error === null;
      this.setIsInCombat(this.waitingResults);
    },
  },

  methods: {
    ...mapActions(['fetchTargets', 'doEncounter', 'fetchFightRewardSkill', 'fetchFightRewardXp', 'getXPRewardsIfWin']),
    ...mapMutations(['setIsInCombat']),
    getEnemyArt,
    getCharacterTrait(trait) {
      return CharacterTrait[trait];
    },
    getWinChance(enemyPower, enemyElement) {
      const characterPower = CharacterPower(this.currentCharacter.level);
      const playerElement = parseInt(this.currentCharacter.trait, 10);
      const selectedWeapon = this.ownWeapons.find((weapon) => weapon.id === this.selectedWeaponId);
      this.selectedWeapon = selectedWeapon;
      const weaponElement = parseInt(WeaponElement[selectedWeapon.element], 10);
      const weaponMultiplier = GetTotalMultiplierForTrait(selectedWeapon, playerElement);
      const totalPower = characterPower * weaponMultiplier + selectedWeapon.bonusPower;
      const totalMultiplier = 1 + (0.075 * (weaponElement === playerElement ? 1 : 0)) + (0.075*this.getElementAdvantage(playerElement, enemyElement));
      const playerMin = totalPower * totalMultiplier * 0.9;
      const playerMax = totalPower * totalMultiplier * 1.1;
      const playerRange = playerMax - playerMin;
      const enemyMin = enemyPower * 0.9;
      const enemyMax = enemyPower * 1.1;
      const enemyRange = enemyMax - enemyMin;
      let rollingTotal = 0;
      // shortcut: if it is impossible for one side to win, just say so
      if (playerMin > enemyMax) return 'Very Likely';
      if (playerMax < enemyMin) return 'Unlikely';

      // case 1: player power is higher than enemy power
      if (playerMin >= enemyMin) {
        // case 1: enemy roll is lower than player's minimum
        rollingTotal = (playerMin - enemyMin) / enemyRange;
        // case 2: 1 is not true, and player roll is higher than enemy maximum
        rollingTotal += (1 - rollingTotal) * ((playerMax - enemyMax) / playerRange);
        // case 3: 1 and 2 are not true, both values are in the overlap range. Since values are basically continuous, we assume 50%
        rollingTotal += (1 - rollingTotal) * 0.5;
      } // otherwise, enemy power is higher
      else {
        // case 1: player rolls below enemy minimum
        rollingTotal = (enemyMin - playerMin) / playerRange;
        // case 2: enemy rolls above player maximum
        rollingTotal += (1 - rollingTotal) * ((enemyMax - playerMax) / enemyRange);
        // case 3: 1 and 2 are not true, both values are in the overlap range
        rollingTotal += (1 - rollingTotal) * 0.5;
        //since this is chance the enemy wins, we negate it
        rollingTotal = 1 - rollingTotal;
      }
      if (rollingTotal <= 0.3) return 'Unlikely';
      if (rollingTotal <= 0.5) return 'Possible';
      if (rollingTotal <= 0.7) return 'Likely';
      return 'Very Likely';
    },
    getElementAdvantage(playerElement, enemyElement) {
      if ((playerElement + 1) % 4 === enemyElement) return 1;
      if ((enemyElement + 1) % 4 === playerElement) return -1;
      return 0;
    },
    async onClickEncounter(targetToFight) {
      if (this.selectedWeaponId === null || this.currentCharacterId === null) {
        return;
      }

      // Force a quick refresh of targets
      await this.fetchTargets({ characterId: this.currentCharacterId, weaponId: this.selectedWeaponId });
      // If the targets list no longer contains the chosen target, return so a new target can be chosen
      if (!this.targets.find((target) => target.original === targetToFight.original)) {
        return;
      }

      this.fightResults = null;
      this.error = null;
      this.waitingResults = true;
      this.setIsInCombat(this.waitingResults);

      try {
        const results = await this.doEncounter({
          characterId: this.currentCharacterId,
          weaponId: this.selectedWeaponId,
          targetString: targetToFight.original,
        });

        this.fightResults = results;

        await this.fetchFightRewardSkill();
        await this.fetchFightRewardXp();

        this.error = null;
      } catch (e) {
        console.error(e);
        this.error = e.message;
      }
    },

    formattedSkill(skill) {
      const skillBalance = Web3.utils.fromWei(skill, 'ether');
      return `${new BN(skillBalance).toFixed(6)} SKILL`;
    },

    getPotentialXp(targetToFight) {

      const characterPower = CharacterPower(this.currentCharacter.level);
      const playerElement = parseInt(this.currentCharacter.trait, 10);
      const selectedWeapon = this.ownWeapons.find((weapon) => weapon.id ===this.selectedWeaponId);
      const weaponMultiplier = GetTotalMultiplierForTrait(selectedWeapon, playerElement);
      const totalPower = ((characterPower * weaponMultiplier) + selectedWeapon.bonusPower);

      //Formula taken from getXpGainForFight funtion of cryptoblades.sol
      return Math.floor((targetToFight.power /totalPower) *  this.fightXpGain);

    },
  },

  components: {
    BigButton,
    WeaponGrid,
    Hint,
    CombatResults,
    WeaponIcon,
  },
};
</script>

<style scoped>

.enemy-character {
  position: relative;
  width: 14em;
  height: 25em;
  background-position: center;
  background-repeat: no-repeat;
  background-size: 115%;
  background-color: #2e2e30cc;
  background-image: url('../assets/cardCharacterFrame.png');
  border: 1px solid #a28d54;
  border-radius: 15px;
  padding: 0.5rem;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin-bottom: 10px;
  box-shadow: 0px 6px 8px rgba(0, 0, 0, 0.705),
               0px 12px 7px rgba(0,0,0,0.5),
               0px 9px 12px rgba(0,0,0,0.1);

}
.encounter img {
    width: calc(100% - 60px);
    height: auto;
    margin: 0 auto;
    display: block;
}

.payout-info {
  margin: auto;
  text-align: center;
  padding-top: 1em;
  font-size: 1.5em;

  display: flex;
  justify-content: center;
  align-items: center;
}

.combat-hints {
  margin: auto;
  text-align: center;
  padding-right: 1em;
  padding-left: 1em;
  padding-bottom: 1em;
  font-size: 2em;

  display: flex;
  justify-content: center;
  align-items: center;
}

.combat-hints .hint {
  margin-left: 10px;
}

.waiting {
  font-size: 2em;
  margin: auto;
  text-align: center;
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

.message-box {
  display: flex;
  justify-content: center;
  width: 100%;
  font-size: 2em;
}

div.encounter.text-center {
  flex-basis: auto !important;
}

.weapon-icon-wrapper {
  background: rgba(255, 255, 255, 0.1);
  width: 12em;
  height: 12em;
}

.encounter-container {
  position: relative;
}

.encounter {
  display : flex;
  justify-content: center;
}

.xp-gain, .encounter-power{
  color: #9e8a57 !important;
}

.xp-gain, .encounter-power, .encounter-element, .victory-chance  {
  position: absolute;
  font-size: x-large;
}

.encounter-element {
  top: 25px;
}

.encounter-power {
  bottom: 55px;
}

.victory-chance {
  left: 0;
  right: 0;
  text-align: center;
  text-shadow: -1px 0 #000, 0 1px #000, 1px 0 #000, 0 -1px #000;
}

.xp-gain {
  bottom: 20px;
}

/* Mobile Support Classes*/
.mobile-divider-wrapper {
  width: 100%;
  display: flex;
}

.mobile-divider{
  margin: auto;
}

.combat-enemy-container {
  display : flex;
  margin-bottom: 50px;
}

.enemy-container {
  flex : 3;
}

.enemy-divider {
  margin-top : 30px;
}

.enemy-list {
  display: flex;
  flex-wrap: wrap;
  padding-left: 30px;
  padding-right: 30px;
}

.weapon-selection {
  border-right : 1px solid #9e8a57;
}

.weapon-header {
    justify-content: center;
    margin-bottom: 20px;
    margin-top: 20px;
}

.enemy-energy {
  top: -30px;
  position: relative;
}

h1  {
  font-weight: 900 !important;
  text-align: center;
  background: linear-gradient(to right, rgb(248, 218, 136) 20%, rgb(233, 226, 167) 40%, rgb(112, 112, 51) 60%, rgb(177, 150, 92) 80%);
  background-size: 200% auto;
  color: #000;
  background-clip: text;
  text-fill-color: transparent;
  text-shadow: 0px 2px 3px rgba(0,0,0,0.4),
               0px 4px 7px rgba(0,0,0,0.1),
               0px 9px 12px rgba(0,0,0,0.1);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: shine 1s linear infinite;
  @keyframes shine {
    to {
      background-position: 200% center;
    }
  }
}

/* Needed to asjust image size, not just image column-size and other classes to accommodate that */
@media all and (max-width:  767.98px) {
  .encounter img {
    max-width: 30vw;
  }

  .xp-gain, .encounter-power, .encounter-element, .victory-chance  {
    position: inherit;
    font-size: x-large;
  }
  .combat-enemy-container {
    flex-direction: column;
  }
  .encounter {
    margin-top: 50px;
  }
  .weapon-selection {
    border-right: none;
  }
  .results-panel {
    width : 100%;
  }
}

.encounter-button {
  display: block;
  margin: 0 auto;
  height: 5em;
  width: 13em;
  position: relative;
  top: 35px;
}


.enemy-img {
  position: relative;
  top: -40px;
}
</style>
