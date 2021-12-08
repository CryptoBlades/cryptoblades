<template>
  <div>
    <div>
      <div>
        <h2>Equip a Sword and a Shield (optional)</h2>
        <br/>
        <div>
          <h3>WEAPON TITLE</h3>
          <pvp-weapon
            v-for="weapon in ownedWeaponsWithInformation"
            :key="weapon.weaponId"
            :stars="weapon.information.stars"
            :element="weapon.information.element"
            :weaponId="weapon.weaponId"
            @click="handleWeaponClick(weapon.weaponId)"
            :disabled="ownedWeaponIds.includes(weapon.weaponId) && !availableWeaponIds.includes(weapon.weaponId)"
          />
          <!-- <button
            v-for="weaponId in ownedWeaponIds"
            :key="weaponId"
            @click="handleWeaponClick(weaponId)"
            :disabled="ownedWeaponIds.includes(weaponId) && !availableWeaponIds.includes(weaponId)"
          >
            Weapon ID: {{ weaponId }}
          </button> -->
          <br/>
          <span>Weapon: {{ selectedWeaponId }}</span>
        </div>
        <br/>
        <div>
          <h3>SHIELD TITLE</h3>
          <button
            v-for="shieldId in ownedShieldIds"
            :key="shieldId"
            @click="handleShieldClick(shieldId)"
            :disabled="ownedShieldIds.includes(shieldId) && !availableShieldIds.includes(shieldId)"
          >
            Shield ID: {{ shieldId }}
          </button>
          <br/>
          <span>Shield: {{ selectedShieldId }}</span>
        </div>
      </div>

      <div>
        <h2>Enter the Arena</h2>
        <br/>
        <span>Entering the Arena will cost you {{ formattedEntryWager }} $SKILL.</span>
        <br/>
        <span>Players can attack you while you are in the Arena.</span>
        <br/>
        <!-- Check this number -->
        <span>Leaving the Arena will cost you {{ +formattedEntryWager / 4 }} $SKILL.</span>
        <br/>
        <input type="checkbox" v-model="checkBoxAgreed" /><span>I understand.</span>
        <br/>
        <button @click="handleEnterArenaClick()">
          Enter Arena
          <br/>
          $SKILL: {{ formattedEntryWager }}
        </button>
      </div>

      <div>
        <h2>Arena Information</h2>
        <br/>
        <div>
          <h3>PVP Rewards Pool ($SKILL)</h3>
          <br/>
          <span>POOL HERE</span>
        </div>
        <div>
          <h3>Top Players</h3>
          <br/>
          <span>1</span>
          <br/>
          <span>2</span>
          <br/>
          <span>3</span>
          <br/>
          <button>View All Rankings</button>
        </div>
      </div>

      <div>
        <h2>CHARACTER NAME</h2>
        <br/>
        <span>Power</span>
        <br/>
        <span>Damage Multiplier</span>
        <br/>
        <span>Level</span>
        <br/>
        <span>Current Rank</span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import BN from 'bignumber.js';
import PvPWeapon from '../../components/PvPWeapon.vue';
import { weaponFromContract as formatWeapon } from '../../../../../contract-models';

export default {
  components: {
    'pvp-weapon': PvPWeapon
  },

  data() {
    return {
      entryWager: null,
      selectedWeaponId: null,
      selectedShieldId: null,
      availableWeaponIds: [],
      availableShieldIds: [],
      checkBoxAgreed: false,
      ownedWeaponsWithInformation: []
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds']),

    formattedEntryWager() {
      return new BN(this.entryWager).div(new BN(10).pow(18)).toFixed(0);
    }
  },

  methods: {
    handleWeaponClick(weaponId) {
      this.selectedWeaponId = weaponId;
    },

    handleShieldClick(shieldId) {
      this.selectedShieldId = shieldId;
    },

    async getWeaponInformation(weaponId) {
      const { element, stars } = formatWeapon(`${weaponId}`, await this.contracts().Weapons.methods.get(`${weaponId}`).call({ from: this.defaultAccount }));

      console.log('ELEMENT: ', element);
      console.log('Stars: ', stars);
      return {
        element,
        stars
      };
    },

    async handleEnterArenaClick() {
      if (!this.checkBoxAgreed) {
        alert('Please check the \'I understand\' box to proceed.');
        return;
      }

      if (this.currentCharacterId && this.selectedWeaponId && this.entryWager) {
        const isUsingShield = this.selectedShieldId !== null;
        const shieldId = this.selectedShieldId === null ? 0 : this.selectedShieldId;

        try {
          await this.contracts().SkillToken.methods
            .approve(this.contracts().PvpArena.options.address, this.entryWager)
            .send({
              from: this.defaultAccount
            });
        } catch(err) {
          console.log('Enter Arena Approval Error: ', err);
          return;
        }

        try {
          await this.contracts().PvpArena.methods
            .enterArena(this.currentCharacterId, this.selectedWeaponId, shieldId, isUsingShield)
            .send({
              from: this.defaultAccount
            });
        } catch(err){
          console.log('Enter Arena Error: ', err);
          return;
        }

        // Do something when succesful
      } else {
        console.log('Missing data');
      }
    },
  },

  async created() {
    this.entryWager = await this.contracts().PvpArena.methods.getEntryWager(this.currentCharacterId).call({ from: this.defaultAccount });

    const weaponAvailability = await Promise.all(this.ownedWeaponIds.map(async (weaponId) => {
      return {
        weaponId,
        isInArena: await this.contracts().PvpArena.methods.isWeaponInArena(weaponId).call({ from: this.defaultAccount })
      };
    }));

    this.availableWeaponIds = weaponAvailability.filter(weapon => !weapon.isInArena)
      .map(weapon => weapon.weaponId);

    this.ownedWeaponsWithInformation = await Promise.all(this.ownedWeaponIds.map(async (weaponId) => {
      return {
        weaponId,
        information: await this.getWeaponInformation(weaponId)
      };
    }));

    console.log('sadasd: ', this.ownedWeaponsWithInformation);

    const shieldAvailability = await Promise.all(this.ownedShieldIds.map(async (shieldId) => {
      return {
        shieldId,
        isInArena: await this.contracts().PvpArena.methods.isShieldInArena(shieldId).call({ from: this.defaultAccount })
      };
    }));

    this.availableShieldIds = shieldAvailability.filter(shield => !shield.isInArena)
      .map(shield => shield.shieldId);
  }

};
</script>
