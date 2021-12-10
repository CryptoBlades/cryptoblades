<template>
  <div class="sign-up">
    <div class="char-status">
      <div class="players">
        <label>Number of Players</label>
        <span>25,099</span>
      </div>
      <div class="raid-power">
        <label>Raid Power</label>
        <span>40,500,332</span>
      </div>
      <div class="boss-power">
        <label>Boss Power</label>
        <span>28,480,233</span>
      </div>
    </div>

    <div class="chances">
      <p>Chance to Drop</p>
      <ul>
        <li class="active"><img src="../../assets/new-ui/item/ring.png" alt="character-default"></li>
        <li class="active"><img src="../../assets/new-ui/item/weapon7.png" alt="character-default"></li>
        <li><img src="../../assets/new-ui/item/helmet.png" alt="character-default"></li>
        <li><img src="../../assets/new-ui/item/dust.png" alt="character-default"></li>
      </ul>
    </div>

    <div class="card-action">
      <Button mainText="Join Raid" sub-text="05:32" route="raid" size="lg"/>
      <div class="cost">
        <p>Joining will cost:</p>
        <ul>
          <li>200 Stamina</li>
          <li>20 Durability</li>
          <li>0.01 SKILL</li>
        </ul>
      </div>
    </div>

  </div>
</template>

<script>
import Button from '@/components/Button';
export default {
  name: 'RaidSignup',
  components: { Button }
};
</script>

<style scoped>

.char-status {
  display: flex;
  margin-bottom: 48px;
}
.char-status > div {
  border-right: 1px solid #3F4756;
  padding: 5px 50px 5px 50px;
}
.char-status > div:first-child {
  padding-left: 0;
}
.char-status > div:last-child {
  border-right: 0;
  padding-right: 0;
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

.chances p {
  color: #CEC198;
  font-size: 16px;
}
.chances ul {
  margin: 0;
  padding: 0;
}
.chances li {
  width: 93px;
  height: 93px;
  padding: 5px;
  border: 1px solid #3F4756;
  display: inline-block;
  margin-right: 15px;
  background: #101010;
}
.chances li.active {
  border-color: #D16100;
}
.chances li:last-child {
  margin-right: 0;
}
.chances li img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.card-action {
  display: flex;
  align-items: center;
  padding-top: 60px;
}
.card-action .cost {
  padding-left: 30px;
}
.card-action .cost p {
  color: #CEC198;
  font-size: 16px;
  margin-bottom: 1px;
}
.card-action .cost ul {
  margin: 0;
  padding: 0;
}
.card-action .cost li {
  border-right: 1px solid #484848;
  display: inline-block;
  margin-right: 15px;
  padding-right: 15px;
  color: #9D98A1;
  line-height: 15px;
  margin-bottom: 0;
}
.card-action .cost li:last-child {
  margin-right: 0;
  padding-right: 0;
  border-right: 0;
}
.card-action .chances li img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

</style>
