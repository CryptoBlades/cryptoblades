<template>
  <div class="card-item raid-card">
    <div class="char-img">
      <img src="../assets/new-ui/character/CB_monsters_HellbornShaman.png" alt="character-default">
    </div>
    <div class="char-info">

      <div class="char-heading">
        <div class="icon-frame-sm active"><img src="../assets/new-ui/icon-alien-fire.png" alt="character"></div>
        <h2 class="char-name">Zhangtsun <span>Hellborn Shaman</span></h2>
      </div>

      <div class="char-status">
        <div class="boss-power">
          <label>Boss Power</label>
          <span>25,099</span>
        </div>
        <div class="element">
          <label>Element</label>
          <span>FIRE</span>
        </div>
        <div class="reg-end">
          <label>Registration Ends</label>
          <span>05:32</span>
        </div>
      </div>

      <div class="progress-wrap">
        <p>Participants Total Power: <span>23,332 (87%)</span></p>
        <div class="char-progress-bar"><span class="percent"></span></div>
      </div>

      <div class="card-action">
        <Button mainText="Join Raid" sub-text="+380 EXP" route="raid" size="lg"/>
        <div class="chances">
          <p>Chance to Drop</p>
          <ul>
            <li><img src="../assets/new-ui/item/ring.png" alt="character-default"></li>
            <li><img src="../assets/new-ui/item/amulet.png" alt="character-default"></li>
            <li><img src="../assets/new-ui/item/weapon7.png" alt="character-default"></li>
          </ul>
        </div>
      </div>

    </div>
  </div>
</template>

<script>
import Button from '@/components/Button';
export default {
  props: ['ctaBg'],
  name: 'HomeRaidCard',
  components: {
    Button
  }
};
</script>

<style scoped>
.raid-card {
  display: flex;
  position: relative;
  background: #404857 url("../assets/new-ui/background/c1242c0420541b3ea3f38f98c9da34ad.png") no-repeat center;
}
.raid-card .background {
  position: absolute;
  width: 100%;
  height: 100%;
  background: red;
}
.raid-card > div {
  position: relative;
}
.char-info {
  flex-grow: 1;
  padding: 30px;
  margin-top: 20px;
}
.char-heading {
  display: flex;
  align-items: center;
  border-bottom: 1px solid #CEC198;
  padding-bottom: 15px;
  margin-bottom: 25px;
}
.char-heading span {
  display: block;
  color: #CEC198;
  font-size: 16px;
  font-family: 'Roboto';
  font-weight: normal;
}
.char-heading .icon-frame-sm {
  margin-right: 15px;
}
.progress-wrap {
  margin-bottom: 40px;
}
.char-progress-bar {
  height: 13px;
  width: 100%;
  max-width: 100%;
}
.char-progress-bar .percent {
  width: 85%;
  height: 13px;
}

.char-status {
  display: flex;
  justify-content: space-between;
  margin-bottom: 28px;
}
.char-status label {
  color: #CEC198;
  font-size: 16px;
}
.char-status span {
  display: block;
  font-family: 'Oswald';
  font-size: 40px;
  line-height: 55px;
  font-weight: 500;
}
.progress-wrap {
  color: #CEC198;
  font-size: 16px;
}
.progress-wrap span {
  color: #fff;
}

.card-action {
  display: flex;
}
.card-action .chances {
  padding-left: 30px;
}
.card-action .chances p {
  color: #CEC198;
  font-size: 16px;
  margin-bottom: 1px;
}
.card-action .chances ul {
  margin: 0;
  padding: 0;
}
.card-action .chances li {
  width: 54px;
  height: 54px;
  padding: 5px;
  border: 1px solid #484848;
  display: inline-block;
  margin-right: 15px;
  background: #101010;
}
.card-action .chances li:last-child {
  margin-right: 0;
}
.card-action .chances li img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

</style>
