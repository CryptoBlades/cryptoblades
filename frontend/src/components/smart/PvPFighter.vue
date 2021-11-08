<template>
  <div class="fighter-container">
      <div class="fighter-inner">
        <div class="fighter-front">
          <char-element
            class="fighter-element"
            v-if="this.show"
            :trait="getCharacterTrait"></char-element>
          <img class="fighter-image" :src="getFighterArt(characterId)"/>
          <div
              v-if="this.show"
              class="fighter-info">
              <div>
              <span class="fighter-name">{{getCharacterName(characterId).toUpperCase()}}</span>
              </div>
              <div>
              <span>Character ID</span>
              <span class="fighter-id">{{characterId}}</span>
              </div>
          </div>
        </div>
        <div class="fighter-back">
          <div
            v-if="this.show"
            class="fighter-header-name">
            <span>{{getCharacterName(characterId).toUpperCase()}}</span>
            <b-row class="fighter-equips">
              <b-col>
                <div class="fighter-weapon">
                  <pvp-weapon
                    v-if="isAttacker"
                    :weapon="this.pvp.attackerFighter.weapon"
                    :inPvP="false"
                    :isEquipContainer="true"></pvp-weapon>
                  <pvp-weapon
                    v-if="!isAttacker"
                    :weapon="this.pvp.defenderFighter.weapon"
                    :inPvP="false"
                    :isEquipContainer="true"></pvp-weapon>
                </div>
              </b-col>
              <b-col>
                <div class="fighter-shield">
                  <pvp-shield
                    v-if="isAttacker"
                    :shield="this.pvp.attackerFighter.shield"
                    :inPvP="false"
                    :isEquipContainer="true"></pvp-shield>
                  <pvp-shield
                    v-if="!isAttacker"
                    :shield="this.pvp.defenderFighter.shield"
                    :inPvP="false"
                    :isEquipContainer="true"></pvp-shield>
                </div>
              </b-col>
            </b-row>
            <b-row>
              <b-col>
                <div class="fighter-combat-details">
                  <b-row class="fighter-level-container" >
                    <b-col>
                      <div>
                        <span class="fighter-combat-details-label">Level</span>
                      </div>
                    </b-col>
                    <b-col>
                      <div>
                        <span class=fighter-combat-details-value>{{characterLevel + 1}}</span>
                      </div>
                    </b-col>
                  </b-row>
                  <b-row class="fighter-combat-tier-container">
                    <b-col>
                      <span class="fighter-combat-details-label">Tier </span>
                    </b-col>
                    <b-col>
                      <div>
                        <span class=fighter-combat-details-value>{{getArenaTier}}</span>
                      </div>
                    </b-col>
                  </b-row>
                  <b-row class="fighter-combat-power-container" >
                    <b-col>
                      <div>
                        <span class="fighter-combat-details-label">Current Power</span>
                      </div>
                    </b-col>
                    <b-col>
                      <div>
                        <span class=fighter-combat-details-value>{{CharacterPower(characterLevel)}}</span>
                      </div>
                    </b-col>
                  </b-row>
                  <b-row class="fighter-trait-bonus-container"
                    v-if="isAttacker">
                    <b-col>
                      <div>
                        <span class="fighter-combat-details-label">Trait Bonus</span>
                      </div>
                    </b-col>
                    <b-col>
                      <div>
                        <span class=fighter-combat-details-value>{{getPvPTraitBonus}}%</span>
                      </div>
                    </b-col>
                  </b-row>
                  <b-row class="fighter-duel-cost-container"
                    v-if="isAttacker">
                    <b-col>
                      <span class="fighter-combat-details-label">Ranking Points</span>
                    </b-col>
                    <b-col>
                      <div>
                        <span class=fighter-combat-details-value>{{getCharacterRankingPoints}}</span>
                      </div>
                    </b-col>
                  </b-row>
                  <b-row class="fighter-wagered-skill-container"
                    v-if="isAttacker">
                    <b-col>
                      <span class="fighter-combat-details-label">Wagered Skill</span>
                    </b-col>
                    <b-col>
                      <div>
                        <span class=fighter-combat-details-value>{{getWageredSkill}}</span>
                      </div>
                    </b-col>
                  </b-row>
                </div>
              </b-col>
            </b-row>
          </div>
        </div>
      </div>

  </div>
</template>

<script>
import { mapGetters, mapState } from 'vuex';
import { getCharacterArtById } from '../../character-arts-placeholder';
import characterSVG from '../../assets/character.svg';
import CharacterElement from '../smart/Element.vue';
import PvPWeapon from './PvPWeapon.vue';
import PvPShield from './PvPShield.vue';
import BN from 'bignumber.js';
import { CharacterPower } from '../../interfaces';

