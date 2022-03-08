<template>
  <div class="wrapper">
    <nav>
      <div class="navTitle">
        {{$t('pvp.arena')}}
      </div>
      <div class="navStats">
        <div>
          <span>
            {{$t('pvp.arenaTier')}}
          </span>
          <span>{{ characterInformation.tier || '-' }}</span>
        </div>
        <div>
          <span>
            {{$t('pvp.wagerLeft')}}
          </span>
          <span>{{ formattedWager || '-' }}</span>
        </div>
      </div>
    </nav>
    <a tabindex="0" class="infoPopover" id="duel-popover">
      <span>Battle odds</span>
      <div class="icon">!</div>
    <b-popover ref="popover" target="duel-popover" triggers="hover blur" placement="bottom" custom-class="popoverWrapper">
      <span class="popoverTitle">Battle odds</span>
      <div class="oddsWrapper">
        <p>You have X chance of getting an ultra roll by fighting this character.</p>
        <p>You will earn X amount of ranking points if you beat this character.</p>
        <p class="goodLuck">Good luck!</p>
      </div>
    </b-popover>
    </a>
    <div class="bottom">
      <div class="characterWrapper">
        <div class="elementWrapper">
          <img :src="getCharacterElementSrc" alt="element" />
        </div>
        <div class="characterImageWrapper">
          <pvp-character :characterId="currentCharacterId" />
        </div>
        <div v-if="characterInformation" class="info">
          <h1 class="characterName">{{ characterInformation.name }}</h1>
          <div class="infoDetails">
            <span>
              {{$t('pvp.level')}}: {{ characterInformation.level }}
            </span>
            <pvp-separator vertical class="separator" />
            <span>
              {{$t('pvp.rankingPoints')}}: {{ characterInformation.rank }}
            </span>
          </div>
        </div>
        <div class="weapons" >
          <pvp-weapon
            v-if="activeWeaponWithInformation.weaponId"
            :weapon="activeWeaponWithInformation.information"
            :weaponId="activeWeaponWithInformation.weaponId"
            :hasInfoPopover="false"
          />
          <pvp-shield
            v-if="activeShieldWithInformation.shieldId"
            :shield="activeShieldWithInformation.information"
            :shieldId="activeShieldWithInformation.shieldId"
            :hasInfoPopover="false"
            class="shield"
          />
        </div>
      </div>
      <div class="middleButtons">
        <div class="middleButtonsStatus">
          <div v-if="this.loading || isCharacterInDuelQueue">
            <img class="spinner" src="../../assets/loadingSpinner.svg" />
          </div>
          <p v-if="isInMatch && !isCharacterInDuelQueue && !this.loading && this.decisionTimeLeft">
            <span>
              {{$t('pvp.youHave')}}
            </span>
            <span>
              {{this.decisionTimeLeft}}
            </span>
            <span>
              {{$t('pvp.toAcceptDuel')}}
            </span>
          </p>
          <span v-else-if="this.decisionTimeLeft === 0 && !this.loading && isCharacterInDuelQueue">
            {{$t('pvp.duelHasExpired')}}
          </span>
        </div>
        <div class="middleMatchProgressButtons">
          <pvp-button class="pvpButton" v-if="isCharacterInDuelQueue" :buttonText="$t('pvp.inProgress')" :disabled="true"/>
          <div v-else class="matchButtonsWrapper">
            <div v-if="!isInMatch">
              <pvp-button class="pvpButton" @click="findMatch" :disabled="loading || formattedMatchablePlayersCount < 1"  :buttonText="$t('pvp.findMatch')" />
              <div class="matchablePlayersCountText">Players in this tier: {{formattedMatchablePlayersCount}}</div>
            </div>
            <pvp-button v-else class="pvpButton" @click="prepareCharacterDuel"
              :disabled="loading || !decisionTimeLeft || isCharacterInDuelQueue" :duelButton="true" :buttonText="$t('pvp.duel')" />
          </div>
        </div>
        <div class="rerollButtonWrapper">
          <pvp-button
            @click="reRollCharacterOpponent" :disabled="loading || !isInMatch || isCharacterInDuelQueue"
            :buttonText="$t('pvp.reRoll')"
            :buttonsubText="!hasSpecialWeapon || !freeRerollReady ? '$SKILL: ' + formattedReRollCost : $t('pvp.free')"
            :secondary="true"
            v-tooltip="hasSpecialWeapon && !freeRerollReady ? `${$t('pvp.freeRerollIn')} ${freeRerollLocalTimestamp}` : ''"
          />
        </div>
        <div class="leaveArenaButtonWrapper">
          <pvp-button
            @click="leaveArena"
            :disabled="loading || isCharacterInDuelQueue"
            :buttonText="$t('pvp.leaveArena')"
            :secondary="true"
          />
        </div>
      </div>
      <div class="characterWrapper">
        <div class="elementWrapper">
          <img v-if="opponentInformation.id" :src="getOpponentElementSrc" alt="opponent element" />
        </div>
        <div v-if="opponentInformation.id" class="characterImageWrapper">
          <pvp-character :characterId="opponentInformation.id" />
        </div>
        <div v-if="opponentInformation.id" class="info">
          <h1 class="characterName">{{ opponentInformation.name }}</h1>
          <div class="infoDetails">
            <span>
              {{$t('pvp.level')}}: {{ opponentInformation.level}}</span>
            <pvp-separator vertical class="separator" />
            <span>
              {{$t('pvp.rankingPoints')}}: {{ opponentInformation.rank }}</span>
          </div>
        </div>
        <div v-else class="findMatchMessage">
          {{$t('pvp.pressFindMatch')}}
        </div>
        <div class="weapons">
          <pvp-weapon
            v-if="opponentActiveWeaponWithInformation.weaponId"
            :weapon="opponentActiveWeaponWithInformation.information"
            :weaponId="opponentActiveWeaponWithInformation.weaponId"
            :hasInfoPopover="false"
          />
          <pvp-shield
            v-if="opponentActiveShieldWithInformation.shieldId"
            :shield="opponentActiveShieldWithInformation.information"
            :shieldId="opponentActiveShieldWithInformation.shieldId"
            :hasInfoPopover="false"
            class="shield"
          />
        </div>
      </div>
    </div>
    <!-- TODO: Get rank variation from contract -->
    <pvp-duel-modal
      v-if="duelResult.result"
      :result="duelResult.result"
      :attackerRoll="duelResult.attackerRoll"
      :attackerPower="duelResult.attackerPower"
      :defenderPower="duelResult.defenderPower"
      :defenderRoll="duelResult.defenderRoll"
      :skillEarned="duelResult.skillDifference"
      :rankVariation="duelResult.result === 'win' ? '+5' : '-3'"
      :userCurrentRank="duelResult.rankDifference"
      @close-modal="handleCloseModal"
    />
    <pvp-under-attack-modal
      v-if="this.isUnderAttack"
      :isUnderAttack="isUnderAttack"
      @close-modal="handleCloseAttackModal"
    />
  </div>
