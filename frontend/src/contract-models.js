export function characterFromContract(id, data) {
  const xp = data[0];
  const level = data[1];
  const trait = data[2];
  const staminaTimestamp = data[3];
  const appearance = data[4];
  return { id, xp, level, trait, staminaTimestamp, appearance };
}

export function weaponFromContract(id, data) {
  const properties = data[0];
  const stat1 = data[1];
  const stat2 = data[2];
  const stat3 = data[3];
  const level = data[4];
  const blade = data[5];
  const crossguard = data[6];
  const hilt = data[7];
  return { id, properties, stat1, stat2, stat3, level, blade, crossguard, hilt };
}
