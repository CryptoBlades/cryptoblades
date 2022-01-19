<template>
  <div class="leaderboardWrapper">
    <h1 class="leaderboardTitle">{{$t("pvp.leaderboard").toUpperCase()}}</h1>
    <div class="filtersWrapper">
      <div class="selectWrapper">
        <label for="tier">Tier: </label>
        <select v-model="tierFilter" name="tier" id="tier">
          <option v-for="tierFilterOption in tierFilterOptions"
           :value="tierFilterOption.value" :key="tierFilterOption.value">
            {{ tierFilterOption.text }}
          </option>
        </select>
      </div>
    </div>
    <div class="listWrapper">
      <ul class="playerList">
        <li>
          <span>{{$t('pvp.rank')}}</span>
          <span>{{$t('pvp.name')}}</span>
          <span>{{$t('pvp.level')}}</span>
          <span>{{$t('characterList.element')}}</span>
          <span>{{$t('pvp.rankingPoints')}}</span>
        </li>
        <li>
          <span>1</span>
          <span>{{tierTopRankers[0] && tierTopRankers[0].name ||'-'}}</span>
          <span>{{tierTopRankers[0] && tierTopRankers[0].level ||'-'}}</span>
          <span>{{tierTopRankers[0] && tierTopRankers[0].element||'-'}}</span>
          <span>{{tierTopRankers[0] && tierTopRankers[0].rank|| '-'}}</span>
        </li>
        <li>
          <span>2</span>
          <span>{{tierTopRankers[1] && tierTopRankers[1].name ||'-'}}</span>
          <span>{{tierTopRankers[1] && tierTopRankers[1].level ||'-'}}</span>
          <span>{{tierTopRankers[1] && tierTopRankers[1].element ||'-'}}</span>
          <span>{{tierTopRankers[1] && tierTopRankers[1].rank ||'-'}}</span>
        </li>
        <li>
          <span>3</span>
          <span>{{tierTopRankers[2] && tierTopRankers[2].name ||'-'}}</span>
          <span>{{tierTopRankers[2] && tierTopRankers[2].level ||'-'}}</span>
          <span>{{tierTopRankers[2] && tierTopRankers[2].element ||'-'}}</span>
          <span>{{tierTopRankers[2] && tierTopRankers[2].rank ||'-'}}</span>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import { getCharacterNameFromSeed } from '../../character-name';
import { characterFromContract as formatCharacter } from '../../contract-models';
import { mapState, mapActions } from 'vuex';
export default {
  inject: ['web3'],
  data() {
    return {
      tierTopRankers: [],
      tierFilterOptions: [
        { text: '1', value: 0 },
        { text: '2', value: 1 },
        { text: '3', value: 2 },
        { text: '4', value: 3 },
        { text: '5', value: 4 },
        { text: '6', value: 5 },
        { text: '7', value: 6 },
        { text: '8', value: 7 },
        { text: '9', value: 8 },
        { text: '10', value: 9 },
      ],
      tierFilter: 0,
    };
  },
  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds']),
  },
  methods: {
    ...mapActions([
      'getCharacter',
      'getCharacterLevel',
      'getRankingPointsByCharacter',
      'getTierTopCharacters',
    ]),
    async getPlayers(){
      const tierTopRankersIds
      = await this.getTierTopCharacters(this.tierFilter);
      this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
        return {
          rankerId,
          name: getCharacterNameFromSeed(rankerId),
          level: await this.getCharacterLevel(rankerId),
          rank: await this.getRankingPointsByCharacter(rankerId),
          element: formatCharacter(rankerId, await this.getCharacter(rankerId)).traitName
        };
      }));
    }
  },
  async created(){
    //TODO: Leaderboards will be improved, for now they will only show top 3 rankers of each tier
    this.getPlayers();
  },
  watch: {
    async tierFilter() {
      this.getPlayers();
    }
  }
};
</script>

<style scoped lang="scss">
.leaderboardWrapper {
  display: flex;
  flex-direction: column;
  width: 100%;
  label, select, option, ul, li, span {
    font-family: 'Roboto';
  }
  .leaderboardTitle {
    margin-bottom: 1rem;
    padding: 0;
    color: #cec198;
    font-size: 1.25rem;
    font-family: 'Trajan';
    line-height: 1.75rem;
  }
  .filtersWrapper {
    display: flex;
    height: 2.5rem;
    flex-direction: row;
    color: #B4B0A7;
    .selectWrapper {
      display: flex;
      position: relative;
      width: 200px;
      align-items: center;
      vertical-align: middle;
      border-radius: 0.25rem;
      margin-right: 1rem;
      padding-right: 10px;
      background-color: #2C2C2C;
      label {
        position: absolute;
        z-index: 30;
        margin-left: 0.5rem;
        top: 50%;
        transform: translateY(-50%);
      }
      select {
        position: absolute;
        top: 0;
        left: 0;
        z-index: 30;
        display: flex;
        width: 100%;
        height: 2.5rem;
        border: none;
        color:#B4B0A7;
        background-color: transparent;
        appearance: none;
        outline: none;
      }
    }
    .selectWrapper::after {
      content: "▼";
      font-size: 0.4rem;
      right: 0.5rem;
      position: absolute;
    }
    .selectWrapper:first-of-type {
      select {
        padding-left: 2.75rem;
      }
    }
    .selectWrapper:nth-of-type(2) {
      select {
        padding-left: 4.75rem;
      }
    }
    .selectWrapper:last-of-type {
      select {
        padding-left: 8.75rem;
      }
    }
  }
  .listWrapper {
    width: 100%;
    margin-top: 2rem;
    .playerList {
      margin: 0;
      padding: 0;
      list-style-type: none;
      justify-content: space-between;
      li {
        display: flex;
        width: 100%;
        padding: 0.5rem 0;
        border-bottom: 1px solid #404857;
        font-size: 0.9rem;
        span {
          display: flex;
          flex: 1;
        }
      }
      li:first-of-type {
        color: #CEC198;
        font-size: 1rem;
      }
      li:not(first-of-type) {
        color: #B4B0A7;
      }
    }
  }
}
</style>