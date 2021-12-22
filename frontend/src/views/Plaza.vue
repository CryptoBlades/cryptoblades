<template>
  <div class="body main-font">
    <ins class="61c208e596bc5000134ec909" style="display:inline-block;width:970px;height:90px;"></ins>
    <script2>!function (e, n, c, t, o, r) {
      !function e(n, c, t, o, r, m, s, a) {
        s = c.getElementsByTagName(t)[0], (a = c.createElement(t)).async = !0, a.src = "https://" + r[m] + "/js/" + o + ".js", a.onerror = function () {
          a.remove(), (m += 1) >= r.length || e(n, c, t, o, r, m)
        }, s.parentNode.insertBefore(a, s)
      }(window, document, "script", "61c208e596bc5000134ec909", ["cdn.bmcdn2.com"], 0)
    }();</script2>
    <div v-if="ownCharacters.length === 0" class="blank-slate">
      <div class="current-promotion">
        <div class="tob-bg-img promotion-decoration">
          <img class="vertical-decoration bottom" src="../assets/border-element.png">
        </div>
        <strong class="upper-text">{{ $t("plaza.welcome") }}</strong>
        <div class="bot-bg-img promotion-decoration">
            <img src="../assets/border-element.png">
        </div>
      </div>
      <big-button
        class="button"
        :mainText="$t('plaza.recruitCharacter') + ` ${recruitCost} SKILL`"
        :disabled="!canRecruit()"
        @click="onMintCharacter"
        tagname="recruit_character"
      />
      <div v-if="formatSkill() < recruitCost" >
        <br>
        <i18n path="plaza.notEnoughSkill" tag="label" for="plaza.notEnoughSkillLink">
          <a v-bind:href="`${getExchangeUrl}`" target="_blank" rel="noopener noreferrer">{{$t("plaza.notEnoughSkillLink")}}</a>
        </i18n>
          <a :href="getExchangeTransakUrl()" target="_blank" rel="noopener noreferrer"> {{$t("plaza.buyBNBTransak")}}</a>.
      </div>
    </div>
    <div class="row mt-3" v-if="ownCharacters.length > 0">
      <div class="col">
        <div v-if="ownCharacters.length > 0">
          <div class="d-flex justify-content-space-between">
            <h1>{{$t('characters')}} ({{ ownCharacters.length }} / 4)</h1>
            <b-button
              v-if="ownCharacters.length < 4"
              :disabled="!canRecruit()"
              variant="primary"
              class="ml-auto gtag-link-others"
              @click="onMintCharacter"
              v-tooltip="$t('plaza.recruitNew')" tagname="recruit_character">
              {{$t('plaza.recruit')}} ({{ recruitCost }} NON-IGO SKILL) <i class="fas fa-plus"></i>
            </b-button>
          </div>

          <character-list
            :value="currentCharacterId"
            :showNftOptions="true"
            @input="setCurrentCharacter"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script lang='ts'>
import BN from 'bignumber.js';
import BigButton from '../components/BigButton.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import {mapActions, mapGetters, mapMutations, mapState} from 'vuex';
import {fromWeiEther, toBN} from '../utils/common';
import Vue from 'vue';
import i18n from '@/i18n';

interface Data {
  recruitCost: string;
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
  },

  async created() {
    console.log(this.getExchangeUrl, this.getExchangeTransakUrl());
    const recruitCost = await this.contracts.CryptoBlades.methods.mintCharacterFee().call({ from: this.defaultAccount });
    const skillRecruitCost = await this.contracts.CryptoBlades.methods.usdToSkill(recruitCost).call();
    this.recruitCost = new BN(skillRecruitCost).div(new BN(10).pow(18)).toFixed(4);
  },

  data() {
    return {
      recruitCost: '0',
    } as Data;
  },

  methods: {
    ...mapMutations(['setCurrentCharacter']),
    ...mapActions(['mintCharacter']),
    ...mapGetters(['getExchangeTransakUrl']),

    async onMintCharacter() {
      try {
        await this.mintCharacter();
      } catch (e) {
        (this as any).$dialog.notify.error(i18n.t('plaza.couldNotMint'));
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
