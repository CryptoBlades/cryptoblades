<template>
  <div>
    <div>
      <div class="link-text team-fight-btn mb-5 mt-5"
        :class="{'team-fight-button-disabled':
          (timeMinutes === 59 && timeSeconds >= 30) ||
          availableCharactersToFight <= 0}"
      >
        {{$t('combat.teamFight')}}
        <div>
          <b>{{ availableCharactersToFight }}</b>/{{ ownCharacters.length  }}
        </div>
      </div>
    </div>

    <div class="d-flex justify-content-around flex-wrap">
      <div class="d-flex flex-column"
          v-for="c in ownCharacters"
          :key="c.id">
        <li
          class="character"
           :class="[showCosmetics ? 'character-animation-applied-' + getCharacterCosmetic(c.id) : '',
            !charactersWeapon[c.id] || !charHasStamina(c.id) ? 'character-disabled' : '']"
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
          <div
            class="change-enemy-button mt-4 mb-3"
          >
            <img
                v-if="selectedTargetByCharacter[c.id]"
                @click="onClickSelectTarget(c.id)"
                class="select-enemy-icon"
                src="./../../../assets/combat/team-adventure/switch.png"
                width="120" alt="">
          </div>
          <div class="selected-enemy-container mb-5" @click="onClickSelectTarget(c.id)" v-if="charactersWeapon[c.id] && charHasStamina(c.id)">
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
            <div v-else class="text-center">
              <img class="select-enemy-icon" src="./../../../assets/combat/team-adventure/enemy.png" width="200" alt="">
            </div>
          </div>
          <div
            class="selected-enemy-container  mb-5"
            :class="{'disabled': !charactersWeapon[c.id]}"
            v-if="!charactersWeapon[c.id] && charHasStamina(c.id)"
          >
            {{$t('combat.errors.youNeedToHaveWeaponEquippedToCombatYouCanEquipInPlaza')}}
          </div>
          <div class="disabled selected-enemy-container mb-5"  v-if="!charHasStamina(c.id)">
            {{$t('combat.needStamina', {staminaPerFight })}}
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
                    :disabled="(timeMinutes === 59 && timeSeconds >= 30)"
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

    <b-modal
      class="centered-modal"
      ref="last-minute-error-modal"
      ok-only
    >
      <template #modal-title>
        <b-icon icon="exclamation-circle" variant="danger"/> {{$t('combat.warning')}}
      </template>
      <span>
        {{$t('combat.errors.lastSeconds')}}
      </span>
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
    },
    availableCharactersToFight() {
      let availableCharactersCounter = 0;
      for (const key in this.selectedTargetByCharacter) {
        const element = this.selectedTargetByCharacter[key];

        if(element) availableCharactersCounter+=1;
      }

      return availableCharactersCounter;
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
    charHasStamina(characterID: number){
      return this.allStaminas[+characterID] >= this.staminaPerFight;
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
    },
    showLastMinuteErrorModal() {
      if(this.timeMinutes === 59 && this.timeSeconds >= 30) {
        (this.$refs['last-minute-error-modal'] as any).show();
      }
    }
  },
  created() {
    (this.$refs['last-minute-error-modal'] as any).show();
    this.intervalSecondsFn = setInterval(() => {
      this.timeSeconds = new Date().getSeconds();
      this.showLastMinuteErrorModal();
    }, 5000);
    this.intervalMinutesFn = setInterval(() => {
      this.timeMinutes = new Date().getMinutes();
      this.showLastMinuteErrorModal();
    }, 20000);
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

.team-fight-btn {
  cursor: pointer;
  display: flex;
  flex-direction: column;
  height: 100%;
  margin-right: 15px;
  align-items: center;
  vertical-align: middle;
  justify-content: center;
  background-image: url('../../../assets/btn-long.svg');
  background-color: transparent;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  object-fit: fill;
  padding: 10px 40px 10px 40px;
  border: none;
  font-family: Oswald;
  color: #fff;
  font-size: 17px;
  margin: auto;
  margin-right: -40px;
}

.change-enemy-button {
  min-height: 67.56px;
}

.change-enemy-button img {
  cursor: pointer;
}

.selected-enemy-container .select-enemy-icon {
  opacity: 0.3;
}
.selected-enemy-container.disabled {
  cursor: not-allowed;
}

.character-disabled {
  opacity: 0.5;
}

.team-fight-button-disabled {
  opacity: 0.5;
  cursor: not-allowed;
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

.character .art {
  width: 100%;
  min-height: 0;
  height: 18rem;
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
}

.character img {
  object-fit: contain;
}

.character.selected {
  box-shadow: 0 0 8px #ffd400;
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

.frame-line{
  position: absolute;
  display: flex;
  justify-content: center;
}


.frame-line:hover{
  max-width: 112%;
  opacity: 1;
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

.enemy-container {
  flex: 3;
}

.enemy-img {
  position: relative;
  top: -30px;
  z-index: 10;
}

@media all and (max-width: 600px) {
  .enemy-container {
    flex: none;
    overflow-x: hidden;
    height: 60vh;
  }

  .enemy-character {
    width: 20rem;
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
}

.encounter-container {
  margin-bottom: 50px;
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
