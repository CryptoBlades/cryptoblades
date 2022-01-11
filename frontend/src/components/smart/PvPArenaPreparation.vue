<template>
    <div v-if="loading">
      <img class="loadingSpinner" src="../../assets/loadingSpinner.svg" />
    </div>
    <div v-else class="arenaPreparationWrapper">    <div class="mainWrapper">
      <div class="arenaSignup">
        <h1 class="title">ARENA SIGNUP</h1>
        <p>Enter the arena and win rewards ($SKILL).</p>
        <div>
          <div class="top">
            <div class="circle">
              <img :src="getIconSource" />
            </div>
            <p>Equip a Sword and a Shield (optional).</p>
          </div>
          <div class="bottomWeapons">
            <pvp-separator dark vertical />
            <div class="weaponsWrapper">
              <div v-if="!selectedWeaponId" :class="{ disabledStyles: ownedWeaponsWithInformation.length === 0 }" class="weaponButtonWrapper">
                <a tabindex="0" class="selectWeaponButton" id="weapon-popover">
                  <img class="placeholderImage" src="../../assets/swordPlaceholder.svg" alt="sword" />
                  <b-popover ref="popover" target="weapon-popover" trigger="click" placement="right" custom-class="popoverWrapper">
                    <p class="popoverTitle">Weapons</p>
                    <select v-model="weaponStarFilter" class="selectFilter">
                      <option v-for="weaponStarOption in weaponStarOptions" :value="weaponStarOption.value" :key="weaponStarOption.value">
                        {{ weaponStarOption.text }}
                      </option>
                    </select>
                    <select v-model="weaponElementFilter" class="selectFilter">
                      <option v-for="weaponElementOption in weaponElementOptions" :value="weaponElementOption.value" :key="weaponElementOption.value">
                        {{ weaponElementOption.text }}
                      </option>
                    </select>
                    <button v-if="weaponStarFilter || weaponElementFilter" @click="handleClearWeaponFilters()" class="clearFiltersButton">Clear</button>
                    <div v-if="ownedWeaponsWithInformation.length !== 0" class="popoverGrid">
                      <pvp-weapon
                        v-for="weapon in filteredWeaponsWithInformation"
                        :key="weapon.weaponId"
                        :weapon="weapon.information"
                        :weaponId="weapon.weaponId"
                        :class="{'disabled': ownedWeaponIds.includes(weapon.weaponId) && !availableWeaponIds.includes(weapon.weaponId)}"
                        @click="handleWeaponClick(weapon.weaponId, weapon.information)"
                        :disabled="ownedWeaponIds.includes(weapon.weaponId) && !availableWeaponIds.includes(weapon.weaponId)"
                      />
                    </div>
                    <div v-else class="noWeaponsOrShields">You have no weapons.</div>
                  </b-popover>
                </a>
              </div>
              <div v-else class="weaponButtonWrapper">
                <pvp-weapon
                  :weapon="selectedWeapon"
                  :weaponId="selectedWeaponId"
                  class="weaponPlaceholder"
                />
                <button @click="handleClearWeapon()" class="clearWeaponButton">Clear</button>
              </div>
              <div v-if="!selectedShieldId" :class="{ disabledStyles: ownedShieldsWithInformation.length === 0 }" class="shieldButtonWrapper">
                <a tabindex="0" class="selectWeaponButton" id="shield-popover">
                  <img class="placeholderImage" src="../../assets/shieldPlaceholder.svg" alt="shield" />
                  <b-popover ref="popover" target="shield-popover" trigger="click" placement="right" custom-class="popoverWrapper">
                    <p class="popoverTitle">Shields</p>
                    <select v-model="shieldStarFilter" class="selectFilter">
                      <option v-for="shieldStarOption in shieldStarOptions" :value="shieldStarOption.value" :key="shieldStarOption.value">
                        {{ shieldStarOption.text }}
                      </option>
                    </select>
                    <select v-model="shieldElementFilter" class="selectFilter">
                      <option v-for="shieldElementOption in shieldElementOptions" :value="shieldElementOption.value" :key="shieldElementOption.value">
                        {{ shieldElementOption.text }}
                      </option>
                    </select>
                    <button v-if="shieldStarFilter || shieldElementFilter" @click="handleClearShieldFilters()" class="clearFiltersButton">Clear</button>
                    <div v-if="ownedShieldsWithInformation.length !== 0" class="popoverGrid">
                      <pvp-shield
                        v-for="shield in filteredShieldsWithInformation"
                        :key="shield.shieldId"
                        :shield="shield.information"
                        :shieldId="shield.shieldId"
                        :class="{'disabled': ownedShieldIds.includes(shield.shieldId) && !availableShieldIds.includes(shield.shieldId)}"
                        @click="handleShieldClick(shield.shieldId, shield.information)"
                        :disabled="ownedShieldIds.includes(shield.shieldId) && !availableShieldIds.includes(shield.shieldId)"
                      />
                    </div>
                    <div v-else class="noWeaponsOrShields">You have no shields.</div>
                  </b-popover>
                </a>
              </div>
              <div v-else class="shieldButtonWrapper">
                <pvp-shield
                  :shield="selectedShield"
                  :shieldId="selectedShieldId"
                />
                <button @click="handleClearShield" class="clearShieldButton">Clear</button>
              </div>
            </div>
          </div>
        </div>
        <div>
        <div class="top">
          <div class="circle">
            <img :src="getIconSource" />
          </div>
          <p>Enter the Arena</p>
        </div>
        <div class="bottomList">
          <pvp-separator dark vertical />
          <div>
            <ul>
              <li>
                <div class="bulletpoint"></div> Entering the Arena will cost you {{ formattedEntryWager }} $SKILL.
              </li>
              <li>
                <div class="bulletpoint"></div> Players can attack you while you are in the
                Arena.
              </li>
              <li>
                <div class="bulletpoint"></div> Leaving the Arena will cost you {{ +formattedEntryWager / 4 }} $SKILL.
              </li>
            </ul>
            <label class="checkboxWrapper">
              <div class="checkboxInnerWrapper">
                <input type="checkbox" v-model="checkBoxAgreed"  class="checkboxInput"/>
              </div>
              <span>I understand.</span>
            </label>
          </div>
        </div>
        </div>
        <div class="enterArenaButtonWrapper">
          <pvp-button
            @click="handleEnterArenaClick()"
            buttonText="ENTER ARENA"
            :buttonsubText="'$SKILL: ' + formattedEntryWager"
            :class="{ disabled: !this.checkBoxAgreed || !this.selectedWeaponId}"
          />
        </div>
      </div>
      <div class="characterImage">
        <pvp-character :characterId="currentCharacterId" />
      </div>
      <div class="arenaInformation">
        <h1 class="title">ARENA INFORMATION</h1>
        <div class="tokenCard">
          <img src="../../assets/skillToken.png" alt="skill token" />
          <div class="tokenCardInfo">
            <span class="text">PVP Rewards Pool ($SKILL)</span>
            <span class="number">{{ formatedTierRewardsPool }}</span>
          </div>
        </div>
        <ul class="topPlayersList">
          <li class="header">
            <span>Top Players</span><span>MMR</span>
          </li>
          <li>
            <span>Rank 1: {{ tierTopRankers[0] && tierTopRankers[0].name || 'N/A' }}</span>
            <span>{{ tierTopRankers[0] && tierTopRankers[0].rank || 'N/A' }}</span>
          </li>
          <li>
            <span>Rank 2: {{ tierTopRankers[1] && tierTopRankers[1].name || 'N/A' }}</span>
            <span>{{ tierTopRankers[1] && tierTopRankers[1].rank || 'N/A'}}</span>
          </li>
          <li>
            <span>Rank 3: {{ tierTopRankers[2] && tierTopRankers[2].name || 'N/A' }}</span>
            <span>{{ tierTopRankers[2] && tierTopRankers[2].rank || 'N/A'}}</span>
          </li>
        </ul>
        <!-- <a href="#" class="rankings">View all rankings</a> -->
        <ul class="characterAttrsList">
          <li class="characterName">{{ characterInformation.name || '' }}</li>
          <li><span>Power </span><span>{{ characterInformation.power }}</span></li>
          <li><span>Level</span><span>{{ characterInformation.level }}</span></li>
          <li><span>Current MMR</span><span>{{ characterInformation.rank }}</span></li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import BN from 'bignumber.js';
