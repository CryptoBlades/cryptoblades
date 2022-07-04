<template>
  <div class="character-display-container bd-right" >
        <div class="row character-full-list">
          <b-col class="character-list" v-if="currentPath != '/blacksmith'"
            v-bind:class="[getIsInCombat ? 'disabled-li' : '', getIsCharacterViewExpanded ? '' : 'centered-list']">
              <div
                :class="`${setListClassForSelChar(filteredCharacter.id, currentCharacterId)}`"
                :style="`--staminaReady: ${(getCharacterStamina(filteredCharacter.id)/maxStamina)*100}%;`"
                v-for="filteredCharacter in filteredCharactersForList"
                :key="filteredCharacter.id"
                @click="(!getIfCharacterIsInRaid(filteredCharacter.id) || !filteredCharacter.pvpStatus === 'IN_ARENA'
                || !getIsInCombat) && setCurrentCharacter(filteredCharacter.id) && alert(filteredCharacter.id)">
              <div class="character-element">
                <div class="element-frame">
                    <div>
                      <span
                        :id="`${setIdForElement(filteredCharacter.trait, filteredCharacter.id === currentCharacterId)}`"
                      />
                      <span v-if="toggled && getIfCharacterIsInRaid(filteredCharacter.id)" class="raid-indicator"></span>
                      <span v-if="toggled && filteredCharacter.pvpStatus === 'IN_ARENA'" class="pvp-indicator"></span>
                      </div>
                  </div>
                  <div class="element-frame-active">
                    <div>
                        <span
                          :id="`${setIdForElement(filteredCharacter.trait, filteredCharacter.isSelected)}`"
                        />
                      </div>
                  </div>
                </div>
                <div class="character-details">
                  <div class="name-list text-primary">
                    {{ getCleanCharacterName(filteredCharacter.id) }}
                  </div>
                  <div class="small-stamina-char"
                    :style="`--staminaReady: ${(getCharacterStamina(filteredCharacter.id)/maxStamina)*100}%;`"
                    v-tooltip.bottom="toolTipHtml(timeUntilCharacterHasMaxStamina(filteredCharacter.id))">
                  </div>
                  <div class="char-level">
                      {{$t('PlayToEarn.level')}} {{ filteredCharacter.level + 1}} <span> (STA {{ getCharacterStamina(filteredCharacter.id) }} / 200)</span>
                  </div>
                </div>
              </div>
          </b-col>
          <b-col class="character-list centered-list" v-else>
            <div v-for="sidebarItem in sideBarBlacksmith"
                  :key="sidebarItem.id"
                  :class="sidebarItem.status === 'active' ? 'character-highlight' : 'character'"
                  @click="setActiveTab(sidebarItem)"
                >
                <div class="character-element">
                  <div class="element-frame">
                      <div>
                        <span :id="`${sidebarItem.iconName}`"/>
                      </div>
                  </div>
                  <div class="element-frame-active">
                     <div>
                        <span
                          :id="`${sidebarItem.iconName}`"/>
                      </div>
                  </div>
                </div>
                <div class="character-details">
                  <div class="name-list text-primary">
                    {{ sidebarItem.title }}
                  </div>
                  <div class="nav-line"></div>
                  <div class="char-level">
                    {{ sidebarItem.desc }}
                  </div>
                </div>
              </div>
          </b-col>
        </div>
        <div class="btn-trigger" @click="hideSideBar(!toggled)">
          <img :class="!toggled ? 'rotateLeft' : 'rotateRight'" src="../../assets/left-arrow.png" alt="">
        </div>
  </div>
</template>

<script lang="ts">
import {mapActions, mapGetters, mapState, mapMutations } from 'vuex';
import { getCharacterArt } from '../../character-arts-placeholder';
import Events from '../../events';
import { CharacterPower, CharacterTrait } from '../../interfaces';
import { RequiredXp } from '../../interfaces';
import Vue from 'vue';
import { toBN, fromWeiEther } from '../../utils/common';
import { getCleanName } from '../../rename-censor';
import {Nft, NftStatus} from '../../interfaces/Nft';
import {Accessors} from 'vue/types/options';


