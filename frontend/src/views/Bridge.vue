<template>
  <div>
    <div class="row m-3 justify-content-center">
      <h2> Bridge for your NFTs</h2>
    </div>
    <div class="row m-3 justify-content-center">
      <h3>Transfer NFTs to another chain</h3>
    </div>
    <div class="row mt-3 justify-content-center">
      <p v-if="bridgeFee">
        Bridge Transfer Fee: <CurrencyConverter :skill="convertWeiToSkill(bridgeFee)"/> &nbsp;
        <b-icon-question-circle class="centered-icon" scale="0.8"
        v-tooltip.bottom="`The fee is deducted when you request a transfer under the 'Storage' tab.`"
        />
      </p>
    </div>
    <div class="row mb-3 justify-content-center">
      <p v-if="queueLength">
        Queue length: <b>{{queueLength}}</b> &nbsp;
        <b-icon-question-circle class="centered-icon" scale="0.8"
        v-tooltip.bottom="`There are currently ${queueLength} NFTs in queue for transfer`"
        />
      </p>
    </div>
    <b-tabs justified>
      <b-tab title="Inventory" @click="nftType = 'weapon'">
        <div class="btnRow d-flex flex-row justify-content-center">
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
              class="gtag-link-others" tagname="click_transfer_bridge">Move NFT to storage</b-button>
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
            When transferring your character to another chain, <b>any</b> unclaimed XP remains on this one!
          </span>
        </b-modal>
      </b-tab>
      <b-tab title="Storage" @click="showStorage(); selectedNftId = ''">
        <div class="btnRow d-flex flex-row justify-content-center" v-if="loadedStorage">
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
            <b-button :disabled="selectedNftId === '' ||
            (currentTransferNFTId == selectedNftId && transferStatus != transferStates.restored) ||
            !storedNftsIds.includes(String(selectedNftId))"
            variant="primary"
            @click="withdrawItem()" class="gtag-link-others"
            tagname="click_transfer_bridge">Withdraw from <br> Storage</b-button>
          </div>
          <div class="p-2">
            <b-button
              :disabled="!canBridge"
              variant="primary"
              @click="requestBridge()" class="gtag-link-others" tagname="click_transfer_bridge">
                Request Transfer <br> <span :style="canAffordBridge ? '' : 'color:red;'"> (<CurrencyConverter :skill="convertWeiToSkill(bridgeFee)"/>) </span>
            </b-button>
          </div>
          <div class="p-2">
            <b-button :disabled="transferStatus != transferStates.pending" variant="primary" @click="$refs['refund-warning-modal'].show()"
              class="gtag-link-others" tagname="click_transfer_bridge">Cancel <br> Transfer Request</b-button>
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
          <div v-if="currentTransferNFTType == 'character'">
            <character-list
            class="currentTransferNFT"
            v-model="selectedNftId"
            :characterIds="[currentTransferNFTId]"
            :showGivenCharacterIds="true"
            :nftDisplay="true"
            />
          </div>
          <div class="text-center">
            Status: {{transferStatus}} <br>
            To Chain: {{currentTransferChain}} <br>
            <span v-if="transferStatus === transferStates.pending"> Your place in Queue: {{currentTransferQueuePosition}}</span><br>
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
          :showReforgedWeaponsDefVal="true"
          :showFavoriteWeaponsDefVal="true"
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
  getBridgeTransferAt(): Promise<number>;
  getBridgeTransfers(): Promise<number>;
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
      storedNftsIds: [] as string[],
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
      loadedStorage: false,
      currentTransferQueuePosition: 0,
      queueLength: 0,
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
    canBridge(){
      if (!this.canAffordBridge) return false;

      else if(!this.enabledChains.length) return false;

      else if(!this.storedNftsIds.includes(String(this.selectedNftId))) return false;

      else if(this.transferStatus === transferStates.done && this.currentTransferNFTId === String(this.selectedNftId)) return false;

      else if(this.transferStatus === transferStates.pending || this.transferStatus === this.transferStates.processing) return false;

      else if(this.selectedNftId === '') return false;

      else return true;
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
      'getBridgeTransferAt',
      'getBridgeTransfers',
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
    async checkQueuePosition(id: number){
      const transferAt = await this.getBridgeTransferAt();
      const bridgetransfers = await this.getBridgeTransfers();
      if(this.transferStatus === transferStates.pending && bridgetransfers > transferAt) return (id - transferAt);
      else return 0;
    },
    async checkQueueLength(){
      const transferAt = await this.getBridgeTransferAt();
      const bridgetransfers = await this.getBridgeTransfers();
      this.queueLength = bridgetransfers - transferAt;
      if(this.queueLength < 0) this.queueLength = 0;
    },
    async getStatus(){
      await this.checkQueueLength();
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
      this.currentTransferQueuePosition = await this.checkQueuePosition(parseInt(id,10));

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
      this.loadedStorage = true;
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
.btnRow{
  flex-wrap: wrap;
}
.btn{
  width: 150px;
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

@media screen and (min-width: 768px) {

}

</style>
