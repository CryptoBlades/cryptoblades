<template>
  <div class="header-nav">
    <div class="left-nav">
      <view-links class="view-links"></view-links>
    </div>
    <div class="right-nav">
      <b-navbar-nav class="available-skill">
        <li><a href="#" class="icon-plus">50.58 Skill</a></li>
        <li><a href="#">20.94 unclaimed skill</a></li>
      </b-navbar-nav>
      <b-navbar-nav class="claim-xp">
        <li><router-link :to="{ name: 'claim-xp' }" exact class="nav-link claim-xp"><span>Claim EXP</span></router-link></li>
        <li><router-link :to="{ name: 'withdraw' }" exact class="nav-link withdraw"><span>Withdraw</span></router-link></li>
        <li><router-link :to="{ name: 'earning-calculator' }" exact class="nav-link earning-calculator"><span>Earning Calculator</span></router-link></li>
      </b-navbar-nav>
    </div>
  </div>
</template>

<script>
import ViewLinks from '@/components/ViewLinks';
export default {
  name: 'HeaderNav',
  components : {
    ViewLinks,
  },
  computed : {
    currentRouteName() {
      return this.$route.name;
    }
  }
};
</script>

<style scoped>
.navbar-nav {
  flex-direction: row;
}
.header-nav {
  display: flex;
  justify-content: space-between;
  flex-grow: 1;
  align-items: center;
  padding: 25px 27px 25px 60px;
}
.header-nav .view-links li {
  display: inline-block;
  padding: 0 10px;
}
.header-nav .left-nav {
  flex-grow: 1;
}
.header-nav .right-nav {
  text-align: right;
}
.header-nav .right-nav ul li {
  display: inline-block;
}
.header-nav .right-nav ul.claim-xp li a {
  color: #EDCD90;
  font-size: 15px;
  line-height: 15px;
  text-transform: uppercase;
  padding: 0 10px;
  font-family: 'Roboto Condensed';
}
.header-nav .right-nav ul.claim-xp li {
  border-left: 1px solid #EDCD90;
  line-height: 15px;
}
.header-nav .right-nav ul.claim-xp li:first-child {
  border-left: 0;
}
.header-nav .right-nav .available-skill {
  margin-bottom: 10px;
  justify-content: end;
}
.header-nav .right-nav ul.available-skill li {
  border-left: 1px solid #fff;
  line-height: 15px;
}
.header-nav .right-nav ul.available-skill li:first-child {
  border-left: 0;
}
.header-nav .right-nav ul.available-skill li a {
  display: block;
  padding: 0 10px;
  font-size: 15px;
  text-transform: uppercase;
  font-family: 'Roboto Condensed';
}
.header-nav .right-nav ul.available-skill li a.icon-plus:before {
  content: '+';
  width: 18px;
  height: 18px;
  border-radius: 20px;
  border: 1px solid #EDCD90;
  color: #EDCD90;
  display: inline-flex;
  align-items: center;
  font-size: 12px;
  font-family: 'Roboto';
  justify-content: center;
  margin-right: 5px;
  text-decoration: none;
}
</style>
