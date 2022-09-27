<template>
<div class="w-100">
  <div v-if="(questTemplateType === QuestTemplateType.QUEST || questTemplateType === QuestTemplateType.PICKABLE) && character" class="quest-row"
       :class="character.status !== undefined && (character.status !== NftStatus.AVAILABLE) ? 'busy-quest-row' : ''">
    <QuestCharacter :character="character" :quest="character.quest"
                    :reputationLevelRequirements="reputationLevelRequirements"/>
    <QuestRequirements v-if="character.quest && character.quest.id !== 0" :quest="character.quest"
                       :progress="character.quest.progress" :index="characterId"/>
    <QuestRewards v-if="character.quest && character.quest.id !== 0" :quest="character.quest"/>
    <QuestActions :character="character" :quest="character.quest" :key="character.quest.id" showSupply
                  @refresh-quest-data="onRefreshQuestData" :questTemplateType="questTemplateType"/>
  </div>
  <div v-if="questTemplateType === QuestTemplateType.WALLET && quest" class="quest-row-wallet">
    <QuestRequirements :quest="quest" :progress="quest.progress"/>
    <QuestRewards v-if="quest && quest.id !== 0" :quest="quest"/>
    <QuestActions :quest="quest" :key="quest.id" showSupply
                  @refresh-quest-data="onRefreshQuestData" :questTemplateType="questTemplateType"/>
  </div>
</div>
</template>

<script lang="ts">
import Vue from 'vue';
import {Accessors, PropType} from 'vue/types/options';
import QuestCharacter from '@/components/smart/QuestCharacter.vue';
import QuestRequirements from '@/components/smart/QuestRequirements.vue';
import QuestRewards from '@/components/smart/QuestRewards.vue';
import QuestActions from '@/components/smart/QuestActions.vue';
import {Quest, ReputationLevelRequirements, Rarity, RewardType, QuestTemplateType} from '@/views/Quests.vue';
import {mapActions, mapGetters} from 'vuex';
import {Nft, NftStatus} from '@/interfaces/Nft';

interface StoreMappedActions {
  getCharacterQuestData(payload: { characterId: string | number }): Promise<Quest>;

  getCharacterBusyStatus(payload: { characterId: string | number }): Promise<number>;
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
    },
    quest: {
      type: Object as PropType<Quest>,
    },
    reputationLevelRequirements: {
      type: Object as PropType<ReputationLevelRequirements>,
    },
    questTemplateType: {
      type: Number as PropType<QuestTemplateType>,
    },
  },

  data() {
    return {
      isLoading: true,
      character: undefined,
      RewardType,
      Rarity,
      NftStatus,
      QuestTemplateType
    } as Data;
  },

  computed: {
    ...mapGetters(['charactersWithIds']) as Accessors<StoreMappedGetters>,
  },

  methods: {
    ...mapActions([
      'getCharacterQuestData',
      'getCharacterBusyStatus',
    ]) as StoreMappedActions,
    async onRefreshQuestData() {
      this.$emit('refresh-quest-data');
      await this.refreshQuestData();
    },

    async refreshQuestData() {
      if (!this.character) return;
      try {
        this.isLoading = true;
        if(this.questTemplateType === QuestTemplateType.QUEST){
          this.character.quest = await this.getCharacterQuestData({characterId: this.characterId});
        }
        this.$forceUpdate();
      } finally {
        this.isLoading = false;
      }
    },
  },


  async mounted() {
    if(this.questTemplateType === QuestTemplateType.QUEST){
      this.character = await this.charactersWithIds([this.characterId]).filter(Boolean)[0];
      this.character.status = +await this.getCharacterBusyStatus({characterId: this.characterId});
    }
    await this.refreshQuestData();
  },

})
;
</script>

<style scoped>
.quest-row,
.quest-row-wallet {
  display: flex;
  width: 100%;
  background: rgba(0, 9, 26, 0.65);
  border: 1px solid #404857;
  border-radius: 10px;
  align-items: center;
  font-family: Roboto;
  height: clamp(200px, 20vh, 250px);
  justify-content: space-between;
  margin: 10px 0;
  padding: 10px 30px;
}

.quest-row-wallet {
  height: clamp(150px, 10vh, 200px);
}

.quest-row {
  height: auto;
}

/* Character */
.quest-row > div:nth-child(1) {
  width: clamp(352px, 20vw, 550px);
}

/* QuestActions */
.quest-row > div:last-child,
.quest-row-wallet > div:last-child{
  width: clamp(200px, 10vw, 250px);
}
/* QuestRequirements for Wallet Quests */
.quest-row-wallet > div:nth-child(1) {
  width: clamp(350px, 20vw, 700px);
}

.busy-quest-row {
  opacity: 0.5;
  pointer-events: none;
}

@media (max-width: 576px) {
  .quest-row,
  .quest-row-wallet {
    flex-direction: column;
    height: auto;
    gap: 1rem;
  }
}

</style>
