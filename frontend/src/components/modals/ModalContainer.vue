<template>
  <b-modal id="modal-info" ref="modal-info" class="md" hide-footer hide-header>
    <div class="to-back" v-if="!noBack">
      <span class="arrow-icon"></span>
      <span>Back</span>
    </div>
    <div class="modal-wrapper">
      <div class="header" v-if="headerContent">
        <h3 class="Title">{{headerContent.title}}</h3>
      </div>
      <div class="content-details">
        <component :is="componentHolder" v-bind="componentProps"/>
      </div>
      <div class="footer-btn">
        <button class="close-btn" @click="$bvModal.hide('modal-info')">Close</button>
      </div>
      <div v-if="showAds && !isMobile()" class="ad-container align-items-center">
        <script2 async src="https://coinzillatag.com/lib/display.js"></script2>
        <div class="coinzilla" data-zone="C-316621de2f7b8b25140"></div>
        <script2>
              window.coinzilla_display = window.coinzilla_display || [];
              var c_display_preferences = {};
              c_display_preferences.zone = "316621de2f7b8b25140";
              c_display_preferences.width = "300";
              c_display_preferences.height = "250";
              coinzilla_display.push(c_display_preferences);
        </script2>
      </div>
    </div>
    <p class="tapAny">{{$t('blacksmith.tapAnyWhere')}}</p>
  </b-modal>
</template>

<script>
import Vue from 'vue';
import CombatResult from '../CombatResults.vue';

export default Vue.extend({
  components: {
    'combat-result' : CombatResult,
  },
  props: ['headerContent','modalData', 'footerContent', 'modalSize', 'modalType', 'componentProps', 'noBack'],
  data() {
    return {
      showAds: false,
      componentHolder: '',
    };
  },
  mounted(){
    this.componentHolder = this.modalType;
  },
  computed: {
  },
  methods: {
    checkStorage() {
      if (process.env.NODE_ENV === 'development') this.showAds = false;
      else this.showAds = localStorage.getItem('show-ads') === 'true';
    },
  },
});
</script>

<style lang="scss" scoped>
  .modal-wrapper{
    padding: 1.5em 1.9em 2em 1.9em;
    div.header{
      width: 100%;
      text-align: center;
      h3{
        font-family: Trajan;
        color: #EDCD90;
      }
    }
  }

  .to-back {
    display: flex;
    justify-content: flex-start;
    align-items: center;
    cursor: pointer;
    span.arrow-icon{
      content: url('../../assets/arrow-left.svg');
      height: auto;
      margin-right: 0.5em;
    }
    span{
      font-size: 0.85em;
      font-family: Roboto;
      color: #ffffff63;
    }
  }

  .to-back:hover {
    span{
      color: #fff9f9;
    }
  }
</style>
