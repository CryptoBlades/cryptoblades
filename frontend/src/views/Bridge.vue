<template>
  <div>
    <div class="row mt-3 justify-content-center">
        <h3> Bridge for your NFTs - Transfer NFTs to another chain </h3>
    </div>
    <b-tabs justified>
      <b-tab title="Inventory" @click="nftType = 'weapon'">
            <div class="d-flex flex-row justify-content-center">
              <div class="p-2">
                <b-button
                  variant="primary"
                  @click="nftType = 'weapon'; selectedNftId = null"  class="gtag-link-others" tagname="show_weapons_bridge">
                  Show Weapons
                </b-button>
              </div>
              <div class="p-2">
                <b-button
                  variant="primary"
                  @click="nftType = 'character'; selectedNftId = null"  class="gtag-link-others" tagname="show_characters_bridge">
                  Show Characters
                </b-button>
              </div>
              <div class="p-2">
                <b-button
                  :disabled="selectedNftId == null"
                  variant="primary"
                  @click="transferToStorage()"  class="gtag-link-others" tagname="click_transfer_bridge">Transfer NFT to storage</b-button>
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
          <character-list
            :showFilters="true"
            v-model="selectedNftId"
          />
        </div>
    </b-tab>
      <b-tab title="Storage" @click="showStorage(); selectedNftId = null">
        <div class="d-flex flex-row justify-content-center">
          <div class="p-2">
            <b-button
              variant="primary"
              @click="nftType = 'weapon'; selectedNftId = null; getStoredIds()"  class="gtag-link-others" tagname="show_weapons_bridge">
              Show Weapons
            </b-button>
          </div>
          <div class="p-2">
            <b-button
              variant="primary"
              @click="nftType = 'character'; selectedNftId = null; getStoredIds()"  class="gtag-link-others" tagname="show_characters_bridge">
              Show Characters
            </b-button>
          </div>
          <div class="p-2">
            <b-button
              :disabled="selectedNftId == null"
              variant="primary"
              @click="withdrawItem()"  class="gtag-link-others" tagname="click_transfer_bridge">Withdraw from Storage</b-button>
          </div>
          <div class="p-2">
            <b-button
              :disabled="transferStatus == 'Pending' || selectedNftId == null"
              variant="primary"
              @click="requestBridge()"  class="gtag-link-others" tagname="click_transfer_bridge">Request Transfer</b-button>
          </div>
          <div class="p-2">
            <b-button
              :disabled="transferStatus != 'Pending'"
              variant="primary"
              @click="cancelAll()"  class="gtag-link-others" tagname="click_transfer_bridge">Cancel Transfer Request</b-button>
          </div>
        </div>
        <div class="d-flex flex-row bd-highlight mb-3 justify-content-center">
          <div class="p-4 w-25" v-if="transferStatus != 'Pending'">
            <h4 class="text-center">Select target chain</h4>
              <select class="form-control" v-model="targetChain">
                <option v-for="chain in chainsToSendTo" :value="chain" :key="chain">{{ chain }}</option>
              </select>
          </div>
        </div>
        <div v-if="transferStatus != 'No transfer'" class="transferBox d-flex flex-column bd-highlight mb-3 justify-content-center">
          <div class="text-center">
            <h4>Current Transfer</h4>
          </div>
          <div v-if="currentTransferNFTType == 'weapon'">
            <weapon-grid
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
              :characterIds="[currentTransferNFTId]"
              :showGivenCharacterIds="true"
              :nftDisplay="true"
            />
          </div>
          <div class="text-center">
            Status: {{transferStatus}} <br>
            To Chain: {{currentTransferChain}}
          </div>
        </div>
        <br>
        <hr style="border:0.5px solid #9E8A57">
        <div v-if="nftType == 'weapon'">
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
        <div v-if="nftType == 'character'">
          <character-list
            :showFilters="false"
            v-model="selectedNftId"
            :showGivenCharacterIds="true"
            :characterIds="storedNftsIds"
          />
        </div>
      </b-tab>
      <b-tab title="Incoming NFTs" @click="getIncoming(); selectedNftId = null">
        <div v-if="incomingChars.length === 0 && incomingWeapons.length === 0">
          <h3 class="text-center p-4">No incoming NFTs!</h3>
        </div>
        <div v-else>
          <div class="d-flex flex-row bd-highlight mb-3 justify-content-center">
            <div class="p-4 w-20">
              <h4 class="text-center">Select Weapon to Withdraw</h4>
              <select class="form-control" v-model="weaponIdToWithdraw">
                <option value="" disabled selected>Select your Weapon</option>
                <option v-for="weapon in incomingWeapons" :value="weapon['3']" :key="weapon['3']">
                  Weapon ID: {{ weapon['3'] }} from Chain: {{supportedChains[supportedChainIds.indexOf(weapon['2'])]}}
                </option>
              </select>
              <div class="p-2 text-center">
                <b-button
                  :disabled="weaponIdToWithdraw == null"
                  variant="primary"
                  @click="withdrawBridge(weaponIdToWithdraw)"  class="gtag-link-others" tagname="click_transfer_bridge">Withdraw Weapon</b-button>
              </div>
            </div>
            <div class="p-4 w-20">
              <h4 class="text-center">Select Character to Withdraw</h4>
              <select class="form-control" v-model="characterIdToWithdraw">
                <option value="" disabled selected>Select your Character</option>
                <option v-for="character in incomingChars" :value="character['3']" :key="character['3']">
                  Character ID: {{ character['3'] }} from Chain: {{supportedChains[supportedChainIds.indexOf(character['2'])]}}
                </option>
              </select>
              <div class="p-2 text-center">
                <b-button
                  :disabled="characterIdToWithdraw == null"
                  variant="primary"
                  @click="withdrawBridge(characterIdToWithdraw)"  class="gtag-link-others" tagname="click_transfer_bridge">Withdraw Character</b-button>
              </div>
            </div>
          </div>
        </div>
      </b-tab>
    </b-tabs>
  </div>
