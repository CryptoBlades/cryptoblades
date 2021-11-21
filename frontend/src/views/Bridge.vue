<template>
  <div>
    <div class="row mt-3 mb-3 justify-content-center">
      <h3> Bridge for your NFTs - Transfer NFTs to another chain </h3>
    </div>
    <div class="row mt-3 mb-3 justify-content-center">
      <p v-if="bridgeFee">
        Transfer Fee: <CurrencyConverter :skill="convertWeiToSkill(bridgeFee)"/>
      </p>
    </div>
    <b-tabs justified>
      <b-tab title="Inventory" @click="nftType = 'weapon'">
        <div class="d-flex flex-row justify-content-center">
          <div class="p-2">
            <b-button variant="primary" @click="nftType = 'weapon'; selectedNftId = ''" class="gtag-link-others"
              tagname="show_weapons_bridge" :disabled="nftType === 'weapon'">
              Show Weapons
            </b-button>
          </div>
          <div class="p-2">
            <b-button variant="primary" @click="nftType = 'character'; selectedNftId = ''" class="gtag-link-others"
              tagname="show_characters_bridge" :disabled="nftType === 'character'">
              Show Characters
            </b-button>
          </div>
          <div class="p-2">
            <b-button :disabled="selectedNftId === ''" variant="primary"
            @click=" nftType === 'character' ? $refs['character-warning-modal'].show() :  transferToStorage()"
              class="gtag-link-others" tagname="click_transfer_bridge">Transfer NFT to storage</b-button>
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
        <div class="outcome" v-if="transferingToStorage">
          <i class="fas fa-spinner fa-spin"></i>
          Loading...
        </div>
        <b-modal class="centered-modal" ref="character-warning-modal" @ok="transferToStorage()">
          <template #modal-title>
           <b-icon icon="exclamation-circle" variant="danger"/> WARNING
          </template>
          <span>
           When transferring your character to another chain, your character will lose <b>all</b> unclaimed XP!<br>
          </span>
        </b-modal>
      </b-tab>
      <b-tab title="Storage" @click="showStorage(); selectedNftId = ''">
        <div class="d-flex flex-row justify-content-center">
          <div class="p-2">
            <b-button variant="primary" @click="nftType = 'weapon'; selectedNftId = ''; getStoredIds()"
              class="gtag-link-others" tagname="show_weapons_bridge" :disabled="nftType === 'weapon'">
              Show Weapons
            </b-button>
          </div>
          <div class="p-2">
            <b-button variant="primary" @click="nftType = 'character'; selectedNftId = ''; getStoredIds()"
              class="gtag-link-others" tagname="show_characters_bridge" :disabled="nftType === 'character'">
              Show Characters
            </b-button>
          </div>
          <div class="p-2">
            <b-button :disabled="selectedNftId === '' || currentTransferNFTId == selectedNftId" variant="primary"
              @click="withdrawItem()" class="gtag-link-others"
              tagname="click_transfer_bridge">Withdraw from Storage</b-button>
          </div>
          <div class="p-2">
            <b-button
              :disabled="!canBridge"
              variant="primary"
              @click="requestBridge()" class="gtag-link-others" tagname="click_transfer_bridge">
                Request Transfer <span :style="canAffordBridge ? '' : 'color:red;'"> (<CurrencyConverter :skill="convertWeiToSkill(bridgeFee)"/>) </span>
            </b-button>
          </div>
          <div class="p-2">
            <b-button :disabled="transferStatus != transferStates.pending" variant="primary" @click="$refs['refund-warning-modal'].show()"
              class="gtag-link-others" tagname="click_transfer_bridge">Cancel Transfer Request</b-button>
          </div>
        </div>
        <div class="d-flex flex-row bd-highlight mb-3 justify-content-center">
          <div class="p-4 w-25" v-if="transferStatus != transferStates.pending && storedNftsIds.length !== 0">
            <h4 class="text-center">Select target chain</h4>
            <select class="form-control" v-model="targetChain">
              <option v-for="chain in chainsToSendTo" :value="chain" :key="chain"
                :disabled="!enabledChains.includes(chain)">
                {{ chain }} <span v-if="!enabledChains.includes(chain)"> is not enabled for transfer </span>
              </option>
            </select>
          </div>
        </div>
        <div v-if="transferStatus != transferStates.noTransfer"
          class="transferBox d-flex flex-column bd-highlight mb-3 justify-content-center">
          <div class="text-center">
            <h4>Current Transfer</h4>
          </div>
          <div v-if="currentTransferNFTType == 'weapon'">
            <weapon-grid
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
          <div v-if="currentTransferNFTType == 'character'">
            <character-list
            v-model="selectedNftId"
            :characterIds="[currentTransferNFTId]"
            :showGivenCharacterIds="true"
            :nftDisplay="true"
            />
          </div>
          <div class="text-center">
            Status: {{transferStatus}} <br>
            To Chain: {{currentTransferChain}}
          </div>
          <br>
          <div class="outcome" v-if="cancellingRequest">
            <i class="fas fa-spinner fa-spin"></i>
            Loading...
          </div>
        </div>
        <hr v-if="currentTransferNFTType == 'character' || 'weapon'" style="border:0.5px solid #9E8A57">
        <div v-if="nftType == 'weapon' && storedNftsIds.length !== 0">
          <weapon-grid
          v-model="selectedNftId"
          :showReforgedWeaponsDefVal="false"
          :showFavoriteWeaponsDefVal="false"
            :showReforgedToggle="true"
            :showFavoriteToggle="true"
            :canFavorite="false"
            :weaponIds="storedNftsIds"
            :showGivenWeaponIds="true"
            />
        </div>
        <div v-else-if="nftType == 'weapon'">
          <h3 class="text-center p-4">No Weapons stored!</h3>
        </div>
        <div v-if="nftType == 'character' && storedNftsIds.length !== 0">
          <character-list :showFilters="false" v-model="selectedNftId" :showGivenCharacterIds="true"
            :characterIds="storedNftsIds" />
        </div>
        <div v-else-if="nftType == 'character'">
          <h3 class="text-center p-4">No Characters stored!</h3>
        </div>
        <div class="outcome" v-if="transferingFromStorage">
          <i class="fas fa-spinner fa-spin"></i>
          Loading...
        </div>
        <b-modal class="centered-modal" ref="refund-warning-modal" @ok="cancelAll()">
          <template #modal-title>
           <b-icon icon="exclamation-circle" variant="danger"/> WARNING
          </template>
          <span>
           You will <b>not get a refund</b> of your spent SKILL fee when cancelling the transfer!<br>
          </span>
        </b-modal>
      </b-tab>
      <b-tab title="Incoming NFTs" @click="getIncoming(); selectedNftId = ''">
        <div v-if="incomingChars.length === 0 && incomingWeapons.length === 0">
          <h3 class="text-center p-4">No incoming NFTs!</h3>
        </div>
        <div v-else>
          <div class="d-flex flex-row bd-highlight mb-3 justify-content-center">
            <div v-if="incomingWeapons.length !== 0" class="p-4 w-20">
              <h4 class="text-center">Select Weapon to Withdraw</h4>
              <select class="form-control" v-model="weaponIdToWithdraw">
                <option value="" disabled selected>Select your Weapon</option>
                <option v-for="weapon in incomingWeapons"
                :value="weapon['7']"
                :key="weapon['3']">
                  Weapon ID: {{ weapon['3'] }}
                  from Chain: {{supportedChains[supportedChainIds.indexOf(weapon['2'])]}}
                </option>
              </select>
              <div class="p-2 text-center">
                <b-button :disabled="!weaponIdToWithdraw" variant="primary"
                  @click="withdrawBridge(weaponIdToWithdraw)" class="gtag-link-others" tagname="click_transfer_bridge">
                  Withdraw Weapon</b-button>
              </div>
            </div>
            <div v-if="incomingChars.length !== 0" class="p-4 w-20">
              <h4 class="text-center">Select Character to Withdraw</h4>
              <select class="form-control" v-model="characterIdToWithdraw">
                <option value="" disabled selected>Select your Character</option>
                <option v-for="character in incomingChars"
                :value="character['7']"
                :key="character['3']">
                  Character ID: {{ character['3'] }} from Chain:
                  {{supportedChains[supportedChainIds.indexOf(character['2'])]}}
                </option>
              </select>
              <div class="p-2 text-center">
                <b-button :disabled="!characterIdToWithdraw" variant="primary"
                  @click="withdrawBridge(characterIdToWithdraw)" class="gtag-link-others"
                  tagname="click_transfer_bridge">Withdraw Character</b-button>
              </div>
            </div>
          </div>
          <div class="outcome" v-if="withdrawingFromBridge">
            <i class="fas fa-spinner fa-spin"></i>
            Loading...
          </div>
        </div>
      </b-tab>
    </b-tabs>
  </div>
