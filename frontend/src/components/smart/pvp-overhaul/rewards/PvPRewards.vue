<template>
  <div class="rewardsWrapper">
    <h1>REWARDS</h1>
    <p>Here you can claim your rewards</p>
    <ul>
      <li><div class="bulletpoint"></div> Lorem ipsum dolor sit amet.</li>
      <li><div class="bulletpoint"></div> Lorem ipsum dolor sit amet consectetur, adipisicing elit. Voluptates, rerum?</li>
      <li><div class="bulletpoint"></div> Lorem ipsum dolor sit amet consectetur adipisicing.</li>
      <li><div class="bulletpoint"></div> Lorem ipsum dolor sit amet.</li>
      <li><div class="bulletpoint"></div> Lorem ipsum dolor sit amet.</li>
    </ul>
    <pvp-button buttonText="CLAIM REWARDS" />
  </div>
</template>


<script>
import PvPButton from '../components/PvPButton.vue';

export default {
  components: {
    'pvp-button': PvPButton
  }

};
</script>

<style scoped lang="scss">
.rewardsWrapper {
  display: flex;
  flex-direction: column;
  font-family: 'Trajan';

  h1 {
    font-size: 1.25rem;
    font-family: 'Trajan';
    color: #cec198;
    padding-top: 0;
  }

  p, li {
    font-family: 'Roboto';
  }

  p {
    margin-bottom: 2rem;
    color: #b4b0a7;
  }

  ul {
    padding-left: 1rem;
    li {
      display: flex;
      margin-bottom: 0.75rem;
      align-items: center;
      vertical-align: middle;
      color: #b4b0a7;
      font-size: 0.875rem;
      line-height: 1.25rem;
      .bulletpoint {
        height: 0.5rem;
        width: 0.5rem;
        margin-right: 0.75rem;
        background-color: #dabe75;
        transform: rotate(45deg);
      }
    }
  }

  button {
    margin-top: 1rem;
    width: 14rem;
    height: 5rem;
  }
}
</style>