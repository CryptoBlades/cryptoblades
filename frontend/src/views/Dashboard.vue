<template>
  <div class="dashboard-container">
    <div class="overlay-bg">
    </div>
    <div class="upper-body-container">
      <div class="character-details-container">
        <div class="character-element">
          <div class="element-frame">
            <div>
              <span id="fire-element" />
            </div>
          </div>
        </div>
        <div class="character-name">
          <span>{{this.characterInformation.name}}</span>
        </div>
        <div class="character-data-container">
          <div class="character-element-name">
              <span>{{this.characterInformation.element}}</span>
          </div>
          <div class="character-data-divider">
              <span>|</span>
          </div>
          <div class="character-level">
              <span>LEVEL {{this.characterInformation.level}}</span>
          </div>
          <div class="character-data-divider">
              <span>|</span>
          </div>
          <div class="character-stamina">
            <span>120/200 STAMINA</span>
          </div>
        </div>
        <div class="small-stamina-char"
              :style="`--staminaReady: ${(120/200)*100}%;`">
        </div>
        <div class="pvp-stats-container">
          <div class="pvp-wins-container">
            <div class="pvp-wins-label">
              <span>PVP WINS</span>
            </div>
            <div class="pvp-wins-value">
              <span>255</span>
            </div>
          </div>
          <div class="pvp-rank-container">
            <div class="pvp-rank-label">
              <span>PVP RANK</span>
            </div>
            <div class="pvp-rank-value">
              <span>{{this.characterInformation.rank}}</span>
            </div>
          </div>
          <div class="pvp-power-container">
            <div class="pvp-power-label">
              <span>POWER</span>
            </div>
            <div class="pvp-power-value">
              <span>{{this.characterInformation.power}}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="lower-body-container">
      <div class="raid-container"></div>
      <div class="pvp-and-pve-container">
        <div class="pve-container">
          <div class="pve-title">
            <span>ADVENTURE</span>
          </div>
          <div class="pve-description">
            <span>Engage on PVE battles to earn rewards.</span>
          </div>
          <div class="pve-button dashboard-btn">
              <span @click="goToCombat()">COMBAT</span>
          </div>
        </div>
        <div class="pvp-container">
          <div class="pve-title">
            <span>RANK MATCH</span>
          </div>
          <div class="pve-description">
            <span>Defeat other Players on PVP battles to earn rewards.</span>
          </div>
          <div class="pve-button dashboard-btn">
              <span @click="goToArena()">SIGN UP</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { characterFromContract as formatCharacter } from '../contract-models';
import { duelResultFromContract as formatDuelResult } from '../contract-models';
export default {
  inject: ['web3'],

  data() {
    return {
      duelHistory: [],
      characterInformation: {
        name: '',
        level: 0,
        power: null,
        rank: null,
        element: '',
      }
    };
  },

  computed: {
    ...mapState(['currentCharacterId']),
    ...mapGetters(['getCharacterName'])
  },

  methods: {
    ...mapActions([
      'getCharacter',
      'getCharacterPower',
      'getCharacterLevel',
      'getPvpCoreContract',
      'getRankingPointsByCharacter',
      'getRename'
    ]),

    goToCombat(){
      console.log('Went to combat');
    },
    goToArena(){
      console.log('Went to arena');
    }
  },

  async created(){

    const rename = await this.getRename(this.currentCharacterId);

    this.characterInformation.name = rename ? rename : this.getCharacterName(this.currentCharacterId);

    this.characterInformation.level = Number(await this.getCharacterLevel(this.currentCharacterId)) + 1;

    this.characterInformation.power = await this.getCharacterPower(this.currentCharacterId);

    this.characterInformation.rank = await this.getRankingPointsByCharacter(this.currentCharacterId);

    this.characterInformation.element = formatCharacter(this.currentCharacterId, await this.getCharacter(this.currentCharacterId)).traitName;

    const fromBlock = Math.max(await this.web3.eth.getBlockNumber() - 1800, 0);

    const previousDuels = await (await this.getPvpCoreContract()).getPastEvents('DuelFinished', {
      filter: {attacker: this.currentCharacterId},
      toBlock: 'latest',
      fromBlock,
    });

    previousDuels.push({
      attackerId: '1',
      defenderId: this.currentCharacterId,
      timestamp: '',
      attackerRoll: '100',
      defenderRoll: '1000',
      attackerWon: true,
      bonusRank: '0'
    });

    this.duelHistory = previousDuels.map(duel => {
      console.log(duel);
      return formatDuelResult(duel);
    });

    console.log(this.duelHistory);
  }

};
</script>

<style scoped>
.dashboard-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  z-index: 1;
}