</template>

<script>
import BN from 'bignumber.js';
import { mapState, mapActions } from 'vuex';
import PvPWeapon from './PvPWeapon.vue';
import PvPShield from './PvPShield.vue';
import PvPSeparator from './PvPSeparator.vue';
import PvPCharacter from './PvPCharacter.vue';
import PvPButton from './PvPButton.vue';
import fireIcon from '../../assets/elements/fire.png';
import waterIcon from '../../assets/elements/water.png';
import earthIcon from '../../assets/elements/earth.png';
import lightningIcon from '../../assets/elements/lightning.png';
import PvPDuelModal from './PvPDuelModal.vue';
import PvPUnderAttackModal from './PvPUnderAttackModal.vue';
import { duelResultFromContract as formatDuelResult } from '../../contract-models';
import i18n from '../../i18n';

export default {
  inject: ['web3'],

  components: {
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield,
    'pvp-character': PvPCharacter,
    'pvp-separator': PvPSeparator,
    'pvp-button': PvPButton,
    'pvp-duel-modal': PvPDuelModal,
    'pvp-under-attack-modal': PvPUnderAttackModal
  },

  props: {
    characterInformation: {
      default: {
        tier: null,
        name: '',
        level: null,
        power: null,
        fullPower: null,
        rank: null,
        element: null
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
    opponentInformation: {
      default: {
        if: null,
        element: '',
        name: '',
        level: null,
        rank: null,
        power: null,
        fullPower: null,
      }
    },
    opponentActiveWeaponWithInformation: {
      default: {
        weaponId: null,
        information: {}
      }
    },
    opponentActiveShieldWithInformation: {
      default: {
        shieldId: null,
        information: {}
      }
    },
  },

  data() {
    return {
      loading: true,
      isInMatch: false,
      isUnderAttack: false,
      decisionTimeLeft: 0,
      wager: null,
      duelCost: null,
      reRollCost: null,
      match: {
        attackerID: null,
        defenderID: null,
        createdAt: null,
      },
      duelQueue: [],
      isCharacterInDuelQueue: false,
      duelResult: {
        attackerRoll: null,
        defenderRoll: null,
        skillDifference: null,
        rankDifference: null,
        result: '',
        attackerPower: null,
        defenderPower: null
      },
      matchablePlayersCount: null,
      duelOffsetCost: null,
      specialWeaponFreeRerollTimestamp: null
    };
  },

  computed: {
    ...mapState(['contracts', 'currentCharacterId', 'defaultAccount']),

    formattedWager() {
      return new BN(this.wager).div(new BN(10).pow(18)).toFixed(2);
    },

    formattedDuelCost() {
      return new BN(this.duelCost).div(new BN(10).pow(18)).toFixed(2);
    },

    formattedReRollCost() {
      return new BN(this.reRollCost).div(new BN(10).pow(18)).toFixed(2);
    },
    formattedMatchablePlayersCount(){
      // TODO subtract from this number the player's other characters that are locked in the arena
      const formattedMatchablePlayersCount = this.matchablePlayersCount - 1;
      if (formattedMatchablePlayersCount < 0) {
        return 0;
      }
      return formattedMatchablePlayersCount;
    },

    getCharacterElementSrc() {
      if (this.characterInformation.element === 'Fire') {
        return fireIcon;
      }
      if (this.characterInformation.element === 'Water') {
        return waterIcon;
      }
      if (this.characterInformation.element === 'Earth') {
        return earthIcon;
      }
      return lightningIcon;
    },

    getOpponentElementSrc() {
      if (this.opponentInformation.element === 'Fire') {
        return fireIcon;
      }
      if (this.opponentInformation.element === 'Water') {
        return waterIcon;
      }
      if (this.opponentInformation.element === 'Earth') {
        return earthIcon;
      }
      return lightningIcon;
    },

    freeRerollReady() {
      if(!this.hasSpecialWeapon) return false;
      return +this.specialWeaponFreeRerollTimestamp <= Date.now()/1000;
    },

    hasSpecialWeapon() {
      return +this.activeWeaponWithInformation.information.weaponType >= 1;
    },

    freeRerollLocalTimestamp() {
      return new Date(this.specialWeaponFreeRerollTimestamp * 1000).toLocaleString();
    }
  },

  methods: {
    ...mapActions([
      'withdrawFromArena',
      'getIsCharacterUnderAttack',
      'findOpponent',
      'getMatchByFinder',
      'approve',
      'reRollOpponent',
      'prepareDuel',
      'getDuelQueue',
      'getMatchablePlayerCount',
      'getDecisionSeconds',
      'getDuelCost',
      'getReRollFeePercent',
      'approvePvpSkillSpending',
      'getPvpContract',
      'getFighterByCharacter',
      'getDuelOffsetCost',
      'fetchFreeOpponentRerollTimestamp'
    ]),

    handleErrorMessage(value, errorMessage, returnedMessage) {
      if (value.includes(`reverted with reason string '${errorMessage}'`)) {
        return this.$dialog.notify.error(returnedMessage);
      }
      return this.$dialog.notify.error(i18n.t('pvp.genericError'));
    },

    async leaveArena() {
      this.loading = true;

      try {
        await this.withdrawFromArena(this.currentCharacterId);

        this.$emit('leaveArena');
      } catch (err) {
        console.log('leave arena error: ', err.message);

        this.handleErrorMessage(err.message, 'Not in arena', i18n.t('pvp.charNotInArena'));
        this.handleErrorMessage(err.message, 'Defender duel in process', i18n.t('pvp.duelInProcess'));
      }

      this.loading = false;
    },

    async findMatch() {
      if ((await this.getIsCharacterUnderAttack(this.currentCharacterId))) {
        this.isUnderAttack = true;
        return;
      }

      this.loading = true;

      try {
        await this.findOpponent(this.currentCharacterId);
      } catch (err) {
        console.log('find match error: ', err.message);

        this.handleErrorMessage(err.message, 'No enemy found', i18n.t('pvp.noEnemyFound'));
        this.handleErrorMessage(err.message, 'Already in match', i18n.t('pvp.alreadyInMatch'));
        this.handleErrorMessage(err.message, 'No enemy in tier', i18n.t('pvp.noEnemyInTier'));
        this.handleErrorMessage(err.message, 'Char dueling', i18n.t('pvp.charDueling'));
        this.handleErrorMessage(err.message, 'Not in arena', i18n.t('pvp.charNotInArena'));

        this.loading = false;
        return;
      }

      this.match = await this.getMatchByFinder(this.currentCharacterId);

      this.loading = false;
    },

    async reRollCharacterOpponent() {
      if ((await this.getIsCharacterUnderAttack(this.currentCharacterId))) {
        this.isUnderAttack = true;
        return;
      }

      this.loading = true;

      try {
        if(!this.freeRerollReady) {
          await this.approvePvpSkillSpending(this.reRollCost.toFixed(0));
        }

        await this.reRollOpponent(this.currentCharacterId);
      } catch (err) {
        console.log('reroll opponent error: ', err.message);

        this.handleErrorMessage(err.message, 'No enemy found', i18n.t('pvp.noEnemyFound'));
        this.handleErrorMessage(err.message, 'Not in match', i18n.t('pvp.notInMatch'));
        this.handleErrorMessage(err.message, 'No enemy in tier', i18n.t('pvp.noEnemyInTier'));
        this.handleErrorMessage(err.message, 'Char dueling', i18n.t('pvp.charDueling'));

        this.loading = false;

        return;
      }

      this.match = await this.getMatchByFinder(this.currentCharacterId);

      this.loading = false;
    },

    async listenForDuel(pvpContract) {
      const currentBlock = await this.web3.eth.getBlockNumber();

      const subscription = this.web3.eth.subscribe('newBlockHeaders', async () => {
        const duelFinishedResult = await pvpContract.getPastEvents('DuelFinished', {
          filter: { attacker: this.currentCharacterId },
          toBlock: 'latest',
          fromBlock: currentBlock
        });

        if (duelFinishedResult.length) {
          const formattedResult = formatDuelResult(duelFinishedResult[duelFinishedResult.length - 1].returnValues);
          this.duelResult.defenderPower = this.opponentInformation.fullPower;
          this.duelResult.attackerPower = this.characterInformation.fullPower;
          this.duelResult.result = formattedResult.attackerWon ? 'win' : 'lose';
          this.duelResult.attackerRoll = formattedResult.attackerRoll;
          this.duelResult.defenderRoll = formattedResult.defenderRoll;
          this.duelResult.skillDifference = formattedResult.attackerWon ?
            +this.formattedDuelCost * 0.7 :
            this.formattedDuelCost;
          // TODO: Make this prettier
          this.duelResult.rankDifference = formattedResult.attackerWon ?
            +this.characterInformation.rank + 5 :
            +this.characterInformation.rank - 3 <= 0 ?
              0 :
              +this.characterInformation.rank - 3;

          subscription.unsubscribe((error, result) => {
            if (!error) {
              console.log(result);
            } else {
              console.log(error);
            }
          });
        }
      });
    },

    async prepareCharacterDuel() {
      this.loading = true;
      try {
        await this.listenForDuel(await this.getPvpContract());

        await this.prepareDuel({characterId: this.currentCharacterId, duelOffsetCost: this.duelOffsetCost});
      } catch (err) {
        console.log('prepare perform duel error: ', err.message);

        this.handleErrorMessage(err.message, 'Decision time expired', i18n.t('pvp.decisionTimeExpired'));
        this.handleErrorMessage(err.message, 'In queue', i18n.t('pvp.charDueling'));
        this.handleErrorMessage(err.message, 'Not in match', i18n.t('pvp.notInMatch'));

        this.loading = false;

        return;
      }

      this.duelQueue = await this.getDuelQueue();

      this.isCharacterInDuelQueue = true;

      this.loading = false;
    },

    clearDuelResult() {
      this.duelResult = {
        attackerRoll: null,
        defenderRoll: null,
        skillDifference: null,
        rankDifference: null,
        result: '',
        attackerPower: null,
        defenderPower: null
      };
    },

    async handleCloseModal() {
      this.clearDuelResult();
      this.decisionTimeLeft = 0;

      this.isInMatch = false;

      this.match = {
        attackerID: null,
        defenderID: null,
        createdAt: null,
      };

      this.isCharacterInDuelQueue = false;

      this.wager = (await this.getFighterByCharacter(this.currentCharacterId)).wager;

      if (this.wager < this.duelCost) {
        this.$emit('kickCharacterFromArena');
      }

      this.$emit('updateRank');
    },

    handleCloseAttackModal() {
      this.isUnderAttack = false;
    }
  },

  async created() {
    this.loading = true;

    this.isInMatch = (await this.getMatchByFinder(this.currentCharacterId)).createdAt !== '0';

    this.duelQueue = await this.getDuelQueue();

    this.matchablePlayersCount = await this.getMatchablePlayerCount(this.currentCharacterId);

    if (this.duelQueue.includes(`${this.currentCharacterId}`)) {
      this.isCharacterInDuelQueue = true;

      await this.listenForDuel(await this.getPvpContract());
    }

    this.decisionSeconds = await this.getDecisionSeconds();

    this.wager = (await this.getFighterByCharacter(this.currentCharacterId)).wager;

    this.duelCost = await this.getDuelCost(this.currentCharacterId);

    this.reRollCost = this.duelCost * ((await this.getReRollFeePercent()) / 100);

    if (this.isInMatch) {
      const timeNow = Math.floor((new Date()).getTime() / 1000);

      this.match = await this.getMatchByFinder(this.currentCharacterId);

      this.decisionTimeLeft = (this.decisionSeconds - (timeNow - this.match.createdAt), 0);

      // Note: This gives a 400+ seconds decisionTimeLeft locally. It's okay on Testnet.
      this.timer = setInterval(() => {
        if (this.isInMatch && !this.isCharacterInDuelQueue) {
          const timeNow = Math.floor((new Date()).getTime() / 1000);

          this.decisionTimeLeft = Math.max(this.decisionSeconds - (timeNow - this.match.createdAt), 0);
        }
      }, 1000);
    } else {
      this.match = {
        attackerID: null,
        defenderID: null,
        createdAt: null,
      };

      this.decisionTimeLeft = 0;
    }

    this.duelQueue = await this.getDuelQueue();

    this.duelOffsetCost = await this.getDuelOffsetCost();

    this.specialWeaponFreeRerollTimestamp = await this.fetchFreeOpponentRerollTimestamp(this.activeWeaponWithInformation.weaponId);

    this.loading = false;
  },

  beforeDestroy() {
    if(this.timer) {
      clearInterval(this.timer);
    }
  },

  watch: {
    async match(value) {
      this.loading = true;

      if (value.defenderID) {
        this.$emit('updateOpponentInformation', value.defenderID);

        this.isInMatch = true;

        const timeNow = Math.floor((new Date()).getTime() / 1000);

        this.decisionTimeLeft = (this.decisionSeconds - (timeNow - this.match.createdAt), 0);

        // Note: This gives a 400 seconds decisionTimeLeft locally. Test if it's ok on testnet.
        this.timer = setInterval(() => {
          if (this.isInMatch && !this.isCharacterInDuelQueue) {
            const timeNow = Math.floor((new Date()).getTime() / 1000);

            this.decisionTimeLeft = Math.max(this.decisionSeconds - (timeNow - this.match.createdAt), 0);
          }
        }, 1000);
      } else {
        this.$emit('clearOpponentInformation');
      }
      this.loading = false;
    },
  }
};
</script>

<style scoped lang="scss">
.wrapper {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  margin-top: 1rem;
}
span, p, li, button {
  font-family: 'Roboto';
}
.infoPopover {
  display: flex;
  margin: 0 auto;
  margin-bottom: 2rem;
  align-items: center;
  vertical-align: middle;
  place-content: center;
  font-size: .85rem;
  &:hover {
    cursor: pointer;
    text-shadow: none;
  }
  span {
    font-family: 'Trajan';
  }
  .icon {
    display: flex;
    height: 1.25rem;
    width: 1.25rem;
    margin-left: 0.25rem;
    align-items: center;
    vertical-align: middle;
    place-content: center;
    border-radius: 9999px;
    background: #cec198;
    color: black;
    font-weight: 700;
  }
}
.popoverWrapper, .permanent {
  padding: 1rem 1rem 0.5rem 1rem;
  border: 1px solid #cec198;
  box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  background-color: #141414;
  .popoverTitle {
    font-family: 'Trajan';
    color: #cec198;
  }
  .oddsWrapper {
    display: flex;
    flex-direction: column;
    margin-top: 1rem;
  }
  p {
    color: #b4b0a7;
    font-size: .8rem;
  }
  p:last-of-type {
    margin-bottom: .5rem;
    color: #cec198;
    font-size: .9rem;
    font-family: 'Trajan';
  }
  .goodLuck {
    margin: 0 auto;
  }
}
  nav {
    display: flex;
    width: 100%;
    justify-content: space-between;
    margin-bottom: 2rem;
    padding-bottom: 0.5rem;
    border-bottom: 1px solid #363636;
    .navTitle {
      color: #cec198;
      font-size: 1.25rem;
      font-family: 'Trajan';
    }
    .navStats {
      display: flex;
      div:nth-of-type(2) {
        margin-left: 1.25rem;
        margin-right: 1.25rem;
      }
      div {
        display: flex;
        align-items: flex-end;
        font-size: 0.875rem;
        line-height: 1.25rem;
        span:first-of-type {
          margin-right: 0.25rem;
          color: #cec198;
        }
        span:last-of-type {
          color: #ffffff;
        }
      }
    }
  }
.bottom {
  display: flex;
  flex-direction: row;
  width: 100%;
  justify-content: center;
  .elementWrapper {
    position: absolute;
    display: flex;
    height: 2.5rem;
    width: 2.5rem;
    top: -5.35%;
    left: 0;
    right: 0;
    padding: 0.4rem;
    transform: rotate(45deg);
    border: 1px solid #edcd90;
    margin-right: auto;
    margin-left: auto;
    background-color: #000000;
    img {
      transform: rotate(-45deg);
    }
  }
}
.characterWrapper,
.middleButtons {
  display: flex;
  height: 25rem;
  justify-content: flex-end;
  align-items: center;

  .pvpButton {
    text-transform: uppercase;
  }
}
.characterWrapper {
  position: relative;
  flex-direction: column;
  width: 35%;
  background-color: #000;
  border: 1px solid #cec198;
  @media screen and (min-width: 1240px) {
    width: 30%;
  }
  @media screen and (min-width: 1440px) {
    width: 25%;
  }
  @media screen and (min-width: 1680px) {
    width: 20%;
  }
  @media screen and (min-width: 2560px) {
    width: 15%;
  }
  .findMatchMessage {
    display: flex;
    width: 75%;
    margin: auto;
    color: gray;
    font-family: 'Trajan';
    font-weight: 200;
    text-align: center;
    span {
      color: #EDCD90;
      font-family: 'Trajan';
    }
  }
  .characterImageWrapper {
    display: flex;
    margin-right: auto;
    margin-left: auto;
    width: 55%;
    height: 55%;
    margin-bottom: 7rem;
  }
  .info {
    position: absolute;
    bottom: 0;
    display: flex;
    width: 100%;
    flex-direction: column;
    align-items: center;
    color: #ffffff;
    margin-bottom: 2.5rem;
    .characterName {
      margin-bottom: 0.3rem;
      color: #EDCD90;
      font-size: 1.25rem;
      line-height: 1.75rem;
      font-family: 'Trajan';
    }
    .infoDetails {
      height: 1.25rem;
      display: flex;
      align-items: center;
      vertical-align: middle;
      font-size: 0.875rem;
      line-height: 1.25rem;
      .separator {
        margin-right: 1.25rem;
        margin-left: 1.25rem;
      }
    }
  }
  .weapons {
    position: absolute;
    bottom: -12%;
    display: flex;
    left: 0;
    justify-content: center;
    right: 0;
    margin-right: auto;
    margin-left: auto;
    .shield {
      margin-left: 1rem;
    }
  }
}
.middleButtons {
  flex-direction: column;
  margin: 0 3rem;
  width: 13rem;
  .spinner {
    animation: spin 1s linear infinite;
    @keyframes spin {
      from {
        transform: rotate(0deg);
      }
      to {
        transform: rotate(360deg);
      }
    }
  }
  .middleButtonsStatus {
    width: 100%;
    display: flex;
    height: 7rem;
    flex-direction: column;
    justify-content: center;
    vertical-align: middle;
    align-items: center;
    text-align: center;
    margin-bottom: 1rem;

    p {
      display: flex;
      flex-direction: column;
    }
    span:first-of-type, span:last-of-type {
      font-size: .75rem;
      color: #cec198;
    }
    span:nth-of-type(2) {
      font-size: 2.25rem;
      color: white;
      margin: 0;
    }
  }
  .middleMatchProgressButtons {
    width: 100%;
    button {
      height: 5.5rem;
      height: 100%;
    }
  }
  .matchButtonsWrapper {
    width: 100%;

    button {
      height: 5.5rem;
    }
  }
  .matchablePlayersCountText{
    display: flex;
    justify-content: center;
    color: #cec198;
    font-size: 0.75rem;
    margin-top: 1rem;
    font-family: 'Roboto';
  }
  .rerollButtonWrapper {
    width: 100%;
    height: 5rem;
    margin: 1.5rem 0;
  }
  .leaveArenaButtonWrapper {
    width: 100%;
  }
  @media screen and (min-width: 1280px) {
    margin: 0 5rem;
  }
}
</style>
