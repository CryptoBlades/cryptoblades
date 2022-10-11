import {
  Contract,
  IState,
} from '@/interfaces';
import {Dispatch} from 'vuex';
import {NftTransfer, TransferedNft} from '@/interfaces/Nft';
import {approveFeeWalletOnly} from '@/contract-call-utils';
import BigNumber from 'bignumber.js';

const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });
import {IERC721} from '@/../../build/abi-interfaces';
import { getGasPrice } from '../store';

const bridge = {
  actions: {
    async storeItem(
      { rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
      { nftContractAddr, tokenId}: { nftContractAddr: string, tokenId: string}) {

      const { NFTStorage, Weapons, Characters, Shields } = rootState.contracts();
      if(!NFTStorage || !Weapons || !Characters || !Shields || !rootState.defaultAccount) return;

      const NFTContract: Contract<IERC721> =
        nftContractAddr === Weapons.options.address
          ? Weapons : nftContractAddr === Characters.options.address
            ? Characters : Shields;

      await NFTContract.methods
        .approve(NFTStorage.options.address, tokenId)
        .send(defaultCallOptions(rootState));
      const res = await NFTStorage.methods
        .storeItem(nftContractAddr, tokenId)
        .send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
        });

      if(nftContractAddr === Weapons.options.address)
        await dispatch('updateWeaponIds');
      else if(nftContractAddr === Characters.options.address)
        await dispatch('updateCharacterIds');
      else if (nftContractAddr === Shields.options.address)
        await dispatch('updateShieldIds');
      return res;
    },
    async getStorageItemIds({ rootState }: {rootState: IState}, { nftContractAddr }: { nftContractAddr: string}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage) return;

      const res = await NFTStorage.methods
        .getStorageItemIds(nftContractAddr)
        .call(defaultCallOptions(rootState));

      return res;
    },
    async getNumberOfStoragedItems({ rootState }: {rootState: IState}, { nftContractAddr }: { nftContractAddr: string}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage) return;

      const res = await NFTStorage.methods
        .getNumberOfStoragedItems(nftContractAddr)
        .call(defaultCallOptions(rootState));

      return res;
    },
    async withdrawFromStorage(
      { rootState, dispatch }: {rootState: IState, dispatch: Dispatch},
      { nftContractAddr, tokenId}: { nftContractAddr: string, tokenId: number}) {
      const { NFTStorage, Weapons, Characters, Shields } = rootState.contracts();
      if(!NFTStorage || !Weapons || !Characters || !Shields || !rootState.defaultAccount) return;

      let withdrawFee = '0';
      const isNftBridged = await dispatch('fetchIsNftBridged', { nftContractAddr, tokenId });
      if(isNftBridged) {
        withdrawFee = await dispatch('fetchBridgeWithdrawFee', nftContractAddr);
      }

      await NFTStorage.methods
        .withdrawFromStorage(nftContractAddr, tokenId)
        .send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
          value: withdrawFee
        });

      if(nftContractAddr === Weapons.options.address)
        await dispatch('updateWeaponIds');
      else if(nftContractAddr === Characters.options.address)
        await dispatch('updateCharacterIds');
      else if (nftContractAddr === Shields.options.address)
        await dispatch('updateShieldIds');

    },
    async bridgeItem({ rootState, dispatch }: {rootState: IState, dispatch: Dispatch}, { nftContractAddr, tokenId, targetChain, bridgeFee }:
    { nftContractAddr: string, tokenId: number, targetChain: string, bridgeFee: string }) {
      const { NFTStorage, CryptoBlades, SkillToken } = rootState.contracts();
      if (!NFTStorage || !CryptoBlades || !SkillToken || !rootState.defaultAccount) return;
      await approveFeeWalletOnly(
        CryptoBlades,
        SkillToken,
        rootState.defaultAccount,
        defaultCallOptions(rootState),
        defaultCallOptions(rootState),
        new BigNumber(bridgeFee)
      );
      await NFTStorage.methods
        .bridgeItem(nftContractAddr, tokenId, targetChain)
        .send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
        });
      await dispatch('fetchSkillBalance');
    },
    async getNFTChainId({rootState}: {rootState: IState, dispatch: Dispatch}, {nftContractAddr, tokenId}: { nftContractAddr: string, tokenId: number}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage) return;
      const chainId = await NFTStorage.methods
        .getNFTChainId(nftContractAddr, tokenId)
        .call(defaultCallOptions(rootState));
      return chainId;
    },
    async getBridgeTransferId({rootState}: {rootState: IState, dispatch: Dispatch}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage) return;
      const id = await NFTStorage.methods
        .getBridgeTransfer()
        .call(defaultCallOptions(rootState));
      return id;
    },
    async getBridgeTransfer({rootState}: {rootState: IState, dispatch: Dispatch}, {transferId}: { transferId: string}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage) return;
      const nft = await NFTStorage.methods
        .getBridgeTransfer(transferId)
        .call(defaultCallOptions(rootState));
      return {
        owner: nft[0],
        nftAddress: nft[1],
        nftId: +nft[2],
        requestBlock: +nft[3],
        lastUpdateBlock: +nft[4],
        chainId: +nft[5],
        status: +nft[6],
      }as NftTransfer;
    },
    async withdrawFromBridge({ rootState }: {rootState: IState, dispatch: Dispatch}, {tokenId}: {tokenId: number}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage || !rootState.defaultAccount) return;
      await NFTStorage.methods
        .withdrawFromBridge(tokenId)
        .send({
          from: rootState.defaultAccount,
          gasPrice: getGasPrice(),
        });
    },
    async cancelBridge({ rootState }: {rootState: IState, dispatch: Dispatch}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage || !rootState.defaultAccount) return;
      await NFTStorage.methods
        .cancelBridge()
        .send({
          from: rootState.defaultAccount,
        });
    },
    async chainEnabled({ rootState }: {rootState: IState, dispatch: Dispatch}, { chainId }: { chainId: string }) {
      const { NFTStorage } = rootState.contracts();
      if (!NFTStorage || !rootState.defaultAccount) return;
      return await NFTStorage.methods
        .chainBridgeEnabled(chainId)
        .call(defaultCallOptions(rootState));
    },
    async getReceivedNFTs({ rootState }: {rootState: IState, dispatch: Dispatch}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage || !rootState.defaultAccount) return;
      const nftIds = await NFTStorage.methods
        .getReceivedNFTs()
        .call(defaultCallOptions(rootState));
      return nftIds.map(Number) as number[];
    },
    async getReceivedNFT({ rootState }: {rootState: IState, dispatch: Dispatch}, {tokenId}: {tokenId: number}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage || !rootState.defaultAccount) return;
      const nft: string[] = await NFTStorage.methods
        .getReceivedNFT(tokenId)
        .call(defaultCallOptions(rootState));
      return {
        owner: nft[0],
        nftType: +nft[1],
        sourceChain: +nft[2],
        sourceId: +nft[3],
        status: +nft[4],
        transferInsMeta: nft[5],
      } as TransferedNft;
    },
    async fetchBridgeFee({ rootState }: {rootState: IState, dispatch: Dispatch}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage || !rootState.defaultAccount) return;
      return await NFTStorage.methods.getBridgeFee().call({
        from: rootState.defaultAccount,
      });
    },
    async fetchBridgeWithdrawFee({ rootState }: {rootState: IState, dispatch: Dispatch}, {tokenAddress}: {tokenAddress: string}) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage || !rootState.defaultAccount) return;
      return await NFTStorage.methods.withdrawFromStorageNativeFee(tokenAddress).call({
        from: rootState.defaultAccount,
      });
    },
    async fetchIsNftBridged({ rootState }: {rootState: IState }, { nftContractAddr, tokenId }: { nftContractAddr: string, tokenId: number }) {
      const { NFTStorage } = rootState.contracts();
      if(!NFTStorage || !rootState.defaultAccount) return;
      return await NFTStorage.methods.isNftBridged(nftContractAddr, tokenId).call(defaultCallOptions(rootState));
    },
  },
};


export default bridge;