interface Data {
  isLoading: boolean;
  character?: Nft;
  charOnRaid: string [],
  sideBarBlacksmith: []
}

interface RaidMappedActions {
  fetchIsCharacterRaiding(payload: { characterID: string }): Promise<boolean>;
}

interface StoreMappedGetters {
  charactersWithIds(ids: (string | number)[]): Nft[];
}

interface StoreMappedActions {
  getCharacterBusyStatus(payload: { characterId: string | number }): Promise<number>;
}
import i18n from '@/i18n';

export default Vue.extend({
  props:['toggled','currentPath'],
  computed: {
    ...mapGetters(['charactersWithIds']) as Accessors<StoreMappedGetters>,
    ...mapState(['maxStamina', 'currentCharacterId', 'ownedCharacterIds']),
    ...mapGetters([
      'currentCharacter',
      'currentCharacterStamina',
      'getCharacterName',
      'getCharacterStamina',
      'charactersWithIds',
      'ownCharacters',
      'timeUntilCharacterHasMaxStamina',
      'getIsInCombat',
      'getIsCharacterViewExpanded',
      'fightGasOffset',
      'getCharacterIsInArena',
      'fightBaseline',
      'getCharacterPower'
    ]),
    isLoadingCharacter(): boolean {
      return !this.currentCharacter;
    },
    filteredCharactersForList(): any {
      const items: any  = this.ownCharacters;
      for(const x of items){
        x.isSelected = false;
        this.setCharacterOnRaid(x.id);
      }
      return items;
    },
  },

  data() {
    return {
      traits: CharacterTrait,
      isPlaza : false,
      sideBarBlacksmith: [
        {
          id: 0,
          title: i18n.t('blacksmith.weapon'),
          desc: i18n.t('blacksmith.weaponDesc'),
          iconName: 'icon-weapon',
          status: 'active',
          route: 'weapon'
        },
        {
          id: 1,
          title: i18n.t('blacksmith.equipment'),
          desc: i18n.t('blacksmith.equipmentDesc'),
          iconName: 'icon-equipment',
          status: '',
          route: 'equipment'
        },
        {
          id: 2,
          title:  i18n.t('blacksmith.dustStorage'),
          desc: i18n.t('blacksmith.dustStorageDesc'),
          iconName: 'icon-dust',
          status: '',
          route: 'dust'
        },
        {
          id: 3,
          title: i18n.t('blacksmith.land'),
          desc: i18n.t('blacksmith.landDesc'),
          iconName: 'icon-land',
          status: '',
          route: 'land'
        },
      ],
      charOnRaid: [],
      charOnPvp: [],
      character: undefined,
      NftStatus
    } as unknown as Data;
  },
  methods: {
    ...mapActions([
      'getCharacterBusyStatus',
    ]) as StoreMappedActions,
    ...(mapActions(['fetchIsCharacterRaiding']) as RaidMappedActions),
    ...mapMutations(['setCurrentCharacter']),
    getCharacterArt,
    CharacterPower,
    RequiredXp,

    async isCharacterAlreadyRaiding(characterID: string)  {
      return await this.fetchIsCharacterRaiding({characterID});
    },

    setListClassForSelChar(id: string, currentCharId: string): any {
      if (id === currentCharId){
        this.setSelectedCharacter(id);
        return 'character-highlight';
      }

      else return 'character';
    },
    getNftStatus(activeCharacter: any){
      this.composeCharacterData(activeCharacter.id).then(data => {
        if (data.status !== undefined && data.status in NftStatus) {
          for(const character of this.filteredCharactersForList){
            if(character.id === activeCharacter.id){
              character.pvpStatus = NftStatus[data.status];
            }
          }
        } else {
          for(const character of this.filteredCharactersForList){
            if(character.id === activeCharacter.id){
              character.pvpStatus = 'BUSY';
            }
          }
        }
      });
    },


    async composeCharacterData(id: any){
      let characterStatus;
      // eslint-disable-next-line prefer-const
      characterStatus = await this.charactersWithIds([id]).filter(Boolean)[0];
      characterStatus.status = + await this.getCharacterBusyStatus({characterId: id});
      return characterStatus;
    },

    async setCharacterOnRaid(id: any){
      const charId = id;
      if(await this.isCharacterAlreadyRaiding(id)){
        this.charOnRaid.push(charId);
      }
    },

    getIfCharacterIsInRaid(id: any){
      let toReturnWarning;
      this.charOnRaid.forEach((characterOnRaid: any) => {
        if(id === characterOnRaid){
          toReturnWarning = true;
        }
      });

      return toReturnWarning;
    },

    setActiveTab(tab: any){
      (this as any).$router.push({ path: 'blacksmith', query: { tab: tab.route }});
      this.sideBarBlacksmith.forEach((sidebarTab: { id: any; status: string; }) => {
        if(sidebarTab.id === tab.id) sidebarTab.status = 'active';
        else sidebarTab.status = '';
      });
    },

    toolTipHtml(time: string): string {
      return i18n.t('blacksmith.regenerate') + time;
    },

    setSelectedCharacter(id: any){
      for(const a of this.filteredCharactersForList){
        if(a.id === id){
          a.isSelected = true;
        }else{
          a.isSelected = false;
        }
      }
    },


    //toggle the sidebar
    hideSideBar(bol: any){
      Events.$emit('toggle-sideBar', bol);
    },

    formattedSkill(skill: number): number {
      const skillBalance = fromWeiEther(skill.toString());
      return toBN(skillBalance).toNumber();
    },

    getCleanCharacterName(id: string): string {
      return getCleanName(this.getCharacterName(id));
    },

    setIdForElement(traits: any, isSelected: boolean){
      if(traits === '0'){
        if(isSelected){
          return 'fire-element';
        }else{
          return 'w-fire-element';
        }
      }
      else if(traits === '1'){
        if(isSelected){
          return 'earth-element';
        }else{
          return 'w-earth-element';
        }
      }
      else if(traits=== '2'){
        if(isSelected){
          return 'lightning-element';
        }else{
          return 'w-lightning-element';
        }
      }
      else if(traits === '3'){
        if(isSelected){
          return 'water-element';
        }else{
          return 'w-water-element';
        }
      }
      else return '';
    },
  },
});
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Cardo:ital,wght@0,400;0,700;1,400&display=swap');

