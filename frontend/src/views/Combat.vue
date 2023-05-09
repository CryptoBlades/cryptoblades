<template>
  <div style="display: inline-flex" class="body main-font">
    <div v-if="ownCharacters.length > 0" class="p-3">
      <div v-if="error !== null">
        <div class="col error">{{$t('combat.error')}} {{ error }}</div>
        <div class="col error" v-if="errorCode === CHANGE_RPC_ERROR_CODE">{{$t('combat.32005Error')}}</div>
      </div>

      <div>
        <div class="adventure" v-if="COMBAT_TAB.Adventure === currentCombatTab">
          <h5 class="m-2 d-inline combat-tab active-tab">
              {{$t('combat.adventure')}}
          </h5>
          <h4
            class="m-2 d-inline combat-tab text-uppercase"
            @click="onChangeCombatTab(COMBAT_TAB.TeamAdventure)">
              {{$t('combat.teamAdventure')}}
          </h4>
        </div>
        <div class="adventure" v-if="COMBAT_TAB.TeamAdventure === currentCombatTab">
          <h4 class="m-2 d-inline combat-tab"
              @click="onChangeCombatTab(COMBAT_TAB.Adventure)"
              :class="{'active-tab': COMBAT_TAB.Adventure === currentCombatTab}">
                {{$t('combat.adventure')}}
          </h4>
          <h5
            class="m-2 d-inline combat-tab active-tab">
              Team Adventure
          </h5>
        </div>

        <div class="col-lg-12 col-md-12 col-xl-12 col-sm-12 text-right combat-hint" :style="isToggled ? 'display:inline' : 'none'"
          @click="hideBottomMenu(false)">
          <div class="combat-hints">
            <Hint class="mr-3" :text="$t('combat.elementHint')"/>
            <div>
              <span class="fire-icon"/> 
              <span class="icon-border">.</span>
            </div> &nbsp;»&nbsp;
            <div>
              <span class="earth-icon" />
              <span class="icon-border">.</span>
            </div> &nbsp;»&nbsp;
            <div>
              <span class="lightning-icon"/>
              <span class="icon-border">.</span>
            </div> &nbsp;»&nbsp;
            <div>
              <span class="water-icon" />
              <span class="icon-border">.</span>
            </div> &nbsp;»&nbsp;
            <div>
              <span class="fire-icon"/>
              <span class="icon-border">.</span>
            </div>
          </div>
        </div>
      </div>
      <img src="../assets/divider7.png" class="info-divider enemy-divider" />

      <div class="mb-3" :style="'align-self: baseline; width: 20vw'">
        <span class="isMobile label-title">{{$t('combat.selectStamina')}}</span>
        <b-form-select
        class="mt-3 custom-select" v-model="fightMultiplier" :options='setStaminaSelectorValues()' @change="setFightMultiplier()"></b-form-select>
      </div>

      <div>
        <TeamAdventure
          v-if="COMBAT_TAB.TeamAdventure === currentCombatTab"
          :fightMultiplier="fightMultiplier"
          :staminaPerFight="staminaPerFight">
        </TeamAdventure>
        <Adventure
        v-if="COMBAT_TAB.Adventure === currentCombatTab"
          :fightMultiplier="fightMultiplier"
          :staminaPerFight="staminaPerFight"
          @error="onErrorChanged"
          @errorCode="onErrorCodeChanged"
        >
        </Adventure>
      </div>
    </div>

    <div class="blank-slate p-3" v-if="ownCharacters.length === 0">
      <div v-if="ownCharacters.length === 0">{{$t('combat.noCharacters')}}</div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import TeamAdventure from '../components/smart/CombatTabs/TeamAdventure.vue';
import Adventure from '../components/smart/CombatTabs/Adventure.vue';
import i18n from '@/i18n';
import Hint from './../components/Hint.vue';
import { Accessors } from 'vue/types/options';
import { mapGetters } from 'vuex';
import { ICharacter } from '@/interfaces';

export enum COMBAT_TAB {
  Adventure=0,
  TeamAdventure=1
}

type numberOrNull = number | null;
type stringOrNull = string | null;

const CHANGE_RPC_ERROR_CODE = -32005;

interface ICombatData {
  fightMultiplier: number;
  staminaPerFight: number;
  isToggled: boolean;
  error: stringOrNull;
  errorCode: numberOrNull;
  currentCombatTab: COMBAT_TAB
}

interface StoreMappedGetters {
  ownCharacters: Array<ICharacter>
}

