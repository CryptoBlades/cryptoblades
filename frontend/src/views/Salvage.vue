<template>
  <div class="main-content">
    <div class="content-wrap">
      <div class="roadmap">
        <router-link to="/forge" exact class="forge active">
          <div class="icon-frame-sm"><div v-html="$appIcon.NavIcon.Blacksmith"></div></div>
          <span>Forge</span>
        </router-link>
        <div class="sep"></div>
        <router-link to="/salvage" exact class="salvage">
          <div class="icon-frame-sm active"><div v-html="$appIcon.NavIcon.Perfection"></div></div>
          <span>Salvage</span>
        </router-link>
      </div>
    </div>

    <div class="content-wrap">
      <ul class="weapons">
        <li class="weapon-card">
          <div class="top">
            <span class="orange">Legendary</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
        <li class="weapon-card">
          <div class="top">
            <span class="purple">Mythical</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
        <li class="weapon-card">
          <div class="top">
            <span class="purple">Mythical</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
        <li class="weapon-card">
          <div class="top">
            <span class="green">Unique</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
        <li class="weapon-card">
          <div class="top">
            <span class="blue">Rare</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
        <li class="weapon-card">
          <div class="top">
            <span class="blue">Rare</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
        <li class="weapon-card">
          <div class="top">
            <span class="">Normal</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
        <li class="weapon-card">
          <div class="top">
            <span class="">Normal</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
        <li class="weapon-card">
          <div class="top">
            <span class="">Normal</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
        <li class="weapon-card">
          <div class="top">
            <span class="">Normal</span>
            <span>#203991</span>
          </div>
          <div class="middle"><img src="../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
          <div class="bot">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <div class="footer-info">
              <p><strong>Malignant Swiftblade</strong></p>
              <p>Multiplier: 3.4</p>
            </div>
          </div>
        </li>
      </ul>
    </div>

    <div class="forge-result" ref="forgeResult" @click="closeResult" v-if="forgeResult">
      <div class="result-wrapper">
        <div class="head-image" v-html="$appIcon.forgeResultHead"></div>
        <h3>The Dwarves Have Forged You Weapons</h3>

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
  name: 'Home',
  components : { Button },
  data() {
    return {
      forgeResult : false
    };
  },
  methods : {
    generateResult (targetRef) {
      console.log(targetRef);
      this.forgeResult = true;
    },
    closeResult() {
      this.forgeResult = false;
    }
  }
};
</script>
<style scoped>
.main-content {
  background: url("../assets/new-ui/background/bg-49.png") no-repeat;
  background-size: cover;
}
.roadmap,
.roadmap > a {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  font-size: 18px;
  color: #7F8693;
}
.roadmap > a.router-link-active {
  color: #fff;
}
.roadmap > div.sep {
  width: 68px;
  height: 1px;
  background: #7F8693;
  margin: 0 15px;
}
.cta-btns .btn-wrap {
  margin: 0 10px;
  padding-top: 36px;
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
.forge-result .result-wrapper .weapons {
  padding: 0;
  list-style: none;
  margin-bottom: 39px;
  display: flex;
  flex-wrap: wrap;
}
.forge-result .result-wrapper .weapons .weapon-card {
  background: #000E29;
  border: 1px solid #43506A;
  border-radius: 5px;
  margin: 0 11px 40px;
  padding: 15px;
  max-width: 166px;
}
.forge-result .result-wrapper .weapons .weapon-card .top,
.forge-result .result-wrapper .weapons .weapon-card .bot {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  font-size: 10px;
  color: #9198A7;
}
.forge-result .result-wrapper .weapons .weapon-card .top {
  align-items: center;
}
.forge-result .result-wrapper .weapons .weapon-card .top span:first-child {
  background: #43506A;
  color: #fff;
  text-align: center;
  min-width: 53px;
  padding: 5px;
  border-radius: 4px;
}
.forge-result .result-wrapper .weapons .weapon-card .top span.orange {
  background: #D16100;
}
.forge-result .result-wrapper .weapons .weapon-card .top span.purple {
  background: #7C1EC1;
}
.forge-result .result-wrapper .weapons .weapon-card .top span.green {
  background: #7BA224;
}
.forge-result .result-wrapper .weapons .weapon-card .top span.blue {
  background: #3997F5;
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
</style>
<style>
.roadmap .icon-frame-sm {
  margin-bottom: 0;
  margin-right: 15px;
}
.roadmap .icon-frame-sm svg {
  width: 14px;
}
.forge-result .result-wrapper .weapons .weapon-card .bot .icon svg {
  width: 12px;
}
</style>
