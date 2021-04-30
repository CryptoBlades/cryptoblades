<template>
  <div class="body main-font">

    <div class="left-side fill-space raid-info">

      <div class="left-side">
        <div class="finish">
          <span class="title">Finishes on</span>
          <br>
          May 4th, 2021
        </div>

        <div class="raiders">
          <span class="title">Raiders</span> 69
          <br>
          <span class="title">Total Power</span> 69k
          <br>
          <span class="title">Bounty</span> 10 SKILL
        </div>

        <div class="drops">
          <span class="title">Drops</span>
          <br>
          items
        </div>
      </div>

      <div class="right-side raid-boss">
        <div class="raid-title">
          <span class="title">Raid title</span>
        </div>

        <div class="image">
          image here
        </div>

        <div class="about-raid">
          <span class="title">Raid Name</span>
          <br>
          <span class="lightning">Lightning</span>
        </div>
      </div>
    </div>

    <div class="right-side fill-space raid-signup">
      <div class="chooser">
        <div class="left-side">
          Characters
        </div>

        <div class="right-side">
          Weapons
        </div>
      </div>

      <div class="signup">
        <div class="warning">
          Joining will cost 12h stamina
        </div>

        <div class="power">
          <div class="left-side">Character Power: 10000</div>
          <div class="right-side">Weapon Multiplier: x1.23</div>
        </div>

        <div class="total-power">
          Total power: 12300
        </div>

        <div class="action">
          <big-button
            class="button"
            mainText="Sign up"
          />
        </div>
      </div>
    </div>

  </div>
</template>

<script lang="ts">
import BigButton from '../components/BigButton.vue';

export default {
  props: {
  },

  components: {
    BigButton
  },
};
</script>

<style scoped>
.body {
  display: flex;
  flex-direction: row;
  align-items: center;
  height: calc(100vh - 56px - 160px - 32px);
}

.title {
  font-weight: bold;
  font-size: 1.4em;
}

.fill-space {
  height: 100%;
  padding: 1em;
  padding-top: 3em;
}

.left-side, .right-side {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.chooser, .power {
  flex: 1;
  display: flex;
  flex-direction: row;
}

.raid-info {
  flex-direction: row;
}

.raiders, .drops {
  margin-top: 1em;
}

.raid-boss, .raid-signup {
  justify-content: space-between;
}

.warning, .power, .total-power, .action {
  text-align: center;
  margin-top: 0.5em;
}

</style>