</template>
<script lang="ts">
import Vue from 'vue';
import { mapActions, mapGetters, mapState } from 'vuex';
import { isNftType, Nft } from '../interfaces/Nft';
import { Accessors } from 'vue/types/options';
import { Contract, Contracts, IState } from '@/interfaces';
import { NftIdType } from '@/components/smart/NftList.vue';
import { Characters, Shields, Weapons } from '../../../build/abi-interfaces';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import CurrencyConverter from '../components/CurrencyConverter.vue';
import { fromWeiEther, toBN } from '../utils/common';
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
    tokenId: string}): Promise<void>;
  getStorageItemIds(payload: {
    nftContractAddr: string;}): Promise<string[]>;
  getNumberOfStoragedItems(payload: {
    nftContractAddr: string;}): Promise<string>;
  withdrawFromStorage(payload: {
    nftContractAddr: string;
    tokenId: string}): Promise<void>;
  getNFTChainId(payload: {
    nftContractAddr: string;
    tokenId: string}): Promise<void>;
  bridgeItem(payload: {
    nftContractAddr: string;
    tokenId: string;
    targetChain: string;
    bridgeFee: string;
  }): Promise<void>;
  getBridgeTransferId(): Promise<string>;
  getBridgeTransfer(payload: {
    transferId: string;
  }): Promise<string[]>;
  withdrawFromBridge(payload: {
    tokenId: string;
  }): Promise<void>;
  cancelBridge(): Promise<void>;
  getReceivedNFTs(): Promise<string[]>;
  getReceivedNFT(payload: {
    tokenId: string;
  }): Promise<string[]>;
  chainEnabled(payload: {
    chainId: string;
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
      storedNftsIds: [],
      currentChain: '',
      targetChain: '',
      targetChainId: '',
      supportedChains: [] as string[],
      supportedChainIds: [] as string[],
      transferStatus: '',
      transferStates,
      currentTransferNFTId: '',
      currentTransferNFTType: '',
      currentTransferChain: '',
      chainsToSendTo: [] as string[],
      incomingNftIds: [] as string[],
      incomingWeapons: [] as string[],
      incomingChars: [] as string[],
      weaponIdToWithdraw: '',
      characterIdToWithdraw: '',
      transferingToStorage: false,
      transferingFromStorage: false,
      cancellingRequest: false,
      withdrawingFromBridge: false,
      enabledChains: [] as string[],
      bridgeFee: '',
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
    canBridge(){
      if (!this.canAffordBridge) return false;

      else if(this.transferStatus === transferStates.done && this.currentTransferNFTId === String(this.selectedNftId)) return false;

      else if(this.transferStatus === transferStates.restored && this.currentTransferNFTId !== String(this.selectedNftId)) return false;

      else if(this.transferStatus === transferStates.pending || this.transferStatus === this.transferStates.processing) return false;

      else if(this.selectedNftId === '') return false;

      else return true;
    },
    canAffordBridge(){
      const cost = toBN(this.bridgeFee);
      const balance = toBN(this.skillBalance);
      return balance.isGreaterThanOrEqualTo(cost);
    },
  },
  created(){
    this.supportedChains  = config.supportedChains;

    //remove currentChain from chains to send to
    this.currentChain = localStorage.getItem('currentChain') || 'BSC';
    this.chainsToSendTo = this.supportedChains.filter(item => item !== this.currentChain);
    this.targetChain = this.chainsToSendTo[0];

    //check current net by checking url
    const env = window.location.href.startsWith('https://test') ? 'test' : 'production'; //const env = 'test';
    const conf = config as any;
    for(let i = 0; i < this.supportedChains.length; i++){
      this.supportedChainIds.push(conf.environments[env].chains[this.supportedChains[i]].VUE_APP_NETWORK_ID);
    }
  },
  async mounted(){
    if (!this.contracts.NFTStorage) return;
    this.bridgeFee = await this.contracts.NFTStorage.methods.getBridgeFee().call({ from: this.defaultAccount });
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
    async transferToStorage(){
      this.transferingToStorage = true;
      try{
        await this.storeItem({
          nftContractAddr: this.contractAddress,
          tokenId: this.selectedNftId});
        this.selectedNftId = '';
        this.transferingToStorage = false;
      }
      catch(e){
        this.transferingToStorage = false;
      }
    },
    async withdrawItem(){
      this.transferingFromStorage = true;
      try{
        await this.withdrawFromStorage({
          nftContractAddr: this.contractAddress,
          tokenId: this.selectedNftId,
        });
        this.transferingFromStorage = false;
        this.selectedNftId = '';
        this.getStoredIds();
      }
      catch(e){
        this.transferingFromStorage = false;
      }
    },
    async cancelAll(){
      this.cancellingRequest = true;
      await this.cancelBridge();
      this.cancellingRequest = false;
      this.getStatus();
    },
    async withdrawBridge(tokenId: string){
      console.log('withdrawBridge', tokenId);
      this.withdrawingFromBridge = true;
      try{
        await this.withdrawFromBridge({
          tokenId });
        this.getIncoming();
        this.withdrawingFromBridge = false;
        this.weaponIdToWithdraw = '';
        this.characterIdToWithdraw = '';
      }
      catch(e){
        this.withdrawingFromBridge = false;
      }
    },
    async getIncoming(){
      this.incomingWeapons = [];
      this.incomingChars = [];

      //get incoming nft ids
      this.incomingNftIds = await this.getReceivedNFTs();

      for(let i = 0; i < this.incomingNftIds.length; i++){
        const nft: any = await this.getReceivedNFT({
          tokenId: this.incomingNftIds[i]
        });
        nft['7'] = this.incomingNftIds[i];
        if(nft['1'] === '1') this.incomingWeapons.push(nft);
        if(nft['1'] === '2') this.incomingChars.push(nft);
      }
    },
    async getChainId(tokenId: string){
      const chainId = await this.getNFTChainId({
        nftContractAddr: this.contractAddress,
        tokenId,
      });
      return chainId;
    },
    async getStatus(){
      const id = await this.getBridgeTransferId();
      const transfer= await this.getBridgeTransfer({
        transferId: id,
      });
      if(transfer[6] === '0'){
        this.transferStatus = transferStates.noTransfer;
        this.currentTransferNFTId = '';
        return;
      }
      if(transfer[6] === '1'){
        this.transferStatus = transferStates.pending;
      }
      else if(transfer[6] === '2'){
        this.transferStatus = transferStates.processing;
      }
      else if(transfer[6] === '3'){
        this.transferStatus = transferStates.done;
      }
      else if(transfer[6] === '4'){
        this.transferStatus = transferStates.error;
      }
      else if(transfer[6] === '5'){
        this.transferStatus = transferStates.restored;
      }

      const currentTransferTokenAddress = transfer[1];
      this.currentTransferNFTId = transfer[2];
      const currentTransferChainId = transfer[5];

      this.currentTransferChain = this.supportedChains[this.supportedChainIds.indexOf(currentTransferChainId)];

      if(currentTransferTokenAddress === this.Weapons.options.address) this.currentTransferNFTType = 'weapon';
      else this.currentTransferNFTType = 'character';
    },
    async requestBridge(){
      this.transferingFromStorage = true;
      this.targetChainId = this.supportedChainIds[this.supportedChains.indexOf(this.targetChain)];
      try{
        await this.bridgeItem({
          nftContractAddr: this.contractAddress,
          tokenId: this.selectedNftId,
          targetChain: this.targetChainId,
          bridgeFee: this.bridgeFee,
        });
        this.getStatus();
        this.getStoredIds();
        this.selectedNftId = '';
        this.transferingFromStorage = false;
      }
      catch(e){
        this.transferingFromStorage = false;
      }
    },
    async getStoredIds(){
      const storedItemIds: any = await this.getStorageItemIds({
        nftContractAddr: this.contractAddress,
      });
      this.storedNftsIds = storedItemIds;
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
    },
  },
  components: {
    WeaponGrid,
    CharacterList,
    CurrencyConverter,
  },
});
</script>

