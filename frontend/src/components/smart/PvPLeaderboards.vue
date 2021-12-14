<template>
  <div class="leaderboardWrapper">
    Leaderboards coming soon!
    <!-- <h1 class="leaderboardTitle">ARENA LEADERBOARD</h1>
    <div class="filtersWrapper">
      <div class="selectWrapper">
        <label for="tier">Tier: </label>
        <select name="tier" id="tier">
          <option value="1">1</option>
          <option value="2">2</option>
          <option value="3">3</option>
          <option value="4">4</option>
        </select>
      </div>
      <div class="selectWrapper">
        <label for="element">Element: </label>
        <select name="element" id="element">
          <option value="1">Fire</option>
          <option value="2">Earth</option>
          <option value="3">Lightning</option>
          <option value="4">Water</option>
        </select>
      </div>
      <div class="selectWrapper">
        <label for="numberOfListings">Listings per page: </label>
        <select name="numberOfListings" id="numberOfListings">
          <option value="1">10</option>
          <option value="2">20</option>
          <option value="3">30</option>
          <option value="4">40</option>
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
          <span>Earned SKILLs</span>
        </li>
        <li>
          <span>1</span>
          <span>Player 1</span>
          <span>11</span>
          <span>Fire</span>
          <span>4</span>
        </li>
        <li>
          <span>2</span>
          <span>Player 2</span>
          <span>12</span>
          <span>Earth</span>
          <span>3</span>
        </li>
      </ul>
    </div> -->
  </div>
</template>

<script>
export default {
  data() {
    return {
      players: [
        // {
        //   name: 'Player1',
        //   rank: 1,
        //   level: 55,
        //   element: 'fire',
        //   earnedSkill: 21
        // },
        // {
        //   name: 'Player2',
        //   rank: 2,
        //   level: 48,
        //   element: 'fire',
        //   earnedSkill: 20
        // },
        // {
        //   name: 'Player3',
        //   rank: 3,
        //   level: 13,
        //   element: 'earth',
        //   earnedSkill: 19
        // }
      ]
    };
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