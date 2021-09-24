<template>
<div class="duel-overlay">
  <div class="slice-container">
    <div class="slice-screen-upper">
    </div>
    <div class="slice-screen-lower">
    </div>
  </div>
  <div class="duel-attacker-container">
    <img class="duel-attacker-img" :src="getCharacterArtById(attackerId)"/>
  </div>
  <div class="duel-loader-middle-second">
  </div>
  <div class="duel-loader-outer">
  </div>
  <div class="duel-loader-outer-second">
  </div>
  <div class="duel-loader-middle">
  </div>
  <div class="duel-loader-inner">
  </div>
  <div class="duel-defender-container">
    <img class="duel-defender-img" :src="getCharacterArtById(defenderId)"/>
  </div>
</div>
</template>

<script>
import { getCharacterArtById } from '../../character-arts-placeholder';
import { getWeaponArtById } from '../../weapon-arts-placeholder';

export default {

  props: ['attackerId','defenderId','isWon'],

  methods:{
    getCharacterArtById,

    getWeaponArtById,
  }

};
</script>

<style>

.duel-overlay {
  position: fixed;
  top: 0;
  left: 0;
  height: 100%;
  width: 100%;
  background-color: #000;
  z-index: 9999999;
  /* animation: fade 6s 1 forwards; */
}

.slice-container {
  position: fixed;
  height: 100%;
  width: 100%;
  background-color: blue;
  animation: slicee 6s 1 forwards;
}

.slice-screen-upper {
  position: fixed;
  background-color: black;
  top: 0%;
  left: 0px;
  height: 50%;
  width: 100%;
  animation: cut-upper 6s 1 forwards;
}

.slice-screen-lower{
  position: fixed;
  background-color: black;
  top: 50%;
  left: 0px;
  height: 100%;
  width: 100%;
  animation: cut-lower 6s 1 forwards;
}

.duel-attacker-container {
  position: fixed;
  left: 0px;
  height: 400px;
  width: 200px;
  animation: attack 4s 1 forwards;
}

.duel-defender-container {
  position: fixed;
  bottom: 0px;
  right: 0px;
  height: 400px;
  width: 200px;
  animation: defend 4s 1 forwards;
}

