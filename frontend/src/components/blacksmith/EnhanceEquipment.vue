<template>
  <div class="content-wrap">
    <div class="weapon-image">
      <img src="../../assets/new-ui/weapon/reforge-weapon5.png" alt="weapon5">
    </div>
    <div class="weapon-details">
      <h2>MALIGNANT SWIFTBLADE</h2>
      <div class="weapon-meta">
        <div class="damage">Damage Multiplier: 3.40</div>
        <div class="rarity">Rarity: <span>Legendary</span></div>
        <div class="element">Element: <span class="red-fire">Fire</span></div>
        <div class="rank">Weapon Rank: 120,031</div>
      </div>

      <div class="stats">
        <div class="power">
          <div class="heading">
            <div class="icon" v-html="$appIcon.forgePower"></div>
            <span>Power</span>
          </div>
          <div class="stat-value">+311</div>
        </div>
        <div class="strength">
          <div class="heading">
            <div class="icon" v-html="$appIcon.Fire"></div>
            <span>Strength</span>
          </div>
          <div class="stat-value">+222</div>
        </div>
        <div class="intelligence">
          <div class="heading">
            <div class="icon" v-html="$appIcon.forgePower"></div>
            <span>Intelligence</span>
          </div>
          <div class="stat-value">+258</div>
        </div>
      </div>

      <b-tabs content-class="mt-3">
        <b-tab title="Reforge" active>
          <reforgeTab :id="id"/>
        </b-tab>
        <b-tab title="Upgrade">
          <div class="actions">
            <router-link to="/perfection">Change Equipment</router-link>
          </div>
        </b-tab>
        <b-tab title="Enchant">
          <div class="actions">
            <router-link to="/perfection">Change Equipment</router-link>
          </div>
        </b-tab>
        <b-tab title="Skins">
          <div class="actions">
            <router-link to="/perfection">Change Equipment</router-link>
          </div>
        </b-tab>
      </b-tabs>
    </div>
  </div>
</template>

<script>
import reforgeTab from '@/components/blacksmith/tabReforge';
export default {
  props : ['id'],
  name: 'EnhanceEquipment',
  components : {
    reforgeTab
  },
  data() {
    return {
      reforgeNotes : 'Reforging weapons is the process of spending SKILL tokens to burn one weapon into another.<br>' +
        'The target weapon receives bonus power, and the burned weapon disappears.'
    };
  },
  mounted() {
    this.fetchWeaponInfo();
  },
  methods : {
    fetchWeaponInfo() {
      console.log('Fetch weapon info: '+ this.id);
    }
  }
};
</script>

<style scoped>
.content-wrap {
  padding-top: 86px;
}

/*image*/
.weapon-image {
  max-width: 492px;
}

/*details*/
.weapon-details {
  flex-grow: 1;
  padding-left: 80px;
}
.weapon-meta {
  display: flex;
  flex-wrap: wrap;
  border-bottom: 1px solid #404857;
  padding-bottom: 30px;
  margin-bottom: 30px;
}
.weapon-meta > div {
  padding-right: 20px;
  margin-right: 20px;
  border-right: 1px solid #404857;
  font-size: 16px;
  line-height: 16px;
}
.weapon-meta > div:last-child {
  padding-right: 0;
  margin-right: 0;
  border-right: 0;
}
.weapon-meta > div > span {
  color: #D16100;
}
.weapon-meta > div > span.red-fire {
  color: #DB0000;
}

/*Statas*/
.stats {
  display: flex;
  flex-wrap: wrap;
  margin-bottom: 30px;
}
.stats > div {
  margin-right: 30px;
}
.stats > div .heading {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  font-size: 18px;
  font-family: 'Oswald';
  text-transform: uppercase;
}
.stats > div .heading .icon {
  margin-right: 5px;
  display: flex;
  align-items: center;
}
.stats > div .stat-value {
  font-size: 30px;
  font-family: 'Oswald';
}

</style>

<style>
.stats > div .heading .icon svg {
  width: 13px;
  height: 14px;
}

/*Tabs*/
.tabs {}
.tabs p {
  color: #7F8693;
}
.tabs .nav {
  border:0;
}
.tabs .nav .nav-item {
  flex-grow: 1;
  color: #7F8693;
}
.tabs .nav .nav-item .nav-link {
  border-radius: 0;
  text-align: center;
  border: 1px solid #404857;
  border-right: 0;
  font-family: 'Oswald';
  text-transform: uppercase;
}
.tabs .nav .nav-item:first-child .nav-link {
  border-top-left-radius: 5px;
  border-bottom-left-radius: 5px;
}
.tabs .nav .nav-item:last-child .nav-link {
  border-right: 1px solid #404857;
  border-top-right-radius: 5px;
  border-bottom-right-radius: 5px;
}
.tabs .nav .nav-item .nav-link.active {
  background-color: #1168D0;
  color: #fff;
}
</style>
