import { Contract as Web3EthContract } from 'web3-eth-contract';
import type { IERC20, IStakingRewards, CryptoBlades, Characters, Weapons, RaidBasic } from '../../../build/abi-interfaces';

interface TypeSafeContract<Abi> {
  methods: Abi;
}

type Contract<Abi> = Omit<Web3EthContract, 'methods'> & TypeSafeContract<Abi>;

export interface Contracts {
  SkillToken: Contract<IERC20>;
  LPToken: Contract<IERC20>;
  LP2Token: Contract<IERC20>;
  SkillStakingRewards: Contract<IStakingRewards>;
  LPStakingRewards: Contract<IStakingRewards>;
  LP2StakingRewards: Contract<IStakingRewards>;

  CryptoBlades?: Contract<CryptoBlades>;
  Characters?: Contract<Characters>;
  Weapons?: Contract<Weapons>;
  RaidBasic?: Contract<RaidBasic>;
}