.duel-attacker-img, .duel-defender-img {
  height: 100%;
  width: 100%;
  filter: drop-shadow(12px 12px 7px #fff);
}

.duel-loader-middle-second{
  position: absolute;
  margin: auto;
  top: 0;
  bottom: 0;
  right: 0;
  left: 0;
  height: 350px;
  width: 350px;
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 0 5px #fff;
  animation: expand-middle-second 2.5s 1 forwards;
}

.duel-loader-outer{
  position: absolute;
  margin: auto;
  top: 0;
  bottom: 0;
  right: 0;
  left: 0;
  height: 300px;
  width: 300px;
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 0 5px #fff;
  animation: expand-outer 2s 1 forwards;
}

.duel-loader-outer-second{
  position: absolute;
  margin: auto;
  top: 0;
  bottom: 0;
  right: 0;
  left: 0;
  height: 250px;
  width: 250px;
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 0 5px #fff;
  animation: expand-outer-second 1.5s 1 forwards;
}

.duel-loader-middle{
  position: absolute;
  margin: auto;
  top: 0;
  bottom: 0;
  right: 0;
  left: 0;
  height: 200px;
  width: 200px;
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 0 5px #fff;
  animation: expand 1s 1 forwards;
}

.duel-loader-inner{
  position: absolute;
  margin: auto;
  top: 0;
  bottom: 0;
  right: 0;
  left: 0;
  height: 150px;
  width: 150px;
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 0 5px #fff;
}

.duel-loader-outer::before{
  content: "";
  background-image: linear-gradient(90deg, #020024 0%, #fff 100%);
  height: 150%;
  width: 150%;
  position: absolute;
  left: -25%;
  top: -25%;
  animation: counterclockwise-rotate 4s infinite linear;
}

.duel-loader-outer-second::before{
  content: "";
  background-image: linear-gradient(90deg, #020024 0%, #fff 100%);
  height: 150%;
  width: 150%;
  position: absolute;
  left: -25%;
  top: -25%;
  animation: clockwise-rotate 4s infinite linear;
}

.duel-loader-middle::before{
  content: "";
  background-image: linear-gradient(90deg, #020024 0%, #fff 100%);
  height: 150%;
  width: 150%;
  position: absolute;
  left: -25%;
  top: -25%;
  animation: clockwise-rotate 3s infinite linear;
}

.duel-loader-middle-second::before{
  content: "";
  background-image: linear-gradient(90deg, #020024 0%, #fff 100%);
  height: 150%;
  width: 150%;
  position: absolute;
  left: -25%;
  top: -25%;
  animation: clockwise-rotate 3s infinite linear;
}

.duel-loader-inner::before{
  content: "";
  background-image: linear-gradient(90deg, #020024 0%, #968332 100%);
  height: 150%;
  width: 150%;
  position: absolute;
  left: -25%;
  top: -25%;
  animation: counterclockwise-rotate 2s infinite linear;
}

.duel-loader-outer::after{
  content: "";
  height: 98%;
  width: 98%;
  position: absolute;
  background-color: #000;
  background-image: url('../../assets/duel-loader-middle.svg');
  border-radius: 50%;
  top: 1%;
  left: 1%;
  display: grid;
  place-items: center;
  animation: clockwise-rotate 8s infinite linear;
}

.duel-loader-outer-second::after{
  content: "";
  height: 98%;
  width: 98%;
  position: absolute;
  background-color: #000;
  background-image: url('../../assets/duel-loader-outer.svg');
  border-radius: 50%;
  top: 1%;
  left: 1%;
  display: grid;
  place-items: center;
  animation: clockwise-rotate 20s infinite linear;
}

.duel-loader-middle::after{
  content: "";
  height: 98%;
  width: 98%;
  position: absolute;
  background-color: #000;
  background-image: url('../../assets/duel-loader-middle.svg');
  border-radius: 50%;
  top: 1%;
  left: 1%;
  display: grid;
  place-items: center;
  animation: counterclockwise-rotate 7s infinite linear;
}

.duel-loader-middle-second::after{
  content: "";
  height: 98%;
  width: 98%;
  position: absolute;
  background-color: #000;
  background-image: url('../../assets/duel-loader-outer.svg');
  border-radius: 50%;
  top: 1%;
  left: 1%;
  display: grid;
  place-items: center;
  animation: counterclockwise-rotate 10s infinite linear;
}

.duel-loader-inner::after{
  content: "DUEL";
  height: 94%;
  width: 94%;
  position: absolute;
  background-color: #000;
  border-radius: 50%;
  top: 3%;
  left: 3%;
  color: white;
  display: grid;
  place-items: center;
  font-size: 20px;
  font-weight: bold;
  letter-spacing: 10px;
}

@keyframes attack {
  0%{
    left: 0%;
    opacity: 1;
  }
  90%{
    opacity: 1;
  }
  100%{
    left: 50%;
    opacity: 0;
  }
}

@keyframes defend {
  0%{
    right: 0%;
    opacity: 1;
  }
  90%{
    opacity: 1;
  }
  100%{
    right: 50%;
    opacity: 0;
  }
}

@keyframes slicee {
  0%{
    width:0%;
  }
  69%{
    width: 0%;
  }
  75%{
    width:100%;
    opacity: 1;
  }
  76%{
    opacity: 0;
  }
  90%{
    opacity: 0;
  }
  100%{
    opacity: 0;
  }
}

@keyframes cut-upper {
  0%{
    opacity: 1;
  }
  50%{
    height: 50%
  }
  60%{
    height: 49.9%;
  }
  79%{
    height: 49.9%;
  }
  80%{
    height: 49.9%;
    background-color: #000;
  }
  90%{
    height: 49.75%;
    background-color: rgb(104, 104, 104);
  }
  100%{
    height: 49.75%;
  }
}

@keyframes cut-lower {
  0%{
    opacity: 1;
  }
  50%{
    height: 50%
  }
  60%{
    height: 50%
  }
  79%{
    height: 50%;
  }
  80%{
    height: 50%;
    background-color: #000;
  }
  90%{
    height: 50%;
    background-color: rgb(104, 104, 104);
  }
  100%{
    height: 50%;
  }
}

@keyframes fade {
  80%{
    background-color: #000;
  }
  90%{
    opacity: 1;
  }
  100%{
    opacity: 0;
    background-color: rgb(104, 104, 104);
  }
}

@keyframes counterclockwise-rotate {
  100%{
    transform: rotate(-360deg);
  }
}

@keyframes clockwise-rotate {
  100%{
    transform: rotate(360deg);
  }
}

@keyframes expand {
  0%{
    height: 0px;
    width: 0px;
  }
  50%{
    height: 250px;
    width: 250px;
  }
  100%{
    height: 200px;
    width: 200px;
  }
}

@keyframes expand-middle-second {
  0%{
    height: 0px;
    width: 0px;
  }
  50%{
    height: 400px;
    width: 400px;
  }
  100%{
    height: 350px;
    width: 350px;
  }
}

@keyframes expand-outer-second  {
  0%{
    height: 0px;
    width: 0px;
  }
  50%{
    height: 300px;
    width: 300px;
  }
  100%{
    height: 250px;
    width: 250px;
  }
}

@keyframes expand-outer {
  0%{
    height: 0px;
    width: 0px;
  }
  50%{
    height: 350px;
    width: 350px;
  }
  100%{
    height: 300px;
    width: 300px;
  }
}



</style>
