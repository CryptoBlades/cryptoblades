<template>
  <div class="app">
    <div class="top-bar">
      <h1 class="app-title">CryptoBlades</h1>
      <view-links class="view-links"></view-links>
      <span>
        <span class="bold">Balance</span>: {{ formattedSkillBalance }}
        <button @click="addMoreSkill">Add more</button>
      </span>
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
        @invalidateWeaponIds="updateWeaponIds"
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
  inject: ["web3", "contractProvider"],
  components: {
    ViewLinks,
  },

  data() {
    return {
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
          id: null,
          name: "???",
          level: -1,
          experience: -1,
        };
      }

      const c = this.characters.find((c) => c.id === this.currentCharacterId);
      return {
        id: c.id,
        name: `Character #${c.id} (Appearance ${c.appearance})`,
        level: c.level,
        experience: c.xp,
      };
    },

    nowAndCurrentCharacterId() {
      return [this.now, this.currentCharacterId];
    },

    formattedSkillBalance() {
      const formatter = new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "ETH",
      });

      return formatter.format(this.skillBalance).replace(/ETH/g, "SKILL");
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

    skillBalance(balance, oldBalance) {
      console.log("BALANCE CHANGE:", balance, oldBalance, balance - oldBalance);
    },
  },

  methods: {
    async addMoreSkill() {
      try {
        const skillToAdd = parseFloat(
          prompt("How much SKILL do you want?", "100")
        );

        await this.CryptoBlades.methods.giveMeSkill(skillToAdd).send({
          from: this.web3.eth.defaultAccount,
        });

        await this.updateSkillBalance();

        alert('Successfully added SKILL to your balance!');
      } catch (e) {
        console.error(e);
      }
    },

    onSelectCharacter(chara) {
      this.currentCharacterId = chara.id;
    },

    async updateWeaponIds() {
      this.weaponIds = Array.from(
        await this.CryptoBlades.methods.getMyWeapons().call()
      );
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

    async updateSkillBalance() {
      const skill = await this.CryptoBlades.methods.getMySkill().call();
      this.skillBalance = skill;
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
    this.contractProvider.CryptoBlades = this.CryptoBlades = CryptoBlades;
    this.contractProvider.Characters = this.Characters = Characters;
    this.contractProvider.Weapons = this.Weapons = Weapons;

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

      this.updateSkillBalance(); // intentionally not awaited

      this.characterIds.push(data.returnValues.character);
    });

    this.Weapons.events.NewWeapon((err, data) => {
      if (err != null) {
        console.error(err);
        return;
      }

      this.updateSkillBalance(); // intentionally not awaited

      this.weaponIds.push(data.returnValues.weapon);
    });

    this.CryptoBlades.events.FightOutcome(async (err, data) => {
      if (err != null) {
        console.error(err);
        return;
      }

      this.updateSkillBalance(); // intentionally not awaited

      const characterId = data.returnValues.character;

      const updatedCharacter = characterFromContract(
        characterId,
        await this.Characters.methods.get(characterId).call()
      );

      this.characters = this.characters.map((c) => {
        return c.id === characterId ? updatedCharacter : c;
      });
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

.view-links {
  flex-grow: 1;
}

.content {
  padding: 0 1em;
}

.bold {
  font-weight: 1000;
}
</style>
