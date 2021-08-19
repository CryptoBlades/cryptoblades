<template>
  <div class="main-font">
    <div class="row">
      <div class="col-md-12 col-lg-6">
        <span class="bold raid-title-section">Dragon's Lair</span>
        <hr class="devider">
        <div class="row">
          <div class="col-md-12 col-lg-6 order-xs-last order-sm-last order-lg-first">
            <ul class="list-group raid-details mb-4">
              <li class="list-group-item d-flex justify-content-between align-items-center raid-details-text">
                Number of Raiders
                <span class="badge badge-primary badge-pill">{{ raiderCount }}</span>
              </li>
              <li class="list-group-item d-flex justify-content-between align-items-center raid-details-text">
                Total Power
                <span class="badge badge-primary badge-pill">{{ totalPower }}</span>
              </li>
               <li class="list-group-item d-flex justify-content-between align-items-center raid-details-text">
                 Boss Power
                <span class="badge badge-primary badge-pill">{{ bossPower }}</span>
              </li>
            </ul>
            <span class="mt-3 bold raid-title-section">
              Drops
              <b-icon-question-circle v-tooltip="'Rewards are based on your contributed power relative to others.<br>Joining early gives up to 10% bonus.'"/>
            </span>
            <hr class="devider">
            <div class="drops">
              <div class="drops-icons">
                <nft-icon :isDefault="true" :nft="{ type: 'weapon' }" />
                <nft-icon :isDefault="true" :nft="{ type: 'junk' }"/>
                <nft-icon :isDefault="true" :nft="{ type: 'secret' }"/>
              </div>
              <br />
              <span class="bold raid-title-section">XP reward</span> <span class="xp-reward ml-3 raid-details-text"> {{ xpReward }} </span>
            </div>
          </div>
          <div class="col-xs-12 col-sm-12 col-md-12 col-lg-6 order-xs-first order-sm-first boss-col">
            <div class="boss-box">
              <div class="raid-title">
                <span class="title mr-3"> {{ bossName }} </span>
                <span class="lightning">ELEMENT: {{ bossTrait }} </span>
              </div>
              <div class="img-responsive boss-img">
                <img src="../assets/DragonFlyIdle_512.gif" class="img-responsive" />
              </div>
            </div>
          </div>
        </div>
        <hr class="devider">
      </div>
      <div class="col-md-12 col-lg-6 weap-char">
        <div class="row">
          <div class="col-xs-12 col-sm-12 col-lg-6 weap-box">
            <span class="raid-title-section bold">Weapon
                <Hint
                text="Your weapon multiplies your power<br>
                  <br>+Stats determine the multiplier
                  <br>Stat element match with character gives greater bonus"/>
                  <span class="float-right sub-text">Multiplier: x{{ currentMultiplier }}</span>
              </span>
              <hr class="devider">
              <div class="header-row">
              <div v-if="selectedWeaponId" class="weapon-icon-wrapper">
                <weapon-icon class="weapon-icon" :weapon="selectedWeapon" />
              </div>
              <b-button v-if="selectedWeaponId" variant="primary" class="ml-3" @click="selectedWeaponId = null">
                Choose New Weapon
              </b-button>
            </div>
            <weapon-grid v-if="!selectedWeaponId" v-model="selectedWeaponId" class="raid-weapon-grid" />
            <hr class="devider">
          </div>
          <div class="col-xs-12 col-sm-12 col-lg-6 char-box">
            <span class="raid-title-section bold">Choose a Character <span class="float-right sub-text">Power {{ currentCharacterPower }}</span></span>
            <hr class="devider">
            <character-list :value="currentCharacterId" @input="setCurrentCharacter" class="raid-style" />
            <hr class="devider">
          </div>
        </div>
      </div>
    </div>
    <div class="container disclaimer-box">
      <div class="row">
        <div class="col-12">
          <div class="text-center">
            Joining will cost <span class="badge badge-secondary">{{ staminaCost }}
            stamina </span>,
            <span class="badge badge-secondary">{{ durabilityCost }}
            durability </span> and
            <span class="badge badge-secondary">{{ joinCost }}SKILL</span>
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-sm-12">
        <div class="raid-info-box mt-3">
          <div class="row">
            <div v-bind:class="claimButtonActive ? 'col-sm-3' : 'col-sm-4'">
              <div class="float-lg-left mb-sm-2">
                <div class="finish">
                    <span class="title">Finishes on</span>
                    {{ expectedFinishTime }}
                    <br />
                    <span class="title">Raid status</span> {{ raidStatus }}
                  </div>
              </div>
            </div>
            <div v-bind:class="claimButtonActive ? 'col-sm-3' : 'col-sm-4'" v-if="claimButtonActive">
              <big-button v-if="claimButtonActive" class="encounter-button btn-styled" :mainText="`Claim rewards`" @click="promptRewardClaim()" />
              <b-modal id="rewardsRaidPicker" title="Raid rewards selector" @ok="claimRewardIndex(rewardsRaidId)">
                <div class="raid-picker">
                  Select a raid to claim rewards from:
                  <select class="form-control raid-id-selector" v-model="rewardsRaidId">
                    <option v-for="id in rewardIndexes" :value="id" :key="id">{{ id }}</option>
                  </select>
                </div>
              </b-modal>
            </div>
            <b-modal id="rewardsModal" title="Raid rewards" size="lg">
              <nft-list :showGivenNftIdTypes="true" :nftIdTypes="rewards" :isReward="true"/>
            </b-modal>
            <div v-bind:class="claimButtonActive ? 'col-sm-3' : 'col-sm-4'">
              <big-button class="encounter-button btn-styled" :mainText="`Sign up!`" v-tooltip="'Joining will cost 12h of stamina'" @click="joinRaidMethod()" />
            </div>
            <div v-bind:class="claimButtonActive ? 'col-sm-3' : 'col-sm-4'">
             <div class="float-lg-right text-sm-center mt-sm-2 text-center">
                <div class="finish">
                    <span class="title">Total Power:  10000</span>
                  </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
 </div>
