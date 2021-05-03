import { Contract as Web3EthContract } from 'web3-eth-contract';

export interface Contracts {
  SkillToken: Web3EthContract;
  LPToken: Web3EthContract;
  SkillStakingRewards: Web3EthContract;
  LPStakingRewards: Web3EthContract;

  CryptoBlades?: Web3EthContract;
  Characters?: Web3EthContract;
  Weapons?: Web3EthContract;
  RaidBasic?: Web3EthContract;
}
