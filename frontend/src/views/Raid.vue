<template>
  <div class="body main-font">
    <div class="left-side fill-space raid-info">
      <div class="left-side">
        <div class="finish">
          <span class="title">Finishes on</span>
          <br />
          {{ expectedFinishTime }}
          <br />
          <br />
          <span class="title">Raid status</span>
          <br />
          {{ raidStatus }}
        </div>

        <div class="raiders">
          <span class="title">Raiders</span> {{ raiderCount }}
          <br />
          <span class="title">Total Player Power</span> {{ totalPower }}
          <br />
          <span class="title">Boss Power</span> {{ bossPower }}
          <br />
          <span class="title">Join Cost</span>
          <br />
          {{ 'Stamina: '+staminaCost }}
          <br />
          {{ 'Durability: '+durabilityCost }}
          <br />
          {{ 'SKILL: '+joinCost }}
        </div>

        <div class="drops">
          <span class="title">Drops</span>
          <br />
          {{ '(Rewards are based on your contributed power relative to others)' }}
          <br />
          {{ '(Joining early gives up to 10% bonus)' }}
          <br />
          {{ 'Weapons (2-5*), Junk (1-5*), SECRET (??) - INSERT IMAGES HERE' }}
          <br />
          <span class="title">XP reward</span> {{ xpReward }}
        </div>
      </div>

      <div class="right-side raid-boss">
        <div class="raid-title">
          <span class="title">Dragon's lair</span>
        </div>

        <div class="image">
          <img src="../assets/DragonFlyIdle_512.gif" />
        </div>

        <div class="about-raid">
          <span class="title"> {{ bossName }} </span>
          <br />
          <span class="lightning"> {{ bossTrait }} </span>
        </div>
      </div>
    </div>

    <div class="right-side fill-space raid-signup">
      <div class="chooser">
        <div class="left-side">
          <character-list :value="currentCharacterId" @input="setCurrentCharacter" />
        </div>
        <div class="right-side">
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
              <b-button v-if="selectedWeaponId" variant="primary" class="ml-3" @click="selectedWeaponId = null">
                Choose New Weapon
              </b-button>
            </div>
            <weapon-grid v-if="!selectedWeaponId" v-model="selectedWeaponId" />
          </div>
        </div>
      </div>

      <div class="signup">
        <div class="warning">
          Joining will cost {{ staminaCost }} stamina, {{ durabilityCost }} durability and {{ joinCost }} SKILL
        </div>

        <div class="power">
          <div class="left-side">Character Power: {{ 10000 }}</div>
          <div class="right-side">Weapon Multiplier: x1.23</div>
        </div>

        <div class="total-power">
          Total power: 12300
        </div>

        <div class="action">
          <big-button class="encounter-button btn-styled" :mainText="`Sign up!`" v-tooltip="'Joining will cost 12h of stamina'" @click="joinRaidMethod()" />
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
    ...mapActions(['fetchRaidState', 'fetchOwnedCharacterRaidStatus', 'joinRaid']),
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

    async getRewardEligibility(lowIndex, highIndex) {
      console.log(lowIndex+' / '+highIndex);
    },

    async getParticipatingCharacters() {
    },

    async getParticipatingWeapons() {
    },

    async canJoinRaid(characterID, weaponID) {
      console.log(characterID+' / '+weaponID);
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
      if (!this.ownWeapons.find((weapon) => weapon.id === weaponId)) {
        this.selectedWeaponId = null;
      } else {
        this.selectedWeapon = this.ownWeapons.find((weapon) => weapon.id === this.selectedWeaponId);
      }
    },
  },

  async mounted() {
    await Promise.all([
      this.fetchRaidState(),
    ]);
    this.processRaidData();
  },

  components: {
    BigButton,
    CharacterList,
    WeaponGrid,
    WeaponIcon,
    Hint,
  },
};
</script>

<style scoped>
.body {
  display: flex;
  flex-direction: row;
  align-items: center;
  height: calc(100vh - 56px - 160px - 32px);
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
</style>