</template>
<script>
import { mapActions, mapGetters, mapState, mapMutations } from 'vuex';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import BigButton from '../components/BigButton.vue';
import WeaponIcon from '../components/WeaponIcon.vue';
import Hint from '../components/Hint.vue';
import NftIcon from '@/components/NftIcon.vue';
import NftList from '@/components/smart/NftList.vue';
import { GetTotalMultiplierForTrait } from '@/interfaces/Weapon';
import { CharacterPower } from '@/interfaces';

let interval = null;

const dragonNames = [
  'Fudbringer',
  'HODL Lord',
  'Skill Eater',
  'Chain Congester',
  'Swap Guardian',
  'Blade Hoarder',
  'Centralizer',
  'Exchange Tormentor',
  'Eater of Stakes'
];

export default {
  data() {
    return {
      selectedWeaponId: null,
      selectedWeapon: null,
      error: null,
      raidIndex: null,
      bossName: null,
      raiderCount: null,
      totalPower: null,
      expectedFinishTime: null,
      xpReward: null,
      staminaCost: null,
      durabilityCost: null,
      joinCost: null,
      raidStatus: null,
      bossPower: null,
      bossTrait: null,
      rewardIndexes: null,
      rewardsRaidId: null,
      rewards: null
    };
  },

  computed: {
    ...mapState(['characters', 'maxStamina', 'currentCharacterId', 'defaultAccount']),
    ...mapGetters(['ownCharacters', 'ownWeapons', 'ownCharacters', 'currentCharacter',
      'currentCharacterStamina', 'getWeaponDurability', 'contracts']),

    selections() {
      return [this.currentCharacterId, this.selectedWeaponId];
    },

    claimButtonActive() {
      return this.rewardIndexes !== null && this.rewardIndexes.length > 0;
    },

    currentMultiplier() {
      if(!this.selectedWeaponId) return '0';
      const currentWeapon = this.ownWeapons[this.selectedWeaponId];
      return GetTotalMultiplierForTrait(currentWeapon, this.currentCharacter.trait);
    },

    currentCharacterPower() {
      if(!this.currentCharacter) return '0';
      return CharacterPower(this.currentCharacter.level);
    }
  },

  methods: {
    ...mapActions(['fetchRaidState', 'fetchOwnedCharacterRaidStatus', 'joinRaid',
      'fetchRaidRewards', 'claimRaidRewards', 'fetchRaidingCharacters', 'fetchRaidingWeapons',
      'fetchRaidJoinEligibility']),
    ...mapMutations(['setCurrentCharacter']),
    ...mapGetters(['getRaidState']),

    weaponHasDurabilit(id) {
      return this.getWeaponDurability(id) > 0;
    },

    async joinRaidMethod() {
      if (!this.selectedWeaponId || !this.currentCharacterId) {
        this.$dialog.notify.error('Check Character and Weapon Selection and try again...');
        return;
      }

      try {
        console.log('Trying to join raid...');
        await this.joinRaid({ characterId: this.currentCharacterId, weaponId: this.selectedWeaponId});
        console.log('Made it to the other side at least...');
      } catch (e) {
        console.error(e);
        this.$dialog.notify.error('Whoops...');
      }
    },

    async getParticipatingCharacters() {
      // gets the list of this player's raid locked characters
      // TODO store these?
      await this.fetchRaidingCharacters();
    },

    async getParticipatingWeapons() {
      // gets the list of this player's raid locked weapons
      // TODO store these?
      await this.fetchRaidingWeapons();
    },

    async canJoinRaid(characterID, weaponID) {
      return await this.fetchRaidJoinEligibility({
        characterID,
        weaponID
      });
    },

    async getRewardIndexes() {
      if(this.raidIndex === null || this.raidIndex === undefined)
        return;
      let startIndex = this.raidIndex-21; // one week worth
      if(startIndex < 0)
        startIndex = 0;
      const endIndex = this.raidIndex;

      this.rewardIndexes = await this.fetchRaidRewards({
        startIndex,
        endIndex
      });
      console.log('SI '+startIndex+' / EI '+endIndex);
      console.log('RI '+this.rewardIndexes.length);
    },

    promptRewardClaim() {
      // should offer a popup here to pick which index to claim
      // if only one index, then claim instantly
      if(this.rewardIndexes !== null && this.rewardIndexes.length > 0) {
        if(this.rewardIndexes.length === 1) {
          this.claimRewardIndex(this.rewardIndexes[0]);
        }
        else {
          this.$bvModal.show('rewardsRaidPicker');
        }
      }
    },

    async claimRewardIndex(rewardIndex) {
      console.log('Attempting to claim reward index '+rewardIndex);
      const result = await this.claimRaidRewards({
        rewardIndex
      });
      console.log(JSON.stringify(result));
      const nfts = [];
      if(result.weapon) {
        nfts.push({ type: 'weapon', id: result.weapon?.tokenId, stars: result.weapon?.stars }); //result.weapons?.map(x => { return { type: 'weapon', id: x.tokenId, stars: x.stars}; }));
      }
      if(result.junk) {
        nfts.push({ type: 'junk', id: result.junk?.tokenId, stars: result.junk?.stars }); //result.junk?.map(x => { return { type: 'junk', id: x.tokenId, stars: x.stars}; }));
      }
      if(result.keybox) {
        nfts.push({ type: 'keybox', id: result.keybox?.tokenId }); //result.keybox?.map(x => { return { type: 'keybox', id: x.tokenId }; }));
      }

      console.log('nfts ' + JSON.stringify(nfts));
      this.rewards = nfts;
      // this.rewards = [
      //   { type:'weapon', id: 1, stars: 2},
      //   { type:'junk', id:1, stars:3 },
      //   { type:'keybox', id:1 }
      // ];
      this.$bvModal.show('rewardsModal');
      console.log('Reward claimed for '+rewardIndex);
      //console.log('Result: '+result);
    },

    getBossName() {
      return dragonNames[this.raidIndex % dragonNames.length];
    },

    processRaidData() {
      const raidData = this.getRaidState();
      this.raidIndex = raidData.index;
      this.bossName = this.getBossName();
      this.raiderCount = raidData.raiderCount;
      this.totalPower = raidData.playerPower;
      this.expectedFinishTime = new Date(raidData.expectedFinishTime * 1000).toLocaleString();
      this.xpReward = raidData.xpReward;
      this.staminaCost = raidData.staminaCost;
      this.durabilityCost = raidData.durabilityCost;
      this.joinCost = raidData.joinSkill;
      this.raidStatus = raidData.status ? 'Preparation' : 'Finished';
      this.bossPower = raidData.bossPower;
      this.bossTrait = raidData.bossTrait;
    }
  },

  watch: {
    async selections([weaponId]) {
      if (!this.ownWeapons.find((weapon) => weapon && weapon.id === weaponId)) {
        this.selectedWeaponId = null;
      } else {
        this.selectedWeapon = this.ownWeapons.find((weapon) => weapon && weapon.id === this.selectedWeaponId);
      }
    },
  },

  async mounted() {
    await Promise.all([
      this.fetchRaidState(),
    ]);
    this.processRaidData();
    interval = setInterval(async () => {
      await this.getRewardIndexes();
      await this.fetchRaidState();
      this.expectedFinishTime = new Date(this.getRaidState()?.expectedFinishTime * 1000).toLocaleString();
    }, 5000);
  },

  beforeDestroy() {
    clearInterval(interval);
  },

  components: {
    BigButton,
    CharacterList,
    WeaponGrid,
    WeaponIcon,
    Hint,
    NftIcon,
    NftList
  },
};
</script>

