<template>
  <div class="body main-font">
    <div class="row">
      <div class="col">
        <div>
          <big-button
            class="button"
            mainText="Sell Weapons"
            @click="activeSell = 'weapons'"
          />

          <big-button
            class="button"
            mainText="Sell Characters"
            @click="activeSell = 'characters'"
          />
        </div>

        <div v-if="activeSell === 'weapons'">
          weapon list
        </div>

        <div v-if="activeSell === 'characters'">
          char list
        </div>
      </div>

      <div class="col">
        <input type="text" class="search" v-model="search" placeholder="Seller ID, NFT ID" />

        <div class="search-buttons">
          <big-button
            class="button"
            mainText="Search NFT"
            @click="searchNFT()"
          />

          <big-button
            class="button"
            mainText="Search Seller"
            @click="searchSeller()"
          />
        </div>
      </div>

      <div class="col">
      </div>
    </div>
  </div>
</template>

<script>

import BigButton from '../components/BigButton.vue';

export default {
  components: { BigButton },

  data() {
    return {
      activeSell: 'weapons',
      search: ''
    };
  },

  computed: {
  },

  methods: {
    searchNFT() {

    },

    searchSeller() {

    }
  },
};
</script>

<style scoped>
.body {
  margin-top: 10px;
}

.row {
  display: flex;
  flex-direction: row;
}

.col {
  flex: 1;
}

.button + .button {
  margin-left: 10px;
}

.search {
  width: 100%;
}

.search-buttons {
  margin-top: 10px;
  display: flex;
  justify-content: space-between;
}
</style>
