<template>
  <div class="rewardsWrapper">
    <h1>
      {{$t('pvp.rewardsCaps')}}
    </h1>
    <p>
      {{$t('pvp.clickToClaim')}}
    </p>
    <ul>
      <li>
        <div class="bulletpoint"></div>
        {{$t('pvp.seasonRewardDistribution')}}
      </li>
      <li>
        <div class="bulletpoint"></div>
        {{$t('pvp.rewardsAccumulate')}}
      </li>
      <li>
        <div class="bulletpoint"></div>
        {{$t('pvp.justClickClaim')}}
      </li>
      <li>
        <div class="bulletpoint"></div>
        {{$t('pvp.yourAvailableSkill', formattedAvailableSkill)}}
        $SKILL
      </li>
    </ul>
    <pvp-button :buttonText="i18n.t('claimRewardsCaps')" @click="claimRewards" />
  </div>
</template>


<script>
import BN from 'bignumber.js';
import { mapState } from 'vuex';
import PvPButton from './PvPButton.vue';

export default {
  components: {
    'pvp-button': PvPButton
  },

  data() {
    return {
      loading: true,
      availableSkill: null,
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds']),

    formattedAvailableSkill() {
      return new BN(this.availableSkill).div(new BN(10).pow(18)).toFixed(2);
    },
  },

  methods: {
    async claimRewards() {
      this.loading = true;

      try {
        await this.contracts().PvpArena.methods.withdrawRankedRewards().send({ from: this.defaultAccount });

        this.availableSkill = await this.contracts().PvpArena.methods.getPlayerPrizePoolRewards().call({ from: this.defaultAccount });
      } catch (err) {
        console.log('withdraw rewards error: ', err);
      }

      this.loading = false;
    }
  },

  async created() {
    this.availableSkill = await this.contracts().PvpArena.methods.getPlayerPrizePoolRewards().call({ from: this.defaultAccount });

    this.loading = false;
  }
};
</script>

<style scoped lang="scss">
.rewardsWrapper {
  display: flex;
  flex-direction: column;
  font-family: 'Trajan';

  h1 {
    font-size: 1.25rem;
    font-family: 'Trajan';
    color: #cec198;
    padding-top: 0;
  }

  p, li {
    font-family: 'Roboto';
  }

  p {
    margin-bottom: 2rem;
    color: #b4b0a7;
  }

  ul {
    padding-left: 1rem;
    li {
      display: flex;
      margin-bottom: 0.75rem;
      align-items: center;
      vertical-align: middle;
      color: #b4b0a7;
      font-size: 0.875rem;
      line-height: 1.25rem;
      .bulletpoint {
        height: 0.5rem;
        width: 0.5rem;
        margin-right: 0.75rem;
        background-color: #dabe75;
        transform: rotate(45deg);
      }
    }
  }

  button {
    margin-top: 1rem;
    width: 14rem;
    height: 5rem;
  }
}
</style>