<style scoped>
.raid-height {
  height: 500px !important;
}

.raid-style {
  display: block;
  width: 100%;
  padding: 0;
 height: 473px;
 overflow-y: auto;
 overflow-x: hidden;
 border: 0.5px solid #1f1f1f;
}


.raid-style::-webkit-scrollbar-track
{
	-webkit-box-shadow: inset 0 0 6px rgba(156, 109, 46, 0.3);
	background-color: #F5F5F5;
}

.raid-style::-webkit-scrollbar
{
	width: 10px;
	background-color: #F5F5F5;
}
.raid-style::-webkit-scrollbar-thumb
{
	background-color: #a3773e;
	border: 2px solid #555555;
}


.raid-style >>> ul.character-list {
    display: flex;
    flex-direction: row;
    flex-wrap: wrap;
}
.raid-style >>> ul.character-list > li.character {
    margin: 0 auto;
    flex-grow: 0;
    flex-shrink: 0;
    flex-basis: 47%;
}

.raid-style >>> ul.character-list > li.character.selected {
    box-shadow: 0 3px 15px #ffd400;
    border: 0.5px solid #fff;
}

.raid-weapon-grid >>> .stars-elem  {
  width: 50% !important;
  max-width: 100% !important;
  flex: 0 0 50% !important;
}