export default {
  props: ['characterId', 'show', 'isAttacker'],

  data(){
    return{
      fighter: null,
      weapon: null,
      duelEarning: '',
      characterLevel: null
    };
  },

  computed: {
    ...mapState(['pvp']),
    ...mapGetters([
      'inPvPCharacters',
      'getCharacterName']),

    getPvPTraitBonus(){
      const traitBonus = new BN(this.pvp.traitBonus).div(new BN(10).pow(18)).toFixed(2);
      return traitBonus;
    },

    getWageredSkill(){
      const wageredSkill = new BN(this.pvp.wageredSkill).div(new BN(10).pow(18)).toFixed(4);
      return wageredSkill;
    },

    getArenaTier(){
      const arenaTier = this.pvp.arenaTier;
      return arenaTier;
    },
    getDuelCost(){
      const duelCost = new BN(this.pvp.duelCost).div(new BN(10).pow(18)).toFixed(4);
      return duelCost;
    },

    getCharacterRankingPoints(){
      const characterRankingPoints = this.pvp.characterRankingPoints;
      return characterRankingPoints;
    },

    getCharacterTrait(){
      if(this.isAttacker){
        return this.pvp.attackerFighter.characterTrait;
      }
      else{
        return this.pvp.defenderFighter.characterTrait;
      }
    }
  },

  methods:{

    getCharacterArtById,

    CharacterPower,

    getFighterArt(characterId){
      if (this.show){
        return getCharacterArtById(characterId);
      }
      return characterSVG;
    },
    getWeaponElementNum(weaponElement){
      if(weaponElement.toUpperCase() === 'FIRE'){
        return '0';
      }
      else if (weaponElement.toUpperCase() === 'EARTH'){
        return '1';
      }
      else if (weaponElement.toUpperCase() === 'LIGHTNING'){
        return '2';
      }
      else if (weaponElement.toUpperCase() === 'WATER'){
        return '3';
      }
    }
  },
  async created(){
    if(this.isAttacker){
      this.characterLevel = await this.$store.dispatch('fetchCharacterLevelForPvP',{ characterID: this.characterId });
    }
    if(this.pvp.defenderFighter.characterID !== null){
      this.characterLevel = await this.$store.dispatch('fetchCharacterLevelForPvP',{ characterID: this.characterId });
    }
    await this.$store.dispatch('fetchPvPTraitBonusAgainst',{
      characterTrait: this.pvp.attackerFighter.characterTrait,
      weaponTrait: this.getWeaponElementNum(this.pvp.attackerFighter.weapon.element),
      opponentTrait: this.pvp.defenderFighter.characterTrait
    });
  },

  components: {
    'char-element': CharacterElement,
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield
  }
};
</script>

<style>
.arena-header-label {
  font-size: 12px;
  color: #968332;
}

.fighter-container {
  margin: auto;
  height: 450px;
  width: 300px;
  perspective: 1000px;
}

.fighter-inner {
  position: relative;
  width: 100%;
  height: 100%;
  text-align: center;
  transition: transform 0.4s;
  transform-style: preserve-3d;
  box-shadow: 0 4px 20px rgba(255, 255, 255, 0.2);
}

.fighter-container:hover .fighter-inner {
  transform: rotateY(180deg);
}

.fighter-front, .fighter-back {
  position: absolute;
  width: 100%;
  height: 100%;
  -webkit-backface-visibility: hidden;
  backface-visibility: hidden;
  border: 2px solid #968332;
  background-color: transparent;
}

.fighter-front {
  background-image: url('../../assets/cardCharacterFrame.png');
  background-repeat: no-repeat;
  background-size: cover;
  background-position: center;
}

.fighter-image {
  margin: 20px auto;
  height: 250px;
  width: 125px;
}

.fighter-element {
  margin-top: 20px;
}

.fighter-name {
  text-align: left;
  color: #fff;
  font-weight: bold;
  font-size: 16px;
}

.fighter-id {
  margin-left: 10px;
  text-align: left;
  color: #fff;
  font-weight: bold;
  font-size: 16px;
}

.fighter-header-name {
  margin: 20px auto;
  color: #fff;
  font-weight: bold;
  font-size: 20px;
}

.fighter-back {
  color: #fff;
  transform: rotateY(180deg);
}

.fighter-equips {
  margin-top: 20px;
}

.fighter-weapon {
  border: 2px solid #968332;
  border-radius: 10%;
  margin: auto;
  height: 80px;
  width: 80px;
}

.fighter-shield {
  border: 2px solid #968332;
  border-radius: 10%;
  margin: auto;
  height: 80px;
  width: 80px;
}

.fighter-combat-details {
  border-top: 1px solid #968332;
  width: 90%;
  height: 200px;
  margin: 20px auto;
}


.fighter-combat-details-label {
  font-size: 14px;
  font-weight: bolder;
  color: #968332;
}

.fighter-combat-details-value {
  font-size: 15px;
  color: #fff;
}


</style>
