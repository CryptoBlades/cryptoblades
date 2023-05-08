<template>
  <div>
    <div class="d-flex justify-content-around">
      <div class="d-flex flex-column"
          v-for="c in ownCharacters"
          :key="c.id">
        <li
          class="character"
          :class="[showCosmetics ? 'character-animation-applied-' + getCharacterCosmetic(c.id) : '', !charactersWeapon[c.id] ? 'character-disabled' : '']"
          :id="c.traitName.toLowerCase()"
        >
          <div class="backdrop-bg"></div>
            <div class="art" >
              <div class="animation" />
              <CharacterArt :class="[showCosmetics ? 'character-cosmetic-applied-' + getCharacterCosmetic(c.id) : '']"
                :character="c"/>
            </div>
        </li>
        <div class="text-center mt-4">
          <div class="selected-enemy-container" @click="onClickSelectTarget(c.id)" v-if="charactersWeapon[c.id]">
            <div v-if="selectedTargetByCharacter[c.id]">
              <div>
                <div class="selected-encounter-element">
                  <span :class="getCharacterTrait(selectedTargetByCharacter[c.id].trait).toLowerCase() + '-icon'" />
                  <span class="icon-border" style="margin-left: -31.5px">.</span>
                </div>
                <div class="chance-winning" :style="changeColorChange(
                  getWinChance(selectedTargetByCharacter[c.id].power, selectedTargetByCharacter[c.id].trait)
                )">
                  {{ getWinChance(selectedTargetByCharacter[c.id].power, selectedTargetByCharacter[c.id].trait).toUpperCase() }}
                  {{$t('combat.victory').toUpperCase()}}
                </div>
              </div>
              <div class="text-center" v-if="selectedTargetByCharacter[c.id]">
                <img class="mx-auto enemy-img" :src="getEnemyArt(selectedTargetByCharacter[c.id].power)" width="125" :alt="$t('combat.enemy')" />
              </div>
              <div>
                <div class="selected-enemy-power">
                  {{$t('combat.power').toUpperCase()}} : {{ selectedTargetByCharacter[c.id].power.toLocaleString() }}
                </div>

                <div class="xp-gain">
                  +{{getPotentialXp(selectedTargetByCharacter[c.id])}} {{$t('combat.xp')}}
                </div>

                <div class="skill-gain mb-1">
                  + {{formattedSkill(+selectedTargetByPayout[c.id] * fightMultiplier)}}
                </div>
              </div>
            </div>
          </div>
          <div
            class="selected-enemy-container"
            :class="{'disabled': !charactersWeapon[c.id]}"
            v-if="!charactersWeapon[c.id]"
          >
            {{$t('combat.errors.youNeedToHaveWeaponEquippedToCombatYouCanEquipInPlaza')}}
          </div>
        </div>
      </div>
    </div>

    <b-modal
    size="xl"
    class="centered-modal"
    ref="select-target-modal"
    :title="$t('needGasModal.title')"
    >
      <transition-group
          appear @before-enter="beforeEnter" @enter="enter"
          :key="2"
          class="row mb-3 enemy-container" v-if="selectedCharacterTargets.length > 0">
        <div class="col-12 col-md-6 col-lg-6 col-sm-6 col-xl-3 encounter" v-for="(e, i) in selectedCharacterTargets" :key="e.original" :data-index="i">
          <div class="encounter-container">
              <div  class="enemy-character"
                    @mouseover="activeCard = i"
                    @click="onSelectTargetEnemy(e)"
                    :disabled="(timeMinutes === 59 && timeSeconds >= 30) ||!charHasStamina()"
                  >

                  <div class="frame-line" v-if="activeCard === i">
                    <img style="width: 20rem; height: 35rem;" src="../../../assets/frame-line-3.png" alt="">
                  </div>

                  <div class="fight-btn" v-if="activeCard === i">
                    <img src="../../../assets/fight.png" alt="">
                  </div>

                  <div class="chance-winning" :style="changeColorChange(getWinChance(e.power, e.trait))">
                    {{ getWinChance(e.power, e.trait).toUpperCase() }}
                    {{$t('combat.victory').toUpperCase()}}
                  </div>

                  <div class="text-center">
                    <img class="mx-auto enemy-img" :src="getEnemyArt(e.power)" :alt="$t('combat.enemy')" />
                  </div>

                  <div class="encounter-element">
                    <span :class="getCharacterTrait(e.trait).toLowerCase() + '-icon'" />
                    <span class="icon-border" style="margin-left: -31.5px" :style="activeCard === i ? 'border:2px solid #9e8a57': ''">.</span>
                  </div>

                  <div class="encounter-power pt-2">
                      {{$t('combat.power').toUpperCase()}} : {{ e.power.toLocaleString() }}
                  </div>

                  <div class="xp-gain">
                    +{{getPotentialXp(e)}} {{$t('combat.xp')}}
                  </div>

                  <div class="skill-gain mb-1">
                    + ~{{formattedSkill(+targetExpectedPayouts[i] * fightMultiplier)}}
                  </div>
              </div>
              <p v-if="isLoadingTargets">{{$t('loading')}}</p>
          </div>
        </div>
      </transition-group>
    </b-modal>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {getEnemyArt} from '../../../enemy-art';
