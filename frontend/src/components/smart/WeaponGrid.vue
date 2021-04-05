<template>
  <ul class="weapon-grid">
    <li
      class="weapon"
      :class="{ selected: weapon.id === value }"
      v-for="weapon in ownWeapons"
      :key="weapon.id"
      :title="JSON.stringify(weapon, null, '  ')"
      @click="$emit('input', weapon.id)"
    >
      <img :src="getImageUrl(weapon)" alt="Placeholder weapon" />
    </li>
  </ul>
</template>

<script>
import { mapGetters } from "vuex";
import img1 from "../../assets/sword-placeholder.png";
import img2 from "../../assets/sword-placeholder-2.png";
import img3 from "../../assets/sword-placeholder-3.png";
import img4 from "../../assets/sword-placeholder-4.png";
import img5 from "../../assets/sword-placeholder-5.png";
import img6 from "../../assets/sword-placeholder-6.png";
import img7 from "../../assets/sword-placeholder-7.png";

const allImages = [img1, img2, img3, img4, img5, img6, img7];

export default {
  props: ["value"],

  computed: {
    ...mapGetters(["ownWeapons"]),
  },

  methods: {
    getImageUrl(weapon) {
      return allImages[weapon.id % allImages.length];
    },
  },
};
</script>

<style scoped>
.weapon-grid {
  list-style-type: none;
  margin: 0;
  padding: 0;
  display: grid;
  padding: 0.5em;
  grid-template-columns: repeat(auto-fit, 7em);
  gap: 0.5em;
}

.weapon {
  width: 6em;
  height: 6em;
  background: rgba(255, 255, 255, 0.1);
  box-shadow: 0 2px 4px #ffffff38;
  border-radius: 5px;
  padding: 0.5em;
  cursor: pointer;
}

.weapon img {
  max-width: 100%;
  max-height: 100%;
}

.weapon.selected {
  outline: solid currentcolor 2px;
}
</style>
