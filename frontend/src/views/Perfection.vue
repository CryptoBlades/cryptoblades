<template>
  <div class="main-content">
    <div class="content-wrap" v-if="!weaponId">
      <div class="inventory-wrap">
        <h2>Equipment Perfection</h2>
        <p>Select equipment to enhance.</p>
        <div class="btn-tabs">
          <a href="javascript:void(0)" class="active">Weapons</a>
          <a href="javascript:void(0)"><div class="locked" v-html="$appIcon.NavIcon.Perfection"></div>Shields</a>
        </div>
        <div class="weapon-filter">
          <div class="category">
            <select>
              <option>Rarity</option>
            </select>
          </div>
          <div class="fav">
            <input type="checkbox" id="show-fav"> <label for="show-fav">Show Favorites Only</label>
          </div>
        </div>
        <EquipmentReforge />
      </div>
    </div>
    <div class="reforge" v-if="weaponId">
      <EnhanceEquipment :id="weaponId"/>
    </div>
 </div>
</template>
<script>
import EquipmentReforge from '@/components/blacksmith/EquipmentReforge';
import EnhanceEquipment from '@/components/blacksmith/EnhanceEquipment';

export default {
  name: 'Home',
  components : { EquipmentReforge, EnhanceEquipment },
  data() {
    return {
      forgeResult : false
    };
  },
  computed : {
    weaponId() {
      return this.$route.params.id;
    }
  },
  methods : {
    salvage () {
      alert('Salvage 0.05 SKILL');
    }
  }
};
</script>
<style scoped>
.main-content {
  background: url("../assets/new-ui/background/bg-49.png") no-repeat;
  background-size: cover;
}
.content-wrap + .content-wrap{
  padding-top: 0;
}
.roadmap {
  padding-top: 36px;
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

/*btn tabs*/
.btn-tabs {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  vertical-align: middle;
  gap: 28px;
  margin-bottom: 30px;
}
.btn-tabs a {
  padding: 12px 12px;
  color: #7F8693;
  font-family: 'Oswald';
  text-transform: uppercase;
  background: #1E293C;
  border-radius: 5px;
  flex-grow: 1;
  text-align: center;
  display: flex;
  font-size: 15px;
  align-items: center;
  justify-content: center;
}
.btn-tabs a.active {
  background: #1168D0;
  color: #fff;
}
.btn-tabs a .locked {
  margin-right: 5px;
}

/*filter*/
.weapon-filter {
  display: flex;
  flex-wrap: wrap;
  gap: 28px;
  margin-bottom: 30px;
}

/*Inventory*/
.inventory-wrap {
  max-width: 1020px;
  margin: 0 auto 60px;
  padding-top: 40px;
}
.inventory-wrap h2,
.inventory-wrap p {
  text-align: center;
}
.inventory-wrap p {
  color: #848A95;
  margin-bottom: 70px;
}

/*Sidebar*/
.inventory-sidebar {
  flex-grow: 1;
  padding-left: 60px;
}
.inventory-sidebar h2 {
  border-bottom: 1px solid #404857;
  padding-bottom: 27px;
  margin-bottom: 32px;
}

.salvage {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  margin-bottom: 24px;
}
.salvage:last-child {
  margin-bottom: 0;
}
.salvage .image {
  margin-right: 15px;
  background: transparent radial-gradient(closest-side at 50% 50%, #1D1D1D 0%, #141414 100%) 0% 0% no-repeat padding-box;
  border: 1px solid #43506A;
  border-radius: 5px;
}
.salvage .info {

}
.salvage.s-orange .image {
  border-color: #D16100;
}
.salvage.s-purple .image {
  border-color: #7C1EC1;
}
</style>
<style>
.btn-tabs a .locked svg {
  width: 60px;
}
</style>