.root {
  display: inline-flex;
  width: 100%;
}

.character-portrait {
  width: 6.5em;
  height: 6.5em;
  background: gray;
  display: flex;
  justify-content: center;
  align-items: center;
  border: 4px rgba(0, 0, 0, 0.5) inset;
  background: url("../../assets/chara-bg.png") center bottom -4px no-repeat;
  background-size: auto 140%;
  background-clip: border-box;
  margin-right: 0.625em;
}

.character-portrait img {
  max-height: 100%;
  max-width: 100%;
}

.character-data-column {
  display: flex;
  flex-direction: column;
}

.character-data-column > * + * {
  margin-top: 0.375rem;
}

.character-data-column .name {
  font-size: 1.5rem;
}

.character-data-column .subtext {
  font-size: 0.9rem;
  opacity: 0.9;
}

.character-data-column .bar {
  height: 1rem;
}

.power-hint {
  font-size: 1.3rem;
}

.character-display-container {
  margin-top: -20px;
  height: 90vh;
}


.character-element{
  margin-right: 20px;
}

.character-element .element-frame{
  border: 2px solid #dabf75;
  display: flex;
  align-items: center;
  justify-content: center;
  -ms-transform: rotate(45deg); /* IE 9 */
  transform: rotate(45deg);
}

 .element-frame > div{
  padding: 7px;
  display: flex;
  align-items: center;
  justify-content: center;
  -ms-transform: rotate(-45deg); /* IE 9 */
  transform: rotate(-45deg);
}


.element-frame-active div{
  opacity: 0;
}

div.character-list{
  width: 70%;
}

