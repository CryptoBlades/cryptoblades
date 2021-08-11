<template>
  <div class="body main-font">

    <div v-if="ownCharacters.length === 0" class="blank-slate">
      <div class="current-promotion">
        <div class="tob-bg-img promotion-decoration">
          <img class="vertical-decoration bottom" src="../assets/border-element.png">
        </div>
        <strong class="upper-text">Start earning today!</strong>
        <div class="bot-bg-img promotion-decoration">
            <img src="../assets/border-element.png">
        </div>
      </div>
      <big-button
        class="button"
        :mainText="`Recruit character for ${recruitCost} SKILL`"
        :disabled="!canRecruit()"
        @click="onMintCharacter"
        tagname="recruit_character"
      />
      <div v-if="formatSkill() < recruitCost" >
        <br>
        You can buy more SKILL from <a v-bind:href="`${getExchangeUrl}`" target="_blank">here</a>.
      </div>
    </div>
    <div class="row mt-3" v-if="ownCharacters.length > 0">
      <div class="col">
        <div v-if="ownCharacters.length > 0">
          <div class="d-flex justify-content-space-between">
            <h1>Characters ({{ ownCharacters.length }} / 4)</h1>
            <b-button
              v-if="canChangeTrait()"
              variant="primary"
              class="ml-auto gtag-link-others"
              @click="openChangeTrait"
              v-tooltip="'Change character\'s trait'" tagname="change_trait_character">
              Change Trait
            </b-button>
            <b-button
              v-if="canRename()"
              variant="primary"
              class="ml-auto gtag-link-others"
              @click="openRenameCharacter"
              v-tooltip="'Rename character'" tagname="rename_character">
              Rename Character
            </b-button>
            <b-button
              v-if="ownCharacters.length < 4"
              :disabled="!canRecruit()"
              variant="primary"
              class="ml-auto gtag-link-others"
              @click="onMintCharacter"
              v-tooltip="'Recruit new character'" tagname="recruit_character">
              Recruit ({{ recruitCost }} NON-IGO SKILL) <i class="fas fa-plus"></i>
            </b-button>
          </div>

          <character-list
            :value="currentCharacterId"
            @input="setCurrentCharacter"
          />
        </div>
        <b-modal class="centered-modal" ref="character-rename-modal"
                  @ok="renameCharacterCall">
                  <template #modal-title>
                    Rename Character
                  </template>
                  <b-form-input type="string"
                    class="modal-input" v-model="characterRename" placeholder="New Name" />
                  <span v-if="characterRename !== '' && characterRename.length < 2">
                    Name can not be shorter than 2 characters.
                  </span>
                </b-modal>
        <b-modal class="centered-modal" ref="character-change-trait-modal"
                  @ok="changeCharacterTraitCall">
                  <template #modal-title>
                    Change Character's Trait
                  </template>
                  <span >
                    Pick a trait to switch to.
                  </span>
                  <select class="form-control" v-model="targetTrait">
                    <option v-for="x in availableTraits" :value="x" :key="x">{{ x || 'Any' }}</option>
                  </select>
                </b-modal>
      </div>
    </div>
  </div>
</template>

<script lang='ts'>
import BN from 'bignumber.js';
import BigButton from '../components/BigButton.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import { fromWeiEther, toBN } from '../utils/common';
import { BModal, BvModalEvent } from 'bootstrap-vue';
import Vue from 'vue';

interface Data {
  recruitCost: string;
  haveRename: number;
  characterRename: string;
  haveChangeTraitFire: number;
  haveChangeTraitEarth: number;
  haveChangeTraitWater: number;
  haveChangeTraitLightning: number;
  targetTrait: string;
}

