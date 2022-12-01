<template>
  <div>
    <div v-if="!hidden" class="banner">
      <div class="image-container">
        <svg @click="hide" class="closeBtn" width="27.667" height="27.667" viewBox="0 0 27.667 27.667">
          <g id="Group_831" data-name="Group 831" transform="translate(-293 -654)">
            <rect id="Rectangle_904" data-name="Rectangle 904" width="1.043" height="6.777" rx="0.521"
                  transform="translate(300.248 661.878) rotate(-45)"/>
            <rect id="Rectangle_905" data-name="Rectangle 905" width="1.043" height="7.771" rx="0.521"
                  transform="translate(306.171 667.8) rotate(-45)"/>
            <rect id="Rectangle_906" data-name="Rectangle 906" width="1.043" height="15.64" rx="0.521"
                  transform="translate(311.703 661.409) rotate(45)"/>
            <path id="Subtraction_2" data-name="Subtraction 2"
                  d="M13.834,27.667A13.837,13.837,0,0,1,8.449,1.087,13.837,13.837,0,0,1,19.219,26.58,13.752,13.752,0,0,1,13.834,27.667Zm0-26.6A12.772,
                12.772,0,0,0,8.864,25.6,12.772,12.772,0,0,0,18.8,2.069,12.7,12.7,0,0,0,13.834,1.065Z"
                  transform="translate(293 654)"/>
          </g>
        </svg>
        <img @click="click" class="image" src="@/assets/blade_quest.png" alt="Blade quest banner"/>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      hidden: false,
    };
  },
  created() {
    if (sessionStorage.getItem('questBannerHidden') === 'true') {
      this.hidden = true;
    }
  },
  methods: {
    hide() {
      sessionStorage.setItem('questBannerHidden', 'true');
      this.hidden = true;
    },
    click() {
      this.hide();
      this.$router.push({ name: 'quests', query: { chain: 'BNB' }});
    }
  },
};

</script>

<style scoped>
.banner path, .banner rect {
  fill: #FFFFFF;
}

.banner {
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1999;
  height: 100vh;
  width: 100%;
  position: absolute;
  background: radial-gradient(circle, rgba(0, 0, 0, 1) 0%, rgba(0, 0, 0, 0.25) 100%);
}

.image {
  border-radius: 10px;
  width: 100%;
}

.image:hover {
  box-shadow: hsl(36deg 100% 69%) 0 1px 7px;
  border-radius: 5px;
  cursor: pointer;
}

.image-container {
  width: 50%;
  position: relative;
}

.closeBtn {
  cursor: pointer;
  position: absolute;
  top: -15px;
  right: -15px;
}

@media screen and (max-width: 768px) {
  .closeBtn {
    right: 3px;
  }

  .image-container {
    width: 100%;
  }
}

</style>
