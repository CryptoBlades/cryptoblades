<template>
    <b-tab title="Skins" title-item-class="character-wrapper" title-link-class="character-tab" @click="$emit('loadCosmeticsCount')">
      <div class="d-flex flex-wrap">
      <div
        class="w-25 p-1 text-white text-center mb-3"
        role="button"
        v-for="(cosmetic, index) in availableSkins" :key="index"
        @click="handleSkin(cosmetic.id)"
      >
        <div
        :class="['imgs px-3 pt-5 pb-3 text-center', characterCosmetics[currentCharacterId] == cosmetic ? 'active' : '' ]"
        :style="{
          border: characterCosmetics[currentCharacterId] === cosmetic.id ? '1px solid #1168D0!important' : '1px solid #404857'
        }"
        >
            <template v-if="characterCosmetics[currentCharacterId] === cosmetic.id">
              <span>Equiped</span>
            </template>
            <div v-bind:class="['character-cosmetic-applied-' + cosmetic.id, 'character-animation-applied-' + cosmetic.id]">
                <div class="animation" />
                <img class="placeholder" :src="getCharacterArt(characters[currentCharacterId])" />
            </div>
        </div>
        <h5 class="m-0 mt-2 cosmetic-font">{{cosmetic.name}}</h5>
        <span class="main-font text-muted">{{$t(`Character.owned`)}}</span>
      </div>
      </div>
    </b-tab>
</template>

<script lang="ts">
import Vue from 'vue';
import { mapActions, mapGetters, mapState } from 'vuex';

import { getCharacterArt } from '@/character-arts-placeholder';


interface Data {
  powerAmount: number
}

interface StoreMappedActions {
  removeCharacterCosmetic(payload: {id: number}): Promise<void>
  changeCharacterCosmetic(payload: {id: number, cosmetic: string}): Promise<void>
}

export default Vue.extend({
  props: {
    availableSkins: {
      type: Array,
      default: ()=> []
    }
  },
  data(): Data{
    return {
      powerAmount: 0
    };
  },
  computed:{
    ...mapState(['characterCosmetics','currentCharacterId', 'characters']),
    ...mapGetters(['getCharacterPower']),
  },
  methods: {
    ...mapActions(['removeCharacterCosmetic', 'changeCharacterCosmetic']) as StoreMappedActions,
    getCharacterArt,
    async handleSkin(cosmetic: string): Promise<void>{
      if (+cosmetic === 0) {
        await this.removeCharacterCosmetic({ id: +this.currentCharacterId });
      } else {
        await this.changeCharacterCosmetic({ id: +this.currentCharacterId, cosmetic });
      }
      this.$emit('loadCosmeticsCount');
    },
  },
});
</script>

<style lang="scss" scoped>
@import '../../../styles/character-cosmetics.css';

.placeholder {
  max-width: 180px;
  max-height: 180px;
  margin-left: 10px;
  margin-top: 5px;
}

.imgs{
  background-color: #000E1D;
  border-radius: 5px;
  height: 245px;
  position: relative;
  span{
    position: absolute;
    top: 10px;
    left: 10px;
    font: normal normal normal 12px/16px Roboto;
    color: #fff;
    background: #1168D0;
    padding: 4px 10px;
    border-radius: 3px;
  }
  div {
    width: 100%;
    height: 100%;
    position: relative;
    img {
      width: 100%;
      height: 100%;
      position: absolute;
      top: 0;
      left: 0;
      margin: 0;
      object-fit: contain;
    }
  }
}

.cosmetic-font{
  font-family: 'Oswald', serif;
  font-size: 18px;
  line-height: 26px;
  text-transform: uppercase;
}



</style>