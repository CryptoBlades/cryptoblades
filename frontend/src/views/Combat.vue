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
            class="m-2 d-inline combat-tab active-tab text-uppercase">
            {{$t('combat.teamAdventure')}}
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
          :staminaPerFight="staminaPerFight"
          @error="onErrorChanged"
          @errorCode="onErrorCodeChanged"
        >
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

.adventure{
  text-align: left;
  margin-top: 30px;
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

  .combat-hint{
    position: absolute;
  }
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
</style>
