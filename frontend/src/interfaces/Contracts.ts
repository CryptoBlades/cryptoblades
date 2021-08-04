import { Contract as Web3EthContract } from 'web3-eth-contract';
import type {
  IERC20, IStakingRewards,
  CryptoBlades, Characters, Weapons, RaidBasic, IRandoms,
  NFTMarket, WaxBridge, Blacksmith
} from '../../../build/abi-interfaces';
import { StakeType } from './State';

interface TypeSafeContract<Abi> {
  methods: Abi;
}

export type Contract<Abi> = Omit<Web3EthContract, 'methods'> & TypeSafeContract<Abi>;

export type StakingContracts = Partial<Record<StakeType, {
  StakingRewards: Contract<IStakingRewards>,
  StakingToken: Contract<IERC20>
}>>;

export interface Contracts {
  SkillToken: Contract<IERC20>;
  staking: StakingContracts;

  CryptoBlades?: Contract<CryptoBlades>;
  Randoms?: Contract<IRandoms>;
  Characters?: Contract<Characters>;
  Weapons?: Contract<Weapons>;
  Blacksmith?: Contract<Blacksmith>;
  RaidBasic?: Contract<RaidBasic>;
  NFTMarket?: Contract<NFTMarket>;
  WaxBridge?: Contract<WaxBridge>;
}