<style scoped>
.outcome {
  margin: 20px auto;
  text-align: center;
  font-size: 1em;
}
.character-list {
  transform: scale(1.5);
}

.nft-list,
.weapon-grid {
  transform: scale(2);
}

/deep/ .weapon-grid {
  justify-items: center;
}

.search-button {
  width: 100%;
}

.search-input-id,
.search-input-type {
  margin-top: 5px;
  width: 22em;
}

.copy-url-button,
.search-button {
  margin-top: 30px;
}

.nft-display {
  height: auto;
}

.search-result-section {
  padding-top: 100px;
}

.search-section {
  border-right: 1px solid #9e8a57;
}

.result-row-section,
.search-row-section {
  flex-direction: column;
  align-content: center;
}

.result-row-section {
  align-items: center;
}

.owned-by,
.info-text {
  text-align: center;
}

.owned-by {
  margin-top: 150px;
  word-break: break-all;
  padding-left: 20px;
  padding-right: 20px;
}

.search-input-section {
  display: flex;
  justify-content: space-evenly;
}

.m-top-negative-5 {
  margin-top: -5px;
}

.disabled-button {
  opacity: 0.65;
}

@media (max-width: 576px) {
  .nft-list,
  .weapon-grid,
  .character-list {
    transform: scale(1);
  }
}

</style>
