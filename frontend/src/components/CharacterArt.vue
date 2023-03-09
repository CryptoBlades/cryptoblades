<template>
  <div class="character-art" ref="el">
    <!-- CHAR IMAGE -->
    <div class="placeholder d-flex align-items-start justify-content-center p-1">
      <div class="character-id">
        # {{ character.id }}
      </div>
      <span v-if="isSelected" class="rounded-check"></span>
      <div class="char-bg" :style="{
        'background-image': 'url(' + getCharacterArt(character) + ')',
      }">
      </div>
    </div>

    <div class="char-details">
      <h4>{{ getCleanCharacterName(character.id).toUpperCase() }}</h4>
      <p v-if="reputationLevelRequirements">
        {{$t(`quests.reputationTier.${ReputationTier[getReputationLevel(reputation)]}`)}}
      </p>
      <div class="sep-line"></div>
      <div class="stats-info">
        <div>
          <span :class="characterTrait.toLowerCase() + '-icon circle-element'"></span>
          <span>{{ character.level + 1 }}</span>
        </div>
        <div>
          <div>
            <span class="pow"></span>
            <span class="lbl-title"  v-tooltip.bottom="$t('CharacterArt.powerTooltip', {
              basePower: baseCharacterPower,
              bonusPower: totalCharacterPower - baseCharacterPower,
              maxPower: 3 * baseCharacterPower
            })">{{$t('homePage.power')}}</span>
            <div class="stamina-bar">
              <div class="stamina" :style="'width:'+(totalCharacterPower/totalCharacterPower)*100+'%'"></div>
            </div>
            <span class="lbl-value">{{totalCharacterPower.toLocaleString()}}</span>
          </div>

          <div v-tooltip.bottom="` ${$t('CharacterArt.claimableXP')} ${this.getCharacterUnclaimedXp(character.id)}`">
            <span class="exp"></span>
            <span class="lbl-title">{{$t('Character.exp')}}</span>
            <div class="stamina-bar">
              <div class="stamina" :style="'width:'+((character.xp || 0) / (RequiredXp(character.level + 1 || 0) || 1))*100+'%'"></div>
            </div>
            <span class="lbl-value">{{RequiredXp(character.level + 1 || 1).toLocaleString()}}</span>
          </div>

          <div v-tooltip.bottom="staminaToolTipHtml(timeUntilCharacterHasMaxStamina(character.id))">
            <span class="stam"></span>
            <span class="lbl-title">{{$t('homePage.stamina')}}</span>
            <div class="stamina-bar">
              <div class="stamina" :style="'width:'+(characterStamina/maxStamina)*100+'%'"></div>
            </div>
            <span class="lbl-value">{{ characterStamina }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getCharacterArt } from '../character-arts-placeholder';
import { CharacterTrait, RequiredXp } from '../interfaces';
import { getCleanName } from '../rename-censor';
import { CharacterPower } from '@/interfaces';
import { ReputationTier } from '@/enums/Quest';
import { burningManager } from './../feature-flags';
import { mapState, mapGetters, mapActions } from 'vuex';

export default {
  props: ['character', 'portrait', 'isGarrison', 'hideXpBar', 'hideIdContainer', 'isSelected'],
  watch: {
    character() {
      this.refreshData();
    },
  },

  data() {
    return {
      ReputationTier,
      reputationLevelRequirements: undefined,
      quest: null,
      trait: this.characterTrait,
      heroScore: 0,
      CharacterPower,
      burningManager
    };
  },

  computed: {
    ...mapState(['maxStamina', 'characterStaminas']),
    ...mapGetters([
      'getCharacterName',
      'getCharacterUnclaimedXp',
      'timeUntilCharacterHasMaxStamina',
      'charactersWithIds',
      'garrisonCharactersWithIds',
      'getCharacterPower'
    ]),

    reputation() {
      return this.quest?.reputation ?? 0;
    },

    characterTrait() {
      const characterWithId = this.charactersWithIds &&
        this.isGarrison ? this.garrisonCharactersWithIds([this.character.id])[0] : this.charactersWithIds([this.character.id])[0];
      return characterWithId && CharacterTrait[characterWithId.trait] || CharacterTrait[this.character.trait];
    },

    characterStamina() {
      return this.isGarrison ? this.characterStaminas[this.character.id] : this.timestampToStamina(this.character.staminaTimestamp);
    },

    totalCharacterPower() {
      return this.getCharacterPower(this.character.id);
    },

    baseCharacterPower() {
      return CharacterPower(this.character.level);
    }
  },

  methods: {
    ...mapActions([
      'getReputationLevelRequirements',
      'getCharacterQuestData'
    ]),
    RequiredXp,
    getCleanCharacterName(id) {
      return getCleanName(this.getCharacterName(id));
    },

    staminaToolTipHtml(time) {
      return this.$t('CharacterArt.staminaTooltip') + time;
    },

    timestampToStamina(timestamp) {
      if(timestamp > Math.floor(Date.now()/1000)) return 0;
      return +Math.min((Math.floor(Date.now()/1000) - timestamp) / 300, 200).toFixed(0);
    },
    getReputationLevel(reputation) {
      if (!this.reputationLevelRequirements) return;
      if (reputation < this.reputationLevelRequirements.level2) {
        return ReputationTier.PEASANT;
      } else if (reputation < this.reputationLevelRequirements.level3) {
        return ReputationTier.TRADESMAN;
      } else if (reputation < this.reputationLevelRequirements.level4) {
        return ReputationTier.NOBLE;
      } else if (reputation < this.reputationLevelRequirements.level5) {
        return ReputationTier.KNIGHT;
      } else {
        return ReputationTier.KING;
      }
    },
    async refreshData(){
      this.reputationLevelRequirements =  await this.getReputationLevelRequirements();
      this.quest = await this.getCharacterQuestData({characterId: this.character.id});
    },
    getCharacterArt
  },
  async mounted() {
    await this.refreshData();
  },
};
</script>

