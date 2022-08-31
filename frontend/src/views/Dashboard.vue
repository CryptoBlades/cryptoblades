<template>
  <div class="dashboard-container">
    <div class="overlay-bg"></div>
    <div style="min-height: 100vh;" class="noChar" v-if="!haveCharacters">
      <div style="z-index: 3;">
        <span>{{$t('homePage.goRecruit')}}</span>
      </div>
      <div style="z-index: 3;">
        <router-link :to="{ name: 'plaza' }" exact>
          <div class="pve-button dashboard-btn">
            <span>{{$t('homePage.gotoPlaza')}}</span>
          </div>
        </router-link>
      </div>
    </div>
      <div v-else>
        <div class="upper-body-container">
          <div class="character-details-container">
            <div class="character-element">
              <div class="element-frame">
                <div>
                  <span :class="characterTrait.toLowerCase() + '-icon circle-element'"></span>
                </div>
              </div>
            </div>
          <div class="character-name">
            <span>{{characterName}}</span>
          </div>
          <div class="character-data-container">
            <div class="character-element-name">
              <span>{{characterTrait}}</span>
            </div>
          <div class="character-data-divider">
              <span>|</span>
          </div>
          <div class="character-level">
              <span>{{$t('homePage.level')}} {{characterLvl}}</span>
          </div>
          <div class="character-data-divider">
              <span>|</span>
          </div>
          <div class="character-stamina">
            <span>{{characterStamina}}/{{maxStamina}} {{$t('homePage.stamina')}}</span>
          </div>
        </div>
        <div class="small-stamina-char"
              :style="`--staminaReady: ${(characterStamina/maxStamina)*100}%;`">
        </div>
        <div class="pvp-stats-container">
          <div class="pvp-rank-container">
            <div class="pvp-rank-label">
              <span>PVP {{$t('homePage.rank')}}</span>
            </div>
            <div class="pvp-rank-value">
              <span>{{this.pvpRankingPoints || 0}}</span>
            </div>
          </div>
          <div class="pvp-power-container">
            <div class="pvp-power-label">
              <span>{{$t('homePage.power')}}</span>
            </div>
            <div class="pvp-power-value">
              <span>{{totalCharacterPower}}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="lower-body-container">
      <div class="raid-container">
        <div class="bg-blocking"></div>
        <div class="raid-boss-image-container"  :style="`background:url('${getBossArt(this.raidData.raidIndex)}')`"></div>
        <div class="raid-info-container">
          <div class="raid-boss-name-element-container">
            <div class="raid-boss-element-container">
                <div class="raid-element-frame">
                  <div>
                    <span :id="traitNumberToName(this.raidData.bossTrait).toLowerCase()+'-element'"/>
                  </div>
                </div>
            </div>
            <div class="raid-boss-name">
              <span>{{this.raidData.bossName}}</span>
              <p>{{$t('raid.title')}}</p>
            </div>
          </div>
          <div class="raid-boss-power-element-duration-container">
            <span class="boss-images" :style="`content:url('${getBossArt(this.raidData.raidIndex)}')`"></span>
            <div class="raid-boss-power">
              <div>
              <span class="raid-boss-label">{{$t('homePage.bossPower')}}</span>
              </div>
              <div>
                <span v-if="raidData.bossPower !== ''" class="raid-boss-value">{{this.raidData.bossPower}}</span>
                <span v-else class="raid-boss-value">0</span>
              </div>
            </div>
            <div class="raid-boss-element">
              <div>
              <span class="raid-boss-label">{{$t('homePage.element')}}</span>
              </div>
              <div>
                <span class="raid-boss-value">{{traitNumberToName(this.raidData.bossTrait).toUpperCase()}}</span>
              </div>
            </div>
            <div class="raid-boss-duration">
              <div>
              <span class="raid-boss-label">{{$t('homePage.registrationEnds')}}</span>
              </div>
              <div>
                <span class="raid-boss-value" v-if="raidData.raidStatus === '0' || raidData.raidStatus === ''">00:00</span>
                <span class="raid-boss-value" v-else>
                  <span class="raid-boss-value" v-if="this.remainingTime.hours > 0">
                    {{this.remainingTime.hours}}:{{this.remainingTime.minutes}}:{{this.remainingTime.seconds}}
                  </span>
                  <span class="raid-boss-value" v-else>
                    {{this.remainingTime.minutes}}:{{this.remainingTime.seconds}}
                  </span>
                </span>
              </div>
            </div>
          </div>
          <div class="raid-boss-participants-total-power-container">
            <div>
            <span class="raid-boss-label">{{$t('homePage.particapantsTotalPower')}}: </span>
            <span class="raid-boss-power-value">{{this.raidData.totalPower}}</span>
            </div>
            <div class="participants-power"
              :style="`--power: ${(this.raidData.totalPower/this.raidData.bossPower)*100}%;`">
            </div>
          </div>
          <router-link :to="{ name: 'raid' }" exact>
            <div class="pve-button dashboard-btn mt-4 none-desktop">
              <span>{{$t('homePage.joinRaid')}}</span>
            </div>
          </router-link>
          <div class="raid-boss-button-and-drops">
            <router-link :to="{ name: 'raid' }" exact>
              <div class="pve-button dashboard-btn joinRaid">
                <span>{{$t('homePage.joinRaid')}}</span>
              </div>
            </router-link>
            <div>
              <p>{{$t('homePage.chanceDrop')}}</p>
              <div class="raid-drops">
                 <img class="raid-img" src="../assets/trinkets/trinket1.png">
                <img class="raid-img" src="../assets/junk/junk1.png">
                <img class="raid-img" src="../assets/placeholder/weapon3.png">
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="pvp-and-pve-container">
        <div class="pve-container">
          <div class="pve-title">
            <span>{{$t('homePage.adventure')}}</span>
          </div>
          <div class="pve-description">
            <span>{{$t('homePage.engage')}}</span>
          </div>
          <router-link :to="{ name: 'combat' }" exact>
            <div class="pve-button dashboard-btn">
              <span>{{$t('homePage.adventure')}}</span>
            </div>
          </router-link>
        </div>
        <div class="pvp-container">
          <div class="pve-title">
            <span>{{$t('homePage.rankMatch')}}</span>
          </div>
          <div class="pve-description">
            <span>{{$t('homePage.defeatRewards')}}.</span>
          </div>
          <router-link :to="{ name: 'pvp' }" exact>
            <div class="pve-button dashboard-btn">
              <span>{{$t('homePage.signUp')}}</span>
            </div>
          </router-link>
        </div>
      </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import {getBossArt, getBossName} from '@/raid-boss-art-placeholder';
