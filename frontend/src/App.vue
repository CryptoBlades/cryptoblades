<template>
  <div class="app">
    <div class="top-bar">
      <h1 class="app-title">CryptoBlades</h1>
      <view-links></view-links>
    </div>

    <h1 style="color: red" v-if="characterFetchError != null">
      Error when fetching charas: {{ characterFetchError }}
    </h1>

    <h1 style="color: red" v-if="weaponFetchError != null">
      Error when fetching weapons: {{ weaponFetchError }}
    </h1>

    <div class="content">
      <router-view
        :character="character"
        :characters="characters"
        :weapons="weapons"
        :stamina="stamina"
        @mintCharacter="mintCharacter"
        @selectCharacter="onSelectCharacter"
      />
    </div>
  </div>
</template>

<script>
import ViewLinks from "./components/ViewLinks.vue";

import { setUpContracts } from "./contracts";

import {
  characterFromContract,
  weaponFromContract,
} from "./contract-models.js";

export default {
  inject: ["web3"],
  components: {
    ViewLinks,
  },

  data() {
    return {
      CryptoBlades: null,
      Characters: null,
      Weapons: null,

      stamina: {
        current: 0,
        max: 0,
      },

      characterIds: [],
      characters: [],
      currentCharacterId: null,
      weaponIds: [],
      weapons: [],
      skillBalance: 0,
      now: Date.now(),

      characterFetchError: null,
      weaponFetchError: null,
    };
  },

  computed: {
    character() {
      if (this.characters.length < 1 || this.currentCharacterId == null) {
        return {
          name: "???",
          level: -1,
          experience: -1,
        };
      }

      const c = this.characters.find((c) => c.id === this.currentCharacterId);
      return {
        name: `Character #${c.id} (Appearance ${c.appearance})`,
        level: c.level,
        experience: c.xp,
      };
    },

    nowAndCurrentCharacterId() {
      return [this.now, this.currentCharacterId];
    },
  },

  watch: {
    async characterIds(charaIds) {
      if (charaIds.length == 0) {
        this.currentCharacterId = null;
      }

      try {
        this.characters = await this.getCharacters(charaIds);
      } catch (e) {
        console.error(e);
        this.characterFetchError = e.message;
      }
    },

    async weaponIds(weaponIds) {
      if (weaponIds.length == 0) {
        this.currentCharacterId = null;
      }

      try {
        this.weapons = await this.getWeapons(weaponIds);
      } catch (e) {
        console.error(e);
        this.weaponFetchError = e.message;
      }
    },

    async nowAndCurrentCharacterId(data) {
      const currentCharacterId = data[1];

      if (currentCharacterId == null) {
        this.stamina.current = 0;
        return;
      }

      this.stamina.current = await this.Characters.methods
        .getStaminaPoints(currentCharacterId)
        .call();
    },
  },

  methods: {
    onSelectCharacter(chara) {
      this.currentCharacterId = chara.id;
    },

    async getCharacters(characterIds) {
      return Promise.all(
        characterIds.map(async (charaId) => {
          return characterFromContract(
            charaId,
            await this.Characters.methods.get(charaId).call()
          );
        })
      );
    },

    async getWeapons(weaponIds) {
      return Promise.all(
        weaponIds.map(async (weaponId) => {
          return weaponFromContract(
            weaponId,
            await this.Weapons.methods.get(weaponId).call()
          );
        })
      );
    },

    async mintCharacter() {
      try {
        await this.CryptoBlades.methods.mintCharacter().send({
          from: this.web3.eth.defaultAccount,
        });
        console.log("Successful minting");
      } catch (e) {
        console.error("oh noes, an error when minting", e);
      }
    },
  },

  async created() {
    setInterval(() => {
      this.now = Date.now();
    }, 3000);

    const accounts = await this.web3.eth.requestAccounts();
    this.web3.eth.defaultAccount = accounts[0];

    const { CryptoBlades, Characters, Weapons } = await setUpContracts(
      this.web3
    );
    this.CryptoBlades = CryptoBlades;
    this.Characters = Characters;
    this.Weapons = Weapons;

    const [
      skillBalance,
      characterIds,
      weaponIds,
      maxStamina,
    ] = await Promise.all([
      this.CryptoBlades.methods.getMySkill().call(),
      this.CryptoBlades.methods.getMyCharacters().call(),
      this.CryptoBlades.methods.getMyWeapons().call(),
      this.Characters.methods.maxStamina().call(),
    ]);

    this.skillBalance = skillBalance;
    this.characterIds = Array.from(characterIds);
    this.weaponIds = Array.from(weaponIds);
    this.stamina.max = maxStamina;

    this.Characters.events.NewCharacter((err, data) => {
      if (err != null) {
        console.error(err);
        return;
      }

      console.log("NewCharacter event received! Data:", data);
      this.characterIds.push(data.returnValues.character);
    });

    this.Weapons.events.NewWeapon((err, data) => {
      if (err != null) {
        console.error(err);
        return;
      }

      console.log("NewWeapon event received! Data:", data);
      this.weaponIds.push(data.returnValues.weapon);
    });
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