<style scoped>
.character-art {
  width: 100%;
  height: 100%;
  /* position: relative; */
  display: flex;
  justify-content: space-between;
  flex-direction: column;
}

.trait {
  top: -30px;
  justify-self: center;
  margin: 0 auto;
  position: relative;
  display: flex;
}

.id {
  top: 5px;
  right: 5px;
  font-style: italic;
}

.hero-score {
  top: 25px;
  right: 5px;
  font-style: italic;
}

.name {
  font-weight: 900;
  overflow: hidden;
  max-height: 24px;
  max-width: 170px;
  white-space: nowrap;
}

.xp {
  position: absolute;
  bottom: -30px;
  left: 30px;
  width: 150px;
  right: 0;
}

.xp-text {
  padding-top: 7px;
  width: 100%;
  text-align: center;
  position: absolute;
}

.placeholder {
  max-width: 200%;
  top: -15px;
  position: relative;
  height: 75%;
  padding-top: 0;
  -o-object-fit: contain;
  object-fit: contain;
}

.char-details{
  background: linear-gradient(to bottom, rgba(0, 0, 0, 0.123), rgba(0, 0, 0, 0.897));
  height: 40%;
  width: 100%;
  z-index: 2;
  bottom: 0;
  position: absolute;
  display: flex;
  flex-direction: column;
  padding: 5px 20px;
  padding-bottom: 0px;
}

.char-details > h4, .char-details > p{
  margin: 0;
  padding: 0;
}

.char-details >  h4{
  font-size: 1.2em;
  font-weight: 400;
  color: #fff;
  font-family: Oswald;
}

.char-details > p{
  font-family: Roboto;
  font-size: 0.9em;
  color: #EDCD90;
}

.sep-line{
  height: 1px;
  width: 100%;
  background-color:#edcc9069;
  margin: 7px 0px;
}

.stats-info{
  display: flex;
  gap: 0.5em;
}

.stats-info > div:nth-child(1){
  display: flex;
  flex-direction: column;
}



.rounded-check{
  content: url('../assets/check-round.svg');
  height: 1.5em;
  width: 1.5em;
  z-index: 3;
  right: 20px;
  top: -5px;
  position: absolute;
}


.stats-info > div:nth-child(1) >span:nth-child(2){
  color: #fff;
  font-family: Roboto;
  border: 2px solid #EDCD90;
  height: 28px;
  width: 28px;
  margin-top: 5px;
  border-radius: 50%;
  text-align: center;
  font-size: 0.78em;
  display: flex;
  align-items: center;
  justify-content: center;
}

.stats-info > div:nth-child(2){
  flex-grow: 2;
  display: flex;
  justify-content: space-between;
  flex-direction: column;
}

.stats-info > div:nth-child(2) > div{
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 0.5em;
}

.stats-info > div:nth-child(2) > div > .lbl-title,
.stats-info > div:nth-child(2) > div > .lbl-value{
  width: 50%;
}

.stamina-bar{
  height: 3px;
  width: 100%;
  background-color:cadetblue;
  border-radius: 5px;
}

.stamina{
  position: relative;
  height: 3px;
  width: 0%;
  background-color: #EDCD90;
  border-radius: 5px;
}

.lbl-value, .lbl-title{
  font-size: 0.7em;
  color: #fff;
  font-family: Roboto;
}

.lbl-value{
  color: rgba(255, 255, 255, 0.411);
  text-align: right;
}

.character-id{
  position: absolute;
  padding: 2px 10px;
  background-color: rgba(0, 0, 0, 0.308);
  color: rgba(255, 255, 255, 0.589);
  border-radius: 5px;
  font-family: Roboto;
  font-size: 0.8em;
  left: 1.3em;
  top: -13px;
  margin-top: -30px;
}

.char-bg{
  height: 220%;
  width: 300%;
}

.placeholder div{
  margin-top: 5px;
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center;
}

.circle-element {
  width: 1.7em;
  height: 1.7em;
  border-radius: 50%;
  border: 2px solid #EDCD90;
  padding: 4px;
}

.name-lvl-container, .score-id-container {
  display :flex;
  justify-content: space-around;
  position: relative;
}

.white {
  color : rgb(204, 204, 204)
}

.small-stamina-char {
  position: relative;
  margin-top: -10px;
  top: 7px;
  align-self: center;
  height :14px;
  width: 180px;
  border-radius: 2px;
  border: 0.5px solid rgb(216, 215, 215);
  background : linear-gradient(to right, rgb(236, 75, 75) var(--staminaReady), rgba(255, 255, 255, 0.1) 0);
}

.stamina-text {
  position: relative;
  top: -3px;
  font-size: 75%;
  left: 0;
  right: 0;
  text-align: center;
  color: #fff;
}

.character-power {
  position: absolute;
  left: 4px;
  top: 4px;
  font-size: 0.82em;
}

.pow{
  content: url('../assets/pow-icon.svg');
  height: 0.7em;
  width: 0.7em;
}

.exp{
  content: url('../assets/exp-icon.svg');
  height: 0.7em;
  width: 0.7em;
}

.stam{
  content: url('../assets/stamina-icon.svg');
  height: 0.7em;
  width: 0.7em;
}

</style>
