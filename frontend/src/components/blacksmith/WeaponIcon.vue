<template>
  <div
    class="weapon-icon"
    v-bind:class="[(getWeaponDurability(weapon.id) === 0 ? 'no-durability' : '')]"
    @mouseover="hover = !isMobile() || true"
    @mouseleave="hover = !isMobile()"
  >
    <div class="loading-container" v-if="!allLoaded">
      <i class="fas fa-spinner fa-spin"></i>
    </div>

    <div class="glow-container" ref="el" :class="selected ? 'selected-border' : ['glow-' + (weapon.stars || 0)]">
      <div class="animation" v-bind:class="showCosmetics ? 'weapon-animation-applied-' + getWeaponCosmetic(weapon.id) : ''"/>
      <img v-if="showPlaceholder" v-bind:class="showCosmetics ? 'weapon-cosmetic-applied-' + getWeaponCosmetic(weapon.id) : ''"
        class="placeholder" :src="weapon.weaponType > 0 ? specialWeaponArts[weapon.weaponType] : getWeaponArt(weapon)"/>

      <div class="d-flex flex-column align-items-end stars-flex" :class="!hasNftOptions ? 'stars-flex-extend' : ''">
        <div>
          <b-icon v-for="s in weapon.stars+1"  :key="s" class="star-stat" icon="star-fill" variant="warning" />
        </div>
        <div v-if="selected">
          <span class="rounded-check"></span>
        </div>
      </div>

      <div class="favorite">
        <span v-if="favorite" class="favorite-weapon"></span>
      </div>
      <div class="weapon-details" :style="weapon.lowStarBurnPoints > 0
        || weapon.fourStarBurnPoints > 0
        || weapon.fiveStarBurnPoints > 0
        ? 'margin-top: -20px' : 'margin-top: 0px'">

        <div class="name">
          <div>
            <div class="id-number">{{$t('weaponIcon.id')}}: #{{ weapon.id }}</div>
            <span span>{{ getCleanWeaponName(weapon.id, weapon.stars).toUpperCase() }}</span>
          </div>
          <span class="icon-trait" :class="weapon.element.toLowerCase() + '-icon'"></span>
          <span class="battle-p">Battle Power: {{weapon.stat1Value + weapon.stat2Value + weapon.stat3Value}}</span>
        </div>
        <div>
          <div class="small-durability-bar"
            :style="`--durabilityReady: ${(getWeaponDurability(weapon.id)/maxDurability)*100}%;`"
            v-tooltip.bottom="`
              ${$t('weaponIcon.durability')} ${getWeaponDurability(weapon.id)}/${maxDurability}<br>
              ${getWeaponDurability(weapon.id) === maxDurability ?
              $t('weaponIcon.durabilityTooltipFull') : `${$t('weaponIcon.durabilityTooltip')} ${timeUntilWeaponHasMaxDurability(weapon.id)}` }
              `">
          </div>
        </div>
        <div class="bonus-pows">
          <div v-if="weapon.lowStarBurnPoints > 0">LB: {{ weapon.lowStarBurnPoints }}</div>
          <div v-if="weapon.fourStarBurnPoints > 0">4B: {{ weapon.fourStarBurnPoints }}</div>
          <div v-if="weapon.fiveStarBurnPoints > 0">5B: {{ weapon.fiveStarBurnPoints }}</div>
        </div>
      </div>
    </div>
    <div class="rarity-label" :class="['rarity-' + (weapon.stars || 0)]">{{setRarity(weapon.stars)}}</div>
    <div class="stats">
      <div v-if="weapon.stat1Value">
        <span :class="weapon.stat1.toLowerCase() + '-icon'" class="mr-1 icon"></span>
        <span :class="weapon.stat1.toLowerCase()">{{ weapon.stat1Value }}</span>
      </div>
      <div v-if="weapon.stat2Value">
        <span :class="weapon.stat2.toLowerCase() + '-icon'" class="mr-1 icon"></span>
        <span :class="weapon.stat2.toLowerCase()">{{ weapon.stat2Value }}</span>
      </div>
      <div v-if="weapon.stat3Value">
        <span :class="weapon.stat3.toLowerCase() + '-icon'" class="mr-1 icon"></span>
        <span :class="weapon.stat3.toLowerCase()">{{ weapon.stat3Value }}</span>
      </div>
    </div>

  </div>
</template>

<script>
import { getWeaponArt } from '../../weapon-arts-placeholder';
import * as Three from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';
import swordspecs from '../../assets/swordspecs.json';
import maskChroma from '../../shaders/maskchroma_frag.glsl.js';
import '@/mixins/general';
import { Stat1PercentForChar,
  Stat2PercentForChar,
  Stat3PercentForChar
} from '../../interfaces';
import Events from '@/utils/events';

import { mapGetters, mapState } from 'vuex';
import { getCleanName } from '../../rename-censor';

const bladeCount = 24;
const crossGuardCount = 24;
const gripCount = 24;
const pommelCount = 24;
const modelScale = 1/100;
const modelRotationX = -Math.PI / 2;
const modelRotationY = 0;
const modelRotationZ = 0;

const rColor = new Three.Color(0x7A7A7A);
const gColor = new Three.Color(0x413F41);
const bColor = new Three.Color(0xAF5822);
const white = new Three.Color(0xFFFFFF);

function transformModel(model, y) {
  model.scale.set( modelScale,modelScale,modelScale );
  model.rotation.set(modelRotationX, modelRotationY, modelRotationZ);
  model.position.y = y;
}

export default {
  props: ['weapon', 'favorite', 'selected', 'hasNftOptions'],
  computed: {
    ...mapState(['maxDurability']),
    ...mapState('specialWeaponsManager',
      ([
        'specialWeaponArts',
      ])),
    ...mapGetters([
      'currentCharacter',
      'timeUntilWeaponHasMaxDurability',
      'getWeaponName',
      'getWeaponCosmetic',
      'getWeaponDurability',
    ]),
    tooltipHtml() {
      if(!this.weapon) return '';

      const wrapInSpan = (spanClass, text) => {
        return `<span class="${spanClass.toLowerCase()}">${text}</span><span class="${spanClass.toLowerCase()+'-icon'}"></span>`;
      };

      const wrapInSpanTextOnly = (spanClass, text) => {
        return `<span class="${spanClass.toLowerCase()}">${text}</span>`;
      };

      let ttHtml = `
        ID: ${this.weapon.id}
        <br>
        ${Array(this.weapon.stars + 1).fill('★').join('')}
      `;
      if(this.weapon.level > 0) {
        ttHtml += `<br>Level ${this.weapon.level + 1}`;
      }

      if(this.weapon.element) {
        ttHtml += `<br>Element: ${wrapInSpan(this.weapon.element, this.weapon.element)}`;
      }
      const avg = [];
      if(this.weapon.stat1Value) {
        avg.push(this.weapon.stat1Value);
        ttHtml += `<br>${wrapInSpan(this.weapon.stat1, this.weapon.stat1)}: +${this.weapon.stat1Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat1PercentForChar(this.weapon, +this.currentCharacter.trait)+'%')
          })`;
        }
      }

      if(this.weapon.stat2Value) {
        avg.push(this.weapon.stat2Value);
        ttHtml += `<br>${wrapInSpan(this.weapon.stat2, this.weapon.stat2)}: +${this.weapon.stat2Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat2PercentForChar(this.weapon, +this.currentCharacter.trait)+'%')
          })`;
        }
      }

      if(this.weapon.stat3Value) {
        avg.push(this.weapon.stat3Value);
        ttHtml += `<br>${wrapInSpan(this.weapon.stat3, this.weapon.stat3)}: +${this.weapon.stat3Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat3PercentForChar(this.weapon, +this.currentCharacter.trait)+'%')
          })`;
        }
      }
      if(avg.length > 0) {
        let totalStats = 0;
        avg.forEach(function (stat) {
          totalStats += stat;
        });
        ttHtml += `<br>${wrapInSpan('summary-text', this.$t('weaponGrid.average') + ': +' + (totalStats / avg.length).toFixed(2))}`;
      }

      if(this.weapon.lowStarBurnPoints > 0) {
        ttHtml += `<br>LB: ${this.weapon.lowStarBurnPoints}/100`;
      }

      if(this.weapon.fourStarBurnPoints > 0) {
        ttHtml += `<br>4B: ${this.weapon.fourStarBurnPoints}/25`;
      }

      if(this.weapon.fiveStarBurnPoints > 0) {
        ttHtml += `<br>5B: ${this.weapon.fiveStarBurnPoints}/10`;
      }

      if(this.weapon.bonusPower > 0) {
        ttHtml += `<br>${this.$t('weaponIcon.bonusPower')} ${this.weapon.bonusPower}`;
      }

      return ttHtml;
    }
  },

  data() {
    return {
      hover: false,
      allLoaded: false,
      allLoadStarted: false,
      camera: null,
      scene: null,
      renderer: null,
      baseMaterial: null,
      loadCount: 0,
      loadCountTotal: 0,
      pommel: null,
      grip: null,
      crossGuard: null,
      blade: null,
      group: null,
      bladeMaskTexture: null,
      bladeNormalTexture: null,
      bladeAOTexture: null,
      crossGuardNormalTexture: null,
      crossGuardAOTexture: null,
      gripMaskTexture: null,
      gripNormalTexture: null,
      gripAOTexture: null,
      pommelNormalTexture: null,
      pommelAOTexture: null,
      showPlaceholder: false,
      showCosmetics: true,
    };
  },

  methods: {
    getWeaponArt,
    init() {
      const container = this.$refs.el;

      this.camera = new Three.PerspectiveCamera(70, container.clientWidth/container.clientHeight, 0.01, 1000);
      this.camera.position.z = 0.6;//1.15625;
      this.camera.rotation.z = Math.PI / 4;

      this.scene = new Three.Scene();

      const directionalLight = new Three.DirectionalLight( 0xffffff, 0.75 );
      directionalLight.position.x = -0.375;
      directionalLight.position.y = 1.375;
      directionalLight.position.z = 2.0;
      this.scene.add( directionalLight );

      const directionalLight2 = new Three.DirectionalLight( 0xffffff, 0.375 );
      directionalLight2.position.x = -0.075;
      directionalLight2.position.y = -1.375;
      directionalLight2.position.z = 2.0;
      this.scene.add( directionalLight2 );

      this.renderer = new Three.WebGLRenderer({antialias: true, alpha:true});
      this.renderer.setPixelRatio( window.devicePixelRatio );
      this.renderer.setClearColor( 0x000000, 0 );
      this.renderer.setSize(container.clientWidth, container.clientHeight);
      this.renderer.getContext().canvas.addEventListener('webglcontextlost', (event) => {
        event.preventDefault();
        this.setupModel();
      }, false);

      container.appendChild(this.renderer.domElement);

      if(this.baseMaterial === undefined || this.baseMaterial === null) {
        this.baseMaterial = new Three.MeshPhysicalMaterial();
        this.baseMaterial.aoMapIntensity = 0.375;
        this.baseMaterial.envMapIntensity = 1.0;
        this.baseMaterial.metalness = 1.0; // non-1 allows ambient lights in
        this.baseMaterial.roughness = 0.5;

        const cmLoader = new Three.CubeTextureLoader();
        cmLoader.load( [
          'textures/cubemap/001_studioHDRI.hdr_Rig.png', 'textures/cubemap/001_studioHDRI.hdr_Lef.png',
          'textures/cubemap/001_studioHDRI.hdr_Top.png', 'textures/cubemap/001_studioHDRI.hdr_Bot.png',
          'textures/cubemap/001_studioHDRI.hdr_Fro.png', 'textures/cubemap/001_studioHDRI.hdr_Bak.png'
        ], (cube) => {
          this.baseMaterial.envMap = cube;
          this.loadingProgress();
        });
      }

      this.setupModel();
    },
    setupModel() {
      this.allLoaded = false;
      this.allLoadStarted = false;
      this.loadCount = 0;
      this.loadCountTotal = 15;

      const blade = (this.weapon.blade % bladeCount)+1;
      const crossGuard = (this.weapon.crossguard % crossGuardCount)+1;
      const grip = (this.weapon.grip % gripCount)+1;
      const pommel = (this.weapon.pommel % pommelCount)+1;

      // i fucked up, their height is on Z axis (due to their original -90x rotation)
      const totalHeight = swordspecs['BLADE_'+blade].sizeZ
        + swordspecs['CROSSGUARD_'+crossGuard].sizeZ
        + swordspecs['GRIP_'+crossGuard].sizeZ
        + swordspecs['POMMEL_'+crossGuard].sizeZ;

      this.camera.position.y = ((totalHeight / 2)
        - swordspecs['POMMEL_'+pommel].sizeZ
        + swordspecs['GRIP_'+grip].bottom) * (1.0/totalHeight);

      this.group = new Three.Group();
      this.group.scale.set(1.0/totalHeight,1.0/totalHeight,1.0/totalHeight);
      this.scene.add(this.group);

      const modelLoader = new FBXLoader();
      const textureLoader = new Three.TextureLoader();

      this.bladeMaskTexture = textureLoader.load( 'textures/swords/blades/Txt_Blade_' + blade + '_Mask.png' , this.loadingProgress());
      this.bladeNormalTexture = textureLoader.load( 'textures/swords/blades/Txt_Blade_' + blade + '_Normal.png' , this.loadingProgress());
      this.bladeAOTexture = textureLoader.load( 'textures/swords/blades/Txt_Blade_' + blade + '_AO.png' , this.loadingProgress());

      this.crossGuardNormalTexture = textureLoader.load( 'textures/swords/crossguards/Txt_CrossGuard_' + crossGuard + '_Normal.png', this.loadingProgress());
      this.crossGuardAOTexture = textureLoader.load( 'textures/swords/crossguards/Txt_CrossGuard_' + crossGuard + '_AO.png', this.loadingProgress());

      this.gripMaskTexture = textureLoader.load( 'textures/swords/grips/Txt_Grip_' + grip + '_Mask.png', this.loadingProgress());
      this.gripNormalTexture = textureLoader.load( 'textures/swords/grips/Txt_Grip_' + grip + '_Normal.png', this.loadingProgress());
      this.gripAOTexture = textureLoader.load( 'textures/swords/grips/Txt_Grip_' + grip + '_AO.png', this.loadingProgress());

      this.pommelNormalTexture = textureLoader.load( 'textures/swords/pommels/Txt_Pommel_' + pommel + '_Normal.png', this.loadingProgress());
      this.pommelAOTexture = textureLoader.load( 'textures/swords/pommels/Txt_Pommel_' + pommel + '_AO.png', this.loadingProgress());

      modelLoader.load('models/blades/Blade_' + blade + '.FBX', model => {

        transformModel(model, swordspecs['GRIP_'+grip].top
          + (swordspecs['CROSSGUARD_'+crossGuard].top - swordspecs['CROSSGUARD_'+crossGuard].bottom));
        this.blade = model;
        this.group.add(model);
        this.loadingProgress();

      }, undefined, function ( error ) {
        console.error( error );
      } );

      modelLoader.load('models/crossguards/CrossGuard_' + crossGuard + '.FBX', model => {

        transformModel(model, swordspecs['GRIP_'+grip].top);
        this.crossGuard = model;
        this.group.add(model);
        this.loadingProgress();

      }, undefined, function ( error ) {
        console.error( error );
      } );

      modelLoader.load('models/grips/Grip_' + grip + '.FBX', model => {

        transformModel(model, 0);// grip stays at origin 0,0
        this.grip = model;
        this.group.add(model);
        this.loadingProgress();

      }, undefined, function ( error ) {
        console.error( error );
      } );

      modelLoader.load('models/pommels/Pommel_' + pommel + '.FBX', model => {

        transformModel(model, swordspecs['GRIP_'+grip].bottom);
        this.pommel = model;
        this.group.add(model);
        this.loadingProgress();

      }, undefined, function ( error ) {
        console.error( error );
      } );

      this.allLoadStarted = true;
    },

    patchShader(material, rc, gc, bc) {
      material.userData.maskR = { value: rc };
      material.userData.maskG = { value: gc };
      material.userData.maskB = { value: bc };
      material.onBeforeCompile = shader => {
        shader.uniforms.maskR = material.userData.maskR;
        shader.uniforms.maskG = material.userData.maskG;
        shader.uniforms.maskB = material.userData.maskB;
        shader.fragmentShader = 'uniform vec3 maskR;\nuniform vec3 maskG;\nuniform vec3 maskB;\n' + shader.fragmentShader;
        shader.fragmentShader =
          shader.fragmentShader.replace(
            '#include <map_fragment>',
            maskChroma
          );
      };
      if(this.allLoaded) // fallback, doesn't always work
        this.renderer.render(this.scene, this.camera);
    },
    loadingProgress() {
      if(++this.loadCount >= this.loadCountTotal && this.allLoadStarted) {
        this.loadingFinished();
      }
    },

    setRarity(rarity){
      if(rarity === 0) return 'Normal';
      if(rarity === 1) return 'Rare';
      if(rarity === 2) return 'Unique';
      if(rarity === 3) return 'Legendary';
      if(rarity === 4) return 'Mythical';
    },
    loadingFinished() {

      const bladeMaterial = this.baseMaterial.clone();
      const crossGuardMaterial = this.baseMaterial.clone();
      const gripMaterial = this.baseMaterial.clone();
      const pommelMaterial = this.baseMaterial.clone();
      this.patchShader(bladeMaterial, rColor, gColor, bColor);
      this.patchShader(crossGuardMaterial, rColor, white, white);
      this.patchShader(gripMaterial, rColor, gColor, bColor);
      this.patchShader(pommelMaterial, rColor, white, white);

      bladeMaterial.map = this.bladeMaskTexture;
      bladeMaterial.normalMap = this.bladeNormalTexture;
      bladeMaterial.aoMap = this.bladeAOTexture;
      this.blade.traverse(child => { if(child.isMesh) { child.material = bladeMaterial; } });

      crossGuardMaterial.normalMap = this.crossGuardNormalTexture;
      crossGuardMaterial.aoMap = this.crossGuardAOTexture;
      this.crossGuard.traverse(child => { if(child.isMesh) { child.material = crossGuardMaterial; } });

      gripMaterial.map = this.gripMaskTexture;
      gripMaterial.normalMap = this.gripNormalTexture;
      gripMaterial.aoMap = this.gripAOTexture;
      this.grip.traverse(child => { if(child.isMesh) { child.material = gripMaterial; } });

      pommelMaterial.normalMap = this.pommelNormalTexture;
      pommelMaterial.aoMap = this.pommelAOTexture;
      this.pommel.traverse(child => { if(child.isMesh) { child.material = pommelMaterial; } });

      this.renderer.render(this.scene, this.camera);
      this.allLoaded = true;
    },
    animate() {
      requestAnimationFrame(this.animate);
      if(this.hover) {
        this.group.rotation.y += 0.02;
        this.renderer.render(this.scene, this.camera);
      }
      else {
        if(this.group.rotation.y !== 0) {
          this.group.rotation.y = 0;
          this.renderer.render(this.scene, this.camera);
        }
      }
    },

    getCleanWeaponName(id, stars) {
      return getCleanName(this.getWeaponName(id, stars));
    },

    checkStorage() {
      this.showCosmetics = localStorage.getItem('showCosmetics') !== 'false';
    },
  },
  mounted() {
    this.checkStorage();
    Events.$on('setting:showCosmetics', () => this.checkStorage());
    if(localStorage.getItem('useGraphics') === 'false') {
      this.allLoaded = true;
      this.showPlaceholder = true;
      return;
    }

    this.init();
    this.animate();
  }
};

</script>

<style scoped>
@import '../../styles/weapon-cosmetics.css';
.rounded-check{
  content: url('../../assets/check-round.svg');
  height: 1.5em;
  width: 1.5em;
  z-index: 3;
  right: -3px;
  top: 25px;
  position: absolute;
}

.small-durability-bar {
  position: relative;
  top: -5px;
  height: 4px;
  width: 100%;
  margin: 0 auto;
  border-radius: 2px;
  background : linear-gradient(to right, rgb(236, 75, 75) var(--durabilityReady), rgba(255, 255, 255, 0.1) 0);
}

.weapon-icon {
  height: 100%;
  width: 100%;
  position: relative;
  overflow: visible;
}

.stats > div{
  font-size: 13px;
  font-family: Roboto;
}

.stats > div > span:nth-child(2){
  color: rgba(255, 255, 255, 0.719);
  font-family: Roboto;
}

.glow-container {
  height: 100%;
  width: 100%;
  border-radius: 5px;
  z-index: 540;
  padding: 5px 25px;
  background: rgb(0, 14, 41);
}

.glow-container > img{
  margin-top: 10px;
}

.loading-container {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  z-index: 541;
  padding: 0;
}

.id, .trait, .stats {
  position: absolute;
}

.rarity-label{
  color: #fff;
  padding: 2px 15px;
  position: absolute;
  left: 15px;
  top: 10px !important;
  font-size: 12px;
  border-radius: 3px;
  font-family: Roboto;
}

.stars-flex{
  position: absolute;
  top:27px;
  right: 20px;
}
.stars-flex-extend{
  top: 9px;
}

.battle-p{
  font-family: Roboto;
  font-size: 12px;
  color: #ffffffc7;
}

.icon-trait{
  font-size: 15px;
  margin-right: 5px;
}

.bonus-pows{
 display: flex;
 justify-content: space-between;
 margin-top: 8px;
}

.bonus-pows > div{
  font-family: Roboto;
  font-size: 10px;
  color: rgba(255, 255, 255, 0.548);
  border: 1px solid rgba(255, 255, 255, 0.384);
  padding: 2px 6px;
  border-radius: 5px;
}

.name > div{
  display: flex;
  flex-direction: column;
}

.name > div > div{
  font-family: Roboto;
}

.name > div > span{
  font-family: Oswald;
  white-space: nowrap;
  overflow: hidden;
  text-overflow:ellipsis;
  font-size: 0.87vw;
}

.name{
  margin-bottom: 10px;
}

.selected-border{
  border: 1px solid rgb(237, 205, 144);
}

.star-stat{
  height: 11px;
  width: 11px;
  margin-left: 2px;
}

.trait {
  top: 10px;
  left: 10px;
}

.favorite-star {
  position: absolute;
  margin-left: 110px;
}

.id {
  top: 8px;
  left: 15px;
  font-style: italic;
}

.stats {
  top: 40px;
  left: 15px;
}

.icon {
  display: inline-block;
  min-width: 18px;
}

.placeholder {
  max-width: 180px;
  max-height: 180px;
  margin: auto;
  display: block;

  transform: scale(0.7);
}

.weapon-details{
  display: flex;
  padding: 0px 15px;
  flex-direction: column;
  margin-top: -20px;
}

.favorite-weapon{
  content: url('../../assets/blacksmith/favorite_icon.svg');
  height: 25px;
  width: 25px;
  position: absolute;
  right: -10px;
  top: -10px;
}

.name {
  bottom: 20px;
  left: 12%;
  right: 12%;
  font-size: 0.6vw;
  color: #fff;
  font-family: Roboto;
  text-align: left;
}

.glow-0 {
  animation: none;
  border: 1px solid rgba(245, 245, 245, 0.116);
}

.glow-1 {
  border: 1px solid rgba(0, 162, 255);
}

.glow-2 {
  border: 1px solid rgba(125, 0, 125);
}

.glow-3 {
  border: 1px solid rgba(255, 102, 0);
}

.glow-4 {
  border: 1px solid rgba(125, 0, 0);
}

.rarity-0 {
  background-color: rgb(85, 85, 85);
}

.rarity-1 {
  background-color: rgba(0, 162, 255);
}

.rarity-2 {
  background-color: rgba(125, 0, 125);
}

.rarity-3 {
  background-color: rgba(255, 102, 0);
}

.rarity-4 {
  background-color: rgba(125, 0, 0);
}


.no-durability {
  opacity: 0.6;
}

.bonus-power {
  position: absolute;
  bottom: 40px;
  right: 10%;
  font-size: 0.6em;
  text-align: right;
}

@media (max-width: 576px) {
  .name > div > span{
    font-family: Oswald;
    white-space: nowrap;
    overflow: hidden;
    text-overflow:ellipsis;
    font-size: 7em;
  }

  .name > div > div{
    font-size: 5em;
    color: rgba(255, 255, 255, 0.445);
  }

}


</style>