.character-list{
  padding-top: 20px;
  overflow-x:hidden;
  overflow-y: visible;
}

.raid-indicator{
  content: url('../../assets/navbar-icons/arena-icon.png');
  height: 15px;
  width: 15px;
  position: absolute;
  margin-bottom: -80px;
  right: 0;
}

.pvp-indicator{
  content: url('../../assets/navbar-icons/arena-icon.png');
  height: 15px;
  width: 15px;
  position: absolute;
  margin-bottom: -80px;
  right: 0;
}



div.character-list .character .character-element .element-frame-active{
  display: none;
}

div.character-list .character, div.character-list .character-highlight{
  display: flex;
  align-items: center;
  margin-bottom: 40px;
  cursor: pointer;
}


.character .character-details{
  width: 100%;
}

.character-highlight .character-details{
  width: 100%;
}

/* properties when character is NOT SELECTED */
.character .character-details .name-list, .character .character-details .char-level, .character .character-details .small-stamina-char {
  opacity: 0.5;
  color: rgb(255, 255, 255);
}

.character .character-element{
  opacity: 0.5;
}


/* ---------------------------------- */

ul.character-list{
  float: right;
  margin: 0px;
}

li.character{
  background: linear-gradient(to right, rgba(255, 255, 255, 0.1) var(--staminaReady), rgba(255, 255, 255, 0.1) 0);
  padding: 7px 4px 2px;
  margin: 5px;
  vertical-align: middle;
  width: 100%;
  cursor: pointer;
  border-radius: 5px;
}

li.character-highlight{
  border: solid #9e8a57 3px;
  font-weight: 800;
  padding: 5px;
  width: 100%;
  border-radius: 5px;
  margin: 5px;
  vertical-align: middle;
  cursor: pointer;
}

.name-list {
  font-family: 'Trajan', serif;
  text-transform: uppercase;
  font-weight: 700;
  margin: auto;
  font-size: 0.8vw;
  text-align: left;
}

.character-list-mobile {
  border-top: 3px solid #9e8a57;
  margin-top : 15px;
  padding-top: 15px;
  display :flex;
  flex-direction: column;
  justify-content: space-around;
  align-items: stretch;
}

.character-full-list {
  padding-top: 15px;
  display :flex;
  flex-direction: row;
  align-items: stretch;
  margin-bottom: 15px;
}

.centered-list {
  justify-content: center;
}

.character-full-list > ul {
  display: flex;
  padding-left: 0px;
}

.character-full-list .character, .character-full-list .character-highlight {
  width: 100%;
  margin: 0 20px 0 0;
}

.character-list-mobile > ul{
  padding :0px;
}
.character-list-mobile > ul > li{
  justify-content: center;
  display: flex;
}
.disabled-li {
  pointer-events: none;
  opacity: 0.6;
  cursor: not-allowed;
}

.trait-icon {
  position: relative;
  border-radius: 15px;
  top: 5px;
  left: 5px;
}

.character-name {
  color: #dabf75; /* little lighter to emboss */
  font-family: serif;
}

.subtext-stats {
  border: 1px solid;
  border-radius: 5px;
  width: 60%;
  padding: 5px;
  margin-bottom: 2px;
}

.subtext-stats > b {
  font-size: 1.2em;
}

.subtext-stats > span {
  color: rgb(230, 230, 230);
  font-size: 1.1em;
  margin-right: 2px;
}

.raid-label{
  margin-top: 6px;
  font-family: Roboto;
  color: #dabf75;
  border: 1px solid #9e8a57;
  padding: 2px 10px;
  border-radius: 5px;
  font-size: 14px;
  display: flex;
  align-items: center;
  width: fit-content;
  background-color:rgba(0, 0, 0, 0.582);
}

.char-level > div > p{
  display: flex;
}


.char-level > div > p{
  margin-right: 10px;
}

.raid-label > img{
  width: 25px;
}

.small-stamina-char {
  position: relative;
  width: 100%;
  max-width: 100%;
  height :2.5px;
  margin: 5px 0px 5px 0px;
  background : linear-gradient(to right, rgb(236, 75, 75) var(--staminaReady), rgba(255, 255, 255, 0.1) 0);
}