import CharacterArt from '../../CharacterArt.vue';
import { Accessors } from 'vue/types/options';
import { mapActions, mapGetters } from 'vuex';
import { CharacterTrait, ICharacter, IPowerData, ITarget } from '@/interfaces';
import gasp from 'gsap';
import i18n from '@/i18n';
import { fromWeiEther, toBN } from '@/utils/common';

interface StoreMappedCombatGetters {
  getTargetsByCharacterId(currentCharacterId: number): ITarget | any[],
}

interface StoreMappedCombatActions {
  fetchTargets(
    { characterId }:
    { characterId: number }): Promise<void>;
  fetchExpectedPayoutForMonsterPower(
    { power }:
    { power: stringOrNumber }): Promise<string>;
  getFightXpGain(): Promise<number>;
}

type stringOrNumber = string | number;

interface ITeamAdventureData {
  showCosmetics: boolean,
  selectedCharacterPowerData: IPowerData;
  selectedCharacterID: number,
  selectedCharacterTargets: any[] | ITarget,
  selectedTargetByCharacter: Record<number, ITarget>
  selectedTargetByPayout: Record<number, stringOrNumber>,
  charactersWeapon: Record<number, number>,
  // eslint-disable-next-line no-undef
  intervalSecondsFn: NodeJS.Timeout | null;
  // eslint-disable-next-line no-undef
  intervalMinutesFn: NodeJS.Timeout | null;
  timeSeconds: number;
  timeMinutes: number;
  activeCard: number;
  fightXpGain: number;
  targetExpectedPayouts: Record<number, stringOrNumber>
  isLoadingTargets: boolean,
}

interface StoreMappedGetters {
  ownCharacters: Array<ICharacter>,
  allStaminas: Record<number, number>;
  getPowerData(characterId: number): IPowerData;
}

interface StoreMappedActions{
  fetchCharacterWeapon(characterId: string | number): Promise<number>;
}

