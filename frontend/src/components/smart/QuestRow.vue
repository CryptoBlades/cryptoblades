<template>
<div class="w-100">
  <div v-if="(questTemplateType === QuestTemplateType.QUEST || questTemplateType === QuestTemplateType.PICKABLE) && character" class="quest-row"
        :class="character.status !== undefined && (character.status !== NftStatus.AVAILABLE) ? 'busy-quest-row' : ''"
        :key="`${componentKey}-${character.quest.id}`">
    <QuestCharacter :character="character" :quest="character.quest"
                    :reputationLevelRequirements="reputationLevelRequirements"/>
    <QuestRequirements v-if="character.quest && character.quest.id !== 0" :quest="character.quest"
                       :progress="character.quest.progress" :index="characterId"/>
    <QuestRewards v-if="character.quest && character.quest.id !== 0" :quest="character.quest"/>
    <QuestActions :character="character" :quest="character.quest" :key="character.quest.id" showSupply
                  @refresh-quest-data="onRefreshQuestData" :questTemplateType="questTemplateType"/>
  </div>
  <div v-if="questTemplateType === QuestTemplateType.WALLET && quest" class="quest-row-wallet" :key="`${componentKey}-${quest.id}`">
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
import {mapActions, mapGetters, mapState} from 'vuex';
import {Nft, NftStatus} from '@/interfaces/Nft';

interface StoreMappedActions {
  getCharacterQuestData(payload: { characterId: string | number }): Promise<Quest>;

  getCharacterBusyStatus(payload: { characterId: string | number }): Promise<number>;

  getQuestTemplates(payload: { tier: number }): Promise<Quest[]>;
}

interface StoreMappedGetters {
  charactersWithIds(ids: (string | number)[]): Nft[];
}

interface Data {
  isLoading: boolean;
  character?: Nft;
  componentKey: number;
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
    walletQuestTier: {
      type: Number as PropType<number>,
    },
    defaultAccountProp: {
      type: String as PropType<string>,
      required: true,
    },
    currentNetworkIdProp: {
      type: Number as PropType<number>,
      required: true,
    },
  },

  data() {
    return {
      isLoading: true,
      character: undefined,
      RewardType,
      Rarity,
      NftStatus,
      QuestTemplateType,
      componentKey: 0,
    } as Data;
  },

  computed: {
    ...mapState(['defaultAccount', 'currentNetworkId']),
    ...mapGetters(['charactersWithIds']) as Accessors<StoreMappedGetters>,

    /**
     * detect if the defaultAccount/networkId have changed.
     */
    hasStateChanged(): boolean {
      return this.defaultAccount + this.currentNetworkId !== this.defaultAccountProp + this.currentNetworkIdProp;
    },
  },

  methods: {
    ...mapActions([
      'getCharacterQuestData',
      'getCharacterBusyStatus',
      'getQuestTemplates',
    ]) as StoreMappedActions,
    async onRefreshQuestData() {
      // if state has changed, trigger full page reload.
      if (this.hasStateChanged) {
        this.$emit('refresh-quest-data');
      }
      // change key of current row to triggering automatic, efficient content update
      else {
        await this.refreshQuestData();
        this.componentKey += 1;
      }
    },

    async refreshQuestData() {
      try {
        this.isLoading = true;
        //update row character-quest
        if(this.character && this.questTemplateType === QuestTemplateType.QUEST){
          this.character.quest = await this.getCharacterQuestData({characterId: this.characterId});
        }
        //update row wallet-quest
        else if(!this.character && this.questTemplateType === QuestTemplateType.WALLET){
          const questUpdate = (await this.getQuestTemplates({tier: this.walletQuestTier + 30})).find((x) => x.id === this.quest.id) as Quest;
          this.quest.progress = questUpdate.progress;
        }
      } finally {
        this.isLoading = false;
      }
    },
  },


  async mounted() {
    if(this.questTemplateType === QuestTemplateType.QUEST){
      this.character = this.charactersWithIds([this.characterId]).filter(Boolean)[0];
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

/* Character */
.quest-row > div:nth-child(1) {
  width: clamp(250px, 20vw, 550px);
}

/* QuestActions */
.quest-row > div:last-child,
.quest-row-wallet > div:last-child{
  width: clamp(200px, 10vw, 250px);
}
/* QuestRequirements for Wallet Quests */
.quest-row-wallet > div:nth-child(1) {
  width: clamp(550px, 20vw, 700px);
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
