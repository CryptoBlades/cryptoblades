<template>
  <div>
    <h1 class="title">
      {{$t('pvp.arenaInformation')}}
    </h1>
    <div class="tokenCard">
      <img src="../../assets/skillToken.png" alt="skill token" />
      <div class="tokenCardInfo">
        <span class="text">
          {{$t('pvp.rewardsPool')}}($SKILL)
        </span>
        <span class="number">{{ formatedTierRewardsPool }}</span>
      </div>
    </div>
    <ul class="topPlayersList">
      <li class="header">
        <span>
          {{$t('pvp.topPlayers')}}
        </span>
        <span>
          {{$t('pvp.rankingPoints')}}
        </span>
      </li>
      <li>
        <span>
          {{$t('pvp.rank')}} 1: {{ tierTopRankers[0] && tierTopRankers[0].name || 'N/A' }}
        </span>
        <span>
          {{ tierTopRankers[0] && tierTopRankers[0].rank || 'N/A' }}
        </span>
      </li>
      <li>
        <span>
          {{$t('pvp.rank')}} 2: {{ tierTopRankers[1] && tierTopRankers[1].name || 'N/A' }}
        </span>
        <span>
          {{ tierTopRankers[1] && tierTopRankers[1].rank || 'N/A'}}
        </span>
      </li>
      <li>
        <span>
          {{$t('pvp.rank')}} 3: {{ tierTopRankers[2] && tierTopRankers[2].name || 'N/A' }}
        </span>
        <span>
          {{ tierTopRankers[2] && tierTopRankers[2].rank || 'N/A'}}
        </span>
      </li>
    </ul>
    <ul class="topPlayersList">
      <li class="header">
        <span>
          {{$t('pvp.currentSeason')}}
        </span>
        <span>
          {{$t('pvp.restartsIn')}}
        </span>
      </li>
      <li>
        <span>{{ currentRankedSeason }}</span>
        <vue-countdown :time="secondsBeforeNextSeason * 1000" v-slot="{ days, hours, minutes, seconds }">
          {{ days && days || '' }} {{ days && daysText + ', ' || '' }}{{ hours }}:{{ minutes }}:{{ seconds }}
        </vue-countdown>
      </li>
    </ul>
    <ul class="characterAttrsList">
      <li class="characterName">{{ characterInformation.name || '' }}</li>
      <li>
        <span>
          {{$t('pvp.power')}}
        </span>
        <span>
          {{ characterInformation.power }}
        </span>
      </li>
      <li>
        <span>
          {{$t('pvp.level')}}
        </span>
        <span>
          {{ characterInformation.level}}
        </span>
      </li>
      <li>
        <span>
          {{$t('pvp.currentRank')}}
        </span>
        <span>
          {{ characterInformation.rank }}
        </span>
      </li>
    </ul>
  </div>
</template>

<script>
import BN from 'bignumber.js';
import VueCountdown from '@chenfengyuan/vue-countdown';
import i18n from '../../i18n';

export default {
  components: {
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
  },

  computed: {
    formatedTierRewardsPool() {
      return new BN(this.tierRewardsPool).div(new BN(10).pow(18)).toFixed(3);
    },
    daysText() {
      return i18n.t('pvp.days');
    }
  }
};
</script>

<style lang="scss" scoped>
.title {
  margin-bottom: 1rem;
  color: #cec198;
  font-size: 1.25rem;
  font-family: 'Trajan';
  line-height: 1.75rem;
  padding: 0;
  text-transform: uppercase;
}
.tokenCard {
display: flex;
padding: 1rem 2rem 1rem 1.5rem;
border-radius: 0.375rem;
margin-bottom: 1rem;
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
ul, li, span {
  font-family: 'Roboto';
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
  font-size: 0.9rem;
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
  }
}
}
.characterAttrsList {
margin-top: 2rem;
.characterName {
  margin-bottom: 1rem;
  color: #cec198;
  font-size: 1.25rem;
  font-family: 'Trajan';
}
}
</style>
