<template>
  <div>
    <div>
      <div>
        <h2>Arena</h2>
        <br/>
        <span>Enter the Arena and win rewards ($SKILL).</span>
        <br/>
        <button @click="handleEnterArenaClick()">
          Enter Arena
        </button>
      </div>

      <button @click="setTab(0)">Equipment</button>
      <button @click="setTab(1)">Duel History</button>

      <div v-if="tab === 0">
        <pvp-weapon
          v-if="activeWeaponWithInformation.weaponId"
          :stars="activeWeaponWithInformation.information.stars + 1"
          :element="activeWeaponWithInformation.information.element"
          :weaponId="activeWeaponWithInformation.weaponId"
        />
        <br/>
        <pvp-shield
          v-if="activeShieldWithInformation.shieldId"
          :stars="activeShieldWithInformation.information.stars + 1"
          :element="activeShieldWithInformation.information.element"
          :shieldId="activeShieldWithInformation.shieldId"
        />
      </div>

      <div v-else>
        DUEL HISTORY
      </div>

      <div>
        <h2>Arena Information</h2>
        <br/>
        <div>
          <h3>PVP Rewards Pool ($SKILL)</h3>
          <br/>
          <span>{{ formatedTierRewardsPool }}</span>
        </div>
        <div>
          <h3>Top Players</h3>
          <br/>
          <span>Rank 1: {{ tierTopRankers[0] && tierTopRankers[0].name || '-' }} / RANK: {{ tierTopRankers[0] && tierTopRankers[0].rank }}</span>
          <br/>
          <span>Rank 2: {{ tierTopRankers[1] && tierTopRankers[1].name || '-' }} / RANK: {{ tierTopRankers[1] && tierTopRankers[1].rank }}</span>
          <br/>
          <span>Rank 3: {{ tierTopRankers[2] && tierTopRankers[2].name || '-' }} / RANK: {{ tierTopRankers[2] && tierTopRankers[2].rank }}</span>
          <br/>
        </div>
      </div>

      <div>
        <h2>{{ characterInformation.name || '' }}</h2>
        <br/>
        <span>Power: {{ characterInformation.power }}</span>
        <!-- <br/>
        <span>Damage Multiplier</span> -->
        <br/>
        <span>Level: {{ characterInformation.level }}</span>
        <br/>
        <span>Current Rank: {{ characterInformation.rank }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import BN from 'bignumber.js';
import PvPWeapon from '../../components/PvPWeapon.vue';
import PvPShield from '../../components/PvPShield.vue';

export default {
  components: {
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield
  },

  props: {
    tierRewardsPool: {
      default: null
    },
    tierTopRankers: {
      default: []
    },
    characterInformation: {
      default: {
        tier: null,
        name: '',
        level: null,
        power: null,
        rank: null,
        element: null,
      }
    },
    activeWeaponWithInformation: {
      default: {
        weaponId: null,
        information: {}
      }
    },
    activeShieldWithInformation: {
      default: {
        shieldId: null,
        information: {}
      }
    },
  },

  data() {
    return {
      tab: 0
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount']),

    formatedTierRewardsPool() {
      return new BN(this.tierRewardsPool).div(new BN(10).pow(18)).toFixed(3);
    },
  },

  methods: {
    setTab(tabNumber) {
      this.tab = tabNumber;
    },

    async handleEnterArenaClick() {
      this.$emit('enterMatchMaking');
    },
  },
};
</script>