import {traitNumberToName} from '@/contract-models';
import { Nft } from '@/interfaces/Nft';
import { CharacterTrait } from '@/interfaces';

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
      pvpRankingPoints: '',
    };
  },

  computed: {
    ...mapState([
      'characters',
      'currentCharacterId',
      'maxStamina',
      'ownedCharacterIds',
      'web3',
      'ownedGarrisonCharacterIds',
    ]),
    ...mapGetters([
      'getCharacterName',
      'getRaidState',
      'ownCharacters',
      'getCharacterRank',
      'getCharacterElement',
      'ownGarrisonCharacters',
      'getCharacterStamina',
      'getCharacterPower',
    ]),
    selectedCharacter(): Nft{
      return this.characters[this.currentCharacterId];
    },
    haveCharacters() {
      return this.ownedGarrisonCharacterIds?.length > 0 || this.ownCharacters?.length > 0;
    },
    characterLvl(): number {
      return this.characters[this.currentCharacterId]?.level + 1 ?? 1;
    },
    totalCharacterPower(): number {
      return this.getCharacterPower(this.currentCharacterId);
    },
    characterTrait(): string {
      const characterWithId = this.characters[this.currentCharacterId];
      return CharacterTrait[characterWithId?.trait] ?? '';
    },
    characterStamina(): string {
      return this.getCharacterStamina(this.currentCharacterId);
    },
    characterName(): string {
      return this.getCharacterName(this.currentCharacterId);
    },
  },

  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions([
      'getCharacter',
      'getRankingPointsByCharacter',
      'fetchRaidState'
    ]),

    getBossArt,
    traitNumberToName,
    getBossName(): string {
      return getBossName(+this.raidData.raidIndex);
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

    async fetchPvpDetails(characterId: string|number) {
      this.pvpRankingPoints = await this.getRankingPointsByCharacter(characterId);
      if(this.pvpRankingPoints  === '0'){
        this.pvpRankingPoints = '-';
      }
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

    Promise.all([
      await this.fetchPvpDetails(this.currentCharacterId),
      await this.fetchRaidState(),
      await this.processRaidData()
    ]);
  },
  watch: {
    currentCharacterId(newId: string|number){
      this.fetchPvpDetails(newId);
      if(this.currentCharacterId === null){
        this.setCurrentCharacter(this.ownedCharacterIds[0]);
      }
    },
  }
});
</script>

<style scoped>
.dashboard-container {
  display: flex;
  flex-direction: column;
  height: auto;
  z-index: 1;
  overflow:hidden;
}

.dashboard-container > div:nth-child(2){
  z-index: 2;
}


