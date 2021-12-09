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
            :stars="weapon.information.stars + 1"
            :element="weapon.information.element"
            :weaponId="weapon.weaponId"
            @click="handleWeaponClick(weapon.weaponId)"
            :disabled="ownedWeaponIds.includes(weapon.weaponId) && !availableWeaponIds.includes(weapon.weaponId)"
          />
          <br/>
          <span>Weapon: {{ selectedWeaponId }}</span>
          <button @click="() => selectedWeaponId = null">Clear Weapon</button>
        </div>
        <br/>
        <div>
          <h3>SHIELD TITLE</h3>
          <pvp-shield
            v-for="shield in ownedShieldsWithInformation"
            :key="shield.shieldId"
            :stars="shield.information.stars + 1"
            :element="shield.information.element"
            :shieldId="shield.shieldId"
            @click="handleShieldClick(shield.shieldId)"
            :disabled="ownedShieldIds.includes(shield.shieldId) && !availableShieldIds.includes(shield.shieldId)"
          />
          <br/>
          <span>Shield: {{ selectedShieldId }}</span>
          <button @click="() => selectedShieldId = null">Clear Shield</button>
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
        <button @click="handleEnterArenaClick()" :disabled="!selectedWeaponId">
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
          <span>{{ formatedTierRewardsPool }}</span>
        </div>
        <div>
          <h3>Top Players</h3>
          <br/>
          <span>Rank 1: {{ tierTopRankers[0] && tierTopRankers[0].name || '-' }} / RANK: {{ tierTopRankers[0] && tierTopRankers[0].rank }}</span>
          <br/>
          <span>Rank 2: {{ tierTopRankers[1] && tierTopRankers[1].name || '-' }} / RANK: {{ tierTopRankers[1] && tierTopRankers[1].rank }}</span>
          <br/>
          <span>Rank 3: {{ tierTopRankers[2] && tierTopRankers[2].name || '-' }} / RANK: {{ tierTopRankers[2] && tierTopRankers[2].rank }}</span>
          <br/>
        </div>
      </div>

      <div>
        <h2>{{ characterInformation.name || '' }}</h2>
        <br/>
        <span>Power: {{ characterInformation.power }}</span>
        <!-- <br/>
        <span>Damage Multiplier</span> -->
        <br/>
        <span>Level: {{ characterInformation.level }}</span>
        <br/>
        <span>Current Rank: {{ characterInformation.rank }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import BN from 'bignumber.js';
import PvPWeapon from '../../components/PvPWeapon.vue';
import PvPShield from '../../components/PvPShield.vue';

export default {
  components: {
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield
  },

  props: {
    tierRewardsPool: {
      default: null
    },
    tierTopRankers: {
      default: []
    },
    characterInformation: {
      default: {
        tier: null,
        name: '',
        level: null,
        power: null,
        rank: null
      }
    },
    entryWager: {
      default: null
    },
    availableWeaponIds: {
      default: []
    },
    availableShieldIds: {
      default: []
    },
    ownedWeaponsWithInformation: {
      default: []
    },
    ownedShieldsWithInformation: {
      default: []
    },
  },

  data() {
    return {
      selectedWeaponId: null,
      selectedShieldId: null,
      checkBoxAgreed: false,
    };
  },

  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds']),

    formattedEntryWager() {
      return new BN(this.entryWager).div(new BN(10).pow(18)).toFixed(0);
    },

    formatedTierRewardsPool() {
      return new BN(this.tierRewardsPool).div(new BN(10).pow(18)).toFixed(3);
    },
  },

  methods: {
    handleWeaponClick(weaponId) {
      this.selectedWeaponId = weaponId;
    },

    handleShieldClick(shieldId) {
      this.selectedShieldId = shieldId;
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

        this.$emit('enteredArena');
      } else {
        console.log('Missing data');
      }
    },
  },
};
</script>
