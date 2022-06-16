<template>
  <div class="container">
    <h1 class="stake-type-title">
    </h1>
    <div class="stake-stats">
      <div class="stake-stats-item">
        <div class="stake-stats-item-title"></div>
        <div class="stake-stats-item-value"></div>
      </div>
      <div class="stake-stats-item">
        <div class="stake-stats-item-title"></div>
        <div class="stake-stats-item-value">
        </div>
      </div>
      <div class="stake-stats-item">
        <div class="stake-stats-item-title"></div>
        <div class="stake-stats-item-value"></div>
      </div>
      <div class="stake-stats-item">
        <div class="stake-stats-item-title"></div>
        <div class="stake-stats-item-value"></div>
      </div>
    </div>
    <div class="stats-row">
      <div class="stats-col">
        <div class="stake-stats-item-title"></div>
        <div class="stake-stats-item-value"></div>
      </div>
      <div class="stats-col">
        <div class="stake-stats-item-title"></div>
        <div class="stake-stats-item-value"></div>
      </div>
      <div class="stats-col">
        <div class="stake-stats-item-title"></div>
        <div class="stake-stats-item-value"></div>
      </div>
    </div>
    <div class="claim-rewards-wrapper">
      <div class="claim-rewards">
        <div>
          <div class="stake-stats-item-title"></div>
          <div class="stake-stats-item-value"></div>
        </div>
        <div class="claim-rewards-btns">
          <button class="stake-button">
            <span></span>
          </button>
          <button class="stake-button">
            <span></span>
          </button>
        </div>
      </div>
      <div class="progressBarWrapper">
          <div class="progressBar"></div>
          <span></span>
      </div>
    </div>
    <div class="stake-buttons">
      <button class="stake-button">
      </button>
      <button class="stake-button">
      </button>
    </div>
    <div class="divider"></div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
export default Vue.extend({
  watch: {
  },
  methods:{
  },
});
</script>

<style src="vue-multiselect/dist/vue-multiselect.min.css"></style>
<style scoped>
.container {
  background: #000E1D; /* change to: background: #000E1D; */
  padding: 45px 40px;
  display: flex;
  flex-direction: column;
  align-items: center;
  height:95%;
  margin-left: 5px;
  animation: blinkOpacity 2s infinite;
  border: 1px solid #404857;
  border-radius: 5px;
  width: 97%;
}

@keyframes blinkOpacity {
  from{
    opacity: 1;
  }
  to{
    opacity: 0.4;
  }
}

.stake-stats{
  display: flex;
  justify-content: space-between;
  width: 100%;
  margin: 20px 0;
  flex-wrap: nowrap;
}
.stake-stats-item{
  border: 1px solid #404857;
  border-radius: 5px;
  display: flex;
  flex-direction: column;
  padding: 15px 15px;
  margin-left: 5px;
  margin-right: 5px;
}

.stake-stats-item-title{
  font: normal normal normal 16px/21px Roboto;
  color: #EDCD90;
  margin-bottom: 5px;
  background-color: #ffffff4d;
  height: 10px;
  width: 100px;
}
.stake-stats-item-value{
  font: normal normal medium 16px/21px Roboto;
  color: #fff;
  height: 10px;
  margin-top: 15px;
  background-color: #f0f8ff21;
}
.stats-row{
  width:100%;
  display: flex;
  justify-content: space-between;
  margin-bottom:25px;
}
.stats-col{
  /* flex:1; */
  display:flex;
  flex-direction: column;
}
.claim-rewards-wrapper{
  border: 1px solid #404857;
  border-radius: 5px;
  width:100%;
}
.progressBarWrapper{
  width:100%;
  position: relative;
  height:15px;
  background: #ffffff33;
  margin-top: 18px;
}
.progressBar{
  height: 15px;
  background: hsl(43, 29%, 48%);
  border-radius: 5px;
  position: absolute;
  z-index: 1;
  animation: progressBar 3s ease-in-out;
  animation-fill-mode:both;
}
.progressBarWrapper > span{
  font: 12px Roboto;
  position: absolute;
  color:#fff;
  z-index: 2;
  left: 50%;
  transform: translateX(-50%);
}
@keyframes progressBar {
  0% {
    background: hsl(43, 0%, 48%);
    width: 0;
  }
}
.claim-rewards{
  margin-top: 15px;
  padding: 15px;
  display:flex;
  justify-content: space-between;
  align-items: center;
}
.claim-rewards-btns{
  display: flex;
}

.claim-rewards-btns button{
  min-width: 85px;
  padding: 5px 10px;
  margin: 0 5px;
}

.btn-restake{
  border: none;
  background: none;
  color: #9D98A1;
  font: normal 16px/21px Roboto;
  text-align: center;
}

.stake-button span{
  font: normal 16px/21px Roboto;
  text-align: center;
}

.stake-button{
  font: normal 16px/21px Roboto;
  text-align: center;
  background: #9E8A57; /* change to: #1168D0; */
  border-radius: 5px;
  border:none;
  color: #FFFFFF;
  width:100%;
  padding:5px 23px;
}

.stake-button:disabled{
  background: #404857;
  color: #9D98A1;
  cursor: default;
}

.stake-buttons{
  width:100%;
  margin: 0 auto;
  display:flex;
  justify-content: space-between;
  margin-top:25px;
}
.stake-buttons .stake-button{
  width:calc(50% - 7px);
  min-height: 43px;
}

.btn_active{
  background: hsl(43, 15%, 18%);
  color: #fff;
}

.divider{
  width:100%;
  height:1px;
  background: #404857; /* maybe change to: #1168D0; */
  margin: 20px 0;
}

.token-amount-input {
  font-variant: tabular-nums;
  font-feature-settings: "tnum";
  padding: 10px 11px 5px 11px;
  color: #fff;
  background-color: transparent;
  outline-width: 0;
  font: normal 34px Roboto;
  line-height: 40px;
  text-align: right;
  text-overflow: ellipsis;
  border-radius: 5px;
  border: 1px solid #404857;
  touch-action: manipulation;
  margin-bottom: 20px;
  width: 100%;
}

.stake-submit-button{
  min-height: 43px;
}

.input-ratio-buttons{
  display:flex;
  justify-content: space-between;
  align-items: center;
  width:100%;
  margin-bottom:20px;
}
.ratio-button{
  width:calc(25% - 25px);
  font-size:12px;
  padding:2px 5px;
}

.multiselect{
  overflow: visible;
  margin-bottom:50px;
}

.stake-type-title {
  font: bold 20px/25px Trajan;
  align-self: flex-start;
  color: #EDCD90;
  height: 25px;
  background-color: #ffffff24;
  width: 200px;
}

.inputSection{
  width: 70%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height:100%;
}

/* Mobile */
@media only screen and (max-width: 768px)  {
  .stake-stats-item{
    margin-bottom: 10px;
    width: calc(50% - 10px );
  }
  .container {
    padding: 20px 15px;
    width: 90%;
  }
  .stake-stats{
    flex-wrap: wrap;
  }
  .claim-rewards-btns{
    justify-content: center;
    flex-wrap: wrap;
    gap:1em;
  }
  .stats-col{
    align-items: center;
    justify-content: center;
  }
  .inputSection{
    width: 100%;
  }
}
</style>
