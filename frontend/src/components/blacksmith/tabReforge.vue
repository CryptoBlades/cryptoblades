<template>
  <div>
    <p v-html="reforgeNotes"></p>
    <div class="reforge-wrapper">
      <div class="reforge-item">
        <div class="reforge s-orange">
          <div class="image">
            <img src="../../assets/new-ui/dust/powerfulDust.png" alt="powerfulDust">
          </div>
          <div class="info">
            <div>Low Star Burn</div>
            <div class="req">Req: 100/500</div>
          </div>
        </div>
        <div class="reforge-slider">
          <div class="slider percent-100"><span class="progress" :style="{width: bonus100+'%'}"></span></div>
          <p>1500/1500 Bonus Damage</p>
        </div>
        <div class="reforge-max">
          <div class="number">100</div>
          <div class="max-btn active">Max</div>
        </div>
      </div>
      <div class="reforge-item">
        <div class="reforge s-purple">
          <div class="image">
            <img src="../../assets/new-ui/dust/greaterDust.png" alt="character">
          </div>
          <div class="info">
            <div>Four Star Burn</div>
            <div class="req">Req: 10/500</div>
          </div>
        </div>
        <div class="reforge-slider">
          <div class="slider percent-100"><span class="progress" :style="{width: bonus50+'%'}"></span></div>
          <p>300/750 Bonus Damage</p>
        </div>
        <div class="reforge-max">
          <div class="number">100</div>
          <div class="max-btn active">Max</div>
        </div>
      </div>
      <div class="reforge-item">
        <div class="reforge">
          <div class="image">
            <img src="../../assets/new-ui/dust/lesserDust.png" alt="character">
          </div>
          <div class="info">
            <div>Four Star Burn</div>
            <div class="req">Req: 1/500</div>
          </div>
        </div>
        <div class="reforge-slider">
          <div class="slider percent-100"><span class="progress" :style="{width: bonus25+'%'}"></span></div>
          <p>60/600 Bonus Damage</p>
        </div>
        <div class="reforge-max">
          <div class="number">100</div>
          <div class="max-btn active">Max</div>
        </div>
      </div>
    </div>
    <div class="actions">
      <Button mainText="Reforge" sub-text="0.005 SKILL" :target-ref="targetRef" @btnAction="reforge" size="lg"/>
      <router-link to="/perfection" class="back">Change Equipment</router-link>
    </div>

    <div class="forge-result" ref="forgeResult" @click="closeResult" v-if="forgeResult">
      <div class="result-wrapper">
        <div class="head-image" v-html="$appIcon.forgeResultHead"></div>
        <h3>Reforge Successful</h3>
        <div class="result-summary">
          <div class="result-image"><img src="../../assets/new-ui/weapon/reforge-weapon5.png" alt="weapon5"></div>
          <div class="summary">
            <div class="result-item">Low Star Burn > +1000</div>
            <div class="result-item">Four Star Burn > +300</div>
            <div class="result-item">Five Star Burn > +60</div>
            <div class="result-item bonus"><strong>Reforge Bonus:</strong> 1860 <span class="green">(<span class="triangle-up">&#8227;</span>1360)</span></div>
          </div>
        </div>
        <div class="sep" v-html="$appIcon.separator"></div>
        <div class="close-text">Tap Anywhere To Close</div>
        <div class="close-icon" v-html="$appIcon.closeIcon"></div>
      </div>
    </div>
  </div>
</template>

<script>
import Button from '@/components/Button';
export default {
  name: 'tabReforge',
  props: ['id'],
  components : {
    Button
  },
  data() {
    return {
      reforgeNotes : 'Reforging weapons is the process of spending SKILL tokens to burn one weapon into another.<br>' +
        'The target weapon receives bonus power, and the burned weapon disappears.',
      bonus100 : 100,
      bonus50 : 50,
      bonus25 : 25,
      forgeResult: false
    };
  },
  computed : {
    targetRef(){
      return 'perfection/'+this.id;
    }
  },
  methods: {
    reforge(){
      this.forgeResult = true;
      console.log('reforge: '+this.id);
    },
    closeResult(){
      this.forgeResult = false;
    }
  }
};
</script>

<style scoped>
.reforge-wrapper {
  margin-bottom: 30px;
}
.reforge-item {
  margin-bottom: 24px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}
.reforge-item > div {
  flex-grow: 1;
}
.reforge {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
}
.reforge:last-child {
  margin-bottom: 0;
}
.reforge .image {
  margin-right: 15px;
  background: transparent radial-gradient(closest-side at 50% 50%, #1D1D1D 0%, #141414 100%) 0% 0% no-repeat padding-box;
  border: 1px solid #43506A;
  border-radius: 5px;
}
.reforge .info .req {
  color: #B9BFCC;
}
.reforge.s-orange .image {
  border-color: #D16100;
}
.reforge.s-purple .image {
  border-color: #7C1EC1;
}

/*slider*/
.reforge-slider {
  text-align: center;
  color: #B9BFCC;
}
.reforge-slider p {
  color: #B9BFCC;
  margin-bottom: 0;
}
.slider {
  width: 100%;
  position: relative;
  height: 4px;
  background: #43506A;
  margin-bottom: 12px;
}
.slider .progress {
  position: absolute;
  left: 0;
  top: 0;
  width: 50%;
  background: #1168D0;
  height: 4px;
  overflow: visible;
}
.slider .progress:after {
  content: '';
  background: #1168D0;
  position: absolute;
  width: 16px;
  height: 16px;
  border-radius: 8px;
  right: -2px;
  top: -6px;
  border: 2px solid #000E1D;
}

/*reforge-max*/
.reforge-max {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  padding-bottom: 25px;
}
.reforge-max .number {
  background: #000E1D;
  border: 1px solid #404857;
  padding: 5px 10px;
  border-radius: 3px;
}
.reforge-max .max-btn {
  background: #000E1D;
  border: 1px solid #404857;
  padding: 5px 10px;
  border-radius: 3px;
}
.reforge-max .max-btn:hover {
  background: #404857;
  cursor: pointer;
}

/*actions*/
.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 40px;
  align-items: center;
}
.actions .back {
  color: #848A95;
  font-size: 20px;
  text-transform: uppercase;
  font-family: 'Oswald';
  border-bottom: 1px solid #848A95;
  padding-bottom: 10px;
  text-decoration: none;
}


/*result modal*/
.forge-result {
  position: absolute;
  background: rgba(0, 8, 25, 0.80);
  width: 100%;
  height: 100%;
  left: 0;
  top: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 100px 0 40px;
  overflow: auto;
}
.forge-result .result-wrapper {
  width: 100%;
  max-width: 968px;
  padding: 10px;
  text-align: center;
}
.forge-result .result-wrapper h3 {
  color: #EDCD90;
  font-size: 25px;
  font-family: 'Trajan';
  margin-bottom: 45px;
}
.forge-result .result-wrapper .head-image {
  margin-bottom: 23px;
}
.forge-result .result-wrapper .close-text {
  margin-bottom: 27px;
}
.forge-result .result-wrapper .sep {
  margin-bottom: 26px;
}

.forge-result .result-wrapper .weapons .weapon-card .bot {
  align-items: baseline;
  justify-content: initial;
}
.forge-result .result-wrapper .weapons .weapon-card .bot p {
  margin-bottom: 0;
  text-align: left;
}
.forge-result .result-wrapper .weapons .weapon-card .bot .icon {
  width: 12px;
  margin-right: 5px;
}
.forge-result .result-wrapper .weapons .weapon-card .bot strong {
  color: #fff;
}

/*result-summary*/
.result-summary {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
}
.result-summary .result-image {
  width: 223px;
}
.result-summary .result-image img {
  width: 100%;
}
.result-summary .green {
  color: #7BA224;
}
.result-summary .result-item {
  color: #7F8693;
  margin-bottom: 20px;
  font-size: 16px;
}
.result-summary .result-item strong {
  color: #fff;
}
.triangle-up {
  display: inline-block;
  transform: rotate(-90deg);
  font-size: 22px;
}
</style>
