<template>
  <div class="character-skin">

    <div class="widget">
      <h2>Character Skin</h2>
      <p>Customize your character appearance with skin.</p>
      <div class="available-skin-wrap">
        <div class="available-skin">
          <ul>
            <li><img src="../../assets/new-ui/icon-lock.png" alt="default"></li>
            <li><img src="../../assets/new-ui/icon-lock.png" alt="default"></li>
          </ul>
        </div>
        <div class="skin-nav">
          <ul>
            <li><img src="../../assets/new-ui/icon-arrow-prev.png" alt="default"></li>
            <li><img src="../../assets/new-ui/icon-arrow-next.png" alt="default"></li>
          </ul>
        </div>
      </div>
    </div>

    <div class="widget">
      <div class="ranking-row">
        <h3>Rankings</h3>
      </div>
      <div class="ranking-row">
        <label>Character Power</label>
        <span>130,255</span>
      </div>
      <div class="ranking-row">
        <label>PVP</label>
        <span>2,320</span>
      </div>
      <div class="ranking-row">
        <label>Raid</label>
        <span>23</span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CharacterSummary',
  data() {
    return {
      characterID : this.$route.params.id
    };
  },
};
</script>

<style scoped>
ul {
  margin: 0;
  padding: 0;
  list-style-type: none;
  display: flex;
  gap: 20px;
  justify-content: center;
}
li {

}

.character-skin {
  padding-top: 20px;
  max-width: 266px;
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
.widget h2 {
  font-family: Oswald;
  font-size: 18px;
  text-transform: uppercase;
  color: #fff;
}
.widget h3 {
  color: #CEC198;
  font-size: 18px;
  margin-bottom: 0;
}
.widget p {
  color: #7F8693;
  font-size: 16px;
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
.widget .ranking-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #404857;
  padding: 10px 0;
}
.available-skin {
  padding-top: 20px;
  padding-bottom: 20px;
}
.available-skin ul {
  padding: 0;
  justify-content: space-between;
}
.available-skin ul li {
  flex-grow: 1;
  background: #1A1A1A;
  border: 1px solid #414141;
  border-radius: 5px;
  height: 171px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