export default Vue.extend({
  props:{
    fightMultiplier: {
      default:  Number(localStorage.getItem('fightMultiplier')),
      required: true
    },
    staminaPerFight: {
      default: 40,
      required: true
    }
  },
  data() {
    return {
      showCosmetics: false,
      selectedCharacterPowerData: {} as IPowerData,
      selectedCharacterID: -1,
      selectedCharacterTargets: [],
      charactersWeapon: {},
      intervalMinutesFn: null,
      intervalSecondsFn: null,
      timeMinutes: 0,
      timeSeconds: 0,
      activeCard: -1,
      fightXpGain: 32,
      targetExpectedPayouts: {},
      isLoadingTargets: false,
      selectedTargetByCharacter: {},
      selectedTargetByPayout: {}
    } as ITeamAdventureData;
  },
  computed: {
    ...(mapGetters([
      'ownCharacters',
      'getCharacterCosmetic',
      'allStaminas',
      'getPowerData'
    ]) as Accessors<StoreMappedGetters>),
    ...(mapGetters('combat', [
      'getTargetsByCharacterId'
    ]) as Accessors<StoreMappedCombatGetters>),
    isGenesisCharacter(): boolean {
      const currentCharacter = this.ownCharacters[this.selectedCharacterID];

      return currentCharacter?.version === 0;
    }
  },
  components: {
    CharacterArt
  },
  methods: {
    ...(mapActions('combat',
      [
        'fetchTargets',
        'getFightXpGain',
        'fetchExpectedPayoutForMonsterPower'
      ]) as StoreMappedCombatActions),
    ...mapActions(['fetchCharacterWeapon']) as StoreMappedActions,
    getEnemyArt,
    checkStorage() {
      this.showCosmetics = localStorage.getItem('showCosmetics') !== 'false';
    },
    getCharacterTrait(trait: CharacterTrait) {
      return CharacterTrait[trait];
    },
    formattedSkill(skill: stringOrNumber) {
      const skillBalance = fromWeiEther(skill.toString());
      return `${toBN(skillBalance).toFixed(6)} ${this.isGenesisCharacter ? 'SKILL' : 'VALOR'}`;
    },
    async onClickSelectTarget(selectedCharacterID: number) {
      this.isLoadingTargets = true;
      this.selectedCharacterID = selectedCharacterID;
      (this.$refs['select-target-modal'] as any).show();
      await this.fetchTargets({characterId: this.selectedCharacterID});
      this.selectedCharacterTargets = await this.getTargetsByCharacterId(+this.selectedCharacterID);

      this.selectedCharacterPowerData = this.getPowerData(+this.selectedCharacterID);
      await this.getExpectedPayouts();
      this.isLoadingTargets = false;
    },
    async onSelectTargetEnemy(target: ITarget) {
      Vue.set(this.selectedTargetByCharacter, this.selectedCharacterID, target);
      (this.$refs['select-target-modal'] as any).hide();
      await this.getExpectedPayoutsByCharacterTarget(this.selectedCharacterID);
    },
    async getExpectedPayouts() {
      if(!this.selectedCharacterTargets) return;
      const expectedPayouts = new Array(4);
      const targets = this.selectedCharacterTargets as ITarget[];
      for(let i = 0; i < targets.length; i++) {
        const expectedPayout = await this.fetchExpectedPayoutForMonsterPower({ power: targets[i].power });
        expectedPayouts[i] = expectedPayout;
        Vue.set(this.targetExpectedPayouts, i, expectedPayouts[i]);
      }
    },
    async getExpectedPayoutsByCharacterTarget(characterID: number) {
      const target = this.selectedTargetByCharacter[characterID];

      const expectedPayout = await this.fetchExpectedPayoutForMonsterPower({ power: target.power });
      console.log(expectedPayout);
      Vue.set(this.selectedTargetByPayout, characterID, expectedPayout);
    },
    enter(el: HTMLElement, done: any) {
      gasp.to(el, {
        opacity: 1,
        y: 0,
        duration: 0.5,
        onComplete: done,
        delay: el.dataset.index as any * 0.1
      });
    },
    beforeEnter(el: HTMLElement){
      el.style.opacity = '0';
      el.style.transform = 'translateY(100px)';
    },
    charHasStamina(){
      return this.allStaminas[+this.selectedCharacterID] >= this.staminaPerFight;
    },
    changeColorChange(stat: string){
      let bgColor;
      if(stat.toUpperCase() === 'UNLIKELY'){
        bgColor =  'background-color: #B10000 !important';
      }else if(stat.toUpperCase() === 'VERY LIKELY'){
        bgColor =  'background-color: #7BA224 !important';
      }else if(stat.toUpperCase() === 'POSSIBLE'){
        bgColor =  'background-color: #D16100 !important';
      }else{
        bgColor = 'background-color: #ff7700 !important';
      }
      return bgColor;
    },
    getWinChance(enemyPower: number, enemyElement: number) {
      const totalMultipliedPower = this.selectedCharacterPowerData.pvePower[enemyElement];
      const playerMin = totalMultipliedPower * 0.9;
      const playerMax = totalMultipliedPower * 1.1;
      const playerRange = playerMax - playerMin;
      const enemyMin = enemyPower * 0.9;
      const enemyMax = enemyPower * 1.1;
      const enemyRange = enemyMax - enemyMin;
      let rollingTotal = 0;
      // shortcut: if it is impossible for one side to win, just say so
      if (playerMin > enemyMax) return i18n.t('combat.winChances.veryLikely');
      if (playerMax < enemyMin) i18n.t('combat.winChances.unlikely');

      // case 1: player power is higher than enemy power
      if (playerMin >= enemyMin) {
        // case 1: enemy roll is lower than player's minimum
        rollingTotal = (playerMin - enemyMin) / enemyRange;
        // case 2: 1 is not true, and player roll is higher than enemy maximum
        rollingTotal += (1 - rollingTotal) * ((playerMax - enemyMax) / playerRange);
        // case 3: 1 and 2 are not true, both values are in the overlap range. Since values are basically continuous, we assume 50%
        rollingTotal += (1 - rollingTotal) * 0.5;
      } // otherwise, enemy power is higher
      else {
        // case 1: player rolls below enemy minimum
        rollingTotal = (enemyMin - playerMin) / playerRange;
        // case 2: enemy rolls above player maximum
        rollingTotal += (1 - rollingTotal) * ((enemyMax - playerMax) / enemyRange);
        // case 3: 1 and 2 are not true, both values are in the overlap range
        rollingTotal += (1 - rollingTotal) * 0.5;
        //since this is chance the enemy wins, we negate it
        rollingTotal = 1 - rollingTotal;
      }
      if (rollingTotal <= 0.3) return i18n.t('combat.winChances.unlikely');
      if (rollingTotal <= 0.5) return i18n.t('combat.winChances.possible');
      if (rollingTotal <= 0.7) return i18n.t('combat.winChances.likely');
      return i18n.t('combat.winChances.veryLikely');
    },
    getPotentialXp(targetToFight: ITarget) {
      const totalPower = this.selectedCharacterPowerData.pvePower[4]; // using base power
      //Formula taken from getXpGainForFight funtion of cryptoblades.sol
      return Math.floor((targetToFight.power / totalPower) * this.fightXpGain) * this.fightMultiplier;
    },
    async getCharactersWeapon() {
      for (let i = 0; i < this.ownCharacters.length; i++) {
        const character = this.ownCharacters[i];
        const weapon = await this.fetchCharacterWeapon(character.id);
        Vue.set(this.charactersWeapon, character.id, weapon);
      }
    }
  },
  created() {
    this.intervalSecondsFn = setInterval(() => (this.timeSeconds = new Date().getSeconds()), 5000);
    this.intervalMinutesFn = setInterval(() => (this.timeMinutes = new Date().getMinutes()), 20000);
    this.checkStorage();
  },
  async mounted() {
    this.fightXpGain = await this.getFightXpGain();
    await this.getCharactersWeapon();
  },
  beforeDestroy() {
    if(this.intervalSecondsFn)
      clearTimeout(this.intervalSecondsFn);
    if(this.intervalMinutesFn)
      clearTimeout(this.intervalMinutesFn);
  }
});
</script>

