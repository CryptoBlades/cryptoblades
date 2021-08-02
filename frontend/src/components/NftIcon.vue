<template>
  <div v-bind:class="isDefault ? 'default-icon-wrapper' : 'nft-icon-wrapper'">
    <div v-if="isDefault" class="nft-icon">
      <img class="default-placeholder" v-if="nftType === 'weapon'" src="../assets/placeholder/sword-placeholder-1.png"
        v-tooltip="'Weapons (2-5*)'"/>
      <img class="default-placeholder" v-if="nftType === 'junk'" src="../assets/bounty.png"
        v-tooltip="'Junk (1-5*)'" />
      <img class="default-placeholder" v-if="nftType === 'secret'" src="../assets/secret.png"
        v-tooltip="'Secret (??)'" />
    </div>

    <div v-if="!isDefault" class="nft-icon">
      <!-- TODO: show nft with id: nftId of type: ndfType (contract address?)-->
    </div>
  </div>
</template>

<script>
export default {
  props: ['nftType', 'nftId', 'isDefault']
};
</script>

<style>
.nft-icon {
  height: 100%;
  width: 100%;
  position: relative;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid #9e8a57;
}

.nft-icon-wrapper {
  width: 12em;
  height: 12em;
}

.default-icon-wrapper {
  width: 8em;
  height: 8em;
  margin: 5px;
}

.default-placeholder {
  max-width: 100px;
  max-height: 100px;
  margin-left: 12px;
  margin-top: 8px;
  transform: scale(1);
}

.placeholder-weapon {
  max-width: 180px;
  max-height: 180px;
  margin-left: 10px;
  margin-top: 5px;
  transform: scale(0.7);
}
</style>