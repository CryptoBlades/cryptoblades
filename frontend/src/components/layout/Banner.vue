<template>
  <div>
    <div v-if="!hidden" class="banner">
        <span class="text">{{text}}</span>
        <a :href="link" class="link" target="_blank" rel="noopener noreferrer">
          <button class="button">{{linkText}}</button>
        </a>
        <svg @click="hide" class="closeBtn" width="27.667" height="27.667" viewBox="0 0 27.667 27.667">
            <g id="Group_831" data-name="Group 831" transform="translate(-293 -654)">
              <rect id="Rectangle_904" data-name="Rectangle 904" width="1.043" height="6.777" rx="0.521" transform="translate(300.248 661.878) rotate(-45)"/>
              <rect id="Rectangle_905" data-name="Rectangle 905" width="1.043" height="7.771" rx="0.521" transform="translate(306.171 667.8) rotate(-45)"/>
              <rect id="Rectangle_906" data-name="Rectangle 906" width="1.043" height="15.64" rx="0.521" transform="translate(311.703 661.409) rotate(45)"/>
              <path id="Subtraction_2" data-name="Subtraction 2"
                d="M13.834,27.667A13.837,13.837,0,0,1,8.449,1.087,13.837,13.837,0,0,1,19.219,26.58,13.752,13.752,0,0,1,13.834,27.667Zm0-26.6A12.772,
                12.772,0,0,0,8.864,25.6,12.772,12.772,0,0,0,18.8,2.069,12.7,12.7,0,0,0,13.834,1.065Z"
                transform="translate(293 654)"/>
            </g>
        </svg>
    </div>
  </div>
</template>

<script>
export default {
  props: ['text', 'linkText', 'link'],
  data() {
    return {
      hidden: false,
    };
  },
  created() {
    if(localStorage.getItem('bannerHidden') === 'true'){
      this.hidden = true;
    }
  },
  methods: {
    hide() {
      localStorage.setItem('bannerHidden', 'true');
      this.hidden = true;
    },
  },
};

</script>

<style scoped>
.banner path, .banner rect {
  fill: #000;
}
.banner{
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: #F5E095;
    z-index: 1999;
    height: 50px;
    width: 100%;
}
.button{
    border: 1px solid #000;
    color: #000;
    border-radius: 5px;
    opacity: 1;
    background: none;
    margin: 0px 20px;
    padding: 5px 25px;
}
.button:hover{
    background-color: hsl(47, 77%, 53%);
    border: 1px solid #000;
}
.button:focus{
    outline:none;
}
.text{
    font: bold 16px Roboto;
    color: #000;
    text-transform: uppercase;
}
.link{
    text-align: center;
    font: normal 16px Roboto;
    color: #000;
    text-decoration: none;
    white-space: nowrap;
}
.link:hover{
    text-decoration: none;
    color: #000;
}
.closeBtn{
    cursor: pointer;
    position: absolute;
    right:20px;
}

@media screen and (max-width: 768px){
    .link{
        font-size: 13px;
    }
    .text{
        font-size: 13px;
        text-align: center;
    }
    .button{
        padding: 5px 5px;
        margin-right: 35px;
    }
    .closeBtn{
        right: 2.5px;
    }
}

</style>