.overlay-bg {
  position: absolute;
  background: linear-gradient(rgba(24, 24, 24, 0.5), rgba(34, 33, 33, 0.5)), url("../assets/background/dashboard-bg.png");
  background-size: cover;
  background-repeat: no-repeat;
  height: 50%;
  width: 100%;
  z-index: 2;
}

.upper-body-container {
  background-color: transparent;
  height: 30%;
}

.lower-body-container {
  background-color: transparent;
  height: 70%;
}

.upper-body-container,
.lower-body-container {
  display: flex;
  flex-direction: row;
  z-index: 3;
  padding: 50px;
}

.pvp-and-pve-container {
  display: flex;
  flex-direction: column;
  width: 35%;
  height: 100%;
  align-items: flex-end;
}

.raid-container {
  background: linear-gradient(rgba(24, 24, 24, 0.5), rgba(34, 33, 33, 0.5)), url("../assets/background/raid-bg.png");
  background-repeat: no-repeat;
  background-size: cover;
  width: 65%;
  height: 100%;
  border-radius: 10px;
  margin-right: 50px;
}

.pvp-container {
  display: flex;
  flex-direction: column;
  align-items: left;
  background: linear-gradient(rgba(24, 24, 24, 0.5), rgba(34, 33, 33, 0.5)), url("../assets/background/arena-bg.png");
  background-repeat: no-repeat;
  background-size: cover;
  width: 100%;
  height: 100%;
  border-radius: 10px;
  row-gap: 10px;
  padding: 30px;
}
.pve-container {
  display: flex;
  flex-direction: column;
  align-items: left;
  background: linear-gradient(rgba(24, 24, 24, 0.5), rgba(34, 33, 33, 0.5)), url("../assets/background/adventure-bg.png");
  background-repeat: no-repeat;
  background-size: cover;
  width: 100%;
  height: 100%;
  border-radius: 10px;
  row-gap: 10px;
  padding: 30px;
  margin-bottom: 50px;
}

.element-frame {
  padding: 10px;
  height: 10px;
  width: 10px;
  border: 2px solid #968E74;
  display: flex;
  align-items: center;
  justify-content: center;
  -ms-transform: rotate(45deg); /* IE 9 */
  transform: rotate(45deg);
  margin-bottom: 10px;
  margin-left: 5px;
}

.element-frame > div {
  display: flex;
  align-items: center;
  justify-content: center;
  -ms-transform: rotate(-45deg); /* IE 9 */
  transform: rotate(-45deg);
}

.character-name > span {
  color: #EDCD90;
  font-family: 'Trajan', serif;
  font-weight: bold;
  font-size: 25px;
  text-transform: uppercase;
  letter-spacing: 0;
}

#fire-element {
  content: url("../assets/elements/icon-fire.png");
  height: 20px;
  width: 20px;
  background: rgba(0, 0, 0, 0.076);
}

.character-details-container {
  width: 30%;
}

.character-data-container {
  display: flex;
  flex-direction: row nowrap;
  font-family: 'Roboto', serif;
  line-height: 17px;
  font-size: 12px;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 1px;
  color: #ffff;
  column-gap: 20px;
}

.character-data-divider {
  color: #7F8693;
}

.small-stamina-char {
  margin: 10px 0px;
  height: 5px;
  width: auto;
  border-radius: 2px;
  border: none;
  background : linear-gradient(to right, #EDCD90 var(--staminaReady), #817D6D 0);
}

.pvp-stats-container {
  display: flex;
  flex-direction: row nowrap;
  column-gap: 40px;
}

.pvp-wins-label > span,
.pvp-rank-label > span,
.pvp-power-label > span {
  color: #CEC198;
  font-family: 'Roboto', serif;
  line-height: 17px;
  font-size: 12px;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 1px;
}

.pvp-wins-value > span,
.pvp-rank-value > span,
.pvp-power-value > span {
  color: #ffff;
  font-family: 'Oswald', serif;
  line-height: 60px;
  font-size: 40px;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 1px;
}

.dashboard-btn:hover{
  cursor: pointer;
}

.dashboard-btn > span{
  background-image: url('../assets/btn-long.svg');
  background-color: transparent;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  object-fit: fill;
  padding: 10px 40px 10px 40px;
  border: none;
  font-family: 'Oswald';
  color: #fff;
  font-size: 30px;
  text-align: center;
}

.pve-title > span {
  color: #EDCD90;
  font: normal normal bold 20px/27px 'Trajan';
}

.pve-description > span {
  color: #E7E7E8;
  font: normal normal normal 13px/19px 'Roboto';
}
</style>
