<template>
  <div>
    <div class="row m-3 justify-content-center">
      <h2>{{$t('bridge.bridgeForYourNfts')}}</h2>
    </div>
    <div class="row m-3 justify-content-center">
      <h3>{{$t('bridge.transferNftsToAnotherChain')}}</h3>
    </div>
    <div class="row mt-3 justify-content-center">
      <p v-if="bridgeFee">
        {{$t('bridge.bridgeTransferFee')}}: <CurrencyConverter :skill="convertWeiToSkill(bridgeFee)"/> &nbsp;
        <b-icon-question-circle class="centered-icon" scale="0.8"
        v-tooltip.bottom="$t('bridge.bridgeTransferFeeTooltip')"
        />
      </p>
    </div>
    <b-tabs justified>
      <b-tab :title="$t('bridge.inventory')">
        <div class="btnRow d-flex flex-row justify-content-center">
          <div class="p-2">
            <b-button variant="primary" @click="showNft('weapon')" class="gtag-link-others"
              tagname="show_weapons_bridge" :disabled="nftType === 'weapon'">
              {{$t('bridge.showWeapons')}}
            </b-button>
          </div>
          <div class="p-2">
            <b-button variant="primary" @click="showNft('character')" class="gtag-link-others"
              tagname="show_characters_bridge" :disabled="nftType === 'character'">
              {{$t('bridge.showCharacters')}}
            </b-button>
          </div>
          <div class="p-2">
            <b-button variant="primary" @click="showNft('shield')" class="gtag-link-others"
              tagname="show_shields_bridge" :disabled="nftType === 'shield'">
              {{$t('bridge.showShields')}}
            </b-button>
          </div>
          <div class="p-2">
            <b-button :disabled="selectedNftId === ''" variant="primary"
            @click="nftType === 'character' ? $refs['character-warning-modal'].show() : transferToStorage()"
              class="gtag-link-others" tagname="click_transfer_bridge">{{$t('bridge.moveNftToStorage')}}</b-button>
          </div>
        </div>

        <div class="sell-grid" v-if="nftType === 'weapon'">
          <weapon-grid
          v-model="selectedNftId"
          :showReforgedWeaponsDefVal="false"
          :showFavoriteWeaponsDefVal="false"
          :canFavorite="false"
          />
        </div>

        <div class="sell-grid" v-if="nftType === 'character'">
          <character-list :showFilters="true" v-model="selectedNftId" />
        </div>

        <div class="sell-grid" v-if="nftType === 'shield'">
          <nft-list v-model="selectedNftId" :isBridge="true"
          />
        </div>

        <div class="outcome" v-if="transferingToStorage">
          <i class="fas fa-spinner fa-spin"></i>
          {{$t('bridge.loading')}}
        </div>
        <b-modal class="centered-modal" ref="character-warning-modal" @ok="transferToStorage()">
          <template #modal-title class="text-capitalize">
           <b-icon class="mr-2" icon="exclamation-circle" variant="danger"/>{{$t('bridge.warning')}}
          </template>
          <span>{{$t('bridge.unclaimedRemains')}}</span>
        </b-modal>
      </b-tab>
      <b-tab :title="$t('bridge.storage')" @click="showStorage(); selectedNftId = ''; targetChain = ''">
        <div class="btnRow d-flex flex-row justify-content-center" v-if="loadedStorage">
          <div class="p-2">
            <b-button variant="primary" @click="showNft('weapon'); getStoredIds();"
              class="gtag-link-others" tagname="show_weapons_bridge" :disabled="nftType === 'weapon'">
              {{$t('bridge.showWeapons')}}
            </b-button>
          </div>
          <div class="p-2">
            <b-button variant="primary" @click="showNft('character'); getStoredIds();"
              class="gtag-link-others" tagname="show_characters_bridge" :disabled="nftType === 'character'">
              {{$t('bridge.showCharacters')}}
            </b-button>
          </div>
          <div class="p-2">
            <b-button variant="primary" @click="showNft('shield'); getStoredIds();"
              class="gtag-link-others" tagname="show_shield_bridge" :disabled="nftType === 'shield'">
              {{$t('bridge.showShields')}}
            </b-button>
          </div>
          <div class="p-2">
            <b-button :disabled="!canWithdraw"
            variant="primary"
            @click="withdrawItem()" class="gtag-link-others"
            tagname="click_transfer_bridge">{{$t('bridge.withdrawFromStorage')}}</b-button>
          </div>
          <div class="p-2">
            <b-button :disabled="!canBridge" variant="primary" @click="requestBridge()" class="gtag-link-others"
                      tagname="click_transfer_bridge"> {{ $t('bridge.requestTransfer') }} <br> <span
              :style="canAffordBridge ? '' : 'color:red;'"> (<CurrencyConverter :skill="convertWeiToSkill(bridgeFee)"/>) </span>
            </b-button>
          </div>
          <div class="p-2">
            <b-button :disabled="transferStatus !== transferStates.pending" variant="primary" @click="$refs['refund-warning-modal'].show()"
                      class="gtag-link-others" tagname="click_transfer_bridge">{{$t('bridge.cancelTransferRequest')}}</b-button>
          </div>
        </div>
        <div v-if="transferStatus !== transferStates.noTransfer"
          class="transferBox d-flex flex-column bd-highlight mb-3 justify-content-center">
          <div class="text-center">
            <h4>{{$t('bridge.currentTransfer')}}</h4>
          </div>
          <div v-if="currentTransferNFTType === 'weapon'">
            <weapon-grid
            class="currentTransferNFT"
            v-model="selectedNftId"
            :weaponIds="[currentTransferNFTId]"
            :showGivenWeaponIds="true"
            :showReforgedToggle="false"
            :showReforgedWeaponsDefVal="false"
            :showFavoriteToggle="false"
            :showFavoriteWeaponsDefVal="false"
            :canFavorite="false"
            :newWeapon="true"
            />
          </div>
          <div v-if="currentTransferNFTType === 'character'">
            <character-list
            class="currentTransferNFT"
            v-model="selectedNftId"
            :characterIds="[currentTransferNFTId]"
            :showGivenCharacterIds="true"
            :nftDisplay="true"
            />
          </div>
          <div v-if="currentTransferNFTType === 'shield'">
            <nft-list
            v-model="selectedNftId"
            :showGivenNftIdTypes="true"
            :nftIdTypes="[currentTransferNFTId].map(id => { return { id: id, type: 'shield' }; })"
            :isBridge="true"
            />
          </div>
          <div class="text-center">
            {{$t('bridge.status')}}: {{transferStatus}} <br>
            {{$t('bridge.toChain')}}: {{currentTransferChain}} <br>
          </div>
          <br>
          <div class="outcome" v-if="cancellingRequest">
            <i class="fas fa-spinner fa-spin"></i>
            {{$t('bridge.loading')}}
          </div>
        </div>
        <hr v-if="currentTransferNFTType === 'character' || 'weapon'" style="border:0.5px solid #9E8A57">
        <div class="d-flex flex-row bd-highlight mb-3 justify-content-center">
          <div class="p-4 w-25" v-if="transferStatus !== transferStates.pending && storedNftsIds.length !== 0">
            <h4 class="text-center">{{$t('bridge.selectTargetChain')}}</h4>
            <select class="form-control" v-model="targetChain">
              <option :value="''" disabled>{{$t('bridge.selectAChain')}}</option>
              <option v-for="chain in chainsToSendTo" :value="chain" :key="chain"
                :disabled="!enabledChains.includes(chain)">
                {{ chain }} <span v-if="!enabledChains.includes(chain)">{{$t('bridge.isNotEnabledForTransfer')}}</span>
              </option>
            </select>
          </div>
        </div>
        <div v-if="nftType === 'weapon' && storedNftsIds.length !== 0">
          <weapon-grid
          v-model="selectedNftId"
          :showReforgedWeaponsDefVal="true"
          :showFavoriteWeaponsDefVal="true"
          :showReforgedToggle="true"
          :showFavoriteToggle="true"
          :canFavorite="false"
          :weaponIds="storedNftsIds"
          :showGivenWeaponIds="true"
            />
        </div>
        <div v-else-if="nftType === 'weapon'">
          <h3 class="text-center p-4">{{$t('bridge.noWeaponsStored')}}</h3>
        </div>
        <div v-if="nftType === 'character' && storedNftsIds.length !== 0">
          <character-list :showFilters="false" v-model="selectedNftId" :showGivenCharacterIds="true"
            :characterIds="storedNftsIds" />
        </div>
        <div v-else-if="nftType === 'character'">
          <h3 class="text-center p-4">{{$t('bridge.noCharactersStored')}}</h3>
        </div>
        <div v-if="nftType === 'shield' && storedNftsIds.length !== 0">
          <nft-list
          v-model="selectedNftId"
          :showGivenNftIdTypes="true"
          :nftIdTypes="storedNftsIds.map(id => { return { id: id, type: 'shield' }; })"
          :isBridge="true"
          />
        </div>
        <div v-else-if="nftType === 'shield'">
          <h3 class="text-center p-4">{{$t('bridge.noShieldsStored')}}</h3>
        </div>
        <div class="outcome" v-if="transferingFromStorage">
          <i class="fas fa-spinner fa-spin"></i>
          {{$t('bridge.loading')}}
        </div>
        <b-modal class="centered-modal" ref="refund-warning-modal" @ok="cancelAll()">
          <template #modal-title class="text-capitalize">
           <b-icon icon="exclamation-circle" variant="danger"/>{{$t('bridge.warning')}}
          </template>
          <span>{{ $t('bridge.noRefundOfSpentSkill') }}</span>
        </b-modal>
      </b-tab>
      <b-tab :title="$t('bridge.incomingNfts')" @click="getIncoming(); selectedNftId = ''">
        <div v-if="incomingNftIds.length === 0">
          <h3 class="text-center p-4">{{$t('bridge.noIncomingNfts')}}</h3>
        </div>
        <div v-else>
          <div class="d-flex flex-row flex-wrap bd-highlight mb-3 justify-content-center">
            <div v-if="incomingWeapons.length !== 0" class="p-4 w-20">
              <h4 class="text-center withdrawText">{{$t('bridge.selectWeaponToWithdraw')}}</h4>
              <select class="form-control withdrawSelect" v-model="weaponIdToWithdraw">
                <option value="" disabled selected>{{$t('bridge.selectYourWeapon')}}</option>
                <option v-for="weapon in incomingWeapons"
                :value="weapon.targetId"
                :key="weapon.sourceId">
                  {{$t('bridge.weaponId')}}: {{ weapon.sourceId }}
                  {{$t('bridge.fromChain')}}: {{supportedChains[supportedChainIds.indexOf(weapon.sourceChain)]}}
                </option>
              </select>
              <div class="mt-2 text-center">
                <b-button :disabled="!weaponIdToWithdraw" variant="primary" @click="withdrawBridge(weaponIdToWithdraw)"
                          class="gtag-link-others withdrawBtn" tagname="click_transfer_bridge"> {{ $t('bridge.withdrawWeapon') }}
                </b-button>
              </div>
            </div>
            <div v-if="incomingChars.length !== 0" class="p-4 w-20">
              <h4 class="text-center withdrawText">{{$t('bridge.selectCharacterToWithdraw')}}</h4>
              <select class="form-control withdrawSelect" v-model="characterIdToWithdraw">
                <option value="" disabled selected>{{$t('bridge.selectYourCharacter')}}</option>
                <option v-for="character in incomingChars"
                :value="character.targetId"
                :key="character.sourceId">
                  {{$t('bridge.characterId')}}: {{ character.sourceId }} {{$t('bridge.fromChain')}}:
                  {{supportedChains[supportedChainIds.indexOf(character.sourceChain)]}}
                </option>
              </select>
              <div class="mt-2 text-center">
                <b-button :disabled="!characterIdToWithdraw" variant="primary"
                  @click="withdrawBridge(characterIdToWithdraw)" class="gtag-link-others withdrawBtn"
                  tagname="click_transfer_bridge">{{$t('bridge.withdrawCharacter')}}</b-button>
              </div>
            </div>
            <div v-if="incomingShields.length !== 0" class="p-4 w-20">
              <h4 class="text-center withdrawText">{{$t('bridge.selectYourShieldToWithdraw')}}</h4>
              <select class="form-control withdrawSelect" v-model="shieldIdToWithdraw">
                <option value="" disabled selected>{{$t('bridge.selectYourShield')}}</option>
                <option v-for="shield in incomingShields"
                :value="shield.targetId"
                :key="shield.sourceId">
                  {{$t('bridge.shieldId')}}: {{ shield.sourceId }}
                  {{$t('bridge.fromChain')}}: {{supportedChains[supportedChainIds.indexOf(shield.sourceChain)]}}
                </option>
              </select>
              <div class="mt-2 text-center">
                <b-button :disabled="!shieldIdToWithdraw" variant="primary" @click="withdrawBridge(shieldIdToWithdraw)"
                          class="gtag-link-others withdrawBtn" tagname="click_transfer_bridge"> {{$t('bridge.withdrawShield')}}
                </b-button>
              </div>
            </div>
          </div>
          <div class="outcome" v-if="withdrawingFromBridge">
            <i class="fas fa-spinner fa-spin"></i>
            {{$t('bridge.loading')}}
          </div>
        </div>
      </b-tab>
    </b-tabs>
  </div>
