<template>
  <div v-if="character" class="quest-row gap-5">
    <QuestCharacter :character="character" :quest="character.quest"
                    :reputationLevelRequirements="reputationLevelRequirements"/>
    <QuestRequirements v-if="character.quest && character.quest.id !== 0" :quest="character.quest"
                       :progress="character.quest.progress"/>
    <QuestRewards v-if="character.quest && character.quest.id !== 0" :quest="character.quest"/>
    <QuestActions :character="character" :quest="character.quest" @refresh-quest-data="onRefreshQuestData"/>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {Accessors, PropType} from 'vue/types/options';
import {Rarity, RewardType} from '@/views/Quests.vue';
import QuestCharacter from '@/components/smart/QuestCharacter.vue';
import QuestRequirements from '@/components/smart/QuestRequirements.vue';
import QuestRewards from '@/components/smart/QuestRewards.vue';
import QuestActions from '@/components/smart/QuestActions.vue';
import {Quest, ReputationLevelRequirements} from '../../views/Quests.vue';
import {mapActions, mapGetters} from 'vuex';
import {Nft} from '@/interfaces/Nft';

interface StoreMappedActions {
  getCharacterQuestData(payload: { characterId: string | number }): Promise<Quest>;
}

interface StoreMappedGetters {
  charactersWithIds(ids: (string | number)[]): Nft[];
}

interface Data {
  isLoading: boolean;
  character?: Nft;
}

export default Vue.extend({
  components: {QuestCharacter, QuestRequirements, QuestActions, QuestRewards},
  props: {
    characterId: {
      type: Number as PropType<number | string>,
      required: true,
    },
    reputationLevelRequirements: {
      type: Object as PropType<ReputationLevelRequirements>,
    },
  },

  data() {
    return {
      isLoading: true,
      character: undefined,
      RewardType,
      Rarity,
    } as Data;
  },

  computed: {
    ...mapGetters(['charactersWithIds']) as Accessors<StoreMappedGetters>,
  },

  methods: {
    ...mapActions(['getCharacterQuestData']) as StoreMappedActions,
    async onRefreshQuestData() {
      await this.refreshQuestData();
    },

    async refreshQuestData() {
      if (!this.character) return;
      try {
        this.isLoading = true;
        this.character.quest = await this.getCharacterQuestData({characterId: this.characterId});
        this.$forceUpdate();
      } finally {
        this.isLoading = false;
      }
    },
  },


  async mounted() {
    this.character = await this.charactersWithIds([this.characterId]).filter(Boolean)[0];
    await this.refreshQuestData();
  },

})
;
</script>

<style scoped>
.quest-row {
  display: flex;
  width: 100%;
  background: #141414;
  border: 1px solid #60583E;
  border-radius: 10px;
  align-items: center;
}
</style>
