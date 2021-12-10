<template>
  <div class="character-summary">
    <div class="char-info">
      <div class="char-name">{{ characterName }}</div>

      <div class="char-meta">
        <ul>
          <li><img :src="require('@/assets/new-ui/' + characterTypeIcon)" alt="character"> {{ characterType }}</li>
          <li>CP: 30,600</li>
        </ul>
      </div>

      <div class="char-bio">
        <p>The Fire class represents strength. It does double damage to earth element.</p>
      </div>

      <div class="stamina-level">
        <div class="stamina-status">
          <div class="number">
            90
          </div>
          <div class="percentage">
            <label>Stamina</label>
            <div class="char-progress-bar">
              <span class="percent" :style="{'background' : characterColor, 'width' : '90%'}"></span>
            </div>
          </div>
        </div>
        <div class="level-status">
          <div class="number">
            51
          </div>
          <div class="percentage">
            <label>
              <ul>
                <li>Level</li>
                <li>EXP (602/724)</li>
              </ul>
            </label>
            <div class="char-progress-bar">
              <span class="percent" :style="{'background' : characterColor , 'width':'51%'}"></span>
            </div>
          </div>
        </div>
      </div>

      <div class="widget">
        <div class="stats-row">
          <h3>Character Stat</h3>
        </div>
        <div class="stats-row">
          <label>Power</label>
          <span>255</span>
        </div>
        <div class="stats-row">
          <label>Damage Multiplier</label>
          <span>2,320</span>
        </div>
      </div>

      <div class="widget">
        <div class="stats-row">
          <h3>Equipment</h3>
        </div>
        <div class="equipment" v-if="characterID === '1'">
          <ul>
            <li class="active"><img src="../../assets/new-ui/item/weapon5.png" alt="character-default"></li>
            <li><img src="../../assets/new-ui/item/shield-02.png" alt="character-default"></li>
          </ul>
        </div>
        <div class="equipment" v-if="characterID === '2'">
          <ul>
            <li class="active"><img src="../../assets/new-ui/item/weapon2.png" alt="character-default"></li>
            <li><img src="../../assets/new-ui/item/Layer_2.png" alt="character-default"></li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CharacterSummary',
  data() {
    return {
      icon : '#D01111',
    };
  },
  computed : {
    characterID() {
      return this.$route.params.id;
    },
    characterColor() {
      if(this.characterID === '2'){
        return '#24A24B';
      }
      return '#D01111';
    },
    characterTypeIcon() {
      if(this.characterID === '2'){
        return 'icon-earth.png';
      }
      return 'icon-alien-fire.png';
    },
    characterType(){
      if(this.characterID === '2'){
        return 'Earth';
      }
      return 'Fire';
    },
    characterName(){
      if(this.characterID === '2'){
        return 'Zenkai';
      }
      return 'Zhangtsun';
    }
  },
  mounted() {
    if(this.characterID === 2){
      this.color = '#24A24B';
    }
    console.log(this.characterID);
  }
};
</script>

<style scoped>
.stamina-level {
  padding-top: 20px;
}
.stamina-level > div {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
}
.stamina-level .percentage {
  padding-left: 10px;
  flex-grow: 1;
  margin-bottom: 5px;
}
.stamina-level .percentage label {
  color: #CEC198;
  font-size: 13px;
  margin-bottom: 0;
  line-height: 13px;
}
.stamina-level .percentage ul {
  margin: 0;
  padding: 0;
  list-style-type: none;
}
.stamina-level .percentage ul li {
  display: inline-block;
  border-right: 1px solid #7F8693;
  padding-right: 10px;
  margin-right: 10px;
}
.stamina-level .percentage ul li:last-child {
  margin-right: 0;
  padding-right: 0;
  border-right: 0;
}
.stamina-level .number {
  border: 1px solid #707070;
  background: #000E1D;
  font-size: 13px;
  line-height: 17px;
  font-family: Oswald;
  padding: 5px 10px;
  min-width: 40px;
  text-align: center;
}

.character-summary {
  display: flex;
  max-width: 266px;
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
  font-family: Oswald;
  font-weight: 500;
  font-size: 20px;
}
.character-summary .char-meta ul li img {
  width: 19px;
}
.character-summary .char-meta ul li:last-child {
  margin-right: 0;
  padding-right: 0;
  border-right: 0;
}
.character-summary .char-progress-bar {
  height: 5px;
  margin-bottom: 0;
  background: #404857;
}
.character-summary .char-progress-bar .percent {
  width: 35%;
}

.widget {
  padding-top: 20px;
}
.stats-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #404857;
  padding: 10px 0;
}
.widget h3 {
  color: #CEC198;
  font-size: 18px;
  margin-bottom: 0;
}
.widget label {
  display: block;
  color: #fff;
  margin-bottom: 0;
}
.widget span {
  display: block;
  color: #7F8693;
}

.char-bio p {
  color: #7F8693;
  font-size: 16px;
}
.equipment {
  padding-top: 30px;
}
.equipment ul {
  margin: 0;
  padding: 0;
  list-style-type: none;
  display: flex;
  justify-content: space-between;
}
.equipment ul li {
  background: transparent radial-gradient(closest-side at 50% 50%, #1D1D1D 0%, #141414 100%) 0% 0% no-repeat padding-box;
  border-radius: 10px;
  border: 1px solid #D16100;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 45%;
}
.equipment ul li:last-child {
  border-color: #7C1EC1;
}

</style>