export default Vue.extend({
  data() {
    return {
      fightMultiplier: Number(localStorage.getItem('fightMultiplier')),
      staminaPerFight: 40,
      isToggled: false,
      error: null,
      errorCode: -1,
      CHANGE_RPC_ERROR_CODE,
      COMBAT_TAB,
      currentCombatTab: COMBAT_TAB.Adventure
    } as ICombatData;
  },
  methods: {
    setStaminaSelectorValues() {
      const choices: {value: numberOrNull, text: string, disabled?: boolean }[] = [
        {value: null, text: i18n.t('combat.pleaseSelect').toString(), disabled: true},
      ];

      const addChoices = [];
      addChoices.push({ value: 5, text: '200' });
      addChoices.push({ value: 4, text: '160' });
      addChoices.push({ value: 3, text: '120' });
      addChoices.push({ value: 2, text: '80' });
      addChoices.push({ value: 1, text: '40' });
      choices.push(...addChoices.reverse());

      return choices;
    },
    setFightMultiplier() {
      localStorage.setItem('fightMultiplier', this.fightMultiplier.toString());
      this.updateStaminaPerFight();
    },
    updateStaminaPerFight() {
      this.staminaPerFight = 40 * Number(localStorage.getItem('fightMultiplier'));
    },
    hideBottomMenu(bol: boolean){
      this.isToggled = bol;
    },
    onErrorChanged(error: stringOrNull) {
      this.error = error;
    },
    onErrorCodeChanged(errorCode: numberOrNull) {
      this.errorCode = errorCode;
    },
    onChangeCombatTab(tab: COMBAT_TAB) {
      if(this.currentCombatTab === tab) return;

      this.currentCombatTab = tab;
      (this as any).$router.push({ path: '/combat', query: { tab: COMBAT_TAB[this.currentCombatTab] } });
    }
  },
  computed: {
    ...(mapGetters([
      'ownCharacters',
    ]) as Accessors<StoreMappedGetters>),
  },
  components: {
    TeamAdventure,
    Adventure,
    Hint
  },
  mounted() {
    const queryTab = (this as any).$route.query.tab;
    if(queryTab) {
      if(queryTab === COMBAT_TAB.Adventure || queryTab === COMBAT_TAB.TeamAdventure)
        this.currentCombatTab = (this as any).$route.query.tab;
    }
  }
});
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Cardo:ital,wght@0,400;0,700;1,400&display=swap');

.combat-tab {
  cursor: default;
}
.combat-tab:not(.active-tab) {
  cursor: pointer;
}
.active-tab {
  color: #EDCD90;
}
.custom-select{
  background-color:#010D22;
  color:#fff
}
.body{
  background: linear-gradient(0deg, rgba(0, 14, 41, 0.68), rgba(0, 14, 41, 0.68)), url('../assets/combat-bg.png');
  background-size: clamp(100%, 100%, 100%) auto;
  background-repeat: no-repeat;
  min-height: 100%;
}
h5{
  font-family: 'Trajan', serif;
  font-size: 25px;
  font-weight: 400;
}

.label-title{
  font-family: Oswald;
  color: #fff;
  text-transform: uppercase;
  font-size: 20px;
}


