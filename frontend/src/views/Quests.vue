<template>
  <div class="d-flex flex-column quests-container">
    <div v-for="c in filteredCharacters" :key="c.id" class="row quest-row">
      <div class="character"
           :class="[showCosmetics ? 'character-animation-applied-' + getCharacterCosmetic(c.id) : undefined]">
        <div class="above-wrapper" v-if="$slots.above || $scopedSlots.above">
          <slot name="above" :character="c"></slot>
        </div>
        <slot name="sold" :character="c"></slot>
        <div class="art">
          <div class="animation"/>
          <CharacterArt
            :class="[showCosmetics ? 'character-cosmetic-applied-' + getCharacterCosmetic(c.id) : undefined]"
            :character="c" :hideIdContainer="true" :hideXpBar="true"/>
        </div>
        <div class="xp">
          <span>Reputation lvl {{ reputationLevel }}</span>
          <strong class="outline xp-text">{{ currentReputation || 0 }} / {{ maxReputation }}</strong>
          <b-progress class="reputation-progress" :max="maxReputation" :value="currentReputation" variant="primary"/>
        </div>
      </div>
      <div class="quest-details d-flex flex-column justify-content-between">
        <div class="d-flex h-100">
          <div class="quest-info d-flex flex-column">
            <div class="quest-description">
              <span>Epic quest</span>
              <span>{{Array(5).fill('★').join('')}}</span>
              <span>Do {{questGoal}} raids</span>
            </div>
            <div>
              <img :src="getFoundersShield" class="quest-goal-image" alt=""/>
            </div>
            <div class="quest-progress">
              <strong class="quest-progress-text">{{ currentReputation || 0 }} / {{ maxReputation }}</strong>
              <b-progress class="reputation-progress" :max="maxReputation" :value="currentReputation" variant="primary"/>
            </div>
          </div>
          <div class="reward-info d-flex flex-column">
            <div class="quest-description">
              <span class="font-weight-bold">Reward</span>
              <span>2 reputation</span>
              <span>1x <span>{{Array(5).fill('★').join('')}}</span> sword</span>
            </div>
            <div>
              <img :src="getQuestReward" class="quest-goal-image" alt=""/>
            </div>
          </div>
        </div>
        <div class="d-flex">
          <b-button variant="primary" class="flex-grow-1">
            Submit
          </b-button>
          <b-button variant="primary" class="flex-grow-1">
            Re-quest / Complete
          </b-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import CharacterArt from '@/components/CharacterArt';
import {mapGetters, mapState} from 'vuex';
import foundersShield from '../assets/shield1.png';
import questReward from '../assets/shield2.png';

export default {
  components: {CharacterArt},

  props: {
    showCosmetics: {
      type: Boolean,
      default: true
    },
  },

  data() {
    return {
      reputationLevel: 2,
      currentReputation: 20,
      maxReputation: 100,
      questGoal: 2,
      questProgress: 1,
    };
  },

  computed: {
    ...mapState(['ownedCharacterIds']),
    ...mapGetters(['charactersWithIds', 'getCharacterCosmetic']),

    getFoundersShield() {
      return foundersShield;
    },

    getQuestReward() {
      return questReward;
    },

    filteredCharacters() {
      return this.charactersWithIds(this.ownedCharacterIds).filter(Boolean);
    },
  },

  methods: {}
};
</script>

<style scoped lang="scss">
@import '../styles/character-cosmetics.css';

.character {
  position: relative;
  width: 14em;
  height: 25em;
  background-position: center;
  background-repeat: no-repeat;
  background-size: 115%;
  background-color: #2e2e30cc;
  background-image: url('../assets/cardCharacterFrame.png');
  border: 1px solid #a28d54;
  border-radius: 15px;
  padding: 0.5rem;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  overflow: hidden;
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

.above-wrapper {
  position: absolute;
  top: 270px;
  left: 0;
  right: 0;
  z-index: 100;
  text-shadow: 0 0 5px #333, 0 0 10px #333, 0 0 15px #333, 0 0 10px #333;
}

.quest-info {
  border-right: 1px solid;
}

.quest-progress {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.reputation-progress {
  width: 75%;
}

.xp {
  position: absolute;
  bottom: 30px;
  width: 100%;
  display: flex;
  right: 0;
  flex-direction: column;
  align-items: center;
}

.xp-text {
  position: absolute;
  bottom: -12%;
}

.quest-progress-text {

}

.quest-row,
.quests-container {
  gap: 1rem;
}

.quest-details {
  border: 1px solid;
  border-radius: 5px;
  width: 25rem;
  height: auto;
}

.quest-description {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.quest-goal-image {
  max-width: 100%;
  height: auto;
}

@media (max-width: 576px) {
}
</style>
