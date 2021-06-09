import { Contract as Web3EthContract } from 'web3-eth-contract';
import type { IERC20, IStakingRewards, CryptoBlades, Characters, Weapons, RaidBasic, IRandoms } from '../../../build/abi-interfaces';

interface TypeSafeContract<Abi> {
  methods: Abi;
}

export type Contract<Abi> = Omit<Web3EthContract, 'methods'> & TypeSafeContract<Abi>;

export interface Contracts {
  SkillToken: Contract<IERC20>;
  LPToken: Contract<IERC20> | null;
  LP2Token: Contract<IERC20> | null;
  SkillStakingRewards: Contract<IStakingRewards>;
  LPStakingRewards: Contract<IStakingRewards> | null;
  LP2StakingRewards: Contract<IStakingRewards> | null;

  CryptoBlades?: Contract<CryptoBlades>;
  Randoms?: Contract<IRandoms>;
  Characters?: Contract<Characters>;
  Weapons?: Contract<Weapons>;
  RaidBasic?: Contract<RaidBasic>;
}
