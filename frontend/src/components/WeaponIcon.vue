<template>
  <div
    class="weapon-icon"
    v-bind:class="[getWeaponDurability(weapon.id) === 0 ? 'no-durability' : '']"
    v-tooltip="{ content: tooltipHtml , trigger: (isMobile() ? 'click' : 'hover') }"
    @mouseover="hover = !isMobile() || true"
    @mouseleave="hover = !isMobile()"
  >

    <div class="loading-container" v-if="!allLoaded">
      <i class="fas fa-spinner fa-spin"></i>
    </div>

    <div class="glow-container" ref="el" :class="['glow-' + (weapon.stars || 0)]">

      <img v-if="showPlaceholder" class="placeholder" :src="getWeaponArt(weapon)" />

      <div class="trait">
        <span :class="weapon.element.toLowerCase() + '-icon'"></span>
        <b-icon v-if="favorite" class="favorite-star" icon="star-fill" variant="warning" />
      </div>

      <div class="name">
        {{ getWeaponNameFromSeed(weapon.id, weapon.stars) }}
      </div>

      <div class="bonus-power">
        <div v-if="weapon.lowStarBurnPoints > 0"><span>{{ weapon.lowStarBurnPoints }} LB</span></div>
        <div v-if="weapon.fourStarBurnPoints > 0"><span>{{ weapon.fourStarBurnPoints }} 4B</span></div>
        <div v-if="weapon.fiveStarBurnPoints > 0"><span>{{ weapon.fiveStarBurnPoints }} 5B</span></div>
      </div>

      <div>
        <div class="small-durability-bar"
        :style="`--durabilityReady: ${(getWeaponDurability(weapon.id)/maxDurability)*100}%;`"
        v-tooltip.bottom="`Durability: ${getWeaponDurability(weapon.id)}/${maxDurability}<br>
          Repairs 1 point every 50 minutes, durability will be full at: ${timeUntilWeaponHasMaxDurability(weapon.id)}`"></div>
      </div>

    </div>

    <div class="id">ID {{ weapon.id }}</div>

    <div class="stats">
      <div v-if="weapon.stat1Value">
        <span :class="weapon.stat1.toLowerCase() + '-icon'" class="mr-1 icon"></span>
        <span :class="weapon.stat1.toLowerCase()">{{ weapon.stat1 }} +{{ weapon.stat1Value }}</span>
      </div>
      <div v-if="weapon.stat2Value">
        <span :class="weapon.stat2.toLowerCase() + '-icon'" class="mr-1 icon"></span>
        <span :class="weapon.stat2.toLowerCase()">{{ weapon.stat2 }} +{{ weapon.stat2Value }}</span>
      </div>
      <div v-if="weapon.stat3Value">
        <span :class="weapon.stat3.toLowerCase() + '-icon'" class="mr-1 icon"></span>
        <span :class="weapon.stat3.toLowerCase()">{{ weapon.stat3 }} +{{ weapon.stat3Value }}</span>
      </div>
    </div>

  </div>
</template>

<script>
import { getWeaponArt } from '../weapon-arts-placeholder';
import { getWeaponNameFromSeed } from '../weapon-name';
import * as Three from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';
import swordspecs from '../assets/swordspecs.json';
import maskChroma from '../shaders/maskchroma_frag.glsl.js';
import '@/mixins/general';
import { Stat1PercentForChar,
  Stat2PercentForChar,
  Stat3PercentForChar
} from '../interfaces';

import { mapGetters, mapState } from 'vuex';

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
  props: ['weapon', 'favorite'],

  computed: {
    ...mapState(['maxDurability']),
    ...mapGetters([
      'currentCharacter',
      'getWeaponDurability',
      'timeUntilWeaponHasMaxDurability'
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

      if(this.weapon.stat1Value) {
        ttHtml += `<br>${wrapInSpan(this.weapon.stat1, this.weapon.stat1)}: +${this.weapon.stat1Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat1PercentForChar(this.weapon, +this.currentCharacter.trait)+'%')
          })`;
        }
      }

      if(this.weapon.stat2Value) {
        ttHtml += `<br>${wrapInSpan(this.weapon.stat2, this.weapon.stat2)}: +${this.weapon.stat2Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat2PercentForChar(this.weapon, +this.currentCharacter.trait)+'%')
          })`;
        }
      }

      if(this.weapon.stat3Value) {
        ttHtml += `<br>${wrapInSpan(this.weapon.stat3, this.weapon.stat3)}: +${this.weapon.stat3Value}`;
        if(this.currentCharacter) {
          ttHtml += ` (${wrapInSpanTextOnly(
            this.currentCharacter.traitName,
            '+'+Stat3PercentForChar(this.weapon, +this.currentCharacter.trait)+'%')
          })`;
        }
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
        ttHtml += `<br>Bonus power: ${this.weapon.bonusPower}`;
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
    };
  },

  methods: {
    getWeaponNameFromSeed,
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
    }
  },
  mounted() {
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
.small-durability-bar {
  position: relative;
  top: -5px;
  height: 10px;
  width: 80%;
  margin: 0 auto;
  border-radius: 2px;
  border: 0.5px solid rgb(216, 215, 215);
  background : linear-gradient(to right, rgb(236, 75, 75) var(--durabilityReady), rgba(255, 255, 255, 0.1) 0);
}

.weapon-icon {
  height: 100%;
  width: 100%;
  position: relative;
}

.glow-container {
  height: 100%;
  width: 100%;
}

.glow-container {
  border-radius: 5px;
  z-index: 540;
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

.trait {
  top: 10px;
  left: 10px;
}

.favorite-star {
  position: absolute;
  margin-left: 5px;
}

.id {
  top: 8px;
  right: 10px;
  font-style: italic;
}

.stats {
  top: 35px;
  left: 10px;
}

.icon {
  display: inline-block;
  min-width: 18px;
}

.placeholder {
  max-width: 180px;
  max-height: 180px;
  margin-left: 10px;
  margin-top: 5px;

  transform: scale(0.7);
}

.name {
  position: absolute;
  bottom: 15px;
  left: 12%;
  right: 12%;
  font-size: 0.9em;
  text-align: center;
}

.glow-0 {
  animation: none;
}

.glow-1 {
  animation: glow-1 2000ms ease-out infinite alternate;
}

.glow-2 {
  animation: glow-2 2000ms ease-out infinite alternate;
}

.glow-3 {
  animation: glow-3 2000ms ease-out infinite alternate;
}

.glow-4 {
  animation: glow-4 2000ms ease-out infinite alternate;
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

@keyframes glow-1 {
  0% {
    box-shadow: inset 0 0 10px rgba(0, 162, 255, 0.5);
  }
  100% {
    box-shadow: inset 0 0 15px rgba(0, 162, 255, 0.5);
  }
}

@keyframes glow-2 {
  0% {
    box-shadow: inset 0 0 10px rgba(125, 0, 125, 0.5);
  }
  100% {
    box-shadow: inset 0 0 20px rgba(125, 0, 125, 0.5);
  }
}

@keyframes glow-3 {
  0% {
    box-shadow: inset 0 0 10px rgba(255, 102, 0, 0.3);
  }
  100% {
    box-shadow: inset 0 0 25px rgba(255, 102, 0, 0.3);
  }
}

@keyframes glow-4 {
  0% {
    box-shadow: inset 0 0 10px rgba(125, 0, 0, 0.5);
  }
  100% {
    box-shadow: inset 0 0 30px rgba(125, 0, 0, 0.5);
  }
}
</style>