import { BPopover } from 'bootstrap-vue';
import PvPWeapon from './PvPWeapon.vue';
import PvPShield from './PvPShield.vue';
import PvPCharacter from './PvPCharacter.vue';
import PvPButton from './PvPButton.vue';
import PvPSeparator from './PvPSeparator.vue';
import checkIcon from '../../assets/checkImage.svg';
import ellipseIcon from '../../assets/ellipseImage.svg';
import i18n from '../../i18n';

export default {
  components: {
    'pvp-weapon': PvPWeapon,
    'pvp-shield': PvPShield,
    'pvp-button': PvPButton,
    'pvp-separator': PvPSeparator,
    'pvp-character': PvPCharacter,
    'b-popover': BPopover
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
        rank: null,
        element: null,
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
      loading: false,
      selectedWeaponId: null,
      selectedWeapon: null,
      selectedShieldId: null,
      selectedShield: null,
      checkBoxAgreed: false,
      filteredWeaponsWithInformation: this.ownedWeaponsWithInformation,
      filteredShieldsWithInformation: this.ownedShieldsWithInformation,
      weaponStarFilter: 0,
      weaponStarOptions: [
        { text: i18n.t('nftList.sorts.any'), value: 0 },
        { text: '1', value: 1 },
        { text: '2', value: 2 },
        { text: '3', value: 3 },
        { text: '4', value: 4 },
        { text: '5', value: 5 },
      ],
      weaponElementFilter: '',
      weaponElementOptions: [
        { value: '', text: i18n.t('nftList.sorts.any') },
        { value: 'Earth', text: i18n.t('traits.earth') },
        { value: 'Fire', text: i18n.t('traits.fire') },
        { value: 'Lightning', text: i18n.t('traits.lightning') },
        { value: 'Water', text: i18n.t('traits.water') }
      ],
      shieldStarFilter: 0,
      shieldStarOptions: [
        { text: i18n.t('nftList.sorts.any'), value: 0 },
        { text: '1', value: 1 },
        { text: '2', value: 2 },
        { text: '3', value: 3 },
        { text: '4', value: 4 },
        { text: '5', value: 5 },
      ],
      shieldElementFilter: '',
      shieldElementOptions: [
        { value: '', text: i18n.t('nftList.sorts.any') },
        { value: 'Earth', text: i18n.t('traits.earth') },
        { value: 'Fire', text: i18n.t('traits.fire') },
        { value: 'Lightning', text: i18n.t('traits.lightning') },
        { value: 'Water', text: i18n.t('traits.water') }
      ]
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
    getIconSource () {
      return this.checkBoxAgreed && this.selectedWeaponId ? checkIcon : ellipseIcon;
    },
  },
  methods: {
    handleClearWeaponFilters() {
      this.weaponStarFilter = 0;
      this.weaponElementFilter = '';
    },
    handleClearShieldFilters() {
      this.shieldStarFilter = 0;
      this.shieldElementFilter = '';
    },
    handleErrorMessage(value, errorMessage, returnedMessage) {
      if(value.includes(`reverted with reason string '${errorMessage}'`)) {
        return this.$dialog.notify.error(returnedMessage);
      }
      return 'There has been an error. Try again.';
    },
    handleWeaponClick(weaponId, weapon) {
      this.selectedWeaponId = weaponId;
      this.selectedWeapon = weapon;
    },
    handleClearWeapon() {
      this.selectedWeaponId = null;
      this.selectedWeapon = null;
    },
    handleShieldClick(shieldId, shield) {
      this.selectedShieldId = shieldId;
      this.selectedShield = shield;
    },
    handleClearShield() {
      this.selectedShieldId = null;
      this.selectedShield = null;
    },
    onOpen() {
      this.$refs.popover.$emit('open');
    },
    onClose() {
      this.$refs.popover.$emit('close');
    },
    async handleEnterArenaClick() {
      if (!this.checkBoxAgreed) {
        alert('Please check the \'I understand\' box to proceed.');
        return;
      }
      this.loading = true;
      if ((this.currentCharacterId || this.currentCharacterId === 0) && (this.selectedWeaponId || this.selectedWeaponId === 0) && this.entryWager) {
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
          this.loading = false;
          this.handleErrorMessage();
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
          this.loading = false;
          this.handleErrorMessage();
          return;
        }
        this.$emit('enteredArena');
      } else {
        console.log(this.currentCharacterId);
        console.log(this.selectedWeaponId);
        console.log(this.entryWager);
        console.log('Missing data');
      }
      this.loading = false;
    },
  },

  watch: {
    weaponStarFilter(value) {
      if (!value && !this.weaponElementFilter) {
        if (!this.weaponElementFilter) {
          this.filteredWeaponsWithInformation = this.ownedWeaponsWithInformation;
        } else {
          this.filteredWeaponsWithInformation = this.ownedWeaponsWithInformation.filter((weapon) => {
            return weapon.information.element === this.weaponElementFilter;
          });
        }
      } else {
        if (!this.weaponElementFilter) {
          this.filteredWeaponsWithInformation = this.ownedWeaponsWithInformation.filter((weapon) => {
            return weapon.information.stars === value - 1;
          });
        } else {
          this.filteredWeaponsWithInformation = this.ownedWeaponsWithInformation.filter((weapon) => {
            return weapon.information.stars === value - 1 && weapon.information.element === this.weaponElementFilter;
          });
        }
      }
    },

    weaponElementFilter(value) {
      if (!value) {
        if (!this.weaponStarFilter) {
          this.filteredWeaponsWithInformation = this.ownedWeaponsWithInformation;
        } else {
          this.filteredWeaponsWithInformation = this.ownedWeaponsWithInformation.filter((weapon) => {
            return weapon.information.stars === this.weaponStarFilter - 1;
          });
        }
      } else {
        if (!this.weaponStarFilter) {
          this.filteredWeaponsWithInformation = this.ownedWeaponsWithInformation.filter((weapon) => {
            return weapon.information.element === value;
          });
        } else {
          this.filteredWeaponsWithInformation = this.ownedWeaponsWithInformation.filter((weapon) => {
            return weapon.information.stars === this.weaponStarFilter - 1 && weapon.information.element === value;
          });
        }
      }
    },

    shieldStarFilter(value) {
      if (!value && !this.shieldElementFilter) {
        if (!this.shieldElementFilter) {
          this.filteredShieldsWithInformation = this.ownedShieldsWithInformation;
        } else {
          this.filteredShieldsWithInformation = this.ownedShieldsWithInformation.filter((shield) => {
            return shield.information.element === this.shieldElementFilter;
          });
        }
      } else {
        if (!this.shieldElementFilter) {
          this.filteredShieldsWithInformation = this.ownedShieldsWithInformation.filter((shield) => {
            return shield.information.stars === value - 1;
          });
        } else {
          this.filteredShieldsWithInformation = this.ownedShieldsWithInformation.filter((shield) => {
            return shield.information.stars === value - 1 && shield.information.element === this.shieldElementFilter;
          });
        }
      }
    },

    shieldElementFilter(value) {
      if (!value) {
        if (!this.shieldStarFilter) {
          this.filteredShieldsWithInformation = this.ownedShieldsWithInformation;
        } else {
          this.filteredShieldsWithInformation = this.ownedShieldsWithInformation.filter((shield) => {
            return shield.information.stars === this.shieldStarFilter - 1;
          });
        }
      } else {
        if (!this.shieldStarFilter) {
          this.filteredShieldsWithInformation = this.ownedShieldsWithInformation.filter((shield) => {
            return shield.information.element === value;
          });
        } else {
          this.filteredShieldsWithInformation = this.ownedShieldsWithInformation.filter((shield) => {
            return shield.information.stars === this.shieldStarFilter - 1 && shield.information.element === value;
          });
        }
      }
    }
  }
};
</script>

