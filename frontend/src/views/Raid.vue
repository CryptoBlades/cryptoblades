<template>
  <div class="main-font">
    <div class="row">
      <div class="col-md-12 col-lg-6">
        <span class="bold raid-title-section">Hellborn raid</span>
        <hr class="divider">
        <div class="row boss-row">
          <div class="col-md-12 col-lg-6 order-xs-last order-sm-last order-lg-first">
            <ul class="list-group raid-details mb-4">
              <li class="list-group-item d-flex justify-content-between align-items-center raid-details-text">
                Number of Raiders
                <span class="badge badge-primary badge-pill">{{ raiderCount }}</span>
              </li>
              <li class="list-group-item d-flex justify-content-between align-items-center raid-details-text">
                Total Power
                <span class="badge badge-primary badge-pill">{{ totalPower }}</span>
              </li>
              <li class="list-group-item d-flex justify-content-between align-items-center raid-details-text">
                 Boss Power
                <span class="badge badge-primary badge-pill">{{ bossPower }}</span>
              </li>
              <li class="list-group-item d-flex justify-content-between align-items-center raid-details-text progress-container">
                <div class="d-flex justify-content-between align-items-center raid-details-text" style="width: 100%;">
                Victory chance
                <span class="badge badge-primary badge-pill">{{ formattedWinChance }}</span>
                </div>
                <div class="progress" style="width: 100%">
                  <div class="progress-bar progress-bar-striped progress-bar-animated players-progress-bar"
                    role="progressbar" :style="[{'width': formattedWinChance, 'background-color': calculateProgressBarColor()}]"></div>
                  <div class="progress-bar progress-bar-striped progress-bar-animated bg-danger boss-progress-bar"
                    role="progressbar" :style="[{'width': (100 - calculateWinChance()) + '%'}]"></div>
                </div>
              </li>
            </ul>
            <span class="mt-3 bold raid-title-section">
              Drops
              <b-icon-question-circle class="rewards-tooltip"
               v-tooltip="'Rewards are based on your contributed power relative to others.<br>Joining early gives up to 10% bonus.'"/>
            </span>
            <hr class="divider">
            <div class="drops">
              <div class="drops-icons">
                <nft-icon :isDefault="true" :nft="{ type: 'weapon' }" />
                <nft-icon :isDefault="true" :nft="{ type: 'trinket' }"/>
                <nft-icon :isDefault="true" :nft="{ type: 'junk' }"/>
                <nft-icon :isDefault="true" :nft="{ type: 'secret' }"/>
                <nft-icon :isDefault="true" :nft="{ type: 'lbdust' }"/>
                <nft-icon :isDefault="true" :nft="{ type: '4bdust' }"/>
                <nft-icon :isDefault="true" :nft="{ type: '5bdust' }"/>
              </div>
              <br />
              <span class="bold raid-title-section xp-reward-section">
                XP reward</span> <span class="xp-reward ml-3 raid-details-text"> {{ xpReward }}
                <b-icon-question-circle
                  v-tooltip="`XP will be automatically claimed by participating characters.<br>
                    If your character performs exceptionally well they will be rewarded with up to +2400% bonus XP.`"/>
              </span>
            </div>
          </div>
          <div class="col-xs-12 col-sm-12 col-md-12 col-lg-6 order-xs-first order-sm-first boss-col">
            <div class="boss-box">
              <div class="raid-title">
                <span class="title mr-3"> {{ bossName }} </span>
                <span :class="traitNumberToName(bossTrait).toLowerCase() + '-icon trait-icon'" />
              </div>
              <div class="img-responsive boss-img">
                <img :src="getBossArt(raidIndex)" class="img-responsive" />
              </div>
            </div>
          </div>
        </div>
        <hr class="divider">
      </div>
      <div class="col-md-12 col-lg-6">
        <div class="row">
          <div class="col-xs-12 col-sm-12 col-lg-6 weap-box">
            <span class="raid-title-section bold">
              <span>Weapon
                <Hint
                text="Your weapon multiplies your power<br>
                  <br>+Stats determine the multiplier
                  <br>Stat element match with character gives greater bonus"/>
                  </span>
                  <span class="float-right sub-text">
                    Multiplier: x{{ currentMultiplier }}
                  </span>
              </span>
              <hr class="divider">
            <div class="header-row">
              <div v-if="selectedWeaponId" class="weapon-icon-wrapper">
                <weapon-icon class="weapon-icon" :weapon="getSelectedWeapon" />
              </div>
              <b-button v-if="selectedWeaponId" variant="primary" class="new-weapon-button" @click="selectedWeaponId = null">
                Choose New Weapon
              </b-button>
            </div>

            <weapon-grid v-if="!selectedWeaponId" v-model="selectedWeaponId" class="raid-weapon-grid">
              <template #sold="{ weapon: { id } }">
                <div class="sold" v-if="participatingWeapons && participatingWeapons.find(x => +x === +id) !== undefined"><span>in raid</span></div>
              </template>
            </weapon-grid>
            <hr class="divider">
          </div>
          <div class="col-xs-12 col-sm-12 col-lg-6 char-box">
            <span class="raid-title-section bold">Character <span class="float-right sub-text">Power {{ currentCharacterPower }}</span></span>
            <hr class="divider">
            <character-list :value="currentCharacterId" @input="setCurrentCharacter" class="raid-style">
              <template #sold="{ character: { id } }">
                <div class="sold" v-if="participatingCharacters && participatingCharacters.find(x => +x === +id) !== undefined"><span>in raid</span></div>
              </template>
            </character-list>
            <hr class="divider">
          </div>
        </div>
      </div>
    </div>
    <div class="container">
      <div class="row">
        <div class="col-12">
          <div class="text-center">
            Joining will cost <span class="badge badge-secondary">{{ staminaCost }}
            stamina </span>,
            <span class="badge badge-secondary">{{ durabilityCost }}
            durability </span> and
            <span class="badge badge-secondary"><CurrencyConverter :skill="convertWeiToSkill(joinCost)" :skill-min-decimals="1"/></span>
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-sm-12">
        <div class="raid-info-box mt-3">
          <div class="row raid-summary-container">
            <div class='col-sm-4 raid-summary-text'>
              <div class="float-lg-left mb-sm-2">
                <div class="finish">
                    <span class="title">Finishes on</span>
                    {{ expectedFinishTime }}
                    <br />
                    <span class="title">Raid status</span> {{ raidStatus }}
                  </div>
              </div>
            </div>
            <div class="col-sm-8 row">
              <big-button v-if="claimButtonActive" class="encounter-button btn-styled" :mainText="`Claim rewards`" @click="promptRewardClaim()" />
              <b-modal id="rewardsRaidPicker" title="Raid rewards selector" @ok="claimRewardIndex(rewardsRaidId)">
                <div class="raid-picker">
                  Select a raid to claim rewards from:
                  <select class="form-control raid-id-selector" v-model="rewardsRaidId">
                    <option v-for="id in rewardIndexes" :value="id" :key="id">{{ id }}</option>
                  </select>
                </div>
              </b-modal>

            <b-modal id="rewardsModal" title="Raid rewards" size="lg">
              <template #modal-header>
                <div v-if="!spin" class="new-weapon-header-text text-center">
                  <strong>Rewards</strong>
                </div>
                <div v-if="spin" class="new-weapon-header-text text-center">
                  <strong>Claiming rewards...</strong>
                </div>
              </template>
              <div class="text-center">
                <b-spinner v-if="spin" type="grow" label="Loading..."></b-spinner>
                <b-spinner v-if="spin" type="grow" label="Loading..."></b-spinner>
                <b-spinner v-if="spin" type="grow" label="Loading..."></b-spinner>
              </div>
              <div class="text-center" v-if="!spin">
                <strong>All participating characters got {{xpReward}} XP</strong><br>
                <div v-if="bonuxXpCharacterNames && bonuxXpCharacterNames.length > 0">
                  <strong>Following character(s) performed exceptionally well and were rewarded with bonus XP:</strong>
                  <br>
                  <span v-for="i in bonuxXpCharacterNames.length" :key="i">
                    {{bonuxXpCharacterNames[i - 1]}}: +{{bonuxXpAmounts[i - 1]}} XP<br>
                  </span>
                </div>
                <br>
                <p class="h2 text-center"><u>Loot</u></p>
              </div>
              <nft-list v-if="!spin" :showGivenNftIdTypes="true" :nftIdTypes="rewards" :isReward="true"/>
            </b-modal>

              <big-button class="encounter-button btn-styled" :mainText="`Sign up!`"
                          v-tooltip="`Joining will cost ${formatStaminaHours}h of stamina`" @click="joinRaidMethod()" />
            </div>
            <div class='col-sm-4 raid-summary-text'>
             <div class="float-lg-right text-sm-center mt-sm-2 text-center">
                <div class="finish">
                    <span class="title">Your Power:  {{accountPower}}</span>
                  </div>
              </div>
            </div>
          </div>
          </div>
        </div>
    </div>
 </div>
</template>
<script lang="ts">

import Vue from 'vue';
import { mapActions, mapGetters, mapState, mapMutations } from 'vuex';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import BigButton from '../components/BigButton.vue';
import WeaponIcon from '../components/WeaponIcon.vue';
import Hint from '../components/Hint.vue';
import NftIcon from '@/components/NftIcon.vue';
import NftList, { NftIdType } from '@/components/smart/NftList.vue';
import CurrencyConverter from '../components/CurrencyConverter.vue';
import { GetTotalMultiplierForTrait, IWeapon } from '@/interfaces/Weapon';
import { CharacterPower, IRaidState, IState } from '@/interfaces';
import { getBossArt } from '@/raid-boss-art-placeholder';
import { traitNumberToName } from '@/contract-models';
import { fromWeiEther } from '@/utils/common';
import { staminaToHours } from '@/utils/date-time';
import { RaidRewards, Weapon, Junk, Keybox, DustLb, Dust4b, Dust5b, BonusXp } from '@/interfaces/RaidRewards';


interface RaidMappedActions {
  fetchRaidState(): Promise<void>;
  joinRaid(payload: { characterId: string, weaponId: string}): Promise<void>;
  fetchRaidRewards(payload: {startIndex: number, endIndex: string }): Promise<string[]>;
  claimRaidRewards(payload: { rewardIndex: string }): Promise<RaidRewards>;
  fetchRaidingCharacters(): Promise<string[]>;
  fetchRaidingWeapons(): Promise<string[]>;
  fetchIsRaidStarted(): Promise<boolean>;
  fetchHaveEnoughEnergy(payload: { characterID: string, weaponID: string }): Promise<boolean>;
  fetchIsCharacterRaiding(payload: { characterID: string }): Promise<boolean>;
  fetchIsWeaponRaiding(payload: { weaponID: string }): Promise<boolean>;
  fetchCharacters(payload: { characterIds: (string | number)[]}): Promise<void>;
}

interface RaidMappedMutations {
  setCurrentCharacter(state: IState, characterId: number): void;
}

interface RaidMappedGetters {
  getRaidState(): IRaidState;
}

let interval: number;

const dragonNames = [
  'Fudbringer',
  'HODL Lord',
  'Skill Eater',
  'Chain Congester',
  'Swap Guardian',
  'Blade Hoarder',
  'Centralizer',
  'Exchange Tormentor',
  'Eater of Stakes'
];

const bossImages = [
  '../assets/CB_Hellborn Brute.gif',
  '../assets/CB_Hellborn Executioner.gif',
  '../assets/CB_Hellborn Marauder.gif',
  '../assets/CB_Hellborn Overlord.gif',
  '../assets/CB_Hellborn Shaman.gif',
];

export default Vue.extend({
  data() {
    return {
      selectedWeaponId: '',
      raidIndex: '',
      bossName: '',
      raiderCount: '',
      totalPower: '',
      expectedFinishTime: '',
      xpReward: '',
      staminaCost: '',
      durabilityCost: '',
      joinCost: '',
      raidStatus: '',
      bossPower: '',
      bossTrait: '',
      accountPower: '',
      rewardsRaidId: '',
      rewardIndexes: [] as string[],
      rewards: [] as NftIdType[],
      spin: false,
      participatingCharacters: [] as string[],
      participatingWeapons: [] as string[],
      bonuxXpCharacterNames: [] as string[],
      bonuxXpAmounts: [] as string[],
    };
  },

  computed: {
    ...mapState(['characters', 'maxStamina', 'currentCharacterId', 'ownedCharacterIds', 'defaultAccount']),
    ...mapGetters(['ownCharacters', 'ownWeapons', 'currentCharacter',
      'currentCharacterStamina', 'getWeaponDurability', 'contracts', 'getCharacterName']),

    claimButtonActive(): boolean {
      return this.rewardIndexes !== null && this.rewardIndexes.length > 0;
    },

    currentMultiplier(): string {
      if(!this.selectedWeaponId) return '0';
      const currentWeapon = this.ownWeapons.find((weapon: IWeapon) => weapon.id === +this.selectedWeaponId);
      if(!currentWeapon) return '0';
      return GetTotalMultiplierForTrait(currentWeapon, this.currentCharacter.trait).toFixed(2);
    },

    currentCharacterPower(): number {
      if(!this.currentCharacter) return 0;
      return CharacterPower(this.currentCharacter.level);
    },

    getSelectedWeapon(): IWeapon {
      return this.ownWeapons.find((weapon: IWeapon) => weapon.id === +this.selectedWeaponId);
    },

    formatStaminaHours(): string {
      return staminaToHours(+this.staminaCost).toFixed(1);
    },

    formattedWinChance(): string {
      return `${this.calculateWinChance()}%`;
    }
  },

  methods: {
    getBossArt,
    traitNumberToName,
    ...(mapActions([
      'fetchRaidState',
      'joinRaid',
      'fetchRaidRewards',
      'claimRaidRewards',
      'fetchRaidingCharacters',
      'fetchRaidingWeapons',
      'fetchIsRaidStarted',
      'fetchHaveEnoughEnergy',
      'fetchIsCharacterRaiding',
      'fetchIsWeaponRaiding',
      'fetchCharacters'
    ]) as RaidMappedActions),
    ...(mapMutations([
      'setCurrentCharacter'
    ]) as RaidMappedMutations),
    ...(mapGetters([
      'getRaidState',
    ]) as RaidMappedGetters),

    calculateWinChance(): string {
      return (Math.min(Math.max(+this.totalPower / +this.bossPower / 2 * 100, 1), 99)).toFixed(0);
    },

    calculateProgressBarColor(): string {
      if(+this.calculateWinChance() < 30){
        return '#ccae4f';
      } else if (+this.calculateWinChance() < 70){
        return 'blue';
      } else {
        return 'green';
      }
    },

    convertWeiToSkill(wei: string): string {
      return fromWeiEther(wei);
    },

    weaponHasDurability(id: number): boolean{
      return this.getWeaponDurability(id) > 0;
    },

    async joinRaidMethod(): Promise<void> {
      if (!this.selectedWeaponId || !this.currentCharacterId) {
        (this as any).$dialog.notify.error('Check Character and Weapon Selection and try again...');
        return;
      }

      const isRaidStarted = await this.isRaidStarted();
      if(!isRaidStarted) {
        (this as any).$dialog.notify.error('Raid has not started yet...');
        return;
      }
      const isCharacterRaiding = await this.isCharacterAlreadyRaiding(this.currentCharacterId);
      if(isCharacterRaiding) {
        (this as any).$dialog.notify.error('Selected character is locked in the raid already...');
        return;
      }
      const isWeaponRaiding = await this.isWeaponAlreadyRaiding(this.selectedWeaponId);
      if(isWeaponRaiding) {
        (this as any).$dialog.notify.error('Selected weapon is locked in the raid already...');
        return;
      }
      const haveEnoughEnergy = await this.haveEnoughEnergy(this.currentCharacterId, this.selectedWeaponId);
      if(!haveEnoughEnergy) {
        (this as any).$dialog.notify.error('Not enough stamina or durability...');
        return;
      }

      try {
        await this.joinRaid({ characterId: this.currentCharacterId, weaponId: this.selectedWeaponId});
        this.selectedWeaponId = '';
      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error('Whoops...');
      }

      await this.getParticipatingCharacters();
      await this.getParticipatingWeapons();
    },

    async getParticipatingCharacters(): Promise<void> {
      // gets the list of this player's raid locked characters
      // TODO store these?
      this.participatingCharacters = await this.fetchRaidingCharacters();
    },

    async getParticipatingWeapons(): Promise<void> {
      // gets the list of this player's raid locked weapons
      // TODO store these?
      this.participatingWeapons = await this.fetchRaidingWeapons();
    },

    async isCharacterAlreadyRaiding(characterID: string): Promise<boolean> {
      return await this.fetchIsCharacterRaiding({
        characterID
      });
    },

    async isWeaponAlreadyRaiding(weaponID: string): Promise<boolean> {
      return await this.fetchIsWeaponRaiding({
        weaponID
      });
    },

    async isRaidStarted(): Promise<boolean> {
      return await this.fetchIsRaidStarted();
    },

    async haveEnoughEnergy(characterID: string, weaponID: string): Promise<boolean>{
      return await this.fetchHaveEnoughEnergy({
        characterID,
        weaponID
      });
    },

    async getRewardIndexes(): Promise<void> {
      if(!this.raidIndex)
        return;
      let startIndex = +this.raidIndex-21; // one week worth
      if(startIndex < 0)
        startIndex = 0;
      const endIndex = this.raidIndex;

      this.rewardIndexes = await this.fetchRaidRewards({
        startIndex,
        endIndex
      });
    },

    promptRewardClaim(): void {
      // should offer a popup here to pick which index to claim
      // if only one index, then claim instantly
      if(this.rewardIndexes !== null && this.rewardIndexes.length > 0) {
        if(this.rewardIndexes.length === 1) {
          this.claimRewardIndex(this.rewardIndexes[0]);
        }
        else {
          (this as any).$bvModal.show('rewardsRaidPicker');
        }
      }
    },

    async claimRewardIndex(rewardIndex: string): Promise<void> {
      this.bonuxXpCharacterNames = [];
      this.bonuxXpAmounts = [];
      const result = await this.claimRaidRewards({
        rewardIndex
      });

      const nfts: NftIdType[] = [];
      if(result.weapons) {
        result.weapons.forEach((x: Weapon) => {
          nfts.push({ type: 'weapon', id: x.tokenID });
        });
      }
      if(result.junks) {
        result.junks.forEach((x: Junk) => {
          nfts.push({ type: 'junk', id: x.tokenID });
        });
      }
      if(result.keyboxes) {
        result.keyboxes.forEach((x: Keybox) => {
          nfts.push({ type: 'keybox', id: x.tokenID });
        });
      }
      if(result.dustLb) {
        result.dustLb.forEach((x: DustLb) => {
          nfts.push({ type: 'dustLb', id: 0, amount: x.amount });
        });
      }
      if(result.dust4b) {
        result.dust4b.forEach((x: Dust4b) => {
          nfts.push({ type: 'dust4b', id: 0, amount: x.amount });
        });
      }
      if(result.dust5b) {
        result.dust5b.forEach((x: Dust5b) => {
          nfts.push({ type: 'dust5b', id: 0, amount: x.amount });
        });
      }
      if(result.bonusXp) {
        result.bonusXp.forEach((x: BonusXp) => {
          this.bonuxXpCharacterNames.push(this.getCharacterName(x.charID));
          this.bonuxXpAmounts.push(x.amount);
        });
      }

      this.rewards = nfts;
      this.spin = true;
      (this as any).$bvModal.show('rewardsModal');
      setTimeout(() => {
        this.spin = false;
      }, 10000);

      await this.fetchCharacters(this.ownedCharacterIds);
    },

    getBossName(): string {
      return dragonNames[+this.raidIndex % dragonNames.length];
    },

    getBossImage(): string {
      return bossImages[+this.raidIndex % bossImages.length];
    },

    processRaidData(): void {
      const raidData = this.getRaidState();
      this.raidIndex = raidData.index;
      this.bossName = this.getBossName();
      this.raiderCount = raidData.raiderCount;
      this.totalPower = raidData.playerPower;
      this.expectedFinishTime = new Date(+raidData.expectedFinishTime * 1000).toLocaleString();
      this.xpReward = raidData.xpReward;
      this.staminaCost = raidData.staminaCost;
      this.durabilityCost = raidData.durabilityCost;
      this.joinCost = raidData.joinSkill;
      this.raidStatus = raidData.status ? 'Preparation' : 'Finished';
      this.bossPower = raidData.bossPower;
      this.bossTrait = raidData.bossTrait;
      this.accountPower = raidData.accountPower;
    }
  },

  async mounted() {
    const refreshRaidData = async () => {
      await (this as any).getRewardIndexes();
      await (this as any).fetchRaidState();
      (this as any).processRaidData();
      await (this as any).getParticipatingCharacters();
      await (this as any).getParticipatingWeapons();
    };
    await refreshRaidData();
    interval = window.setInterval(async () => {
      await refreshRaidData();
    }, 3000);
  },

  beforeDestroy() {
    clearInterval(interval);
  },

  components: {
    CurrencyConverter,
    BigButton,
    CharacterList,
    WeaponGrid,
    WeaponIcon,
    Hint,
    NftIcon,
    NftList
  },
});
</script>

<style scoped>

.raid-height {
  height: 500px !important;
}

.raid-style {
  display: block;
  width: 100%;
  padding: 0;
  height: 577px;
  overflow-y: auto;
  overflow-x: hidden;
  border: 0.5px solid #1f1f1f;
}

.progress-container {
  flex-direction: column;
}

.players-progress-bar {
  animation-direction: reverse;
}

.boss-progress-bar {
  animation-direction: normal;
}

.raid-style::-webkit-scrollbar-track
{
	-webkit-box-shadow: inset 0 0 6px rgba(156, 109, 46, 0.3);
	background-color: #F5F5F5;
}

.raid-style::-webkit-scrollbar
{
	width: 10px;
	background-color: #F5F5F5;
}
.raid-style::-webkit-scrollbar-thumb
{
	background-color: #a3773e;
	border: 2px solid #555555;
}

.raid-style >>> ul.character-list {
    display: flex;
    flex-direction: row;
    flex-wrap: wrap;
}
.raid-style >>> ul.character-list > li.character {
    margin: 0 0 0 0;
    flex-grow: 0;
    flex-shrink: 0;
}

.raid-style >>> ul.character-list > li.character.selected {
    box-shadow: 0 3px 15px #ffd400;
    border: 0.5px solid #fff;
}

.raid-weapon-grid >>> .stars-elem  {
  width: 50% !important;
  max-width: 100% !important;
  flex: 0 0 50% !important;
}

.raid-weapon-grid >>> .clear-filters-button {
  max-width: 300px;
  width: 100%;
  margin-top: 10px;
  margin-left: 0px;
}

.raid-weapon-grid >>> .clear-filters-button > span {
  margin: 0 auto;
}

.raid-weapon-grid {
  height: 577px;
  overflow-y: auto;
  border: 0.5px solid #1f1f1f;
}

.raid-weapon-grid::-webkit-scrollbar-track
{
	-webkit-box-shadow: inset 0 0 6px rgba(156, 109, 46, 0.3);
	background-color: #F5F5F5;
}

.raid-weapon-grid::-webkit-scrollbar
{
	width: 10px;
	background-color: #F5F5F5;
}
.raid-weapon-grid::-webkit-scrollbar-thumb
{
	background-color: #a3773e;
	border: 2px solid #555555;
}


.raid-weapon-grid >>> .weapon-grid {
  width: 100% !important;
  margin: 0 auto;
  display: grid;
  justify-content: center;
  align-content: center;
  position: relative;
}

.raid-weapon-grid >>> ul.weapon-grid > li.weapon {
  margin: 0 auto;
  height: 100%;
  border-radius: 0;
  background-image: none;
  height: auto;
}
h2 {
  font-size: 20px;
}
h2 > span.sub-text {
  font-size: 16px;
  color: #fff;
  vertical-align: middle;
  line-height: 2;
}
hr.divider {
  border: 0.5px solid #dabf75;
}
.container-fluid {
  margin-top: 500px;
}
.list-group {
  max-width: 100%;
  border: 0;
  background: none;
}
.list-group-item {
  border-top: 0px !important;
  border-left: 0px !important;
  border-right: 0px !important;
  border-bottom: 0.5px solid #242423 !important;
}
.body {
  display: flex;
  flex-direction: row;
  align-items: center;
  height: calc(100vh - 56px - 160px - 32px);
}
.raid-info-box {
  background: #2e2e30cc;
  padding: 20px;
  margin-bottom: 20px;
  border-radius: 0px;
  border: 1px solid #515152cc;
}
.border-box {
  border: 0.5px solid #242423;
  border-radius: 5px;
  padding: 10px 20px;
}
.raid-header {
  border-bottom: 0.5px dashed rgb(49, 45, 40);
  margin-bottom: 20px;
}
.boss-row {
  margin-bottom: -3px;
}
.boss-img {
  width: 100%;
  height: 100%;
  max-height: 413px;
  text-align: center;
}
.boss-img > img {
  width: 100%;
  height: 100%;
  max-height: 413px;
  max-width: 370px;
}
.boss-box {
  border: 0.5px solid #242423;
  border-radius: 5px;
  padding: 10px 20px;
  background: #ccc;
  background-image: url(https://www.cryptoblades.io/images/background/video-bg.png);
  background-repeat: no-repeat;
   background-position: center;
}
.title {
  font-weight: bold;
  font-size: 1.4em;
}

.fill-space {
  height: 100%;
  padding: 1em;
  padding-top: 3em;
}

.left-side,
.right-side {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.chooser,
.power {
  flex: 1;
  display: flex;
  flex-direction: row;
}

.chooser .left-side,
.chooser .right-side {
  max-height: 300px;
  overflow-y: auto;
}

.raid-info {
  flex-direction: row;
}

.raid-summary-text {
    width: auto;
    flex: none;
}

.raid-summary-container {
    flex-wrap: wrap;
    justify-content: space-between;
}

.raiders,
.drops {
  margin-top: 1em;
}

.drops-icons {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  width: 100%;
  padding: 0;
  overflow-y: auto;
  overflow-x: hidden;
  border: 0.5px solid #1f1f1f;
  height: 161px;
}

.drops-icons >>> ul {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
}

.drops-icons::-webkit-scrollbar-track
{
	-webkit-box-shadow: inset 0 0 6px rgba(156, 109, 46, 0.3);
	background-color: #F5F5F5;
}

.drops-icons::-webkit-scrollbar
{
	width: 10px;
	background-color: #F5F5F5;
}
.drops-icons::-webkit-scrollbar-thumb
{
	background-color: #a3773e;
	border: 2px solid #555555;
}


.encounter-button {
  display: block;
  top:0 !important;
}
.raid-boss,
.raid-signup {
  justify-content: space-between;
}

.warning,
.power,
.total-power,
.action {
  text-align: center;
  margin-top: 0.5em;
}

.encounter-button {
  display: block;
  margin: 2px auto;
  height: 5em;
  width: 20em;
  position: relative;
  top: 3vw;
}

.weapon-icon-wrapper {
  background: rgba(255, 255, 255, 0.1);
  width: 12em;
  height: 12em;
  margin: 0 auto;
}

.new-weapon-button {
  margin-left: 0;
  margin-top: 20px;
}

.enemy-list[data-v-067077ae] {
    display: flex;
    flex-wrap: wrap;
    padding-left: 30px;
    padding-right: 30px;
}

.raid-picker {
  display: flex;
  align-items: center;
}

.xp-reward-section {
  display: inline;
}

.rewards-tooltip {
  margin: auto 0;
}

.raid-title-section {
  font-size : 1.5em;
  color : #dabf75;
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
}

.raid-details {
  border: 1px solid;
  border-radius: 5px;
}

.raid-details-text {
  font-size: 1.2em;
  color: #ccae4f;
}

.raid-details-text > span {
  background-color: #5c6063;
}
.form-control.raid-id-selector {
  width: fit-content;
  height: fit-content;
  margin: 5px;
  padding: 0;
}

.xp-reward {
  background: #40422f;
  border: 1px solid #727151;
  padding: 4px;
  border-radius: 25%;
}

.trait-icon {
  transform: scale(1.5);
  margin-left: -10px;
}

.header-row {
  display: flex;
  align-items: center;
}

.header-row h1 {
  margin-left: 10px;
  margin-bottom: 5px;
}

.header-row .hint {
  font-size: 2em;
}

.header-row {
  display: block;
  text-align: center;
}

@media (max-width: 994px) {

  img.img-responsive {
    height: 350px;
  }
}
@media (max-width: 726px) {
  .weap-box, .char-box {
    margin-top: 30px;
  }
  .img-responsive .boss-img {
    height: 300px;
  }
  .finish {
    text-align: center;
    margin: 10px;
  }
}


@media (max-width: 1251px) {
  .boss-col {
    display: block;
  }
}
</style>
