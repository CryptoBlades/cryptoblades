<template>
  <div class="body">
    <h1>Blacksmith</h1>

    <h2>Weapon to reforge:</h2>
    <weapon-grid
      :weapons="weapons"
      :selectedWeaponId="selectedWeaponIdForReforging"
      @select="selectWeaponForReforging"
    />
    <h2>Weapon to burn:</h2>
    <weapon-grid
      :weapons="weapons"
      :selectedWeaponId="selectedWeaponIdForBurning"
      @select="selectWeaponForBurning"
    />

    <div class="button-row">
      <big-button
        class="button"
        mainText="Forge sword"
        subText="(1 loot)"
        @click="forgeWeapon"
      />
      <big-button
        class="button"
        mainText="Reforge sword"
        subText="(+weapon xp sacrificing another)"
        :disabled="canReforge"
        @click="reforgeWeapon"
      />
    </div>
  </div>
</template>

<script>
import WeaponGrid from "../components/WeaponGrid.vue";
import BigButton from "../components/BigButton.vue";

export default {
  props: ["weapons"],
  inject: ["web3", "contractProvider"],

  data() {
    return {
      selectedWeaponIdForReforging: null,
      selectedWeaponIdForBurning: null,
    };
  },

  computed: {
    canReforge() {
      return (
        this.selectedWeaponIdForReforging == null ||
        this.selectedWeaponIdForBurning == null ||
        this.selectedWeaponIdForReforging === this.selectedWeaponIdForBurning
      );
    },
  },

  methods: {
    selectWeaponForReforging(weapon) {
      if (this.selectedWeaponIdForReforging == weapon.id) {
        this.selectedWeaponIdForReforging = null;
        return;
      }

      this.selectedWeaponIdForReforging = weapon.id;
    },

    selectWeaponForBurning(weapon) {
      if (this.selectedWeaponIdForBurning == weapon.id) {
        this.selectedWeaponIdForBurning = null;
        return;
      }

      this.selectedWeaponIdForBurning = weapon.id;
    },

    async forgeWeapon() {
      try {
        await this.contractProvider.CryptoBlades.methods.mintWeapon().send({
          from: this.web3.eth.defaultAccount,
        });
      } catch (e) {
        console.error(e);
      }
    },

    async reforgeWeapon() {
      try {
        await this.contractProvider.Weapons.methods
          .approve(
            this.contractProvider.CryptoBlades.options.address,
            this.selectedWeaponIdForBurning
          )
          .send({
            from: this.web3.eth.defaultAccount,
          });

        await this.contractProvider.CryptoBlades.methods
          .reforgeWeapon(
            this.selectedWeaponIdForReforging,
            this.selectedWeaponIdForBurning
          )
          .send({
            from: this.web3.eth.defaultAccount,
          });

        this.$emit("invalidateWeaponIds");
      } catch (e) {
        console.error(e);
      }
    },
  },

  components: {
    WeaponGrid,
    BigButton,
  },
};
</script>

<style scoped>
.button-row {
  margin-top: 1em;
  display: flex;
}

.button + .button {
  margin-left: 1em;
}
</style>
