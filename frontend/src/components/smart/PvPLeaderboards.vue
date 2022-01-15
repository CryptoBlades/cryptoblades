<template>
  <div class="leaderboardWrapper">
    <h1 class="leaderboardTitle">ARENA LEADERBOARD</h1>
    <h2>value: {{tierFilter}}</h2>
    <div class="filtersWrapper">
      <div class="selectWrapper">
        <label for="tier">Tier: </label>
        <select @change="handleValue" v-model="tierFilter" name="tier" id="tier">
          <option v-for="tierFilterOption in tierFilterOptions"
           :value="tierFilterOption.value" :key="tierFilterOption.value">
            {{ tierFilterOption.value }}
          </option>
        </select>
      </div>
    </div>
    <div class="listWrapper">
      <ul class="playerList">
        <li>
          <span>Rank</span>
          <span>Name</span>
          <span>Level</span>
          <span>Element</span>
          <span>MMR</span>
        </li>
        <li>
          <span>1</span>
          <span>{{tierTopRankers[0].name}}</span>
          <span>{{tierTopRankers[0].level}}</span>
          <span>{{tierTopRankers[0].element}}</span>
          <span>{{tierTopRankers[0].rank}}</span>
        </li>
        <li>
          <span>2</span>
          <span>{{tierTopRankers[1].name}}</span>
          <span>{{tierTopRankers[1].level}}</span>
          <span>{{tierTopRankers[1].element}}</span>
          <span>{{tierTopRankers[1].rank}}</span>
        </li>
        <li>
          <span>3</span>
          <span>{{tierTopRankers[2].name}}</span>
          <span>{{tierTopRankers[2].level}}</span>
          <span>{{tierTopRankers[2].element}}</span>
          <span>{{tierTopRankers[2].rank}}</span>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import { getCharacterNameFromSeed } from '../../character-name';
import { mapState } from 'vuex';
import { characterFromContract as formatCharacter } from '../../contract-models';
export default {
  inject: ['web3'],
  data() {
    return {
      tierTopRankers: [],
      tier: 0,
      tierFilterOptions: [
        { text: '1', value: 0 },
        { text: '2', value: 2 },
        { text: '3', value: 3 },
        { text: '4', value: 4 },
        { text: '5', value: 5 },
        { text: '6', value: 6 },
        { text: '7', value: 7 },
        { text: '8', value: 8 },
      ],
      tierFilter: 0,
    };
  },
  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds']),
  },
  methods: {
    async handleValue(){
      console.log('runs');
      const tierTopRankersIds
      = await this.contracts().PvpArena.methods.getTierTopCharacters(this.tierFilter).call({ from: this.defaultAccount });
      console.log(tierTopRankersIds);
      this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
        return {
          rankerId,
          name: getCharacterNameFromSeed(rankerId),
          rank: await this.contracts().PvpArena.methods.rankingPointsByCharacter(rankerId).call({ from: this.defaultAccount }),
          level: await this.contracts().Characters.methods.getLevel(rankerId).call({ from: this.defaultAccount }),
          element: formatCharacter(rankerId, await this.contracts().Characters.methods.get(`${rankerId}`)
            .call({ from: this.defaultAccount })).traitName
        };
      }));
    }
  },
  async created(){
    //Leaderboards will be improved, for now they will only show top 3 rankers of each tier
    const tierTopRankersIds
    = await this.contracts().PvpArena.methods.getTierTopCharacters(this.tierFilter).call({ from: this.defaultAccount });
    console.log(tierTopRankersIds);
    this.tierTopRankers = await Promise.all(tierTopRankersIds.map(async (rankerId) => {
      return {
        rankerId,
        name: getCharacterNameFromSeed(rankerId),
        rank: await this.contracts().PvpArena.methods.rankingPointsByCharacter(rankerId).call({ from: this.defaultAccount }),
        level: await this.contracts().Characters.methods.getLevel(rankerId).call({ from: this.defaultAccount }),
        element: formatCharacter(rankerId, await this.contracts().Characters.methods.get(`${rankerId}`)
          .call({ from: this.defaultAccount })).traitName
      };
    }));
  },
  watch: {

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