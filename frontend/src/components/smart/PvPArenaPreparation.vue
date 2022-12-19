<template>
    <div v-if="loading">
      <img class="loadingSpinner" src="../../assets/loadingSpinner.svg" />
    </div>
    <div v-else class="arenaPreparationWrapper">    <div class="mainWrapper">
      <div class="arenaSignup">
        <h1 class="title">
          {{$t('pvp.arenaSignUp')}}
        </h1>
        <p>
          {{$t('pvp.enterAndWin')}}($SKILL).
        </p>
        <div>
        <div class="top">
          <div class="circle">
            <img :src="getIconSource" />
          </div>
          <p>
            {{$t('pvp.enterTheArena')}}
          </p>
        </div>
        <div class="bottomList">
          <pvp-separator dark vertical />
          <div>
            <ul>
              <li>
                <div class="bulletpoint"></div>
                {{$t('pvp.enterArenaWillCost', {formattedEntryWager})}}
              </li>
              <li>
                <div class="bulletpoint"></div>
                {{$t('pvp.enterUntieredArenaWillCost', {formattedUntieredEntryWager})}}
              </li>
              <li>
                <div class="bulletpoint"></div>
                {{$t('pvp.playersCanAttackYou')}}
              </li>
              <li>
                <div class="bulletpoint"></div>
                {{$t('pvp.leavingWillCost', {formattedWithdrawCost})}}
              </li>
              <li>
                <div class="bulletpoint"></div>
                {{$t('pvp.tieredArena')}}
              </li>
              <li>
                <div class="bulletpoint"></div>
                {{$t('pvp.untieredArena')}}
              </li>
            </ul>
            <label class="checkboxWrapper">
              <div class="checkboxInnerWrapper">
                <input type="checkbox" v-model="checkBoxAgreed"  class="checkboxInput"/>
              </div>
              <span>
                {{$t('pvp.iUnderstand')}}
              </span>
            </label>
          </div>
        </div>
        </div>
        <p v-if="!selectedWeaponId">
          {{$t('pvp.youNeedToHaveWeaponEquippedToEnterYouCanEquipInPlaza')}}
        </p>
        <div class="enterButtonsWrapper">
          <div class="enterArenaButtonWrapper">
            <cb-button class="custom-enter-arena-btn" :title="`${$t('pvp.enterArena')} <br/>`" :subTitle="$t('pvp.untiered')"
            @clickEvent="handleEnterArenaClick(true)"
            :isDisabled="!this.checkBoxAgreed || !this.selectedWeaponId"
            />
          </div>
          <div class="enterArenaButtonWrapper">
            <cb-button class="custom-enter-arena-btn" :title="`${$t('pvp.enterArena')} <br/>`" :subTitle="$t('pvp.tiered')"
            @clickEvent="handleEnterArenaClick(false)"
            :isDisabled="!this.checkBoxAgreed || !this.selectedWeaponId"
            />
          </div>
        </div>
      </div>
      <div class="characterImage">
        <pvp-character :characterTrait="characterInformation.element" :characterVersion="characterInformation.version" />
      </div>
      <pvp-arena-information
        class="arenaInformation"
        :tierRewardsPool="tierRewardsPool"
        :untieredRewardsPool="untieredRewardsPool"
        :tierTopRankers="untieredTopRankers"
        :currentRankedSeason="currentRankedSeason"
        :secondsBeforeNextSeason="secondsBeforeNextSeason"
        :characterInformation="characterInformation"
      />
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';
import BN from 'bignumber.js';
import PvPCharacter from './PvPCharacter.vue';
import PvPSeparator from './PvPSeparator.vue';
import checkIcon from '../../assets/checkImage.svg';
import ellipseIcon from '../../assets/ellipseImage.svg';
import i18n from '../../i18n';
import PvPArenaInfo from './PvPArenaInfo.vue';

const defaultStarOptions = [
  { text: i18n.t('nftList.sorts.any'), value: 0 },
  { text: '1', value: 1 },
  { text: '2', value: 2 },
  { text: '3', value: 3 },
  { text: '4', value: 4 },
  { text: '5', value: 5 },
];

const defaultElementOptions = [
  { value: '', text: i18n.t('nftList.sorts.any') },
  { value: 'Earth', text: i18n.t('traits.earth') },
  { value: 'Fire', text: i18n.t('traits.fire') },
  { value: 'Lightning', text: i18n.t('traits.lightning') },
  { value: 'Water', text: i18n.t('traits.water') }
];

