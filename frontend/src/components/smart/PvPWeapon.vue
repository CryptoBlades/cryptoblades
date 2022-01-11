<template>
  <div>
    <div class="mainWrapper" @click="$emit('click')" :id="`${weaponId}-info`" :class="{ withoutInfoPopover: !hasInfoPopover}">
      <div class="starsWrapper">
        <img
          v-for="index in (weapon.stars + 1)"
          :key="index"
          src="../../assets/star.svg"
          alt="star"
        />
      </div>
      <div class="weaponWrapper">
        <img :src="getWeaponArtById(weaponId)" alt="weapon image">
        <b-popover v-if="hasInfoPopover" :target="`${weaponId}-info`" triggers="hover" data-trigger="focus" placement="top right" class="popover">
          <div v-if="weaponId" class="weapon-icon-wrapper">
            <span>Weapon stats</span>
            <ul class="statsWrapper">
              <li v-if="weapon.stat1Value !== 0">{{weapon.stat1}}: +{{weapon.stat1Value}}</li>
              <li v-if="weapon.stat2Value !== 0">{{weapon.stat2}}: +{{weapon.stat2Value}}</li>
              <li v-if="weapon.stat3Value !== 0">{{weapon.stat3}}: +{{weapon.stat3Value}}</li>
            </ul>
          </div>
        </b-popover>
      </div>
      <div class="elementWrapper">
        <img :src="getElementImageUrl" alt="element icon" />
      </div>
    </div>
  </div>
</template>

<script>
import fire from '../../assets/elements/fire.png';
import water from '../../assets/elements/water.png';
import earth from '../../assets/elements/earth.png';
import lightning from '../../assets/elements/lightning.png';
import { getWeaponArtById } from '../../weapon-arts-placeholder';
import { BPopover } from 'bootstrap-vue';

export default {
  components: {
    'b-popover': BPopover,
  },

  props: {
    hasInfoPopover: {
      type: Boolean,
      default: true
    },
    weapon: {
      required: true,
    },
    weaponId: {
      type: String
    },
    disabled: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    getElementImageUrl() {
      if (this.weapon.element === 'Fire') {
        return fire;
      }
      if (this.weapon.element === 'Water') {
        return water;
      }
      if (this.weapon.element === 'Earth') {
        return earth;
      } else {
        return lightning;
      }
    },
  },
  methods: {
    getWeaponArtById,
  },
};
</script>

<style scoped lang="scss">
.mainWrapper {
  position: relative;
  display: flex;
  flex-direction: column;
  height: 4.5rem;
  width: 4.5rem;
  padding: 0.25rem;
  border-radius: 0.375rem;
  background-color: #151515;
  border: 1px solid #cec198;
  :hover {
    cursor: pointer;
  }
}
.red {
  color: red;
}
.cyan {
  color: cyan;
}
.green {
  color: green;
}
.yellow {
  color: yellow;
}
.brown {
  color: #9e8a57;
}
.withoutInfoPopover {
  pointer-events: none;
  :hover {
    cursor: default;
  }
}
.disabled {
  opacity: 30%;
  pointer-events: none;
}
.starsWrapper {
  display: flex;
  height: 13%;
  margin-left: 0.1rem;

  img {
    height: 0.5rem;
    width: 0.45rem;
    margin-right: 0.125rem;
    pointer-events: none;
  }
}
.weaponWrapper {
  display: flex;
  margin: 0 auto;
  height: 80%;
  width: 80%;

.popover-body {
  background-color: yellow;
  .arrow {
    background-color: yellow;
  }
}
}
.statsWrapper {
  margin-top: 1rem;
}
.elementWrapper {
  position: absolute;
  display: flex;
  width: 1.5rem;
  margin-left: auto;
  margin-right: auto;
  left: 0;
  right: 0;
  bottom: -25%;
  padding: 0.2rem;
  border: 1px solid #cec198;
  border-radius: 9999px;
  background-color: #151515;

  img {
    max-width: 100%;
    max-height: 100%;
  }
}
.weapon-icon {
  height: 100%;
  width: 100%;
  position: relative;
  overflow: hidden;
  background: #000;
}
.weapon-icon-wrapper {
  font-family: 'Roboto';
  width: max-content;
  margin: 0 auto;
  background-color: black;
  padding: 0;
  span {
    font-family: 'Roboto';
  }
  ul {
    margin: .75rem 0 0 0;
    padding: 0;
  }
  li {
    font-family: 'Roboto';
    list-style: none;
  }
}
</style>