</template>
<script lang="ts">
import Vue from 'vue';
import {mapActions, mapGetters, mapState} from 'vuex';
import {isNftType, Nft, TransferedNft, NftTransfer} from '@/interfaces/Nft';
import {Accessors} from 'vue/types/options';
import {Contract, Contracts, IState} from '@/interfaces';
import {NftIdType} from '@/components/smart/NftList.vue';
import {Characters, Shields, Weapons} from '../../../build/abi-interfaces';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import NftList from '../components/smart/NftList.vue';
import CurrencyConverter from '../components/CurrencyConverter.vue';
import {fromWeiEther, toBN} from '@/utils/common';
import config from '../../app-config.json';

type StoreMappedState = Pick<IState, 'defaultAccount'| 'ownedWeaponIds' | 'skillBalance' | 'inGameOnlyFunds' | 'skillRewards'>;

interface StoreMappedGetters {
  contracts: Contracts;
  weaponsWithIds(ids: (string | number)[]): Nft[];
  nftsWithIdType(nftIdType: NftIdType[]): Nft[];
  shieldsWithIds(ids: string[]): Nft[];
  charactersWithIds(ids: (string | number)[]): Nft[];
  ownCharacters: any[];
}
interface StoreMappedActions {
  storeItem(payload: {
    nftContractAddr: string;
    tokenId: number}): Promise<void>;
  getStorageItemIds(payload: {
    nftContractAddr: string;}): Promise<string[]>;
  getNumberOfStoragedItems(payload: {
    nftContractAddr: string;}): Promise<string>;
  withdrawFromStorage(payload: {
    nftContractAddr: string;
    tokenId: number}): Promise<void>;
  getNFTChainId(payload: {
    nftContractAddr: string;
    tokenId: number}): Promise<void>;
  bridgeItem(payload: {
    nftContractAddr: string;
    tokenId: number;
    targetChain: number;
    bridgeFee: string;
  }): Promise<void>;
  getBridgeTransferId(): Promise<string>;
  getBridgeTransfer(payload: {
    transferId: string;
  }): Promise<NftTransfer>;
  withdrawFromBridge(payload: {
    tokenId: number;
  }): Promise<void>;
  cancelBridge(): Promise<void>;
  getReceivedNFTs(): Promise<number[]>;
  getReceivedNFT(payload: {
    tokenId: number;
  }): Promise<TransferedNft>;
  chainEnabled(payload: {
    chainId: number;
  }): Promise<boolean>;
}

