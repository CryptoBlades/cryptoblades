<template>
  <div class="dashboard-container">
    <div class="overlay-bg">
    </div>
    <div v-if="haveCharacters">
    <div class="upper-body-container">
      <div class="character-details-container">
        <div class="character-element">
          <div class="element-frame">
            <div>
              <span :class="this.characterInformation.element.toLowerCase() + '-icon circle-element'"></span>
            </div>
          </div>
        </div>
        <div class="character-name">
          <span>{{ getCharacterName(currentCharacterId) }}</span>
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
            <span>{{this.characterInformation.stamina}}/{{maxStamina}} STAMINA</span>
          </div>
        </div>
        <div class="small-stamina-char"
              :style="`--staminaReady: ${(this.characterInformation.stamina/maxStamina)*100}%;`">
        </div>
        <div class="pvp-stats-container">
          <div class="pvp-wins-container">
            <div class="pvp-wins-label">
              <span>PVP WINS</span>
            </div>
            <div class="pvp-wins-value">
              <span>{{this.characterInformation.pvpWins}}</span>
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
              <span>{{ totalCharacterPower }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="lower-body-container">
      <div class="raid-container">
        <div class="raid-boss-image-container">
          <img class="boss-image" :src="getBossArt(this.raidData.raidIndex)">
        </div>
        <div class="raid-info-container">
          <div class="raid-boss-name-element-container">
            <div class="raid-boss-element-container">
                <div class="raid-element-frame">
                  <div>
                    <span :class="traitNumberToName(this.raidData.bossTrait).toLowerCase() + '-icon circle-element'"></span>
                  </div>
                </div>
            </div>
            <div class="raid-boss-name">
              <span>{{this.raidData.bossName}}</span>
            </div>
          </div>
          <div class="raid-divider">

          </div>
          <div class="raid-boss-power-element-duration-container">
            <div class="raid-boss-power">
              <div>
              <span class="raid-boss-label">Boss Power</span>
              </div>
              <div>
                <span class="raid-boss-value">{{this.raidData.bossPower}}</span>
              </div>
            </div>
            <div class="raid-boss-element">
              <div>
              <span class="raid-boss-label">Element</span>
              </div>
              <div>
                <span class="raid-boss-value">{{traitNumberToName(this.raidData.bossTrait).toUpperCase()}}</span>
              </div>
            </div>
            <div class="raid-boss-duration">
              <div>
              <span class="raid-boss-label">Registration Ends</span>
              </div>
              <div>
                <span class="raid-boss-value">{{this.remainingTime.minutes}}:{{this.remainingTime.seconds}}</span>
              </div>
            </div>
          </div>
          <div class="raid-boss-participants-total-power-container">
            <div>
            <span class="raid-boss-label">Participants Total Power: </span>
            <span class="raid-boss-power-value">{{this.raidData.totalPower}} ({{((this.raidData.totalPower/this.raidData.bossPower)*100).toFixed(0)}}%)</span>
            </div>
            <div class="participants-power"
              :style="`--power: ${((this.raidData.totalPower/this.raidData.bossPower)*100).toFixed(0)}%;`">
            </div>
          </div>
          <div class="raid-boss-button-and-drops">
            <router-link :to="{ name: 'raid' }" exact>
              <div class="pve-button dashboard-btn">
                <span>JOIN RAID</span>
              </div>
            </router-link>
              <div class="raid-drops">
                <img class="raid-img" src="../assets/trinkets/trinket1.png">
                <img class="raid-img" src="../assets/junk/junk1.png">
                <img class="raid-img" src="../assets/placeholder/sword-placeholder-0.png">
              </div>
          </div>
        </div>
      </div>
      <div class="pvp-and-pve-container">
        <div class="pve-container">
          <div class="pve-title">
            <span>ADVENTURE</span>
          </div>
          <div class="pve-description">
            <span>Engage on PVE battles to earn rewards.</span>
          </div>
          <router-link :to="{ name: 'combat' }" exact>
            <div class="pve-button dashboard-btn">
              <span>Adventure</span>
            </div>
          </router-link>
        </div>
        <div class="pvp-container">
          <div class="pve-title">
            <span>RANK MATCH</span>
          </div>
          <div class="pve-description">
            <span>Defeat other Players on PVP battles to earn rewards.</span>
          </div>
          <router-link :to="{ name: 'pvp' }" exact>
            <div class="pve-button dashboard-btn">
              <span>SIGN UP</span>
            </div>
          </router-link>
        </div>
      </div>
      </div>
    </div>
    <div style="min-height: 100vh;" class="d-flex align-items-start justify-content-center" v-if="!haveCharacters">
      <div style="z-index: 3;">
        <span>Go to plaza to recruit your first character</span>
      </div>
      <div style="z-index: 3;">
        <router-link :to="{ name: 'plaza' }" exact>
          <div class="pve-button dashboard-btn">
            <span>Go to Plaza</span>
          </div>
        </router-link>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import { characterFromContract as formatCharacter } from '../contract-models';
import { duelResultFromContract as formatDuelResult } from '../contract-models';
import {getBossArt} from '@/raid-boss-art-placeholder';
import {traitNumberToName} from '@/contract-models';
import { Nft } from '@/interfaces/Nft';

export default Vue.extend({
  data() {
    return {
      duelHistory: [],
      raidData: {
        raidIndex: '',
        bossName: '',
        raiderCount: '',
        totalPower: 0,
        expectedFinishTime: new Date(),
        xpReward: '',
        staminaCost: '',
        durabilityCost: '',
        joinCost: '',
        raidStatus: '',
        bossPower: 0,
        bossTrait: '',
        accountPower: 0
      },
      remainingTime: {
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0
      },
      characterInformation: {
        name: '',
        level: 0,
        power: null,
        rank: null,
        element: '',
        stamina: '',
        pvpWins: 0
      }
    };
  },

  computed: {
    ...mapState(['characters', 'currentCharacterId', 'maxStamina', 'ownedCharacterIds', 'web3', 'ownedGarrisonCharacterIds',]),
    ...mapGetters(['getCharacterName', 'currentCharacterStamina', 'getRaidState', 'ownCharacters',
      'getCharacterPower', 'getCharacterRank', 'getCharacterElement', 'getCharacterPvpWins', 'ownGarrisonCharacters']),
    selectedCharacter(): Nft{
      return this.characters[this.currentCharacterId];
    },
    haveCharacters() {
      return this.ownedGarrisonCharacterIds.length > 0 || this.ownCharacters?.length > 0;
    },
    characterLvl(): number {
      return this.characters[this.currentCharacterId]?.level + 1 ?? 1;
    },
    totalCharacterPower(): number {
      return this.getCharacterPower(this.currentCharacterId);
    },
  },

  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions([
      'getCharacter',
      'getCharacterLevel',
      'getPvpCoreContract',
      'getRankingPointsByCharacter',
      'getRename',
      'fetchCharacterStamina',
      'fetchRaidState'
    ]),

    getBossArt,
    traitNumberToName,
    getBossName() {
      const raidBossNames = [
        'Fudbringer',
        'HODL Lord',
        'Skill Eater',
        'Chain Congester',
        'Swap Guardian',
        'Blade Hoarder',
        'Centralizer',
        'Exchange Tormentor',
        'Eater of Stakes',
      ];

      return raidBossNames[+this.raidData.raidIndex % raidBossNames.length];
    },

    getTimeRemaining(){
      setInterval(() => {
        const eventTime = this.raidData.expectedFinishTime.getTime();
        const currentTime = new Date().getTime();
        const diffTime = eventTime - currentTime;

        const d = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        const h = Math.floor((diffTime % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const m = Math.floor((diffTime % (1000 * 60 * 60)) / (1000 * 60));
        const s = Math.floor((diffTime % (1000 * 60)) / 1000);

        this.remainingTime = {days:d,hours:h,minutes:m,seconds:s};
      }, 1000);
    },

    async fetchDashboardDetails(characterId: string|number) {
      this.characterInformation.level = Number(await this.getCharacterLevel(characterId)) + 1;

      this.characterInformation.power = await this.getCharacterPower(characterId);

      this.characterInformation.rank = await this.getRankingPointsByCharacter(characterId);

      this.characterInformation.element = formatCharacter(characterId, await this.getCharacter(characterId)).traitName;

      await this.fetchCharacterStamina(characterId);

      this.characterInformation.stamina = this.currentCharacterStamina;

      const fromBlock = Math.max(await this.web3.eth.getBlockNumber() - 1800, 0);

      const previousDuels = await (await this.getPvpCoreContract()).getPastEvents('DuelFinished', {
        filter: {attacker: characterId},
        toBlock: 'latest',
        fromBlock,
      });

      previousDuels.push({
        attackerId: '1',
        defenderId: characterId,
        timestamp: '',
        attackerRoll: '100',
        defenderRoll: '1000',
        attackerWon: true,
        bonusRank: '0'
      });

      this.duelHistory = previousDuels.map((duel: [string, string, string, string, string, boolean, string]) => {
        return formatDuelResult(duel);
      });

    },
    async processRaidData() {
      const raidData = this.getRaidState;
      this.raidData.raidIndex = raidData.index;
      this.raidData.bossName = this.getBossName();
      this.raidData.raiderCount = raidData.raiderCount;
      this.raidData.totalPower = +raidData.playerPower;
      this.raidData.expectedFinishTime = new Date(+raidData.expectedFinishTime * 1000);
      this.raidData.xpReward = raidData.xpReward;
      this.raidData.staminaCost = raidData.staminaCost;
      this.raidData.durabilityCost = raidData.durabilityCost;
      this.raidData.joinCost = raidData.joinSkill;
      this.raidData.raidStatus = raidData.status;
      this.raidData.bossPower = +raidData.bossPower;
      this.raidData.bossTrait = raidData.bossTrait;
      this.raidData.accountPower = +raidData.accountPower;
    }
  },

  async mounted(){
    this.getTimeRemaining();
    const refreshRaidData = async () => {
      await (this as any).fetchRaidState();
      (this as any).processRaidData();
    };
    await refreshRaidData();
    window.setInterval(async () => {
      await refreshRaidData();
    }, 3000);

    if(this.currentCharacterId === null){
      this.setCurrentCharacter(this.ownedCharacterIds[0]);
      this.fetchDashboardDetails(this.ownedCharacterIds[0]);
    }

    Promise.all([
      await this.fetchDashboardDetails(this.currentCharacterId),
      await this.fetchRaidState(),
      await this.processRaidData()
    ]);
  },
  watch: {
    currentCharacterId(newId: string|number){
      this.fetchDashboardDetails(newId);
    }
  }
});
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
  display: flex;
  flex-direction: row;
  background: linear-gradient(rgba(24, 24, 24, 0.5), rgba(34, 33, 33, 0.5)), url("../assets/background/raid-bg.png");
  background-repeat: no-repeat;
  background-size: cover;
  width: 65%;
  height: 100%;
  border-radius: 10px;
  margin-right: 50px;
  overflow: hidden;
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

.character-name > span,
.raid-boss-name > span {
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

.participants-power {
  margin: 10px 0px;
  height: 10px;
  width: auto;
  border-radius: 2px;
  border: none;
  background : linear-gradient(to right, #EDCD90 var(--power), #817D6D 0);
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

.raid-boss-value {
  color: #ffff;
  font-family: 'Oswald', serif;
  line-height: 60px;
  font-size: 30px;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 0px;
}

.raid-boss-power-value {
  color: #ffff;
  font-family: 'Oswald', serif;
  line-height: 17px;
  font-size: 12px;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 0px;
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

.raid-boss-image-container {
  width: 40%;
  height: 100%;
}

.boss-image {
  width: 100%;
  height: inherit;
}

.raid-info-container {
  display: flex;
  flex-direction: column;
  width: 60%;
  padding: 20px;
}

.raid-element-frame {
  padding: 10px;
  height: 30px;
  width: 30px;
  border: 2px solid #968E74;
  display: flex;
  align-items: center;
  justify-content: center;
  -ms-transform: rotate(45deg); /* IE 9 */
  transform: rotate(45deg);
  margin-bottom: 10px;
  margin-left: 5px;
}

.raid-element-frame > div {
  display: flex;
  align-items: center;
  justify-content: center;
  -ms-transform: rotate(-45deg); /* IE 9 */
  transform: rotate(-45deg);
}

#raid-fire-element {
  content: url("../assets/elements/icon-fire.png");
  height: 20px;
  width: 20px;
  background: rgba(0, 0, 0, 0.076);
}

.raid-boss-name-element-container{
  display: flex;
  flex-direction: row;
  padding-top: 50px;
  column-gap: 30px;
  margin-bottom: 20px;
}

.raid-divider {
  border-bottom: 3px solid gray;
  width: 100%;
  opacity: 0.5;
}

.pve-description > span {
  color: #E7E7E8;
  font: normal normal normal 13px/19px 'Roboto';
}

.raid-boss-power-element-duration-container {
  display: flex;
  flex-direction: row;
}

.raid-boss-power,
.raid-boss-element,
.raid-boss-duration {
  display: flex;
  flex-direction: column;
  width: 30%;
}

.raid-boss-label {
  color: #CEC198;
  font-family: 'Roboto', 'sans serif';
  line-height: 17px;
  font-size: 12px;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 0px;
}

.raid-boss-button-and-drops{
  display: flex;
  flex-direction: row;
  column-gap: 10px;
}

.raid-drops {
  display: flex;
  flex-direction: row;
  column-gap: 10px;
}

.raid-img {
  height: 50px;
  width: 50px;
  background-color: rgba(0, 0, 0, 0.767) ;
  border: 1px solid #343a40;
}

@media screen and (max-width: 1280px)  {

  .overlay-bg {
    background-color: rgba(0, 0, 0, 0.425);
  }
  .lower-body-container {
  display: flex;
  flex-direction: column;
  row-gap: 10px;
  width: 100%;
  margin-top: 50px;
}
  .raid-container {
    width: 100%;
  }
  .pvp-and-pve-container {
    width: 100%;
  }
}
</style>
