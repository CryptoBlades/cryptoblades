<template>
  <div class="wrapper">
    <div class="mainWrapper">
      <div class="arenaSignup">
        <h1 class="title">ARENA SIGNUP</h1>
        <p>Enter the arena and win rewards ($SKILL).</p>
        <div></div>
        <div class="buttonWrapper">
          <pvp-button
            @click="handleEnterArenaClick()"
            buttonText="ENTER ARENA"
          />
        </div>
        <div class="bottomWrapper">
          <div class="bottomWrapperNav">
            <button @click="setTab(0)" :class="tab === 0 && 'active'">Equipment</button>
            <button @click="setTab(1)" :class="tab === 1 && 'active'">Duel history</button>
          </div>
          <div class="bottomWrapperInner">
            <div v-if="tab === 0" class="bottomWeapons">
              <pvp-weapon
                v-if="activeWeaponWithInformation.weaponId"
                :weapon="activeWeaponWithInformation.information"
                :weaponId="activeWeaponWithInformation.weaponId"
              />
              <br/>
              <pvp-shield
                v-if="activeShieldWithInformation.shieldId"
                :shield="activeShieldWithInformation.information"
                :shieldId="activeShieldWithInformation.shieldId"
              />
            </div>
             <div v-if="tab === 1" class="bottomDuels">
              <div v-if="duelHistory.length === 0" class="noDuels">You have not disputed any duels yet!</div>
              <ul v-else>
                <li><span>Date</span><span>Result</span></li>
                <li v-for="duel in duelHistory" :key="`${duel.attackerId}-${duel.timestamp}`">
                  <span class="date">{{ dayjs(new Date(duel.timestamp * 1000)).format('YYYY/MM/DD') }}</span>
                  <span :class="{'lost': !duel.attackerWon}" class="result">{{ duel.attackerWon ? 'Win' : 'Lose' }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
      <div class="characterImage">
        <pvp-character :characterId="currentCharacterId" />
      </div>
      <div class="arenaInformation">
        <h1 class="title">ARENA INFORMATION</h1>
        <div class="tokenCard">
          <img src="../../assets/skillToken.png" alt="skill token" />
          <div class="tokenCardInfo">
            <span class="text">PVP Rewards Pool ($SKILL)</span>
            <span class="number">{{ formatedTierRewardsPool }}</span>
          </div>
        </div>
        <ul class="topPlayersList">
          <li class="header">
            <span>Top Players</span><span>Rank</span>
          </li>
          <li>
            <span>Rank 1: {{ tierTopRankers[0] && tierTopRankers[0].name || 'N/A' }}</span>
            <span>{{ tierTopRankers[0] && tierTopRankers[0].rank || 'N/A' }}</span>
          </li>
          <li>
            <span>Rank 2: {{ tierTopRankers[1] && tierTopRankers[1].name || 'N/A' }}</span>
            <span>{{ tierTopRankers[1] && tierTopRankers[1].rank || 'N/A'}}</span>
          </li>
          <li>
            <span>Rank 3: {{ tierTopRankers[2] && tierTopRankers[2].name || 'N/A' }}</span>
            <span>{{ tierTopRankers[2] && tierTopRankers[2].rank || 'N/A'}}</span>
          </li>
        </ul>
        <ul class="topPlayersList">
          <li class="header">
            <span>Current Season</span><span>Restarts In</span>
          </li>
          <li>
            <span>{{ currentRankedSeason }}</span>
            <vue-countdown :time="secondsBeforeNextSeason * 1000" v-slot="{ days, hours, minutes, seconds }">
              {{ days && days || '' }} {{ days && 'days, ' || '' }}{{ hours }}:{{ minutes }}:{{ seconds }}
            </vue-countdown>
          </li>
        </ul>
        <ul class="characterAttrsList">
          <li class="characterName">{{ characterInformation.name || '' }}</li>
          <li><span>Power </span><span>{{ characterInformation.power }}</span></li>
          <li><span>Level</span><span>{{ characterInformation.level }}</span></li>
          <li><span>Current rank</span><span>{{ characterInformation.rank }}</span></li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import BN from 'bignumber.js';
import PvPWeapon from './PvPWeapon.vue';
import PvPShield from './PvPShield.vue';
import PvPButton from './PvPButton.vue';
import PvPCharacter from './PvPCharacter.vue';
import dayjs from 'dayjs';
import VueCountdown from '@chenfengyuan/vue-countdown';

export default {
  components: {
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield,
    'pvp-button': PvPButton,
    'pvp-character': PvPCharacter,
    'vue-countdown': VueCountdown
  },

  props: {
    tierRewardsPool: {
      default: null
    },
    tierTopRankers: {
      default: []
    },
    currentRankedSeason: {
      default: null
    },
    secondsBeforeNextSeason: {
      default: null
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
    duelHistory: {
      default: []
    }
  },

  data() {
    return {
      tab: 0,
      dayjs
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

<style scoped lang="scss">
.wrapper {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}
span, p, li, button, a {
  font-family: 'Roboto';
}
.mainWrapper {
  display: flex;
  justify-content: space-between;
}
.title {
  margin-bottom: 0.75rem;
  color: #cec198;
  font-size: 1.25rem;
  line-height: 1.75rem;
  font-family: 'Trajan';
}
.arenaSignup {
  p {
    color: #b4b0a7;
    font-size: 1rem;
    line-height: 1.5rem;
  }
  .top {
    display: flex;
    margin-top: 1.5rem;
    vertical-align: middle;
    align-items: center;
    .circle {
      display: flex;
      width: 1.75rem;
      height: 1.75rem;
      margin-right: 1rem;
      align-items: center;
      vertical-align: middle;
      justify-content: center;
      border-radius: 9999px;
      border: 2px solid #cec198;
    }
    img {
      height: 0.75rem;
      width: 0.75rem;
    }
    p {
      color: #cec198;
    }
  }
  .buttonWrapper {
    margin-top: 2.25rem;
    height: 5rem;
    width: 80%;
  }
}
.bottomWrapper {
  display: flex;
  width: 100%;
  flex-direction: column;
  margin-top: 4rem;
  .bottomWrapperNav {
    display: flex;
    border-bottom: 1px solid #363636;
    button {
      display: flex;
      padding-top: 0.5rem;
      padding-bottom: 0.5rem;
      align-items: center;
      vertical-align: middle;
      color: #b4b0a7;
      font-size: 0.875rem;
      line-height: 1.25rem;
      border-bottom: 2px solid transparent;
      border-right: none;
      border-left: none;
      border-top: none;
      background-color: transparent;
      img {
        width: 1rem;
        height: 1rem;
        margin-right: 0.5rem;
      }
      :hover {
        cursor: pointer;
      }
      &.active {
        color: #CEC198;
        border-bottom: 2px solid #CEC198;
      }
    }
    button:first-of-type {
      margin-right: 2rem;
    }
  }
  .bottomWrapperInner {
    padding-top: 2rem;
    padding-bottom: 2rem;
    border-bottom: 1px solid #363636;
  }
  .bottomWeapons {
    display: flex;
    div:first-of-type {
      margin-right: 1rem;
    }
  }
  .bottomDuels {
    display: flex;
    justify-content: space-between;
    span, li, div {
      font-family: 'Roboto';
    }
    .noDuels {
      font-size: .85rem;
    }
    .date {
      color: #B4B0A7;
    }
    .result {
      color: green;
    }
    .lost {
      color: red;
    }
    ul {
      margin-bottom: 0;
      padding-left: 0;
      width: 100%;
      list-style-type: none;
      li {
        display: flex;
        width: 100%;
        justify-content: space-between;
        color: #b4b0a7;
        span {
          display: flex;
          flex: 1;
        }
      }
      li:first-of-type {
        color: white;
        margin-bottom: 1rem;
      }
    }
  }
}
.characterImage {
  display: flex;
  width: 50%;
  padding: 3rem 0;
  margin: 0 1rem;
  @media only screen and (min-width: 1440px) {
    width: 40%;
    margin: 0;
  }
  @media only screen and (min-width: 1980px) {
    width: 30%;
  }
}
.arenaInformation {
  display: flex;
  flex-direction: column;
  .tokenCard {
    display: flex;
    padding: 1rem 2rem 1rem 1.5rem;
    border-radius: 0.375rem;
    align-items: center;
    vertical-align: middle;
    background-color: rgba(0, 0, 0, 0.3);
    img {
      width: 4rem;
      height: 4rem;
    }
    .tokenCardInfo {
      display: flex;
      flex-direction: column;
      margin-left: 1rem;
      .text {
        color: #cec198;
        font-size: 0.875rem;
        line-height: 1.25rem;
      }
      .number {
        color: #ffffff;
        font-size: 1.25rem;
        line-height: 1.75rem;
      }
    }
  }
  .topPlayersList,
  .characterAttrsList {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    margin-top: 1.5rem;
    padding: 0;
    span {
      color: #b4b0a7;
      font-size: 0.75rem;
      line-height: 1rem;
    }
    span:nth-of-type(2) {
      margin-left: auto;
    }
    li {
      display: flex;
      margin-bottom: 0.5rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid #363636;
    }
    li:first-of-type,
    li:last-of-type {
      padding-bottom: 0;
      border-style: none;
    }
  }
  .topPlayersList {
    .header {
      margin-bottom: 1rem;
      span {
        color: #cec198;
        font-size: 0.875rem;
        line-height: 1.25rem;
      }
    }
  }
  .rankings {
    margin-top: 0.75rem;
    color: #cec198;
    font-size: 0.875rem;
    line-height: 1.25rem;
  }
  .characterAttrsList {
    margin-top: 2.25rem;
    .characterName {
      margin-bottom: 1rem;
      color: #cec198;
      font-size: 1.25rem;
      line-height: 1.75rem;
      font-family: 'Trajan';
    }
  }
}
</style>
