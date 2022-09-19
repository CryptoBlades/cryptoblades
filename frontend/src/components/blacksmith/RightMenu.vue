<template>
  <div class="mobile-right-menu" v-if="activeTab == 'forge' && !showReforgeDust">
      <div v-for="menu in menuItem" :key="menu.id" class="menu-item mb-3 mt-3" :class="menu.isActive ? 'active-tag' : 'unactive-tag'">
        <span :class="menu.iconName" @click="setActive(menu.id !== 4 ? menu.id : '')"></span>
        <span @click="forge(menu.id)">{{menu.title}}</span>
      </div>
  </div>
  <div class="mobile-right-menu" v-else-if="activeTab == 'salvage' && !showReforgeDust">
      <div class="menu-item mb-3 mt-3 dusting">
        <span class="lb-dust"  @click="confirmDust"></span>
        <span class="dust-amount">+{{dusts.lesser}}</span>
        <span>LB</span>
      </div>
      <div class="menu-item mb-3 mt-3 dusting" @click="confirmDust">
        <span class="four-dust"></span>
        <span class="dust-amount">+{{dusts.greater}}</span>
        <span>4B</span>
      </div>
      <div class="menu-item mb-3 mt-3 dusting" @click="confirmDust">
        <span class="five-dust"></span>
        <span class="dust-amount">+{{dusts.powerful}}</span>
        <span>5B</span>
      </div>
  </div>
</template>

<script>
import Events from '../../utils/events';

export default {
  props: ['activeTab','dusts','showReforgeDust'],
  data(){
    return{
      menuToggled: '',
      menuItem: [
        {
          id: 0,
          title: 'FORGE',
          isActive: false,
          iconName: 'forge-icon-x1'
        },
        {
          id: 1,
          title: 'FORGE',
          isActive: false,
          iconName: 'forge-icon-x10'
        },
        {
          id: 2,
          title: 'SPECIAL',
          isActive: false,
          iconName: 'special'
        },
        {
          id: 3,
          title: 'REFORGE',
          isActive: false,
          iconName: 'reforge'
        },
      ],
    };
  },
  methods:{
    setActive(id){
      this.menuItem.forEach(x => {
        if(x.id === id){
          if(x.isActive){
            x.isActive = false;
          }else{
            x.isActive = true;
          }
        }else{
          x.isActive = false;
        }
      });
    },
    forge(id){
      Events.$emit('forge-weapon', id);
    },
    confirmDust(){
      Events.$emit('create-dust');
    }
  },
  mounted(){
    Events.$on('hasSelected', () =>{
      this.menuItem.forEach(x => {
        if(x.id === 3){
          x.isActive = true;
        }else{
          x.isActive = false;
        }
      });
    });
  }
};
</script>

<style>
  .mobile-right-menu{
    position: fixed;
    z-index: 999;
    justify-content: flex-end;
    bottom: 60px;
    margin-right: -67px;
    right: 0;
    background-image: linear-gradient(to right, rgba(0, 0, 0, 0.055), rgba(0, 0, 0, 0.733),#000);
  }

  .active-tag{
    margin-right: 70px;
  }

  .unactive-tag{
    margin-left: 90px;
  }

  .forge-icon-x1{
    content: url('../../assets/blacksmith/x1.png');
    height: 50px;
    width: 55px;
    position: absolute;
    margin-left: -60px;
  }

  .forge-icon-x10{
    content: url('../../assets/blacksmith/x10.png');
    height: 50px;
    width: 55px;
    position: absolute;
    margin-left: -60px;
  }

  .reforge{
    content: url('../../assets/blacksmith/special.png');
    height: 50px;
    width: 50px;
    position: absolute;
    margin-left: -60px;
  }

  .special{
    content: url('../../assets/blacksmith/reforge.png');
    height: 50px;
    width: 50px;
    position: absolute;
    margin-left: -60px;
  }


  .lb-dust{
    content: url('../../assets/dusts/lesserDust.png');
    height: 40px;
    width: 40px;
    position: absolute;
    margin-left: -60px;
  }

   .four-dust{
    content: url('../../assets/dusts/greaterDust.png');
    height: 40px;
    width: 40px;
    position: absolute;
    margin-left: -60px;
  }

   .five-dust{
    content: url('../../assets/dusts/powerfulDust.png');
    height: 40px;
    width: 40px;
    position: absolute;
    margin-left: -60px;
  }


  .menu-item{
    display: flex;
    align-items: center;
    padding: 10px 20px 10px 30px;
    background-color: black;
    border-top: 1px solid #edcc9086;
    border-bottom: 1px solid #edcc9091;
    transition: all 0.5s ease-in-out;
  }

  .menu-item > span{
    font-family: Oswald;
    color: #fff;
  }

  .menu-item > span.forge-icon{
    margin-right: 2em;
  }

  .dusting{
    border: 1px solid #fff;
  }

  .dusting > span:nth-child(1){
    margin-left: -115px;
    border: 1px solid #edcc9086;
    border-radius: 5px;
    background-color: #000;
  }

  .dusting > span:nth-child(3){
    margin-left: -80px;
    border: 1px solid #edcc90d7;
    width: 50px;
    background-color: #000;
    padding-left: 10px;
  }

  .dusting > span:nth-child(2){
    position: absolute;
    left: 0;
    font-size: 15px;
    margin-left: -70px;
    background-color: rgba(0, 0, 0, 0.534);
    padding: 2px 5px;
    border-radius: 5px;
    margin-bottom: -40px;
  }



  @media (max-width: 576px){
    .mobile-right-menu{
      display: inline;
    }

    .icon-hint{
      content: url('../../assets/hint.png');
      height: 30px;
      width: 30px;
    }
  }
</style>
