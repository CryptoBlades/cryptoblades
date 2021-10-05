<template>
      <b-popover id="weapon-stats" target="inventory-weapon-content" triggers="hover" placement="topleft">
            <template #title>Weapon Stats</template>
                      <div class="stat-text">INT 300</div>
                      <div class="stat-text">INT 300</div>
                      <div class="stat-text">INT 300</div>
      </b-popover>
</template>

<script>
export default {
  data(){
    return {
      id:`weapon-stats+${1}`,
    };
  },
};
</script>