export default Vue.extend({
  computed: {
    ...mapState(['characters', 'maxStamina', 'currentCharacterId', 'defaultAccount', 'skillBalance']),
    ...mapGetters([
      'contracts',
      'ownCharacters',
      'ownWeapons',
      'currentCharacter',
      'currentCharacterStamina',
      'getCharacterName',
      'getExchangeUrl',
    ]),

    character(): any {
      if (!this.currentCharacter) {
        return {
          id: null,
          name: '???',
          level: -1,
          experience: -1,
        };
      }

      const c = this.currentCharacter;
      return {
        id: c.id,
        name: this.getCharacterName(c.id),
        level: c.level,
        experience: c.xp,
      };
    },

    availableTraits(): string[] {
      const availableTraits = [''];
      if(this.haveChangeTraitFire) {
        availableTraits.push('Fire');
      }
      if(this.haveChangeTraitEarth) {
        availableTraits.push('Earth');
      }
      if(this.haveChangeTraitWater) {
        availableTraits.push('Water');
      }
      if(this.haveChangeTraitLightning) {
        availableTraits.push('Lightning');
      }

      return availableTraits;
    }
  },

  async created() {
    const recruitCost = await this.contracts.CryptoBlades.methods.mintCharacterFee().call({ from: this.defaultAccount });
    const skillRecruitCost = await this.contracts.CryptoBlades.methods.usdToSkill(recruitCost).call();
    this.recruitCost = new BN(skillRecruitCost).div(new BN(10).pow(18)).toFixed(4);
    this.haveRename = await this.fetchTotalRenameTags();
    this.haveChangeTraitFire = await this.contracts.CharacterFireTraitChangeConsumables?.methods.getItemCount().call();
    this.haveChangeTraitEarth = await this.contracts.CharacterEarthTraitChangeConsumables?.methods.getItemCount().call();
    this.haveChangeTraitWater = await this.contracts.CharacterWaterTraitChangeConsumables?.methods.getItemCount().call();
    this.haveChangeTraitLightning = await this.contracts.CharacterLightningTraitChangeConsumables?.methods.getItemCount().call();
  },

  data() {
    return {
      recruitCost: '0',
      haveRename: 0,
      characterRename: '',
      haveChangeTraitFire: 0,
      haveChangeTraitEarth: 0,
      haveChangeTraitWater: 0,
      haveChangeTraitLightning: 0,
      targetTrait: '',
    } as Data;
  },

  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions(['mintCharacter', 'renameCharacter','changeCharacterTraitLightning',
      'changeCharacterTraitEarth', 'changeCharacterTraitFire', 'changeCharacterTraitWater', 'fetchTotalRenameTags']),

    async onMintCharacter() {
      try {
        await this.mintCharacter();
      } catch (e) {
        (this as any).$dialog.notify.error('Could not mint character: insufficient funds or transaction denied.');
      }
    },
    formatSkill() {
      return fromWeiEther(this.skillBalance);
    },
    canRecruit() {
      const cost = toBN(this.recruitCost);
      const balance = toBN(this.skillBalance);
      return balance.isGreaterThanOrEqualTo(cost);
    },
    canRename() {
      console.log('CR '+this.haveRename+' / '+this.currentCharacter+' / '+this.currentCharacter.id);
      return this.haveRename > 0 && this.currentCharacter !== undefined && this.currentCharacter.id > 0;
    },
    openRenameCharacter() {
      (this.$refs['character-rename-modal'] as BModal).show();
    },
    async renameCharacterCall(bvModalEvt: BvModalEvent) {
      if(this.characterRename.length < 2){
        bvModalEvt.preventDefault();
        return;
      }

      await this.renameCharacter({id: this.currentCharacter.id, name: this.characterRename.trim()});
      this.haveRename = await this.contracts.CharacterRenameTagConsumables?.methods.getItemCount().call();
    },

    canChangeTrait() {
      return (this.haveChangeTraitFire || this.haveChangeTraitEarth || this.haveChangeTraitWater || this.haveChangeTraitLightning)
        && this.currentCharacter !== undefined && this.currentCharacter.id > 0;
    },
    openChangeTrait() {
      (this.$refs['character-change-trait-modal'] as BModal).show();
    },
    async changeCharacterTraitCall(bvModalEvt: BvModalEvent) {
      if(!this.targetTrait) {
        bvModalEvt.preventDefault();
      }
      switch(this.targetTrait) {
      case 'Fire':
        await this.changeCharacterTraitFire({ id: this.currentCharacter.id });
        this.haveChangeTraitFire = await this.contracts.CharacterFireTraitChangeConsumables?.methods.getItemCount().call();
        break;
      case 'Earth' :
        await this.changeCharacterTraitEarth({ id: this.currentCharacter.id });
        this.haveChangeTraitEarth = await this.contracts.CharacterEarthTraitChangeConsumables?.methods.getItemCount().call();
        break;
      case 'Water':
        await this.changeCharacterTraitWater({ id: this.currentCharacter.id });
        this.haveChangeTraitWater = await this.contracts.CharacterWaterTraitChangeConsumables?.methods.getItemCount().call();
        break;
      case 'Lightning':
        await this.changeCharacterTraitLightning({ id: this.currentCharacter.id });
        this.haveChangeTraitLightning = await this.contracts.CharacterLightningTraitChangeConsumables?.methods.getItemCount().call();
        break;
      }
    },
  },

  components: {
    BigButton,
    CharacterList,
  },
});
</script>

<style scoped>

.current-promotion {
  width: 40%;
  text-align: center;
}

@media all and (max-width:  767.98px) {
  .current-promotion {
    width: 100vw;
    margin-top: 90px;
    padding-left: 15px;
  }
}

.promotion-decoration {
  width: 100%;
  margin-left: auto;
  margin-right: auto;
  margin-top: 10px;
  margin-bottom: 10px;
}

.upper-text {
  text-transform: uppercase;
}
</style>