<style scoped>
@import '../../../styles/character-cosmetics.css';

.selected-enemy-container.disabled {
  cursor: not-allowed;
}

.character-disabled {
  opacity: 0.5;
}

.selected-encounter-element {
  top: 10px;
  left: 20px;
  font-size: 30px;
  position: absolute;
}

.selected-encounter-element > .icon-border{
  width: 33px;
  height: 33px;
  margin-top: 1px
}


.selected-enemy-container {
  height: 300px;
  width: 270px;
  display: flex;
  justify-content: center;
  align-items: center;
  border: #ccae4f dashed 2px;
  border-radius: 5px;
  position: relative;
  cursor: pointer;
}

.selected-enemy-power{
  color: #fff;
  font-size: 1rem;
  font-weight: 600;
  font-family: Oswald;
}

.filters {
   justify-content: space-between;
   width: 100%;
   margin: 0 auto;
   align-content: center;
   border-bottom: 0.2px solid rgba(102, 80, 80, 0.1);
   margin-bottom: 20px;
}

.character-list {
  list-style-type: none;
  margin: 0;
  padding: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 16em);
  gap: 2.5em;
  padding-left: 2em;
  padding-right: 2em;
  justify-content: center;
  padding-bottom: 2em;
}

.character-list-container{
  border: 1px solid #333;
  border-radius: 10px;
}

.character-list-container > .filters{
  border-bottom: 1px solid #333;
}

.character-list-container > .row.filters{
  max-width: 100%;
}

.filters > div {
  display: flex;
  gap: 2em;
  padding:1em;
}

.filters > div:nth-child(2){
  gap: 0em;
  justify-content: flex-end;
}

.select-wrapper-no > select.form-control,
.select-wrapper-element > select.form-control{
  background-color: rgba(0, 0, 0, 0);
  width: 200px;
  font-family: Roboto;
  color: rgb(128, 128, 128);
}

.select-wrapper-no:after {
  content: attr(data-content);
  width: 0;
  height: 0;
  border-top: 6px solid #666;
  position: absolute;
  left: 55px;
  top: 50px;
  font-family: Roboto;
  color: rgba(255, 255, 255, 0.541);
}

