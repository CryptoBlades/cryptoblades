<template>
  <div class="character-summary">
    <div class="char-info">
      <div class="icon-frame-sm"><img src="../assets/new-ui/icon-alien-fire.png" alt="character"></div>
      <div class="char-name">Zhangtsun</div>
      <div class="char-meta">
        <ul>
          <li>FIRE</li>
          <li>LEVEL 51</li>
          <li>120/200 STAMINA</li>
        </ul>
      </div>
      <div class="char-progress-bar"><span class="percent"></span></div>
      <div class="char-stats">
        <div class="wins">
          <label>PVP WINS</label>
          <span>255</span>
        </div>
        <div class="rank">
          <label>PVP Rank</label>
          <span>2,320</span>
        </div>
        <div class="power">
          <label>Power</label>
          <span>5,320</span>
        </div>
      </div>
    </div>
    <div class="char-img">
      <img src="../assets/new-ui/character/char-default.png" alt="character-default">
    </div>
  </div>
</template>

<script>
export default {
  name: 'CharacterSummary'
};
</script>

<style scoped>
.character-summary {
  display: flex;
}
.character-summary .char-info {
  padding-top: 20px;
  margin-right: 20px;
}
.character-summary .char-name {
  font-family: 'Trajan';
  color: #EDCD90;
  font-size: 30px;
  font-weight: bold;
}
.character-summary .char-meta {
  margin-bottom: 23px;
}
.character-summary .char-meta ul {
  list-style-type: none;
  margin: 0;
  padding: 0;
}
.character-summary .char-meta ul li {
  display: inline-block;
  border-right: 1px solid #7F8693;
  padding-right: 15px;
  margin-right: 15px;
  line-height: 14px;
}
.character-summary .char-meta ul li:last-child {
  margin-right: 0;
  padding-right: 0;
  border-right: 0;
}
.character-summary .char-progress-bar {
  height: 5px;
}
.character-summary .char-progress-bar .percent {
  width: 35%;
}

.char-stats {
  display: flex;
  justify-content: space-between;
}
.char-stats label {
  display: block;
  color: #CEC198;
  font-size: 14px;
  text-transform: uppercase;
  margin-bottom: 0;
}
.char-stats span {
  display: block;
  font-family: 'Oswald';
  font-size: 40px;
  line-height: 55px;
  font-weight: 500;
}
</style>
