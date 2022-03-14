<template>
  <div class="wrapper">
    <div class="mainWrapper">
      <div class="arenaSignup">
        <h1 class="title">
          {{$t('pvp.arenaSignUp')}}
        </h1>
        <p>
          {{$t('pvp.enterAndWin')}}
          ($SKILL).</p>
        <div class="buttonsWrapper">
          <div class="buttonWrapper">
            <pvp-button
              class="pvpButton"
              @click="handleEnterArenaClick"
              :buttonText="$t('pvp.enterArena')"
            />
          </div>
          <div class="buttonWrapperSecondary">
            <pvp-button
              @click="leaveArena"
              :disabled="loading"
              :buttonText="$t('pvp.leaveArena')"
              secondary
            />
          </div>
        </div>
        <div class="bottomWrapper">
          <div class="bottomWrapperNav">
            <button @click="setTab(0)" :class="tab === 0 && 'active'">
              {{$t('pvp.equipment')}}
            </button>
            <button @click="setTab(1)" :class="tab === 1 && 'active'">
              {{$t('pvp.duelHistory')}}
            </button>
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
                <li>
                  <span>
                    {{$t('pvp.date')}}
                  </span>
                  <span>
                    {{$t('pvp.result')}}
                  </span>
                </li>
                <li v-for="duel in duelHistory" :key="`${duel.attackerId}-${duel.timestamp}`">
                  <span class="date">{{ dayjs(new Date(duel.timestamp * 1000)).format('YYYY/MM/DD') }}</span>
                  <span :class="{'lost': !duel.attackerWon}" class="result">{{ duel.attackerWon ? $t('pvp.win') : $t('pvp.lose') }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
      <div class="characterImage">
        <pvp-character :characterId="currentCharacterId" />
      </div>
      <pvp-arena-information
        class="arenaInformation"
        :tierRewardsPool="tierRewardsPool"
        :tierTopRankers="tierTopRankers"
        :currentRankedSeason="currentRankedSeason"
        :secondsBeforeNextSeason="secondsBeforeNextSeason"
        :characterInformation="characterInformation"
        insideArena
      />
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';
import PvPWeapon from './PvPWeapon.vue';
import PvPShield from './PvPShield.vue';
import PvPButton from './PvPButton.vue';
import PvPCharacter from './PvPCharacter.vue';
import dayjs from 'dayjs';
import PvPArenaInfo from './PvPArenaInfo.vue';
import i18n from '../../i18n';

export default {
  components: {
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield,
    'pvp-button': PvPButton,
    'pvp-character': PvPCharacter,
    'pvp-arena-information': PvPArenaInfo,
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
        fullPower: null,
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
      dayjs,
      loading: false,
      duelQueue: [],
      isCharacterInDuelQueue: false,
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount']),
  },

  methods: {
    ...mapActions([
      'withdrawFromArena',
      'getDuelQueue'
    ]),

    setTab(tabNumber) {
      this.tab = tabNumber;
    },

    handleErrorMessage(value, errorMessage, returnedMessage) {
      if (value.includes(`reverted with reason string '${errorMessage}'`)) {
        return this.$dialog.notify.error(returnedMessage);
      }
      return this.$dialog.notify.error(i18n.t('pvp.genericError'));
    },

    async handleEnterArenaClick() {
      this.$emit('enterMatchMaking');
    },

    async leaveArena() {
      this.loading = true;

      if (this.isCharacterInDuelQueue) {
        alert(i18n.t('pvp.currentlyInDuel'));
        this.loading = false;
        return;
      }

      try {
        await this.withdrawFromArena(this.currentCharacterId);

        this.$emit('leaveArena');
      } catch (err) {
        console.log('leave arena error: ', err.message);

        this.handleErrorMessage(err.message, 'Not in arena', i18n.t('pvp.charNotInArena'));
        this.handleErrorMessage(err.message, 'Defender duel in process', i18n.t('pvp.duelInProcess'));
      } finally {
        this.loading = false;
      }
    },
  },

  async created() {
    this.loading = true;

    try {
      this.duelQueue = await this.getDuelQueue();

      if (this.duelQueue.includes(`${this.currentCharacterId}`)) {
        this.isCharacterInDuelQueue = true;
      }
    } catch (err) {
      console.log('get duel queue error: ', err.message);
      this.handleErrorMessage();
    }

    this.loading = false;
  }
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
  text-transform: uppercase;
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
  .buttonsWrapper {
    display: flex;
    justify-content: center;
    flex-direction: column;
    .buttonWrapper {
      margin-top: 2.25rem;
      height: 5rem;
      width: 80%;

      .pvpButton {
        text-transform: uppercase;
      }
    }
    .buttonWrapperSecondary {
      margin-top: 2rem;
      margin-left: 10%;
      height: 3rem;
      width: 60%;
    }
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
.arenaInformation {
  display: flex;
  flex-direction: column;
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
</style>