.enemy-character {
  position: relative;
  width: inherit;
  cursor: pointer;
  background-position: center;
  background-repeat: no-repeat;
  background-size: clamp(100%, 100%, 100%) auto;
  background-image: url('../assets/enemy-bg-transparent.png');
  background-color: linear-gradient(45deg, rgba(20, 20, 20, 1) 100%, #242720 100%);
  border: 1px solid #a28d54;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin-bottom: 10px;
  box-shadow: 0px 6px 8px rgba(0, 0, 0, 0.705), 0px 12px 7px rgba(0, 0, 0, 0.5), 0px 9px 12px rgba(0, 0, 0, 0.1);
}

.enemy-character:hover{
  transition: all 0.2s ease-in-out;
  border: 1px solid #a28d54;
  box-shadow: inset 0px 0px 0px 0px rgba(0,0,0,0.6);
}

.encounter img {
  width: 13rem;
  transition: 1s all;
}

.payout-info {
  margin: auto;
  text-align: center;
  padding-top: 1em;
  font-size: 1.5em;
  display: flex;
  justify-content: center;
  align-items: center;
}

.frame-line{
  position: absolute;
  display: flex;
  justify-content: center;
}


.frame-line:hover{
  max-width: 112%;
  opacity: 1;
}


@keyframes resizeUp {
  0%   {
    width: 80%;
    opacity: 0;
  }
  100%  {
    width: 115%;
    opacity: 1;
  }
}


.combat-hints {
  margin: auto;
  text-align: center;
  font-size: 2em;
  display: flex;
  align-items: center;
  justify-content: center;
}

.combat-hints > div{
  display: flex;
  padding-right: 12px;
  padding-left: 12px;
}

.combat-hints > div > .fire-icon,
.combat-hints > div > .earth-icon,
.combat-hints > div > .lightning-icon,
.combat-hints > div > .water-icon{
  max-height: 25px !important;
  max-width: 25px !important;
  width: auto;
  height: auto;
}

.combat-hints .hint {
  margin-left: 50px;
  width: 30px;
}

.waiting {
  font-size: 2em;
  margin: auto;
  text-align: center;
}

.header-row {
  display: flex;
  align-items: center;
}

.header-row h1 {
  margin-left: 10px;
  margin-bottom: 5px;
}

.header-row .hint {
  font-size: 2em;
}

.message-box {
  font-family: Trajan;
  display: flex;
  justify-content: center;
  width: 100%;
  font-size: 2em;
  height: calc(80vh - 150px);
}

div.encounter.text-center {
  flex-basis: auto !important;
}

.encounter-container {
  position: relative;
}

.encounter {
  display: flex;
  justify-content: center;
}

.xp-gain,
.skill-gain {
  color: rgb(158, 138, 87) !important;
  font-family: Roboto;
  font-size: 12px;
}

.encounter-power{
  color: #fff;
  font-size: 1.3rem;
  font-weight: 600;
  margin-top: 1.5rem;
  font-family: Oswald;
}

.chance-winning{
    z-index: 1;
    color: #fff;
    padding: 1px 15px;
    border-radius: 2px;
    font-size: 13px;
    font-family: Oswald;
    text-transform: capitalize;
    position: absolute;
    top: 15px;
    right: 15px;
}

.fight-btn> img{
  width: 22px !important;
}

.fight-btn{
  position:absolute;
  top: 15px;
  left: 15px;
  animation-name: moveUpFade;
  animation-duration: 1s;
}

.modal-body{
  background-image: url('../assets/enemy-bg.png') !important;
}

@keyframes moveUpFade {
  0%   {
    margin-top: 20px;
    opacity: 0;
  }
  100%  {
    margin-top: 10px;
    opacity: 1;
  }
}



.encounter-element {
  top: 25px;
  font-size: 30px;
}

.encounter-element > .icon-border{
  width: 33px;
  height: 33px;
  margin-top: 1px
}

.encounter-power {
  bottom: 60px;
}

.xp-gain {
  bottom: 40px;
  font-size: 1rem;
}

.skill-gain {
  bottom: 20px;
  font-size: 1rem;
}

.victory-chance {
  left: 0;
  right: 0;
  text-align: center;
  font-size: 1.5em;
  text-shadow: -1px 0 #000, 0 1px #000, 1px 0 #000, 0 -1px #000;
}

/* Mobile Support Classes*/
.mobile-divider-wrapper {
  width: 100%;
  display: flex;
}

.mobile-divider {
  margin: auto;
}

.combat-enemy-container {
  display: flex;
  flex-direction: column;
  margin-bottom: 50px;
}

.enemy-container {
  flex: 3;
}

.enemy-list {
  display: flex;
  flex-wrap: wrap;
  padding-left: 30px;
  padding-right: 30px;
}

.enemy-energy {
  top: -30px;
  position: relative;
}


.hideMobile{
  display: none;
}

h1 {
  font-weight: 900 !important;
  text-align: center;
  font-size: 3vw;
  padding-top: 0px;
}

.encounter-button {
  display: block;
  margin: 0 auto;
  height: 5em;
  width: 13em;
  position: relative;
  top: 3vw;
  margin-top: 2em;
}

.enemy-img {
  position: relative;
  top: -30px;
}

.adventure{
    text-align: left;
    margin-top: 30px;
  }

.btn-trigger{
  display: none;
}

@media (max-width: 1334px) {
  .enemy-list {
    flex-flow: row wrap;
    align-items: center;
  }
  .enemy-list > .enemy-list-child{
     flex-basis: 50%;
  }
  .encounter-button {
    margin-top: 1.35em;
  }

}

.message-box  .ct-btn > img{
  width: 30px;
  margin-left: 20px;
}


.message-box  .ct-btn{
  margin-left: 20px;
  background-color: rgba(255, 255, 255, 0);
}

.message-box  .ct-btn:hover{
  margin-top: -10px;
  transition: 0.3s all ease-in-out;
}

.showInMobile{
  display: none;
}

.adventure > img{
  display: none;
}


@media all and (max-width: 600px) {
  .combat-hints > div > .fire-icon,
  .combat-hints > div > .earth-icon,
  .combat-hints > div > .lightning-icon,
  .combat-hints > div > .water-icon {
    max-height: 20px !important;
    max-width: 20px !important;
    width: auto;
    height: auto;
  }

  .hideMobile{
    display: inline;
  }

  .body  > div{
    padding-left: 0px;
  }

  .isMobile{
    display: none;
  }

  .combat-hints > div > .icon-border{
    height: 21px !important;
    width: 21px !important;
  }

  .showInMobile{
    display: inline;
    font-family: Roboto;
    font-size: 11px;
  }

  .adventure{
    display: flex;
    margin-right: 10px;
    justify-content: space-between;
    margin-top: 10px;
  }

  .adventure > h5{
    margin-left: 10px;
  }

  .adventure > img{
    display: inline;
    width: 35px;
    height: 35px;
  }

  .combat-hint{
    display: none;
    z-index: 99;
    background-color:rgba(1, 13, 34,1);
    transition: all 1s ease-in-out;
  }

  .enemy-container {
    flex: none;
    overflow-x: hidden;
    height: 60vh;
  }
  .header-row {
    justify-content: center !important;
  }

  .enemy-character {
    width: 20rem;
  }

  .hideMenu{
    margin-bottom: -120px;
    transition: all 1s ease-in-out;
  }

  .showMenu{
    margin-bottom: 0px;
    transition: all 1s ease-in-out;
  }

  .btn-trigger{
    right: 30px;
    position: absolute;
    width: 20px;
    z-index: 100;
  }

  .btn-trigger{
    display: inline;
  }

  .btn-trigger > img{
    width: 30px;
    margin-left: 0px;
    margin-top: -20px;
    margin-top: -70px;
  }

  .rotateUp{
    transform: rotate(270deg);
    transition: all 1s ease-in-out;
  }

  .rotateDown{
    transform: rotate(90deg);
    transition: all 1s ease-in-out;
  }

  .waitingForResult .col{
    font-family: Trajan;
    font-size: 15px !important;
  }

  .combat-hint{
    position: absolute;
  }

}

/* Needed to asjust image size, not just image column-size and other classes to accommodate that */
@media all and (max-width: 767.98px) {
  .encounter img {
    max-width: 140px;
  }

  .frame-line {
    display: none;
  }

  .enemy-list{
    flex-direction:column;
    align-items:center;
  }
  .combat-enemy-container {
    flex-direction: column;
    align-items: center;
  }
  .results-panel {
    width: 100%;
  }
}
.hint.has-tooltip {
  font-size: 1.8rem;
  display: inline-block;
  margin-left: 10px;
}
.dark-bg-text {
  width: 100% !important;
}
.content {
  padding: 0 !important;
}

.encounter-container {
  margin-bottom: 50px;
}

#gtag-link-others {
  margin: 0 auto;
  display: block;
  position: relative;
  margin-top: 20px;
  width: 100%;
}
.ml-3 {
  margin-left: 0px !important;
}
.header-row {
  display: block;
  text-align: center;
}
#expectedSkillHint{
  margin:0;
  font-size: 1em;
}

