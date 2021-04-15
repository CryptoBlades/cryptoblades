import { abi as cryptoBladesAbi } from '../../build/contracts/CryptoBlades.json';
import { abi as charactersAbi } from '../../build/contracts/Characters.json';
import { abi as weaponsAbi } from '../../build/contracts/Weapons.json';
import { abi as stakingRewardsAbi } from '../../build/contracts/StakingRewards.json';
import { abi as skillTokenAbi } from '../../build/contracts/SkillToken.json';

function createContracts(web3, featureFlagStakeOnly) {
  const at = abi => addr => new web3.eth.Contract(abi, addr);

  const StakingRewards = new web3.eth.Contract(stakingRewardsAbi, process.env.VUE_APP_STAKING_REWARDS_CONTRACT_ADDRESS);
  const SkillToken = new web3.eth.Contract(skillTokenAbi, process.env.VUE_APP_SKILL_TOKEN_CONTRACT_ADDRESS);

  if (featureFlagStakeOnly) {
    return { StakingRewards, SkillToken };
  }

  const CryptoBlades = new web3.eth.Contract(cryptoBladesAbi, process.env.VUE_APP_CRYPTOBLADES_CONTRACT_ADDRESS);
  const Characters = { at: at(charactersAbi) };
  const Weapons = { at: at(weaponsAbi) };

  return { CryptoBlades, Characters, Weapons, StakingRewards, SkillToken };
}

export async function setUpContracts(web3, featureFlagStakeOnly) {
  const contracts = createContracts(web3, featureFlagStakeOnly);

  if (featureFlagStakeOnly) {
    return contracts;
  }

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
