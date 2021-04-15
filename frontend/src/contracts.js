import { abi as cryptoBladesAbi, networks as cryptoBladesNetworks } from '../../build/contracts/CryptoBlades.json';
import { abi as stakingRewardsAbi, networks as stakingRewardsNetworks } from '../../build/contracts/StakingRewards.json';
import { abi as skillTokenAbi, networks as skillTokenNetworks } from '../../build/contracts/SkillToken.json';

import { abi as charactersAbi } from '../../build/contracts/Characters.json';
import { abi as weaponsAbi } from '../../build/contracts/Weapons.json';

function createContracts(web3) {
  const at = abi => addr => new web3.eth.Contract(abi, addr);

  const networkId = process.env.VUE_APP_NETWORK_ID || 5777;
  const cryptoBladesContractAddr = process.env.VUE_APP_CRYPTOBLADES_CONTRACT_ADDRESS || cryptoBladesNetworks[networkId].address;
  const stakingRewardsContractAddr = process.env.VUE_APP_STAKING_REWARDS_CONTRACT_ADDRESS || stakingRewardsNetworks[networkId].address;
  const skillTokenContractAddr = process.env.VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS || skillTokenNetworks[networkId].address;

  const CryptoBlades = new web3.eth.Contract(cryptoBladesAbi, cryptoBladesContractAddr);
  const StakingRewards = new web3.eth.Contract(stakingRewardsAbi, stakingRewardsContractAddr);
  const SkillToken = new web3.eth.Contract(skillTokenAbi, skillTokenContractAddr);

  const Characters = { at: at(charactersAbi) };
  const Weapons = { at: at(weaponsAbi) };

  return { CryptoBlades, Characters, Weapons, StakingRewards, SkillToken };
}

export async function setUpContracts(web3) {
  const contracts = createContracts(web3);

  const CryptoBlades = contracts.CryptoBlades;
  const StakingRewards = contracts.StakingRewards;
  const SkillToken = contracts.SkillToken;
  const [charactersAddr, weaponsAddr] = await Promise.all([
    contracts.CryptoBlades.methods.getCharactersAddress().call(),
    contracts.CryptoBlades.methods.getWeaponsAddress().call(),
  ]);
  const Characters = contracts.Characters.at(charactersAddr);
  const Weapons = contracts.Weapons.at(weaponsAddr);

  return { CryptoBlades, Characters, Weapons, StakingRewards, SkillToken };
}