.cw-content h4{
    font-family: 'Trajan', serif;
    text-transform: capitalize;
}


.cw-content{
  padding: 40px;
  border: 1px solid #ffffff52;
}
/* --------------------------------- */
.ct-btn{
  padding: 0px;
  height: fit-content;
  border: none !important;
}

.ct-btn:hover{
  border: none !important;
}


.icon-border{
    border: 1px solid #9e8a57;
    height: 27px;
    width: 27px;
    color: #f0f8ff00;
    position: absolute;
    transform: rotate(45deg);
    margin-left: -1px;
    margin-top: -1px;
}


/* enemy card animaton */
.slide-fade-enter-active {
  transition: all 3s ease-in-out;
}

.slide-fade-leave-active {
  transition: all 3s ease-in-out;
  /* transition: all 0.4s cubic-bezier(1, 0.5, 0.8, 1); */
}

.slide-fade-enter-from,
.slide-fade-leave-to {
  transform: translateY(50px);
  opacity: 0;
}

.enemy-name{
  margin-top: 10px;
  font-family: 'Trajan', 'serif';
  font-weight: 600;
}

.waitingForResult{
  height: 90vh;
  position: absolute;
  width: 99%;
  z-index: 98;
}

.waitingForResult .col{
  font-family: Trajan;
    font-size: 25px;
    position: absolute;
    text-align: center;
    bottom: 40vh;
    background: linear-gradient(to right, rgba(255,0,0,0), rgb(0 0 0),rgb(6 0 0 / 0%));
    z-index: 99;
    padding: 20px;
}

.footer-close{
  margin: auto;
}

.footer-close > span{
  cursor: pointer;
}

.footer-close > .tap{
  font-size: 15px;
  color: #fff;
  margin-top: 40px;
  text-align: center;
  margin-left: auto;
  margin-bottom: 20px;
  font-family: Roboto;
}

.vertical-decoration.bottom{
  transform: rotate(0deg) !important;
}

.combat-disabled {
  pointer-events: none;
  opacity: 0.5;
}

@media (max-width: 575.98px) {
  .show-reforged {
    width: 100%;
    justify-content: center;
    display: block;
  }
}
</style>