.nav-line {
  position: relative;
  width: 100%;
  max-width: 100%;
  height :1px;
  margin: 5px 0px 5px 0px;
  background : rgba(255, 255, 255, 0.075);
}

.stamina-text {
  font-size: 70%;
  text-align: left;
  color: #fff;
}


.element-frame-active{
  padding: 6px 9px;
  border: 2px solid #dabf75;
  position: absolute;
  margin-top: -49px;
  margin-left: -3px;
  animation-name: rotateBox;
  animation-duration: 0.28s;
}

@keyframes rotateBox {
  0%   {
    transform: rotate(45deg)
  }
  100%  {
    transform: rotate(0deg)
  }
}

.char-level{
  font-size: 0.7vw;
  color: #fff;
  white-space: nowrap;
}

.slide-fade-enter-active {
  transition: all .3s ease;
}
.slide-fade-leave-active {
  transition: all .3s ease;
}
.slide-fade-enter, .slide-fade-leave-to {
  transform: translateY(-30px);
  overflow: hidden;
  opacity: 0;
}

.rotateLeft{
    transform: rotate(180deg);
    transition: all 1s;
  }

.rotateRight{
  transform: rotate(0deg);
  transition: all 1s;
}

 .btn-trigger{
    position: relative;
    margin-right: -100px;
    width: 100%;
    justify-content: flex-end;
    z-index: 100;
    bottom: 0;
    display: flex;
    cursor: pointer;
  }

.btn-trigger > img{
    width: 30px;
    margin-right: -40px;
}

 .character-full-list{
    overflow-y: hidden;
  }

@media all and (max-width: 1200px ){
  .name-list{
    font-size: 1.3vw;
  }

  .char-level{
    font-size: 1.1vw;
  }
}

@media all and (max-width: 600px) {
  .character-bar {
    padding: 0.5em 0.6em;
  }

  .name-list{
    font-size: 4vw;
  }

  .char-level{
    font-size: 3vw;
  }

  .character-full-list .col-12{
    padding-right: 0px !important;
  }

  .character-full-list{
    overflow-y: hidden;
    margin-top: -45px;
  }

  .combat-hints > span{
    display: none;
  }

  .bd-right{
    border: none;
  }

  .main-font{
    overflow-y:hidden ;
  }

  .sideBar{
    border-right: 1px solid rgba(255, 255, 255, 0.289);
  }

  .btn-trigger{
    position: relative;
    width: 20px;
    z-index: 100;
    bottom: 0px;
    margin-right: -40px;
  }

  .btn-trigger{
    display: inline;
  }

  .btn-trigger > img{
    width: 30px;
    margin-right: -100px;
  }

  .rotateLeft{
    transform: rotate(180deg);
    transition: all 1s;
  }

  .rotateRight{
    transform: rotate(0deg);
    transition: all 1s;
  }
}

/* Element Style */
#fire-element {
  content: url("../../assets/elements/icon-fire.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#earth-element {
  content: url("../../assets/elements/icon-earth.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#lightning-element {
  content: url("../../assets/elements/icon-thunder.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#water-element {
  content: url("../../assets/elements/icon-water.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#w-fire-element {
  content: url("../../assets/elements/w-icon-fire.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#w-earth-element {
  content: url("../../assets/elements/w-icon-earth.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#w-lightning-element {
  content: url("../../assets/elements/w-icon-thunder.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#w-water-element {
  content: url("../../assets/elements/w-icon-water.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}


/* FOR BLACKSMITH SIDEBAR */
#icon-weapon {
  content: url("../../assets/raid-sidebar/icon-sword.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#icon-equipment {
  content: url("../../assets/raid-sidebar/icon-shield.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#icon-land {
  content: url("../../assets/raid-sidebar/icon-map.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

#icon-dust {
  content: url("../../assets/raid-sidebar/icon-dust.png");
  height: 30px;
  width: 30px;
  background: rgba(0, 0, 0, 0.076);
}

</style>
