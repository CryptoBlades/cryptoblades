import { Contract as Web3EthContract } from 'web3-eth-contract';
import { AbiMethods } from '../abi-to-ts';
import type { IERC20, StakingRewards, CryptoBlades, Characters, Weapons, RaidBasic } from '../../../build/abis';

interface TypeSafeContract<Abi> {
  methods: AbiMethods<Abi>;
}

type Contract<Abi> = Omit<Web3EthContract, 'methods'> & TypeSafeContract<Abi>;

export interface Contracts {
  SkillToken: Contract<typeof IERC20>;
  LPToken: Contract<typeof IERC20>;
  SkillStakingRewards: Contract<typeof StakingRewards>;
  LPStakingRewards: Contract<typeof StakingRewards>;

  CryptoBlades?: Contract<typeof CryptoBlades>;
  Characters?: Contract<typeof Characters>;
  Weapons?: Contract<typeof Weapons>;
  RaidBasic?: Contract<typeof RaidBasic>;
}