.overlay-bg {
  position: absolute;
  background: linear-gradient(rgba(24, 24, 24, 0.5), rgba(34, 33, 33, 0.5)), url("../assets/background/dashboard-bg.png");
  background-size: cover;
  background-repeat: no-repeat;
  height: 50%;
  width: 100%;
  z-index: 1;
  border-bottom: 1px solid #404857;
}

.noChar{
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
}

.noChar > div:nth-child(1) > span{
  font-family: Trajan;
  font-size: 2em;
}

.noChar > div:nth-child(1){
  margin-bottom: 2em;
}

.noChar > div:nth-child(2){
  margin-top: 2em;
}


.upper-body-container {
  background-color: transparent;
  height: 30%;
}

.lower-body-container {
  background-color: transparent;
  height: 68%;
}

.upper-body-container,
.lower-body-container {
  display: flex;
  flex-direction: row;
  z-index: 3;
  padding: 50px;
  padding-top: 25px;
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
  background-size: 110%;
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
  background-size: 110%;
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
  background-size: 110%;
  width: 100%;
  height: 100%;
  border-radius: 10px;
  row-gap: 10px;
  padding: 30px;
  margin-bottom: 50px;
}

.element-frame {
  padding: 15px;
  height: 20px;
  width: 20px;
  border: 1px solid #968E74;
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
  font-weight: 500;
  font-size: 1.5vw;
  text-transform: uppercase;
  letter-spacing: 0;
}

.raid-boss-name > p{
  text-transform: capitalize;
  font-family: Roboto;
  color: #CEC198;
  font-size: 0.75vw;
}

#fire-element {
  content: url("../assets/elements/icon-fire.png");
  height: 25px;
  width: 25px;
  background: rgba(0, 0, 0, 0.076);
}

#water-element {
  content: url("../assets/elements/icon-water.png");
  height: 25px;
  width: 25px;
  background: rgba(0, 0, 0, 0.076);
}

#lightning-element {
  content: url("../assets/elements/icon-thunder.png");
  height: 25px;
  width: 25px;
  background: rgba(0, 0, 0, 0.076);
}

#earth-element {
  content: url("../assets/elements/icon-earth.png");
  height: 25px;
  width: 25px;
  background: rgba(0, 0, 0, 0.076);
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

.character-data-container > div {
  padding-top: 6px;
  padding-bottom: 6px;
}

