<template>
  <div class="body main-font">
    <div class="left-side fill-space raid-info">
      <div class="left-side">
        <div class="finish">
          <span class="title">Finishes on</span>
          <br />
          {{expectedFinishTime}}
        </div>

        <div class="raiders">
          <span class="title">Raiders</span> {{raiderCount}}
          <br />
          <span class="title">Total Power</span> {{totalPower}}
          <br />
          <span class="title">Bounty</span> {{bounty}}
        </div>

        <div class="drops">
          <span class="title">Drops</span>
          <br />
          {{weaponDrops}}
        </div>
      </div>

      <div class="right-side raid-boss">
        <div class="raid-title">
          <span class="title">Raid title</span>
        </div>

        <div class="image">
          <img src="../assets/DragonFlyIdle_512.gif" />
        </div>

        <div class="about-raid">
          <span class="title">Raid Name</span>
          <br />
          <span class="lightning">Lightning</span>
        </div>
      </div>
    </div>

    <div class="right-side fill-space raid-signup">
      <div class="chooser">
        <div class="left-side">
          <character-list />
        </div>

        <div class="right-side">
          <weapon-grid />
        </div>
      </div>

      <div class="signup">
        <div class="warning">
          Joining will cost 12h stamina
        </div>

        <div class="power">
          <div class="left-side">Character Power: {{10000}}</div>
          <div class="right-side">Weapon Multiplier: x1.23</div>
        </div>

        <div class="total-power">
          Total power: 12300
        </div>

        <div class="action">
          <big-button class="button" mainText="Sign up" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters,mapState } from 'vuex';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import BigButton from '../components/BigButton.vue';
import WeaponIcon from '../components/WeaponIcon.vue';

export default {
  computed: {
    ...mapState(['currentCharacterId']),
    ...mapGetters([
      'ownCharacters',
      'ownWeapons',
      'ownCharacters',
      'currentCharacter',
      'currentCharacterStamina',
      'getWeaponDurability',
      'fightGasOffset',
      'fightBaseline',
    ]),

    selections() {
      return [this.currentCharacterId, this.selectedWeaponId];
    },
  },

  props: {},

  methods: {
    ...mapActions(['fetchRaidData', 'fetchOwnedCharacterRaidStatus']),

    weaponHasDurabilit(id) {
      return this.getWeaponDurability(id) > 0;
    },

    async onClickEncounter() {
      if (this.selectedWeaponId === null || this.currentCharacterId === null) {
        return;
      }
    },
  },

  watch: {
    async selections([characterId, weaponId]) {
      if (!this.ownWeapons.find((weapon) => weapon.id === weaponId)) {
        this.selectedWeaponId = null;
      }
    },
  },

  async mounted() {
    await Promise.all([this.fetchRaidData(), this.fetchOwnedCharacterRaidStatus()]);
  },

  components: {
    BigButton,
    CharacterList,
    WeaponGrid,
    WeaponIcon,
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
</style>
