<template>
  <div class="leaderboard-summary">
    <div class="ld-heading">
      <h2>S1 Leaderboard</h2>
      <div class="ld-tab">
        <ul>
          <li><div class="icon-frame-sm active"><img src="../assets/new-ui/icon-char-sm.png" alt="character"></div></li>
          <li><div class="icon-frame-sm"><img src="../assets/new-ui/icon-sword.png" alt="character"></div></li>
          <li><div class="icon-frame-sm"><img src="../assets/new-ui/icon-weapon.png" alt="character"></div></li>
        </ul>
      </div>
    </div>
    <div class="ld-table">
      <table>
        <tr>
          <th>Rank</th>
          <th>CHARACTER NAME</th>
          <th>ID</th>
          <th>SKILL EARNINGS</th>
        </tr>
        <tr>
          <td>1</td>
          <td>KhalAmo</td>
          <td>322</td>
          <td>101.1</td>
        </tr>
        <tr>
          <td>2</td>
          <td>Mizuyo</td>
          <td>3221</td>
          <td>90.5</td>
        </tr>
        <tr>
          <td>3</td>
          <td>SkyDragon</td>
          <td>2221</td>
          <td>86.3</td>
        </tr>
        <tr>
          <td>4</td>
          <td>Diego</td>
          <td>5612</td>
          <td>83</td>
        </tr>
      </table>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Leaderboard'
};
</script>

<style scoped>
.leaderboard-summary {
  flex-grow: 1;
  padding-left: 50px;
  max-width: 550px;
  width: 100%;
}
.ld-heading {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.ld-tab ul li{
  display: inline-block;
  list-style-type: none;
  margin-left: 15px;
}
.ld-tab ul li:first-child {
  margin-left: 0;
}

.ld-table table {
  width: 100%;
}
.ld-table table th {
  text-transform: uppercase;
  font-family: Oswald;
  font-size: 16px;
  font-weight: 500;
  border-bottom: 1px solid #535964;
  padding: 0 0 10px;
}
.ld-table table td {
  padding: 5px 0;
  color: #B9BFCC;
  font-size: 16px;
}
</style>