</template>
<script lang="ts">
import Vue from 'vue';
import { mapActions, mapGetters } from 'vuex';
import { isNftType, Nft, allNftTypes } from '../interfaces/Nft';
import { Accessors } from 'vue/types/options';
import { Contract, Contracts } from '@/interfaces';
import { NftIdType } from '@/components/smart/NftList.vue';
import { Characters, Shields, Weapons } from '../../../build/abi-interfaces';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import CharacterList from '../components/smart/CharacterList.vue';
import config from '../../app-config.json';
import { getConfigValue } from '@/contracts';


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
      allNftTypes,
      ownerAddress: '',
      nftType: 'weapon',
      nftId: '',
      nftPrice: '',
      selectedNftId: '',
      storedNftsIds: [],
      currentChain: '',
      targetChain: '',
      targetChainId: '',
      supportedChains: [] as string[],
      supportedChainIds: [] as string[],
      transferStatus: '',
      currentTransferNFTId: '',
      currentTransferNFTType: '',
      currentTransferChain: '',
      chainsToSendTo: [] as string[],
      incomingNfts: [] as Nft[],
      incomingWeapons: [] as string[],
      incomingChars: [] as string[],
      weaponIdToWithdraw: '',
      characterIdToWithdraw: '',
    };
  },

  computed: {
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
    canPurchase(): boolean {
      return this.ownCharacters.length < 4;
    },
  },
  created(){
    console.log(getConfigValue('supportedChains'));
    this.supportedChains  = config.supportedChains;

    //remove currentChain from chains to send to
    this.currentChain = localStorage.getItem('currentChain') || 'BSC';
    this.chainsToSendTo = this.supportedChains.filter(item => item !== this.currentChain);
    this.targetChain = this.chainsToSendTo[0];

    //check current net by checking url
    let currentNet = 'production';
    if(window.location.href.indexOf('test') !== -1) currentNet = 'test';
    console.log('currentNet: ', currentNet);

    const conf = config as any;
    for(let i = 0; i < this.supportedChains.length; i++){
      this.supportedChainIds.push(conf.environments[currentNet].chains[this.supportedChains[i]].VUE_APP_NETWORK_ID);
    }
  },

  methods: {
    ...(mapActions([
      'fetchShields',
      'fetchWeapons',
      'fetchCharacters',
      'checkMarketItemOwnership',
      'fetchMarketNftPrice',
      'purchaseMarketListing',
      'fetchAllMarketNftIds',
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
      'getReceivedNFT'
    ]) as StoreMappedActions),
    async cancelAll(){
      await this.cancelBridge();
      this.getStatus();
    },
    async withdrawBridge(tokenId){
      await this.withdrawFromBridge({
        tokenId });
      this.getIncoming();
    },
    async getIncoming(){
      this.incomingWeapons = [];
      this.incomingChars = [];

      //get incoming nft ids
      const incomingNftIds = await this.getReceivedNFTs();
      console.log('incomingIds: ', incomingNftIds);

      for(let i = 0; i < incomingNftIds.length; i++){
        const nft: any = await this.getReceivedNFT({
          tokenId: incomingNftIds[i]
        });
        if(nft['1'] === '1') this.incomingWeapons.push(nft);
        if(nft['1'] === '2') this.incomingChars.push(nft);
      }
      console.log(this.incomingWeapons);
      console.log(this.incomingChars);
    },
    async getChainId(tokenId: string){
      const chainId = await this.getNFTChainId({
        nftContractAddr: this.contractAddress,
        tokenId,
      });
      console.log('chainId: ',chainId);
    },
    async getStatus(){
      const id = await this.getBridgeTransferId();
      const transfer= await this.getBridgeTransfer({
        transferId: id,
      });
      console.log('status: ', transfer);
      if(transfer[6] === '0'){
        this.transferStatus = 'No transfer';
      }
      if(transfer[6] === '1'){
        this.transferStatus = 'Pending';
      }
      else if(transfer[6] === '2'){
        this.transferStatus = 'Processing';
      }
      else if(transfer[6] === '3'){
        this.transferStatus = 'DONE';
      }
      else if(transfer[6] === '4'){
        this.transferStatus = 'Error';
      }

      const currentTransferTokenAddress = transfer[1];
      this.currentTransferNFTId = transfer[2];
      const currentTransferChainId = transfer[5];

      this.currentTransferChain = this.supportedChains[this.supportedChainIds.indexOf(currentTransferChainId)];

      if(currentTransferTokenAddress === this.Weapons.options.address) this.currentTransferNFTType = 'weapon';
      else this.currentTransferNFTType = 'character';

    },
    async requestBridge(){
      this.targetChainId = this.supportedChainIds[this.supportedChains.indexOf(this.targetChain)];
      await this.bridgeItem({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        targetChain: this.targetChainId});
      this.getStatus();
    },
    async withdrawItem(){
      const res = await this.withdrawFromStorage({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
      });
      console.log(res);
      this.getStoredIds();
    },
    async getStoredIds(){
      const results: any = await this.getStorageItemIds({
        nftContractAddr: this.contractAddress,
      });
      this.storedNftsIds = results;
      console.log('results: ', results);
    },
    async showStorage(){
      //const getNumberOfStoragedItems = await this.getNumberOfStoragedItems({nftContractAddr: this.contractAddress,});
      const storedItemIds: any = await this.getStorageItemIds({
        nftContractAddr: this.contractAddress,
      });
      console.log('storedItemIds: ', storedItemIds);
      this.storedNftsIds = storedItemIds;
      this.getStatus();
    },
    async transferToStorage(){
      try{
        const res = await this.storeItem({
          nftContractAddr: this.contractAddress,
          tokenId: this.selectedNftId});
        console.log('results: ', res);
      }
      catch(e){
        console.log('error: ', e);
      }

    },
  },

  mounted() {

  },

  components: {
    WeaponGrid,
    CharacterList,
  },
});
</script>

<style scoped>

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