export default {
  components: {
    'pvp-separator': PvPSeparator,
    'pvp-character': PvPCharacter,
    'pvp-arena-information': PvPArenaInfo,
  },

  props: {
    tierRewardsPool: {
      default: null
    },
    untieredRewardsPool: {
      default: null
    },
    tierTopRankers: {
      default: []
    },
    untieredTopRankers: {
      default: []
    },
    currentRankedSeason: {
      default: null
    },
    secondsBeforeNextSeason: {
      default: null
    },
    characterInformation: {
      default: {
        tier: null,
        name: '',
        level: null,
        power: null,
        fullPower: null,
        untieredFullPower: null,
        rank: null,
        element: null,
        version: null
      }
    },
    entryWager: {
      default: null
    },
    untieredEntryWager: {
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
    withdrawCost: {
      default: null
    }
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
      weaponStarOptions: defaultStarOptions,
      weaponElementFilter: '',
      weaponElementOptions: defaultElementOptions,
      shieldStarFilter: 0,
      shieldStarOptions: defaultStarOptions,
      shieldElementFilter: '',
      shieldElementOptions: defaultElementOptions,
    };
  },
  computed: {
    ...mapState(['currentCharacterId', 'contracts', 'defaultAccount', 'ownedWeaponIds', 'ownedShieldIds']),
    formattedEntryWager() {
      return new BN(this.entryWager).div(new BN(10).pow(18)).toFixed(2);
    },
    formattedWithdrawCost() {
      return new BN(this.withdrawCost).div(new BN(10).pow(18)).toFixed(2);
    },
    formattedUntieredEntryWager() {
      return new BN(this.untieredEntryWager).div(new BN(10).pow(18)).toFixed(2);
    },
    leavingArenaCost() {
      return +this.formattedEntryWager / 4;
    },
    getIconSource () {
      return this.checkBoxAgreed && this.selectedWeaponId ? checkIcon : ellipseIcon;
    },
  },
  methods: {
    ...mapActions([
      'approvePvpSkillSpending',
      'enterArena',
      'fetchCharacterWeapon',
      'fetchCharacterShield',
    ]),

    handleClearWeaponFilters() {
      this.weaponStarFilter = 0;
      this.weaponElementFilter = '';
    },
    handleClearShieldFilters() {
      this.shieldStarFilter = 0;
      this.shieldElementFilter = '';
    },
    handleErrorMessage(value, errorMessage, returnedMessage) {
      if (value.includes(`reverted with reason string '${errorMessage}'`)) {
        return this.$dialog.notify.error(returnedMessage);
      }
      return this.$dialog.notify.error(i18n.t('pvp.genericError'));
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
    async handleEnterArenaClick(tierless) {
      if (!this.checkBoxAgreed) {
        alert('Please check the \'I understand\' box to proceed.');
        return;
      }
      this.loading = true;
      if ((this.currentCharacterId || this.currentCharacterId === 0) && (this.selectedWeaponId || this.selectedWeaponId === 0) && this.entryWager) {
        const isUsingShield = this.selectedShieldId !== null;
        const shieldId = this.selectedShieldId === null ? 0 : this.selectedShieldId;
        try {
          if (tierless) {
            await this.approvePvpSkillSpending(this.untieredEntryWager);
          } else {
            await this.approvePvpSkillSpending(this.entryWager);
          }
        } catch(error) {
          console.error('Enter Arena Approval Error: ', error);
          this.loading = false;
          this.handleErrorMessage();
          return;
        }
        try {
          await this.enterArena({
            characterId: this.currentCharacterId,
            weaponId: this.selectedWeaponId,
            shieldId,
            useShield: isUsingShield,
            tierless
          });
        } catch(error){
          console.error('Enter Arena Error: ', error);
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

  async mounted() {
    this.selectedWeaponId = await this.fetchCharacterWeapon(this.currentCharacterId);
    this.selectedShieldId = await this.fetchCharacterShield(this.currentCharacterId);
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
.custom-enter-arena-btn{
  margin-right: 0px !important;
}
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
  display: flex;
  margin: 0 auto;
  font-family: 'Roboto';
  color: #b4b0a7;
  font-size: 0.75rem;
  margin-top: 1rem;
}
.mainWrapper {
  display: flex;
  width: 100%;
  margin: 0 auto;
  justify-content: space-between;
  flex-wrap: wrap;
}
.title {
  margin-bottom: 0.75rem;
  color: #cec198;
  font-size: 1.25rem;
  font-family: 'Trajan';
  line-height: 1.75rem;
  padding: 0;
  text-transform: uppercase;
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
        .placeholderImageWrapper{
          width: 4.5rem;
          height: 4.5rem;
          padding: 1rem;
          img {
            width: 100%;
            height: 100%;
          }
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
        white-space: wrap;
        @media  all and (max-width: 1057px) {
          white-space: inherit;
        }
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
      display: inline-flex;
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
        margin-bottom: 0.35rem;
        color: #b4b0a7;
        font-size: 0.875rem;
      }
    }
  }
  .enterButtonsWrapper {
    display: flex;
    margin-top: 2rem;
    margin-left: 2rem;
    flex-wrap: wrap;

      .enterArenaButtonWrapper {
      &:first-of-type {
        margin-right: 1rem;
      }

      .pvpButton {
        text-transform: uppercase;
      }
    }
  }
}
.characterImage {
  display: flex;
  width: 40%;
  min-width: 200px;
  padding: 3rem 0;
  @media only screen and (min-width: 1440px) {
    width: 30%;
    margin: 0;
  }
  @media only screen and (min-width: 1980px) {
    width: 20%;
  }
}
.arenaInformation {
  display: flex;
  flex-direction: column;
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
