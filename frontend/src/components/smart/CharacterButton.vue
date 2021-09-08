<template>
  <div
    v-bind:class="character.id === currentCharacter.id ? 'selected' : 'notSelected'"
    @click="setCurrentCharacter(character.id)">
      <div>
        <img
          class="character-buttons"
          :src="getCharacterArt(currentCharacter)" />
      </div>
  </div>
</template>

<script>
export default {
  props:{
    characterId: String
  },

};
</script>

<style>

.selected {
  border: 1px dashed #968332;
  border-radius: 10%;
  margin: 3px auto;
  height:90px;
  width: 90px;
}

.notSelected {
  border: 1px none transparent;
  border-radius: 10%;
  margin: 3px auto;
  height:90px;
  width: 90px;
}

.character-buttons {
  background: transparent;
  border: 2px solid #968332;
  border-radius: 10%;
  height: 80px;
  width: 80px;
  margin: 3px auto;
}
</style>