enum transferStates{
  noTransfer = 'No transfer',
  pending = 'Pending',
  processing = 'Processing',
  done = 'DONE',
  error = 'Error',
  restored = 'Restored'
}

type NftTypeString = 'weapon' | 'shield' | 'character';

export default Vue.extend({
  props: {
    nftTypeProp: {
      type: String,
      validator(type) {
        return isNftType(type);
      },
    },
    nftIdProp: {
      type: String,
    },
  },

  data() {
    return {
      weapon: null as Nft | null,
      character: null as Nft | null,
      shield: null as Nft | null,
      ownerAddress: '',
      nftType: 'weapon',
      selectedNftId: '' as string,
      storedNftsIds: [] as string[],
      currentChain: '',
      targetChain: '',
      targetChainId: 0 as number | null,
      supportedChains: [] as string[],
      supportedChainIds: [] as number[],
      transferStatus: '',
      transferStates,
      currentTransferNFTId: 0 as number | null,
      currentTransferNFTType: '',
      currentTransferChain: '',
      chainsToSendTo: [] as string[],
      incomingNftIds: [] as number[],
      incomingWeapons: [] as TransferedNft[],
      incomingChars: [] as TransferedNft[],
      incomingShields: [] as TransferedNft[],
      weaponIdToWithdraw: '',
      characterIdToWithdraw: '',
      shieldIdToWithdraw: '',
      transferingToStorage: false,
      transferingFromStorage: false,
      cancellingRequest: false,
      withdrawingFromBridge: false,
      enabledChains: [] as string[],
      bridgeFee: '',
      loadedStorage: false,
      refreshIntervall: 0 as number,
    };
  },

  computed: {
    ...(mapState(['defaultAccount','ownedWeaponIds','ownedShieldIds','skillBalance', 'inGameOnlyFunds', 'skillRewards']) as Accessors<StoreMappedState>),
    ...(mapGetters([
      'contracts',
      'weaponsWithIds',
      'nftsWithIdType',
      'shieldsWithIds',
      'charactersWithIds',
      'ownCharacters',
    ]) as Accessors<StoreMappedGetters>),
    isKnownNftType(): boolean {
      return isNftType(this.nftType);
    },

    Weapons(): Contract<Weapons> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Weapons!;
    },

    Characters(): Contract<Characters> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Characters!;
    },

    Shields(): Contract<Shields> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Shields!;
    },

    contractAddress(): string {
      return this.nftType === 'weapon'
        ? this.Weapons.options.address
        : this.nftType === 'character'
          ? this.Characters.options.address
          : this.Shields.options.address;
    },
    canWithdraw(): boolean {
      //check first if weapon/char or other nft
      if(String(this.selectedNftId).split('.').length === 2){
        //is other nft
        const idToCheck = this.selectedNftId.split('.')[1];
        if(this.currentTransferNFTId === +idToCheck && this.transferStatus !== transferStates.restored) return false;
        else return this.selectedNftId !== '';
      }else{
        //is weapon/char
        const idToCheck = this.selectedNftId;
        if(idToCheck === '') return false;
        else if(this.currentTransferNFTId === +this.selectedNftId && this.transferStatus !== transferStates.restored) return false;
        else return this.selectedNftId !== '';
      }
    },
    canBridge(): boolean{
      if (!this.canAffordBridge) return false;

      else if(!this.targetChain) return false;

      else if(!this.enabledChains.length) return false;

      else if(this.nftType === 'shield') {
        if(!this.storedNftsIds.includes(this.selectedNftId.split('.')[1])) return false;
        return this.selectedNftId !== '';
      }
      else if(!this.storedNftsIds.includes(String(this.selectedNftId))) return false;

      else if(this.transferStatus === transferStates.done && this.currentTransferNFTId === +this.selectedNftId) return false;

      else if(this.transferStatus === transferStates.pending || this.transferStatus === this.transferStates.processing) return false;

      else return this.selectedNftId !== '';
    },
    canAffordBridge(){
      const cost = toBN(this.bridgeFee);
      const balance = toBN(this.skillBalance);
      const skillRewards = toBN(this.skillRewards);
      const totalBalance = balance.plus(skillRewards);
      return totalBalance.isGreaterThanOrEqualTo(cost);
    },
  },
  created(){
    this.supportedChains = config.supportedChains;

    //remove currentChain from chains to send to
    this.currentChain = localStorage.getItem('currentChain') || 'BSC';
    this.chainsToSendTo = this.supportedChains.filter(item => item !== this.currentChain);

    //check current net by checking url
    const env = window.location.href.startsWith('https://test') ? 'test' : 'production'; //const env = 'test';
    const conf = config as any;
    for(let i = 0; i < this.supportedChains.length; i++){
      this.supportedChainIds.push(+conf.environments[env].chains[this.supportedChains[i]].VUE_APP_NETWORK_ID);
    }
  },
  async mounted(){
    if (!this.contracts.NFTStorage) return;
    this.bridgeFee = await this.contracts.NFTStorage.methods.getBridgeFee().call({ from: this.defaultAccount });
    await this.showStorage();
    this.refreshIntervall = window.setInterval(async () => await this.showStorage(), 5000);
  },
  beforeDestroy(){
    clearInterval(this.refreshIntervall);
  },
  methods: {
    ...(mapActions([
      'fetchShields',
      'fetchWeapons',
      'fetchCharacters',
      'storeItem',
      'getStorageItemIds',
      'getNumberOfStoragedItems',
      'withdrawFromStorage',
      'getNFTChainId',
      'bridgeItem',
      'getBridgeTransfer',
      'getBridgeTransferId',
      'withdrawFromBridge',
      'cancelBridge',
      'getReceivedNFTs',
      'getReceivedNFT',
      'chainEnabled',
    ]) as StoreMappedActions),
    convertWeiToSkill(wei: string): string {
      return fromWeiEther(wei);
    },
    showNft(nftType: NftTypeString): void {
      this.nftType = nftType;
      this.selectedNftId = '';
    },
    async transferToStorage(){
      // chars & weapon ids are ints; other nfts are <type.id>
      if(this.nftType !== 'weapon' && this.nftType !== 'character') this.selectedNftId = this.selectedNftId.split('.')[1];

      this.transferingToStorage = true;
      try{
        await this.storeItem({
          nftContractAddr: this.contractAddress,
          tokenId: +this.selectedNftId});
        this.selectedNftId = '';
        this.transferingToStorage = false;
      }
      catch(e){
        this.transferingToStorage = false;
      }
    },
    async withdrawItem(){
      if(this.nftType !== 'weapon' && this.nftType !== 'character') this.selectedNftId = this.selectedNftId.split('.')[1];

      this.transferingFromStorage = true;
      try{
        await this.withdrawFromStorage({
          nftContractAddr: this.contractAddress,
          tokenId: +this.selectedNftId,
        });
        this.transferingFromStorage = false;
        this.selectedNftId = '';
        await this.getStoredIds();
      }
      catch(e){
        this.transferingFromStorage = false;
      }
    },
    async cancelAll(){
      this.cancellingRequest = true;
      await this.cancelBridge();
      this.cancellingRequest = false;
      await this.getStatus();
    },
    async withdrawBridge(tokenId: number){
      if(this.nftType !== 'weapon' && this.nftType !== 'character') this.selectedNftId = this.selectedNftId.split('.')[1];

      this.withdrawingFromBridge = true;
      try{
        await this.withdrawFromBridge({
          tokenId });
        await this.getIncoming();
        this.withdrawingFromBridge = false;
        this.weaponIdToWithdraw = '';
        this.characterIdToWithdraw = '';
        this.shieldIdToWithdraw = '';
      } catch(e){
        this.withdrawingFromBridge = false;
      }
    },
    async getIncoming(){
      this.incomingWeapons = [];
      this.incomingChars = [];
      this.incomingShields = [];

      //get incoming nft ids
      this.incomingNftIds = await this.getReceivedNFTs();

      for(let i = 0; i < this.incomingNftIds.length; i++){
        const incomingNft: TransferedNft  = await this.getReceivedNFT({
          tokenId: +this.incomingNftIds[i]
        });

        incomingNft.targetId = +this.incomingNftIds[i];

        if(incomingNft.nftType === 1) this.incomingWeapons.push(incomingNft);
        if(incomingNft.nftType === 2) this.incomingChars.push(incomingNft);
        if(incomingNft.nftType === 3) this.incomingShields.push(incomingNft);
      }
    },
    async getChainId(tokenId: number){
      return await this.getNFTChainId({
        nftContractAddr: this.contractAddress,
        tokenId: +tokenId,
      });
    },
    async getStatus(){
      const id = await this.getBridgeTransferId();
      const transfer: NftTransfer = await this.getBridgeTransfer({
        transferId: id,
      });

      if(transfer.status === 0){
        this.transferStatus = transferStates.noTransfer;
        this.currentTransferNFTId = null;
        return;
      }
      if(transfer.status === 1){
        this.transferStatus = transferStates.pending;
      }
      else if(transfer.status === 2){
        this.transferStatus = transferStates.processing;
      }
      else if(transfer.status === 3){
        this.transferStatus = transferStates.done;
      }
      else if(transfer.status === 4){
        this.transferStatus = transferStates.error;
      }
      else if(transfer.status === 5){
        this.transferStatus = transferStates.restored;
      }

      this.currentTransferNFTId = transfer.nftId;
      this.currentTransferChain = this.supportedChains[this.supportedChainIds.indexOf(transfer.chainId)];

      const currentTransferTokenAddress: string = transfer.nftAddress;
      if(currentTransferTokenAddress === this.Weapons.options.address) this.currentTransferNFTType = 'weapon';
      else if (currentTransferTokenAddress === this.Characters.options.address) this.currentTransferNFTType = 'character';
      else this.currentTransferNFTType = 'shield';
    },
    async requestBridge(){
      if(this.nftType !== 'weapon' && this.nftType !== 'character') this.selectedNftId = this.selectedNftId.split('.')[1];

      this.transferingFromStorage = true;
      this.targetChainId = this.supportedChainIds[this.supportedChains.indexOf(this.targetChain)];
      try{
        await this.bridgeItem({
          nftContractAddr: this.contractAddress,
          tokenId: +this.selectedNftId,
          targetChain: this.targetChainId,
          bridgeFee: this.bridgeFee,
        });
        await this.getStatus();
        await this.getStoredIds();
        this.selectedNftId = '';
        this.transferingFromStorage = false;
      }
      catch(e){
        this.transferingFromStorage = false;
      }
    },
    async getStoredIds(){
      this.storedNftsIds = await this.getStorageItemIds({
        nftContractAddr: this.contractAddress,
      });
    },
    async showStorage(){
      // check which chains are enabled for transfer
      for (const chainId of this.supportedChainIds){
        if(await this.chainEnabled({chainId})){
          const chain = this.supportedChains[this.supportedChainIds.indexOf(chainId)];
          this.enabledChains.push(chain);
        }
      }
      await this.getStoredIds();
      await this.getStatus();
      this.loadedStorage = true;
    },
  },
  components: {
    WeaponGrid,
    CharacterList,
    CurrencyConverter,
    NftList,
  },
});
</script>

<style scoped>
.btnRow{
  flex-wrap: wrap;
}
.btn{
  line-height: 1.25em;
  height: 4em;
  white-space:nowrap;
}
.outcome {
  margin: 20px auto;
  text-align: center;
  font-size: 1em;
}
/deep/ .character-list{
  justify-content: center;
}
/deep/ .weapon-grid{
  grid-template-columns: repeat(auto-fit,12em);
	box-shadow: 0 0 0 0 rgba(0, 0, 0, 1);
	transform: scale(1);
}
.withdrawText{
  font-size: clamp(12px, 1.25rem, 24px);
}
.withdrawSelect, .withdrawBtn{
  width: clamp(200px, 20vw, 300px);
  margin:0 auto;
}
</style>