<style scoped lang="scss">
.arenaPreparationWrapper {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}
p, li, span {
  font-family: 'Roboto';
}
.popoverWrapper {
  height: 450px;
  overflow-y: auto;
  min-width: max-content;
  padding: 0.5rem 0.5rem 1.5rem 0.5rem;
  background-color: black;
  border: 1px solid #cec198;
  box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  .popoverTitle {
    color: #cec198;
    font-size: 1.25rem;
    line-height: 1.75rem;
  }
  .popoverGrid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    grid-template-rows: repeat(4, 1fr);
    grid-column-gap: 1rem;
    grid-row-gap: 2rem;
    margin-top: 1rem;
  }
}
.clearFiltersButton {
  background-color: transparent;
  font-family: 'Roboto';
  color: #cec198;
  font-size: .75rem;
  border: none;
}
.selectFilter {
  margin-right: 1rem;
  padding: .25rem;
  font-family: 'Roboto';
  font-size: .75rem;
  color: #b4b0a7;
  background-color: #151515;
  border-color: transparent;
  border-radius: 0.2rem;
  width: 6rem;
}
.selectFilter:first-of-type {
  width: 4rem
}
.noWeaponsOrShields {
  font-family: 'Roboto';
  color: #b4b0a7;
  font-size: 1rem;
}
.mainWrapper {
  display: flex;
  width: 100%;
  margin: 0 auto;
  justify-content: space-between;
}
.title {
  margin-bottom: 0.75rem;
  color: #cec198;
  font-size: 1.25rem;
  font-family: 'Trajan';
  line-height: 1.75rem;
  padding: 0;
}
.arenaSignup {
  p {
    margin-bottom: 0;
    color: #b4b0a7;
    font-size: 1rem;
    line-height: 1.5rem;
  }
  .top {
    display: flex;
    margin-top: 1.5rem;
    margin-bottom: 1rem;
    vertical-align: middle;
    align-items: center;
    .circle {
      display: flex;
      width: 1.75rem;
      height: 1.75rem;
      margin-right: 1rem;
      align-items: center;
      vertical-align: middle;
      justify-content: center;
      border-radius: 9999px;
      border: 2px solid #cec198;
    }
    img {
      height: 0.75rem;
      width: 0.75rem;
    }
    p {
      color: #cec198;
    }
  }
  .bottomWeapons,
  .bottomList {
    display: flex;
    margin-left: 0.75rem;
  }
  .bottomWeapons {
    flex-direction: row;
    height: 5rem;
    .weaponsWrapper {
      display: flex;
      flex-direction: row;
      justify-content: space-between;
      margin-left: 1.75rem;
      .clearWeaponButton, .clearShieldButton {
        display: flex;
        position: absolute;
        top: -10px;
        right: -10px;
        align-items: center;
        vertical-align: middle;
        justify-content: center;
        background: #b53c48;
        border: none;
        color: white;
        border-radius: 0.2rem;
        font-size: 0.7rem;
        font-family: 'Roboto';
        border-radius: 0.25rem;
        font-size: 0.75rem;
      }
      .weaponButtonWrapper {
        margin-right: 1.5rem;
        position: relative;
      }
      .shieldButtonWrapper {
        position: relative;
      }
      .selectWeaponButton {
        display: flex;
        width: 4.5rem;
        height: 4.5rem;
        align-items: center;
        vertical-align: middle;
        justify-content: center;
        border-radius: 0.375rem;
        border: 1px solid #cec198;
        background-color: #141414;
        :hover {
          cursor: pointer;
        }
        .placeholderImage {
          width: 2.25rem;
          height: 2.25rem;
        }
      }
    }
  }
  .bottomList {
    flex-direction: row;
    height: 8rem;
    ul {
      flex-direction: column;
      padding-left: 2rem;
      padding-top: 0.65rem;
      li {
        display: flex;
        margin-bottom: 0.75rem;
        align-items: center;
        vertical-align: middle;
        color: #b4b0a7;
        font-size: 0.875rem;
        line-height: 1.25rem;
        white-space: nowrap;
      }
      .bulletpoint {
        height: 0.5rem;
        width: 0.5rem;
        margin-right: 0.75rem;
        background-color: #dabe75;
        transform: rotate(45deg);
      }
    }
    .checkboxWrapper {
      display: inline-block;
      align-items: center;
      vertical-align: middle;
      margin-left: 1.75rem;
      margin-top: 1.1rem;
      user-select: none;
      .checkboxInnerWrapper {
        position: absolute;
        display: inline-block;
        overflow: hidden;
        .checkboxInput {
          width: 1.25rem;
          height: 1.25rem;
          cursor: pointer;
          background: rgba(40,40,40,0.2);
          appearance: none;
          position: relative;
          border: 1px solid #b4b0a7;
          padding: 4px;
        }
        .checkboxInput:checked {
          background-image: url('../../assets/checkImage.svg');
          background-repeat: no-repeat;
          background-size: 75% 50%;
          background-position: center;
        }
    }
      span {
        margin-left: 2rem;
        color: #b4b0a7;
        font-size: 0.875rem;
      }
    }
  }
  .enterArenaButtonWrapper {
    width: 15rem;
    height: 5rem;
    margin-top: 3rem;
  }
}
.characterImage {
  display: flex;
  width: 50%;
  padding: 3rem 0;
  @media only screen and (min-width: 1440px) {
    width: 40%;
    margin: 0;
  }
  @media only screen and (min-width: 1980px) {
    width: 30%;
  }
}
.arenaInformation {
  display: flex;
  flex-direction: column;
  .tokenCard {
    display: flex;
    padding: 1rem 2rem 1rem 1.5rem;
    border-radius: 0.375rem;
    align-items: center;
    vertical-align: middle;
    background-color: rgba(0, 0, 0, 0.3);
    img {
      width: 4rem;
      height: 4rem;
    }
    .tokenCardInfo {
      display: flex;
      flex-direction: column;
      margin-left: 1rem;
      .text {
        color: #cec198;
        font-size: 0.875rem;
        line-height: 1.25rem;
      }
      .number {
        color: #ffffff;
        font-size: 1.25rem;
        line-height: 1.75rem;
      }
    }
  }
  .topPlayersList,
  .characterAttrsList {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    margin-top: 1.5rem;
    padding: 0;
    span {
      color: #b4b0a7;
      font-size: 0.75rem;
      line-height: 1rem;
    }
    span:nth-of-type(2) {
      margin-left: auto;
    }
    li {
      display: flex;
      margin-bottom: 0.5rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid #363636;
    }
    li:first-of-type,
    li:last-of-type {
      padding-bottom: 0;
      border-style: none;
    }
  }
  .topPlayersList {
    .header {
      margin-bottom: 1rem;
      span {
        color: #cec198;
        font-size: 0.875rem;
      }
    }
  }
  .rankings {
    margin-top: 0.75rem;
    color: #cec198;
    font-size: 0.875rem;
  }
  .characterAttrsList {
    margin-top: 2.25rem;
    .characterName {
      margin-bottom: 1rem;
      color: #cec198;
      font-size: 1.25rem;
      font-family: 'Trajan';
    }
  }
}
.loadingSpinner {
  display: flex;
  height: 3rem;
  width: 3rem;
  margin: 0 auto;
  margin-top: 3rem ;
  animation: spin 1s linear infinite;
  @keyframes spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }
}
</style>
