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
              v-if="canChangeSkin()"
              variant="primary"
              class="ml-auto gtag-link-others"
              @click="openChangeSkin"
              v-tooltip="'Change character\'s skin'" tagname="change_skin_character">
              Change Skin
            </b-button>
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
         <b-modal class="centered-modal" ref="character-change-skin-modal"
                  @ok="changeCharacterSkinCall">
                  <template #modal-title>
                    Change Character's Skin
                  </template>
                  <span >
                    Pick a skin to switch to.
                  </span>
                  <select class="form-control" v-model="targetSkin">
                    <option v-for="x in availableSkins" :value="x" :key="x">{{ x }}</option>
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
import Vue from 'vue';

let getCosmeticsCountInterval: any = null;

interface Data {
  recruitCost: string;
  haveCharacterCosmetic1: number;
  haveCharacterCosmetic2: number;
  targetSkin: string;
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
    availableSkins(): string[] {
      const availableSkins = [];

      availableSkins.push('No Skin');

      if(this.haveCharacterCosmetic1 > 0) {
        availableSkins.push('Cool Skin 1');
      }
      if(this.haveCharacterCosmetic2 > 0) {
        availableSkins.push('Cool Skin 2');
      }

      return availableSkins;
    }
  },

  async created() {
    const recruitCost = await this.contracts.CryptoBlades.methods.mintCharacterFee().call({ from: this.defaultAccount });
    const skillRecruitCost = await this.contracts.CryptoBlades.methods.usdToSkill(recruitCost).call();
    this.recruitCost = new BN(skillRecruitCost).div(new BN(10).pow(18)).toFixed(4);

    this.loadCosmeticsCount();
    getCosmeticsCountInterval = setInterval(async () => {
      this.loadCosmeticsCount();
    }, 3000);
  },

  destroyed() {
    clearInterval(getCosmeticsCountInterval);
  },

  data() {
    return {
      recruitCost: '0',
      haveCharacterCosmetic1: 0,
      haveCharacterCosmetic2: 0,
      targetSkin: ''
    } as Data;
  },

  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions(['mintCharacter',]),
      'changeCharacterCosmetic', 'removeCharacterCosmetic', 'fetchOwnedCharacterCosmetics']),

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

    async loadCosmeticsCount() {
      this.haveCharacterCosmetic1 = await this.fetchOwnedCharacterCosmetics({cosmetic: 1});
      this.haveCharacterCosmetic2 = await this.fetchOwnedCharacterCosmetics({cosmetic: 2});
    },
    canChangeSkin() {
      return this.currentCharacter !== undefined && this.currentCharacter.id >= 0; // show even if no owned cosmetics to allow removing cosmetic
    },
    openChangeSkin() {
      (this.$refs['character-change-skin-modal'] as BModal).show();
    },
    async changeCharacterSkinCall() {
      switch(this.targetSkin) {
      case 'No Skin':
        await this.removeCharacterCosmetic({ id: this.currentCharacter.id });
        this.haveCharacterCosmetic1 = await this.fetchOwnedCharacterCosmetics({cosmetic: 1});
        this.haveCharacterCosmetic2 = await this.fetchOwnedCharacterCosmetics({cosmetic: 2});
        break;
      case 'Cool Skin 1':
        await this.changeCharacterCosmetic({ id: this.currentCharacter.id, cosmetic: 1 });
        this.haveCharacterCosmetic1 = await this.fetchOwnedCharacterCosmetics({cosmetic: 1});
        break;
      case 'Cool Skin 2':
        await this.changeCharacterCosmetic({ id: this.currentCharacter.id, cosmetic: 2 });
        this.haveCharacterCosmetic2 = await this.fetchOwnedCharacterCosmetics({cosmetic: 2});
        break;
      }
    }
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