.character-data-container > div > span {
  text-transform: uppercase;
  font-family: Roboto;
  font-size: 0.75vw
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
  background : linear-gradient(to right, #EDCD90 var(--staminaReady), #484848 0);
}

.participants-power {
  margin: 10px 0px;
  height: 10px;
  width: auto;
  border-radius: 2px;
  border: none;
  background : linear-gradient(to right, #EDCD90 var(--power), #484848 0);
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
  font-size: 0.75vw;
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
  font-size: 2.2vw;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 1px;
}

.raid-boss-value {
  color: #ffff;
  font-family: 'Oswald', serif;
  line-height: 50px;
  font-size: 30px;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 0px;
}

.raid-boss-power-value {
  color: #ffff;
  font-family: 'Roboto', serif;
  line-height: 17px;
  font-size: 0.9em;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 0px;
}

.raid-boss-power-element-duration-container{
  margin-bottom: 20px;
}

.dashboard-btn:hover{
  cursor: pointer;
}

.dashboard-btn > span{
  background-image: url('../assets/buttonOutline.svg');
  background-color: transparent;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  object-fit: fill;
  padding: 10px 40px 10px 40px;
  border: none;
  font-family: 'Oswald';
  color: #fff;
  font-size: 1.2vw;
  text-align: center;
}

.pve-title > span {
  color: #EDCD90;
  font: normal normal bold 20px/27px 'Trajan';
}

/* added this important coz there's a weird css issue that preventing the styling to applying in the div*/
.lower-body-container > .raid-container > .raid-boss-image-container{
  background-position-y: 30px !important;
  background-size: 100% !important;
  background-repeat: no-repeat !important;
}

.lower-body-container > .bg-blocking{
  background-color: rgba(0, 0, 0, 0.274);
  position: absolute;
  left: 0;
  bottom: 0;
  height: 100%;
  width: 100%;
}

.raid-boss-image-container {
  width: 40%;
  height: 100%;
}

.boss-image {
  width: 30vw;
  height: auto;
  position: absolute;
  bottom: -90px;
  left: -90px;
}

.raid-info-container {
  display: flex;
  flex-direction: column;
  width: 60%;
  padding: 20px;
}

.raid-element-frame {
  padding: 18px;
  height: 30px;
  width: 30px;
  border: 1px solid #968E74;
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

.raid-boss-name-element-container{
  display: flex;
  flex-direction: row;
  padding-top: 50px;
  align-items: center;
  column-gap: 30px;
  border-bottom: 1px solid #cec1985b;
  margin-bottom: 30px;
}

.raid-element-frame > div > span{
  width: 30px;
  height: 30px;
}

.raid-divider {
  border-bottom: 1px solid gray;
  width: 100%;
  opacity: 0.5;
}

.pve-description{
  margin-bottom: 20px;
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
  width: clamp(200px, 30%, 100%);
  margin-right:20px;
}

.raid-boss-label {
  color: #CEC198;
  font-family: 'Roboto', 'sans serif';
  line-height: 17px;
  font-size: 0.75vw;
  font-style: normal;
  font-variant: normal;
  letter-spacing: 0px;
}

.raid-boss-button-and-drops{
  display: flex;
  flex-direction: row;
  column-gap: 10px;
  margin-top: 40px;
  align-items: center;
}


.raid-boss-button-and-drops > div:nth-child(2){
  display: flex;
  flex-direction: column;
}

.raid-boss-button-and-drops > div:nth-child(2) > p{
  margin-bottom: 5px;
  font-family: Roboto;
  color: #CEC198;
  font-size: 0.8em;
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

.none-desktop{
  display: none;
}

.boss-images{
  display: none;
}

.pve-container:hover,
.pvp-container:hover,
.raid-container:hover{
  animation: animateBG 3s ease;
}

@keyframes animateBG {
  from{
    background-size: 110%;
  }
  to{
    background-size: 120%;
  }
}

@media screen and (max-width: 1280px)  {
  .raid-container,
  .pvp-container,
  .pve-container {
    background-size: cover;
  }
  .pve-container:hover,
  .pvp-container:hover,
  .raid-container:hover{
    animation: none;
  }
  .overlay-bg {
    background-color: rgba(0, 0, 0, 0.425);
  }
  .lower-body-container {
    display: flex;
    flex-direction: column;
    row-gap: 10px;
    width: 100%;
    margin-top: 50px;
    height: 80%;
  }

  .raid-container {
    width: 100%;
  }
  .pvp-and-pve-container {
    width: 100%;
  }
}

@media all and (max-width: 600px) {
  .upper-body-container,
  .lower-body-container {
    display: flex;
    flex-direction: row;
    z-index: 3;
    padding-left: 20px;
    padding-right: 20px;
  }

  .joinRaid{
    display: none;
  }

  .upper-body-container{
    height: 15%;
  }

  .character-name > span,
  .raid-boss-name > span {
    font-size: 4.5vw;
  }

  .character-data-container > div > span {
    font-size: 2.2vw
  }

  .pvp-wins-label > span,
  .pvp-rank-label > span,
  .pvp-power-label > span {
    font-size: 2.5vw;
  }

  .raid-boss-button-and-drops > div:nth-child(1){
    display: none;
  }

  .raid-boss-name-element-container{
    padding-top: 10px;
  }

  .raid-container{
    overflow: visible;
  }

  .raid-boss-image-container{
    display: none;
  }

  .lower-body-container{
    padding-top: 5px;
    margin-top: 10px !important;
  }

  .raid-boss-power-element-duration-container{
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    grid-template-rows: repeat(2, 1fr);
    grid-column-gap: 0px;
    grid-row-gap: 0px;
    z-index: 1;
    overflow: hidden;
  }

  .raid-boss-power { grid-area: 1 / 1 / 2 / 2; width: 100%; }
  .aid-boss-element { grid-area: 1 / 2 / 2 / 3; width: 100%;}
  .raid-boss-duration { grid-area: 2 / 1 / 3 / 3; width: 100%;}

  .pvp-wins-value > span,
  .pvp-rank-value > span,
  .pvp-power-value > span {
    font-size: 5.5vw;
    line-height: 7vw;
  }

  .raid-boss-name > p{
    font-size: 3vw;
  }

  .dashboard-btn > span{
    font-size: 5vw;
  }


  .small-stamina-char{
    margin-top: 2px;
    margin-bottom: 2px;
  }

  .raid-boss-label {
    font-size: 3vw;
  }

  .raid-info-container{
    width: 100%;
  }


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

  .boss-images{
    display: inline;
    width: 100%;
    height: auto;
    z-index: 2;
  }

  .pvp-and-pve-container {
    width: 100%;
    margin-top: 30px;
  }

  .none-desktop{
    display: inline-block;
  }
  .raid-info-container > a{
    display: flex;
    justify-content: center;
  }
}
</style>
