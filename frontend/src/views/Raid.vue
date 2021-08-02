<template>
  <div class="main-font">
    <div class="row">
      <div class="col-6">
        <h2>Dragon's Lair</h2>
        <hr class="devider">
        <div class="row">
          <div class="col-6">
            <ul class="list-group">
              <li class="list-group-item d-flex justify-content-between align-items-center">
                Number of Raiders
                <span class="badge badge-primary badge-pill">{{ raiderCount }}</span>
              </li>
              <li class="list-group-item d-flex justify-content-between align-items-center">
                Total Power
                <span class="badge badge-primary badge-pill">{{ totalPower }}</span>
              </li>
               <li class="list-group-item d-flex justify-content-between align-items-center">
                 Boss Power
                <span class="badge badge-primary badge-pill">{{ bossPower }}</span>
              </li>
            </ul>
            <h5 class="mt-3">
              Drops
              <b-icon-question-circle v-tooltip="'Rewards are based on your contributed power relative to others.<br>Joining early gives up to 10% bonus.'"/>
            </h5>
            <hr class="devider">
            <div class="drops">
              <div class="drops-icons">
                <nft-icon :isDefault="true" :nftType="'weapon'" />
                <nft-icon :isDefault="true" :nftType="'junk'"/>
                <nft-icon :isDefault="true" :nftType="'secret'"/>
              </div>
              <br />
              <span class="title">XP reward</span> {{ xpReward }}
            </div>
          </div>
          <div class="col-6">
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
      </div>
      <div class="col-6">
        <div class="row">
          <div class="col-6">
            <h2>Weapon
                <Hint
                text="Your weapon multiplies your power<br>
                  <br>+Stats determine the multiplier
                  <br>Stat element match with character gives greater bonus"/>
                  <span class="float-right sub-text">Multiplier: x1.23</span>
              </h2>
              <hr class="devider">
              <div class="header-row">
              <div v-if="selectedWeaponId" class="weapon-icon-wrapper">
                <weapon-icon class="weapon-icon" :weapon="selectedWeapon" />
              </div>
              <b-button v-if="selectedWeaponId" variant="primary" class="ml-3" @click="selectedWeaponId = null">
                Choose New Weapon
              </b-button>
            </div>
            <weapon-grid v-if="!selectedWeaponId" v-model="selectedWeaponId" />
          </div>
          <div class="col-6">
            <h3>Choose a Character <span class="float-right sub-text">Power {{ 10000 }}</span></h3>
            <hr class="devider">
            <character-list :value="currentCharacterId" @input="setCurrentCharacter" />
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
            <div class="col-sm-4">
              <div class="float-left">
                <div class="finish">
                    <span class="title">Finishes on</span>
                    {{ expectedFinishTime }}
                    <br />
                    <span class="title">Raid status</span> {{ raidStatus }}
                  </div>
              </div>
            </div>
            <div class="col-sm-4" v-if="rewardIndexes !== null && rewardIndexes.length > 0">
              <big-button class="encounter-button btn-styled" :mainText="`Claim rewards`" @click="promptRewardClaim()" />
              <b-modal id="rewardsRaidPicker" title="Raid rewards selector" @ok="claimRewardIndex(rewardsRaidId)">
                <div class="raid-picker">
                  Select a raid to claim rewards from:
                  <select class="form-control raid-id-selector" v-model="rewardsRaidId">
                    <option v-for="id in rewardIndexes" :value="id" :key="id">{{ id }}</option>
                  </select>
                </div>
              </b-modal>
            </div>
            <div class="col-sm-4">
              <big-button class="encounter-button btn-styled" :mainText="`Sign up!`" v-tooltip="'Joining will cost 12h of stamina'" @click="joinRaidMethod()" />
            </div>
            <div class="col-sm-4">
             <div class="float-right">
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
      rewardsRaidId: null
    };
  },

  computed: {
    ...mapState(['characters', 'maxStamina', 'currentCharacterId', 'defaultAccount']),
    ...mapGetters(['ownCharacters', 'ownWeapons', 'ownCharacters', 'currentCharacter',
      'currentCharacterStamina', 'getWeaponDurability', 'contracts']),

    selections() {
      return [this.currentCharacterId, this.selectedWeaponId];
    },
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
      if (this.selectedWeaponId === null || this.currentCharacterId === null) {
        this.$dialog.notify.error('Check Character and Weapon Selection and try again...');
        return;
      }

      try {
        console.log('Trying to join raid...');
        await this.joinRaid(this.currentCharacterId, this.selectedWeaponId);
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
      console.log('Reward claimed for '+rewardIndex);
      console.log('Result: '+result);
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
      this.expectedFinishTime = raidData.expectedFinishTime;
      this.xpReward = raidData.xpReward;
      this.staminaCost = raidData.staminaCost;
      this.durabilityCost = raidData.durabilityCost;
      this.joinCost = raidData.joinSkill;
      this.raidStatus = raidData.status;
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
    await this.getRewardIndexes();
  },

  components: {
    BigButton,
    CharacterList,
    WeaponGrid,
    WeaponIcon,
    Hint,
    NftIcon
  },
};
</script>

<style scoped>
hr.devider {
   border: 0.5px solid #242423;
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
  background: rgb(49, 44, 44);
  padding: 20px;
  margin-bottom: 20px;
  border-radius: 5px;
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
  margin: 0 auto;
  height: 5em;
  width: 13em;
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

.form-control.raid-id-selector {
  width: fit-content;
  height: fit-content;
  margin: 5px;
  padding: 0;
}
</style>
