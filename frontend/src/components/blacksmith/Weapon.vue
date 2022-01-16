<template>
  <ul class="weapons">
    <li class="weapon-card">
        <div class="top">
          <span class="orange">Legendary</span>
          <span>#203991</span>
        </div>
        <div class="middle"><img src="../../assets/new-ui/weapon/weapon5.png" alt="weapon5"></div>
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
      <div class="middle"><img src="../../assets/new-ui/weapon/weapon7.png" alt="weapon5"></div>
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
      <div class="middle"><img src="../../assets/new-ui/weapon/weapon6.png" alt="weapon5"></div>
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
      <div class="middle"><img src="../../assets/new-ui/weapon/weapon4.png" alt="weapon5"></div>
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
      <div class="middle"><img src="../../assets/new-ui/weapon/weapon4.png" alt="weapon5"></div>
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
      <div class="middle"><img src="../../assets/new-ui/weapon/weapon2.png" alt="weapon5"></div>
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
      <div class="middle"><img src="../../assets/new-ui/weapon/weapon3.png" alt="weapon5"></div>
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
      <div class="middle"><img src="../../assets/new-ui/weapon/weapon2.png" alt="weapon5"></div>
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
      <div class="middle"><img src="../../assets/new-ui/weapon/weapon4.png" alt="weapon5"></div>
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
      <div class="middle"><img src="../../assets/new-ui/weapon/weapon7.png" alt="weapon5"></div>
      <div class="bot">
        <div class="icon" v-html="$appIcon.Fire"></div>
        <div class="footer-info">
          <p><strong>Malignant Swiftblade</strong></p>
          <p>Multiplier: 3.4</p>
        </div>
      </div>
    </li>
  </ul>
</template>

<script>
export default {
  name: 'Weapon',
};
</script>

<style scoped>
.weapons {
  padding: 0;
  list-style: none;
  margin-bottom: 39px;
  display: flex;
  flex-wrap: wrap;
  gap: 22px;
}
.weapons .weapon-card {
  background: #000E29;
  border: 1px solid #43506A;
  border-radius: 5px;
  margin: 0 0 20px;
  padding: 15px;
  width: 166px;
  flex-grow: 1;
}
.weapons .weapon-card .top,
.weapons .weapon-card .bot {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  font-size: 10px;
  color: #9198A7;
}
.weapons .weapon-card .top {
  align-items: center;
}
.weapons .weapon-card .top span:first-child {
  background: #43506A;
  color: #fff;
  text-align: center;
  min-width: 53px;
  padding: 5px;
  border-radius: 4px;
}
.weapons .weapon-card .top span.orange {
  background: #D16100;
}
.weapons .weapon-card .top span.purple {
  background: #7C1EC1;
}
.weapons .weapon-card .top span.green {
  background: #7BA224;
}
.weapons .weapon-card .top span.blue {
  background: #3997F5;
}

.weapons .weapon-card .bot {
  align-items: baseline;
  justify-content: initial;
}
.weapons .weapon-card .bot p {
  margin-bottom: 0;
  text-align: left;
}
.weapons .weapon-card .bot .icon {
  width: 12px;
  margin-right: 5px;
}
.weapons .weapon-card .bot strong {
  color: #fff;
}
</style>
<style>
.icon-frame-sm {
  margin-bottom: 0;
  margin-right: 15px;
}
.icon-frame-sm svg {
  width: 14px;
}
.weapons .weapon-card .bot .icon svg {
  width: 12px;
}
</style>
