<template>
  <div class="app">
    <div class="top-bar">
      <h1 class="app-title">{{ appName }}</h1>
      <view-links></view-links>
    </div>

    <div class="content">
      <button @click="mintCharacter">Mint character</button>
      <button @click="getCharacterXp">Get character XP</button>
      <button @click="testThingie">Test</button>
      <router-view
        :character="character"
        :weapons="weapons"
        :stamina="stamina"
      />
    </div>
  </div>
</template>

<script>
import ViewLinks from "./components/ViewLinks.vue";

export default {
  inject: ["web3", "abi", "Kryptoknights"],
  components: {
    ViewLinks,
  },

  data() {
    return {
      appName: "Unknown",
      character: {
        name: "Bimmy Bozo",
        level: 12,
        experience: 10,
      },
      characterIds: [],
      stamina: {
        current: 85,
        max: 120,
      },
      weapons: ["one", "two", "three", "four", "five", "six", "seven", "steve"],
    };
  },

  methods: {
    async testThingie() {
      try {
        const accounts = await this.web3.eth.requestAccounts();

        const charactersContractAddress = await this.Kryptoknights.methods
          .characters()
          .call();

        const characters = new this.web3.eth.Contract(
          this.abi,
          charactersContractAddress
        );

        const xp = await characters.methods.setXp(0, 1000).send({
          from: accounts[0],
        });

        console.log(xp);
      }
      catch(e) {
        console.error('Oh no, a test error!', e);
      }
    },

    async mintCharacter() {
      try {
        const accounts = await this.web3.eth.requestAccounts();

        const receipt = await this.Kryptoknights.methods.mintCharacter().send({
          from: accounts[0],
          value: this.web3.utils.toWei("5", "ether"),
        });
        console.log("wew?", receipt);
        const {
          character: characterId,
        } = receipt.events.NewCharacter.returnValues;

        console.log(characterId);
        this.characterIds.push(characterId);
      } catch (e) {
        console.error("oh noes, an error", e);
      }
    },

    async getCharacterXp() {
      const accounts = await this.web3.eth.requestAccounts();

      const res = await this.Kryptoknights.methods
        .characters()
        .call({ from: accounts[0] });

      console.log(res);

      const Characters = new this.web3.eth.Contract(this.abi, res);

      const xpRes = await Characters.methods
        .getXp(this.characterIds[0])
        .call({ from: accounts[0] });

      console.log(xpRes);
    },
  },

  created() {
    console.log(this.Kryptoknights.methods);
  },
};
</script>

<style>
body {
  margin: 0;
}

.app {
  margin: 0;
}

.top-bar {
  background: rgb(0, 217, 224);
  display: flex;
  align-items: baseline;
  padding: 1em;
}

.app-title {
  margin: 0;
  margin-right: 1em;
}

.content {
  padding: 0 1em;
}
</style>