.raid-weapon-grid >>> .clear-filters-button {
  max-width: 300px;
  width: 100%;
  margin-top: 10px;
  margin-left: 0px;
}

.raid-weapon-grid >>> .clear-filters-button > span {
  margin: 0 auto;
}

.raid-weapon-grid {
  height: 473px;
  overflow-y: auto;
  border: 0.5px solid #1f1f1f;
}

.raid-weapon-grid::-webkit-scrollbar-track
{
	-webkit-box-shadow: inset 0 0 6px rgba(156, 109, 46, 0.3);
	background-color: #F5F5F5;
}

.raid-weapon-grid::-webkit-scrollbar
{
	width: 10px;
	background-color: #F5F5F5;
}
.raid-weapon-grid::-webkit-scrollbar-thumb
{
	background-color: #a3773e;
	border: 2px solid #555555;
}


.raid-weapon-grid >>> .weapon-grid {
  width: 100% !important;
  margin: 0 auto;
  display: grid;
  justify-content: center;
  align-content: center;
  position: relative;
}

.raid-weapon-grid >>> ul.weapon-grid > li.weapon {
  margin: 0 auto;
  height: 100%;
  border-radius: 0;
  background-image: none;
  height: auto;
}
h2 {
  font-size: 20px;
}
h2 > span.sub-text {
  font-size: 16px;
  color: #fff;
  vertical-align: middle;
  line-height: 2;
}
hr.devider {
  border: 0.5px solid #dabf75;
}
.container-fluid {
  margin-top: 500px;
}
.disclaimer-box {
  margin-top: 20px;
  border-top: 0.5px solid #242423;
  padding: 20px;
}
.list-group {
  max-width: 100%;
  border: 0;
  background: none;
}
.list-group-item {
  border-top: 0px !important;
  border-left: 0px !important;
  border-right: 0px !important;
  border-bottom: 0.5px solid #242423 !important;
}
.body {
  display: flex;
  flex-direction: row;
  align-items: center;
  height: calc(100vh - 56px - 160px - 32px);
}
.raid-info-box {
  background: #2e2e30cc;
  padding: 20px;
  margin-bottom: 20px;
  border-radius: 0px;
  border: 1px solid #515152cc;
}
.border-box {
  border: 0.5px solid #242423;
  border-radius: 5px;
  padding: 10px 20px;
}
.raid-header {
  border-bottom: 0.5px dashed rgb(49, 45, 40);
  margin-bottom: 20px;
}
.boss-img {
  width: 100%;
}
.boss-img > img {
  width: 100%;
}
.boss-box {
  border: 0.5px solid #242423;
  border-radius: 5px;
  padding: 10px 20px;
  background: #ccc;
  background-image: url(https://www.cryptoblades.io/images/background/video-bg.png);
  background-repeat: no-repeat;
   background-position: center;
}
.title {
  font-weight: bold;
  font-size: 1.4em;
}

.fill-space {
  height: 100%;
  padding: 1em;
  padding-top: 3em;
}

.left-side,
.right-side {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.chooser,
.power {
  flex: 1;
  display: flex;
  flex-direction: row;
}

.chooser .left-side,
.chooser .right-side {
  max-height: 300px;
  overflow-y: auto;
}

.raid-info {
  flex-direction: row;
}

.raiders,
.drops {
  margin-top: 1em;
}

.drops-icons {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
}
.encounter-button {
  display: block;
  top:0 !important;
}
.raid-boss,
.raid-signup {
  justify-content: space-between;
}

.warning,
.power,
.total-power,
.action {
  text-align: center;
  margin-top: 0.5em;
}

.encounter-button {
  display: block;
  margin: 2px auto;
  height: 5em;
  width: 20em;
  position: relative;
  top: 3vw;
}

.weapon-icon-wrapper {
  background: rgba(255, 255, 255, 0.1);
  width: 12em;
  height: 12em;
}

.enemy-list[data-v-067077ae] {
    display: flex;
    flex-wrap: wrap;
    padding-left: 30px;
    padding-right: 30px;
}

.raid-picker {
  display: flex;
  align-items: center;
}

.raid-title-section {
  font-size : 1.5em;
  color : #dabf75;
}

.raid-details {
  border: 1px solid;
  border-radius: 5px;
}

.raid-details-text {
  font-size: 1.2em;
  color: #ccae4f;
}
.raid-details-text > span {
  background-color: #5c6063;
}
.form-control.raid-id-selector {
  width: fit-content;
  height: fit-content;
  margin: 5px;
  padding: 0;
}

.xp-reward {
  background: #40422f;
  border: 1px solid #727151;
  padding: 4px;
  border-radius: 25%;
}

@media (max-width: 1024px) {
  .weap-char {
    margin-top: 50px;
    border-top: dashed 1px #ccc;
    padding-top : 20px;
  }
}

@media (max-width: 994px) {

  img.img-responsive {
    height: 350px;
  }
}
@media (max-width: 726px) {
  .weap-box, .char-box {
    margin-top: 30px;
  }
  .img-responsive .boss-img {
    height: 300px;
  }
  .finish {
    text-align: center;
    margin: 10px;
  }
}


@media (max-width: 1251px) {
  .boss-col {
    display: block;
  }
}
</style>
