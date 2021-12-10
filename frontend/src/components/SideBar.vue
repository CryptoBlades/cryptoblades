<template>
  <aside>
    <b-navbar-nav>
      <li class="character" :class="{ active: characterID === '1' }">
        <router-link to="/character/1" exact class="nav-link">
          <div class="icon-wrap">
            <img v-if="characterID !== '1'" src="../assets/new-ui/alien-fire.png" alt="character">
            <img v-if="characterID === '1'" src="../assets/new-ui/icon-alien-fire.png" alt="character">
          </div>
          <div class="info-wrap">
            <span class="character-name">ZhangTsun</span>
            <span class="progress-bar"><span class="percent"></span></span>
            <span class="character-level">Level 51 (300 EXP to 61)</span>
          </div>
        </router-link>
      </li>
      <li class="character" :class="{ active: characterID === '2' }">
        <router-link to="/character/2"  exact class="nav-link">
          <div class="icon-wrap">
            <img v-if="characterID !== '2'" src="../assets/new-ui/icon-nature.png" alt="character">
            <img v-if="characterID === '2'" src="../assets/new-ui/icon-earth.png" alt="character">
          </div>
          <div class="info-wrap">
            <span class="character-name">Zenkai</span>
            <span class="progress-bar"></span>
            <span class="character-level">Level 51 (300 EXP to 61)</span>
          </div>
        </router-link>
      </li>
      <li class="character">
        <router-link to="/character/3"  exact class="nav-link">
          <div class="icon-wrap">
            <img src="../assets/new-ui/icon-nature.png" alt="character">
          </div>
          <div class="info-wrap">
            <span class="character-name">Azure</span>
            <span class="progress-bar"></span>
            <span class="character-level">Level 51 (300 EXP to 61)</span>
          </div>
        </router-link>
      </li>
      <li class="character">
        <router-link to="/character/3" exact class="nav-link">
          <div class="icon-wrap">
            <img src="../assets/new-ui/icon-nature.png" alt="character">
          </div>
          <div class="info-wrap">
            <span class="character-name">BlackFire</span>
            <span class="progress-bar"></span>
            <span class="character-level">Level 51 (300 EXP to 61)</span>
          </div>
        </router-link>
      </li>
    </b-navbar-nav>

    <div class="sponsor">
      <div class="label">Sponsored By:</div>
      <div class="sponsor-info">
        <div class="sponsor-icon">
          <img src="../assets/new-ui/icon-sponsor-logo.png" alt="sponsor-logo">
        </div>
        <div class="sponsor-name">
          <p>Incubator & Launchpad for Blockchain Games & Gamers</p>
          <a href="#" target="_blank">Seedify.fund</a>
        </div>
      </div>
    </div>
  </aside>
</template>

<script>
export default {
  name: 'SideBar',
  components : {
  },
  computed : {
    characterID() {
      return this.$route.params.id;
    },
  }
};
</script>

<style scoped>
aside {
  width: 380px;
  background: #000E29;
  border-right: 1px solid #404857;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 36px 35px 36px 50px;
}
.character {
  margin-bottom: 35px;
}
.character a {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  padding: 0;
}
.character .icon-wrap {
  width: 83px;
  height: 83px;
  background: url("../assets/new-ui/icon-frame.png") no-repeat;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 15px;
}
.character .info-wrap {
  display: block;
}
.character .character-name {
  display: block;
  font-size: 16px;
  line-height: 20px;
  font-family: 'Trajan';
  color: #968E74;
  margin-bottom: 2px;
  font-weight: bold;
}
.character .progress-bar {
  height: 3px;
  display: block;
  background: #817D6D;
  position: relative;
  width: 170px;
}
.character .progress-bar .percent {
  display: block;
  position: absolute;
  width: 50%;
  height: 3px;
  background: #C1B49C;
  left: 0;
  top: 0;
}
.character .character-level {
  color: #817D6D;
  font-size: 13px;
}

.character.active .character-name {
  color: #EDCD90;
}
.character.active .progress-bar {
  background: #817D6D;
}
.character.active .character-level {
  color: #fff;
}
.character.active .icon-wrap {
  background: url("../assets/new-ui/icon-frame-active.png") no-repeat;
}

/*Sponsor*/
.sponsor .label {
  color: #7F8693;
  font-size: 13px;
  margin-bottom: 10px;
}
.sponsor-info {
  display: flex;
}
.sponsor-info .sponsor-icon {
  margin-right: 15px;
}
.sponsor-info .sponsor-icon img {
  width: 100px;
}
.sponsor-info .sponsor-name {
  font-size: 16px;
  line-height: 19px;
}
.sponsor-info .sponsor-name a {
  color: #7F8693;
}
</style>
