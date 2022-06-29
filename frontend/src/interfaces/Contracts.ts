import { Contract as Web3EthContract } from 'web3-eth-contract';
import type {
  IERC20, IERC721, IStakingRewards, INftStakingRewards, KingStakingRewardsUpgradeable,
  KingStakingRewardsUpgradeable90, KingStakingRewardsUpgradeable180, CryptoBlades, Characters, Weapons, RaidBasic, IRandoms,
  NFTMarket, WaxBridge, Blacksmith, Shields, Garrison, CharacterRenameTagConsumables,
  WeaponRenameTagConsumables, CharacterFireTraitChangeConsumables, CharacterEarthTraitChangeConsumables,
  CharacterWaterTraitChangeConsumables, CharacterLightningTraitChangeConsumables, Raid1, RaidTrinket, Junk, KeyLootbox, PvpArena,
  WeaponCosmetics, CharacterCosmetics, NFTStorage, CBKLandSale, CBKLand, Treasury, Promos, BurningManager, SimpleQuests,
  PartnerVault, SpecialWeaponsManager, PvpCore, PvpRankings, TokensManager
} from '../../../build/abi-interfaces';
import { StakeType, NftStakeType } from './State';

interface TypeSafeContract<Abi> {
  methods: Abi;
}

export type Contract<Abi> = Omit<Web3EthContract, 'methods'> & TypeSafeContract<Abi>;

export type StakingContracts = Partial<Record<StakeType, {
  StakingRewards: Contract<IStakingRewards>,
  StakingToken: Contract<IERC20>
}>>;

export type NftStakingContracts = Partial<Record<NftStakeType, {
  StakingRewards: Contract<INftStakingRewards>,
  StakingToken: Contract<IERC721>
}>>;

export interface Contracts {
  SkillToken: Contract<IERC20>;
  staking: StakingContracts;
  nftStaking: NftStakingContracts;

  CryptoBlades?: Contract<CryptoBlades>;
  Randoms?: Contract<IRandoms>;
  Characters?: Contract<Characters>;
  Weapons?: Contract<Weapons>;
  Blacksmith?: Contract<Blacksmith>;
  RaidBasic?: Contract<RaidBasic>;
  NFTMarket?: Contract<NFTMarket>;
  WaxBridge?: Contract<WaxBridge>;
  Shields?: Contract<Shields>;
  Garrison?: Contract<Garrison>;
  CharacterRenameTagConsumables?: Contract<CharacterRenameTagConsumables>;
  WeaponRenameTagConsumables?: Contract<WeaponRenameTagConsumables>;
  CharacterFireTraitChangeConsumables?: Contract <CharacterFireTraitChangeConsumables>;
  CharacterEarthTraitChangeConsumables?: Contract <CharacterEarthTraitChangeConsumables>;
  CharacterWaterTraitChangeConsumables?: Contract <CharacterWaterTraitChangeConsumables>;
  CharacterLightningTraitChangeConsumables?: Contract <CharacterLightningTraitChangeConsumables>;
  Raid1?: Contract<Raid1>;
  RaidTrinket?: Contract<RaidTrinket>;
  Junk?: Contract<Junk>;
  KeyLootbox?: Contract<KeyLootbox>;
  PvpArena?: Contract<PvpArena>;
  PvpCore?: Contract<PvpCore>;
  PvpRankings?: Contract<PvpRankings>;
  TokensManager?: Contract<TokensManager>;
  WeaponCosmetics?: Contract<WeaponCosmetics>;
  CharacterCosmetics?: Contract<CharacterCosmetics>;
  NFTStorage?: Contract<NFTStorage>;
  CBKLandSale?: Contract<CBKLandSale>;
  CBKLand?: Contract<CBKLand>;

  Treasury?: Contract<Treasury>;
  BurningManager?: Contract<BurningManager>;
  KingStakingRewardsUpgradeable?: Contract<KingStakingRewardsUpgradeable>;
  KingStakingRewardsUpgradeable90?: Contract<KingStakingRewardsUpgradeable90>;
  KingStakingRewardsUpgradeable180?: Contract<KingStakingRewardsUpgradeable180>;
  Promos?: Contract<Promos>;
  SimpleQuests?: Contract<SimpleQuests>;
  PartnerVault?: Contract<PartnerVault>;
  SpecialWeaponsManager?: Contract<SpecialWeaponsManager>;
}