.select-wrapper-element:after {
  content: attr(data-content);
  width: 0;
  height: 0;
  border-top: 6px solid #666;
  position: absolute;
  margin-left: 10px;
  top: 50px;
  font-family: Roboto;
  color: rgba(255, 255, 255, 0.541);
}

.select-wrapper-no > select.form-control option,
.select-wrapper-element > select.form-control option{
  background-color: #171617;
  padding: 1px;
  color: #fff;
  font-family: Roboto;
  text-align: right;
}

.select-wrapper-no > select.form-control, .select-wrapper-element > select.form-control {
  text-align: right;
}

.mobile-filter{
  display: flex;
  align-items: center;
  text-align: center;
  justify-content: center;
}

.mobile-filter > span.filter{
  content: url('../../../assets/filter-circle.svg');
  height: 2em;
  width: 2em;
  margin-top: 1em;
}

.character {
  position: relative;
  width: 17em;
  height: 23em;
  background-position: center;
  background-repeat: no-repeat;
  background-size: 115%;
  /* background-color: #2e2e30cc; */
  background-image: url('../../../assets/background/earth-bg.png');
  border: 1px solid #a28d54;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  overflow: hidden;
}

.backdrop-bg{
  /* background-image: linear-gradient(to bottom, rgba(0, 0, 0, 0.082),  rgba(0, 0, 0, 0.466), rgba(0, 0, 0, 0.466)); */
  background-color: rgba(0, 0, 0, 0.267);
  position: absolute;
  left: 0;
  top: 0;
  height: 100%;
  width: 100%;
}

#earth{
  background-image: url('../../../assets/background/earth-bg.png');
}
#water{
  background-image: url('../../../assets/background/water-bg.png');
}
#lightning{
  background-image: url('../../../assets/background/lightning-bg.png');
}
#fire{
  background-image: url('../../../assets/background/fire-bg.png');
}

.character .art {
  width: 100%;
  min-height: 0;
  height: 18rem;
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
}

.valign-middle {
  vertical-align: middle;
}

.character img {
  object-fit: contain;
}

.character.selected {
  box-shadow: 0 0 8px #ffd400;
}

.above-wrapper-nft-display,
.above-wrapper {
  position: absolute;
  top: 270px;
  left: 0;
  right: 0;
  z-index: 100;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
}

.above-wrapper-nft-display {
  top: 220px;
}

@media (max-width: 576px) {
  .character-list {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  .clear-filters-button {
    width: 100%;
    text-align: center;
    justify-content: center;
    margin: 0px;
    padding: 8px 20px;
  }

  .clear-filters-button > span{
    font-family: Roboto;
  }

  .select-wrapper-no > select.form-control, .select-wrapper-element > select.form-control {
    background-color: rgba(0, 0, 0, 0);
    width: 100%;
    font-family: Roboto;
    color: rgb(128, 128, 128);
  }

  .filter-title > h4{
    font-family: Trajan;
    color: #EDCD90;
    text-align: center;
  }

  .select-wrapper-no > span,.select-wrapper-element > span{
    font-size: 0.9em;
    font-family: Roboto;
    color: #fff;
    margin-bottom: 10px;
  }
}

.sold {
  height: 40px;
  width: 300px;
  background-color: rgb(187, 33, 0);
  transform: rotate(30deg);
  left: -40px;
  position: absolute;
  top: 150px;
  z-index: 100;
}

.sold span {
    text-align: center;
    width: auto;
    color: white;
    display: block;
    font-size: 30px;
    font-weight: bold;
    line-height: 40px;
    text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
    text-transform: uppercase;
}

.fix-h24 {
  height: 24px;
}

.nft-options {
  position: absolute;
  right: 0;
  top: 0;
}







@import url('https://fonts.googleapis.com/css2?family=Cardo:ital,wght@0,400;0,700;1,400&display=swap');
.custom-select{
  background-color:#010D22;
  color:#fff
}
.body{
  background: linear-gradient(0deg, rgba(0, 14, 41, 0.68), rgba(0, 14, 41, 0.68)), url('../../../assets/combat-bg.png');
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
  background-image: url('../../../assets/enemy-bg-transparent.png');
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
  background-image: url('../../../assets/enemy-bg.png') !important;
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
  z-index: 10;
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
