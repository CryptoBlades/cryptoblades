<template>
  <div class="raid-tab">
    <b-tabs content-class="mt-3">
      <b-tab title="Raid Signup" active>
        <RaidSignup />
      </b-tab>
      <b-tab title="History">
        <RaidHistory />
      </b-tab>
    </b-tabs>
  </div>
</template>

<script>
import RaidHistory from '@/components/raid/History';
import RaidSignup from '@/components/raid/Signup';

export default {
  name: 'RaidTab',
  components : {
    RaidHistory,
    RaidSignup
  }
};
</script>

<style scoped>
.raid-tab {
  width: 100%;
  left: 0;
  bottom: 0;
  padding-left: 607px;
  margin-top: -80px;
  position: relative;
}
.raid-tab > div {
  position: relative;
  z-index: 2;
}
.raid-tab:before {
  content: '';
  display: block;
  position: absolute;
  left: 0;
  top: 0;
  width: 100%;
  height: 80px;
  background: rgba(0,0,0,.44);
  z-index: 1;
}
</style>

<style>
.raid-tab .nav-tabs .nav-item {
  margin-right: 60px;
}
.raid-tab .nav-tabs .nav-item a {
  font-family: 'Oswald';
  font-size: 20px;
  text-transform: uppercase;
  color: #9D98A1;
  background: none;
  border: 0;
  display: flex;
  height: 80px;
  align-items: center;
  border-bottom: 3px solid transparent;
}
.raid-tab .nav-tabs {
  border: 0;
}
.raid-tab .nav-tabs .nav-item a.active {
  color: #fff;
  border-bottom: 3px solid #EDCD90;
}

.raid-tab .tab-content {
  padding: 30px 60px 100px 0;
}
</style>
