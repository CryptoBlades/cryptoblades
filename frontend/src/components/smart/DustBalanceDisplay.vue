<template>
  <div>
    <div class="col-lg-12">
      <h1 class="text-center">Available Dust</h1>
      <div class="row">
        <div class="col-lg-3"></div>
        <div class="col-lg-2 dust-container" align="center">
          <div class="dust">
            LB: <span class="text-warning">15 power per point</span>
            <div class="dust-image1">
            </div>
          </div>
          <h1 class="text-center">Lesser</h1>
          <div class="boxed">
            <h2>
              <h2>{{getLesserDust()}}</h2>
            </h2>
          </div>
        </div>
        <div class="col-lg-2 dust-container" align="center">
          <div class="dust">
            4B: <span class="text-warning">30 power per point</span>
            <div class="dust-image2">
            </div>
          </div>
          <h1 class="text-center">Greater</h1>
          <div class="boxed">
            <h2>
              <h2>{{getGreaterDust()}}</h2>
            </h2>
          </div>
        </div>
        <div class="col-lg-2 dust-container" align="center">
          <div class="dust">
            5B: <span class="text-warning">75 power per point</span>
            <div class="dust-image3">
            </div>
          </div>
          <h1 class="text-center">Powerful</h1>
          <div class="boxed">
            <h2>
              <h2>{{getPowerfulDust()}}</h2>
            </h2>
          </div>
        </div>
        <div class="col-lg-3"></div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex';

export default {
  props: [],

  data() {
    return {
    };
  },

  components: {
  },

  computed: {
    ...mapGetters(['getPowerfulDust', 'getGreaterDust', 'getLesserDust']),

  },

  async created() {
  },

  methods: {
    ...mapActions([]),
  }
};
</script>

<style>

.dust-container {
  margin: 1em auto 2em;
  border-radius: 5px;
  cursor: pointer;
  align-items :center;
}

.dust {
  min-height: 13em;
  max-height: 12em;
  border-style: dashed;
  border-color: #9e8a57;
  width: 12em;
  border-radius: 5px;
  cursor: pointer;
  margin-bottom: 2em;
}

.dust-image1 {
  content: url("../../assets/dusts/LesserDust.png");
  max-width: 12em;
  max-height: 10em;
}

.dust-image2 {
  content: url("../../assets/dusts/greaterDust.png");
  max-width: 12em;
  max-height: 10em;
}

.dust-image3 {
  content: url("../../assets/dusts/powerfulDust.png");
  max-width: 12em;
  max-height: 10em;
}

.boxed {
  max-width: 6em;
  max-height: 6em;
  border: 1px solid #9e8a57;
  margin: 2em;
}

.slidecontainer {
  width: 100%;
}

.range{
  border-radius: 10px;
  padding: 0 65px 0 45px;
}
.range .sliderValue{
  position:relative;
  width:100%;
}
.range .sliderValue span{
  position: absolute;
  color: #9e8a57;
  font-weight: 500;
  top: -40px;
  transform: translateX(-50%) scale(0);
  transform-origin: bottom;
  transition: transform 0.3s ease-in-out;
  line-height: 55px;
  z-index: 2;
}
.range .sliderValue span.show{
  transform: translateX(-50%) scale(1);
}
.range .sliderValue span:after{
  position: absolute;
  content: "";
  height:45px;
  width:45px;
  background: red;
  left:50%;
  transform: translateX(-50%) rotate(45deg);
  border:solid 3px #9e8a57;
  z-index: -1;
  border-top-left-radius: 50%;
  border-top-right-radius: 50%;
  border-bottom-left-radius: 50%;
}
.range .field{
  position:relative;
  display:flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}
.range .field .value{
  position:absolute;
  font-size:18px;
  font-weight:600;
  color: #9e8a57;
}
.range .field .value.left{
  left: -22px;
}
.range .field .value.right{
  right: -43px;
}
.range .field input{
  -webkit-appearance: none;
  height:3px;
  background:#9e8a57;
  border-radius: 5px;
  outline:none;
  border:none;
  width:100%;
}
.range .field input::-webkit-slider-thumb{
  -webkit-appearance: none;
  height: 20px;
  width: 20px;
  background: #9e8a57;
  border-radius: 50%;
  border: 1px solid white;
  cursor: pointer;
}

</style>
