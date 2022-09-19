<template>
  <div class="body main-font" style="inline-flex">
    <div class="blind-background bg-dark"></div>
    <div class="custom-padding">
      <div>
          <div class="col-lg-6 col-sm-12 adventure">
            <h5>{{$t('PlayToEarn.playToEarn')}}</h5>
          </div>
      </div>
      <img src="../assets/divider7.png" class="info-divider enemy-divider" />
      <div>
          <div class="col-lg-12 play-to-earn">
            <router-link :to="{ name: 'combat' }" exact class="adventures navs">
                <div>
                  <h4>{{$t('PlayToEarn.adventure')}}</h4>
                  <p>{{$t('PlayToEarn.adventureDesc')}}</p>
                  <div class="btn-join">{{$t('PlayToEarn.btnCombat')}}</div>
                </div>
                <component v-bind:is="!isMobile() && !isToggled ? 'card-frame' : 'card-frame-toggled'"></component>
            </router-link>

            <router-link :to="{ name: 'raid' }" exact class="raid navs">
                <div>
                  <h4>{{$t('PlayToEarn.raid')}}</h4>
                  <p>{{$t('PlayToEarn.raidDesc')}}</p>
                  <div class="btn-join">{{$t('PlayToEarn.btnJoin')}}</div>
                </div>
                <component v-bind:is="!isMobile() && !isToggled ? 'card-frame' : 'card-frame-toggled'"></component>
            </router-link>

            <router-link :to="{ name: 'pvp' }" exact class="arena navs">
                <div>
                  <h4>{{$t('PlayToEarn.arena')}}</h4>
                  <p>{{$t('PlayToEarn.arenaDesc')}}</p>
                  <div class="btn-join">{{$t('PlayToEarn.btnPvp')}}</div>
                </div>
                <component v-bind:is="!isMobile() && !isToggled ? 'card-frame' : 'card-frame-toggled'"></component>
            </router-link>
          </div>
      </div>
    </div>
  </div>
</template>

<script>

import Events from '../events';
import CardFrame from '../components/common/CardFrame.vue';
import CardFrameToggled from '../components/common/CardFrameToggled.vue';

export default {
  data() {
    return {
      isToggled: false
    };
  },
  async mounted(){
    Events.$on('setWeaponId', (id) =>{
      this.selectedWeaponId = id;
    });
    Events.$on('toggle-sideBar', (bol) =>{
      this.isToggled = bol;
    });
  },
  methods: {
  },
  components: {
    'card-frame': CardFrame,
    'card-frame-toggled' : CardFrameToggled
  },
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Cardo:ital,wght@0,400;0,700;1,400&display=swap');
.custom-padding{
  padding: 60px !important;
}
h5{
  font-family: 'Trajan', serif;
  font-size: 25px;
  font-weight: 400;
}

.play-to-earn{
  display: flex;
  justify-content: space-around;
  margin-top: 30px;
}

.play-to-earn > .navs{
  border: 1px solid #9e8a57;
  height: 30vw;
  display: flex;
  width: 25%;
  align-items: center;
  flex-direction: column;
  justify-content: flex-end;
  /* box-shadow: inset 0px 0px 20px 10px rgba(0,0,0,0.6); */
  padding-top: 30px;
  cursor: pointer;
}

.main-font{
  background-image: url('../assets/combat-bg.png');
  background-position: 0 0;
  background-size: cover;
  height: 90vh;
}


.main-font > div:nth-child(1){
  background-color: rgb(0, 0, 0);
  opacity: 0.7;
  height: 100%;
  width: 100%;
  position: absolute;
}


.main-font > div:nth-child(2){
  padding-top: 20px;
}

.play-to-earn > .navs:hover{
  transition: all 0.4s ease-in-out;
  animation: movingBg 4s ease-in-out;
  background-repeat: no-repeat;
}


@keyframes movingBg {
  0%{
    background-size: 110%;
  }
  25%{
    background-size: 120%;
  }
}

.play-to-earn > .navs > div{
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
  justify-content: center;
  text-align: center;
  background-image: linear-gradient(to top, rgb(0, 0, 0),rgba(0, 0, 0, 0.692), rgba(0, 0, 0, 0.042));
  padding: 200px 50px 40px 50px;
}

.play-to-earn > .navs > div > p{
  font-family: Roboto;
  color: #fff;
  font-size: 15px;
}

.play-to-earn > .navs > div > h4{
  font-family: Trajan;
  font-weight: 500;
  color:#9e8a57;
}

.play-to-earn > .navs > div > .btn-join{
  width: 160px;
  background-image: url('../assets/btn-join.png') ;
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
  padding: 20px;
  font-size: 18px;
  font-family: Oswald;
  color: #fff;
  font-weight: 800;
  cursor: pointer;
}


.play-to-earn .adventures{
  background-image: url('../assets/bg-orc.png');
  background-position:center ;
  background-size: cover;
}

.play-to-earn .raid{
  background-image: url('../assets/bg-demon.png');
  background-position:center ;
  background-size: cover;
}

.play-to-earn .arena{
  background-image: url('../assets/bg-arena.png');
  background-position:center ;
  background-size: cover;
}


.adventure{
    text-align: left;
    color: #EDCD90;
  }


.adventure > img{
  display: none;
}


/* FOR BORDER ANIMATION */
.play-to-earn > .navs{
  border: 1px solid #9e8a57;
  height: 30vw;
  display: flex;
  width: 25%;
  align-items: center;
  flex-direction: column;
  justify-content: flex-end;
  /* box-shadow: inset 0px 0px 20px 10px rgba(0,0,0,0.6); */
  padding-top: 30px;
  cursor: pointer;
}


@keyframes animateBorder {
  0%{}
  100%{}
}




@media all and (max-width: 600px) {

  .play-to-earn > .navs{
    font-family: Roboto;
    color: aliceblue;
    font-size: 13px;
    width: 100%;
    height: 30em;
    flex-grow: 1;
    background-position:center;
  }

  .play-to-earn{
    height: 70vh;
    display: flex;
    justify-content: space-around;
    flex-grow: 1;
    flex-wrap: wrap;
    flex: none;
    gap: 30px;
    margin-top: 0px;
    overflow-x: auto;
  }
}

</style>
