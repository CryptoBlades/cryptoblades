<template>
  <div class="body main-font">
    <div>
      <div class="row">
          <div class="col-lg-6 col-sm-12 adventure">
            <h5>{{$t('PlayToEarn.playToEarn')}}</h5>
          </div>
      </div>
      <img src="../assets/divider7.png" class="info-divider enemy-divider" />
      <div class="row">
          <div class="col-lg-12 play-to-earn">
            <router-link v-if="!stakeOnly" :to="{ name: 'combat' }" exact class="adventures navs">
                <div>
                  <h4>{{$t('PlayToEarn.adventure')}}</h4>
                  <p>{{$t('PlayToEarn.adventureDesc')}}</p>
                  <div class="btn-join">{{$t('PlayToEarn.btnCombat')}}</div>
                </div>
            </router-link>

            <!-- change this to raid route -->
            <router-link v-if="!stakeOnly" :to="{ name: 'combat' }" exact class="raid navs">
                <div>
                  <h4>{{$t('PlayToEarn.raid')}}</h4>
                  <p>{{$t('PlayToEarn.raidDesc')}}</p>
                  <div class="btn-join">{{$t('PlayToEarn.btnJoin')}}</div>
                </div>
            </router-link>

            <!-- change this to arena route -->
            <router-link v-if="!stakeOnly" :to="{ name: 'combat' }" exact class="arena navs">
                <div>
                  <h4>{{$t('PlayToEarn.arena')}}</h4>
                  <p>{{$t('PlayToEarn.arenaDesc')}}</p>
                  <div class="btn-join">{{$t('PlayToEarn.btnPvp')}}</div>
                </div>
            </router-link>
          </div>
      </div>
    </div>
  </div>
</template>

<script>

import {stakeOnly} from '@/feature-flags';
import Events from '../events';
// import gasp from 'gsap'; // for enemy card animaton

export default {
  data() {
    return {
      stakeOnly,
      isToggled: false
    };
  },
  async mounted(){
    Events.$on('setWeaponId', (id) =>{
      this.selectedWeaponId = id;
    });
  },
  methods: {
  },
  components: {
  },
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Cardo:ital,wght@0,400;0,700;1,400&display=swap');

h5{
  font-family: Trajan;
  font-size: 25px;
  font-weight: 600;
}

.play-to-earn{
  display: flex;
  justify-content: space-around;
  margin-top: 30px;
}

.play-to-earn > .navs{
  border: 1px solid #9e8a57;
  height: 30em;
  display: flex;
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
}

.play-to-earn > .navs:hover{
  margin-top: -20px;
  transition: all 0.4s ease-in-out;
}

.play-to-earn > .navs > div{
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  background-image: linear-gradient(to top, rgb(0, 0, 0),rgba(0, 0, 0, 0.542), rgba(0, 0, 0, 0.042));
  padding: 30px 50px 40px 50px;
}

.play-to-earn > .navs > div > p{
  font-family: Roboto;
  color: aliceblue;
  font-size: 13px;
}

.play-to-earn > .navs > div > h4{
  font-family: Trajan;
  font-weight: 800;
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
  font-family: Roboto;
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
  }


.adventure > img{
  display: none;
}


@media all and (max-width: 600px) {

  .play-to-earn > .navs{
    font-family: Roboto;
    color: aliceblue;
    font-size: 13px;
    width: 100%;
    /* height: 10em; */
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
