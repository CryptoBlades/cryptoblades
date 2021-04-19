<template>
  <div
    class="weapon-icon"
    v-tooltip="tooltipHtml"
    ref="el">

    <div class="glow-container" :class="['glow-' + (weapon.stars || 0)]"></div>

  </div>
</template>

<script>
import { getWeaponArt } from '../weapon-arts-placeholder';
import * as Three from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';
import swordspecs from '../assets/swordspecs.json';
import maskChroma from '../shaders/maskchroma_frag.glsl.js';

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

let bladeMaterial;
let crossGuardMaterial;
let gripMaterial;
let pommelMaterial;

let bladeMaskTexture;
let bladeNormalTexture;
let bladeAOTexture;

let crossGuardNormalTexture;
let crossGuardAOTexture;

let gripMaskTexture;
let gripNormalTexture;
let gripAOTexture;

let pommelNormalTexture;
let pommelAOTexture;

let textureCube;

function patchShader(material, rc, gc, bc) {
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
}

function transformModel(model, y) {
  model.scale.set( modelScale,modelScale,modelScale );
  model.rotation.set(modelRotationX, modelRotationY, modelRotationZ);
  model.position.y = y;
}

export default {
  props: ['weapon'],

  computed: {
    tooltipHtml() {
      if(!this.weapon) return '';

      return `
        ${Array(this.weapon.stars + 1).fill('★')}
        <br>
        Level ${this.weapon.level}
        <br>
        Stat1 +${this.weapon.stat1}
        <br>
        Stat2 +${this.weapon.stat2}
        <br>
        Stat3 +${this.weapon.stat3}
      `;
    }
  },

  data() {
    return {
      camera: null,
      scene: null,
      renderer: null,
      pommel: null,
      grip: null,
      crossGuard: null,
      blade: null,
      group: null
    };
  },

  methods: {
    getWeaponArt,

    init() {
      const container = this.$refs.el;

      this.camera = new Three.PerspectiveCamera(70, container.clientWidth/container.clientHeight, 0.01, 1000);
      this.camera.position.z = 1.15625;
      this.camera.rotation.z = Math.PI / 4;

      this.scene = new Three.Scene();

      const directionalLight = new Three.DirectionalLight( 0xffffff, 0.5 );
      directionalLight.position.x = -0.375;
      directionalLight.position.y = 1.375;
      directionalLight.position.z = 2.0;
      this.scene.add( directionalLight );

      this.renderer = new Three.WebGLRenderer({antialias: false, alpha:true});
      this.renderer.setClearColor( 0x000000, 0 );
      this.renderer.setSize(container.clientWidth, container.clientHeight);

      container.appendChild(this.renderer.domElement);

      const blade = (this.weapon.blade % bladeCount)+1;
      const crossGuard = (this.weapon.crossguard % crossGuardCount)+1;
      const grip = (this.weapon.grip % gripCount)+1;
      const pommel = (this.weapon.pommel % pommelCount)+1;

      // i fucked up, their height is on Z axis (due to their original -90x rotation)
      const totalHeight = swordspecs['BLADE_'+blade].sizeZ
        + swordspecs['CROSSGUARD_'+crossGuard].sizeZ
        + swordspecs['GRIP_'+crossGuard].sizeZ
        + swordspecs['POMMEL_'+crossGuard].sizeZ;

      this.camera.position.y = (totalHeight / 2)
        - swordspecs['POMMEL_'+pommel].sizeZ
        + swordspecs['GRIP_'+grip].bottom;

      this.group = new Three.Group();
      this.scene.add(this.group);

      const baseMaterial = new Three.MeshPhysicalMaterial();
      baseMaterial.aoMapIntensity = 0.375;
      baseMaterial.envMapIntensity = 0.75;
      baseMaterial.metalness = 1.0;
      baseMaterial.roughness = 0.5;

      // some access level bullshit for the manager's lambda
      let bladeModel;
      let crossGuardModel;
      let gripModel;
      let pommelModel;
      const scene = this.scene;
      const renderer = this.renderer;
      const camera = this.camera;

      const manager = new Three.LoadingManager(
        function () {
          //console.log('All sword assets loaded');

          baseMaterial.envMap = textureCube;

          bladeMaterial = baseMaterial.clone();
          crossGuardMaterial = baseMaterial.clone();
          gripMaterial = baseMaterial.clone();
          pommelMaterial = baseMaterial.clone();
          patchShader(bladeMaterial, rColor, gColor, bColor);
          patchShader(crossGuardMaterial, rColor, white, white);
          patchShader(gripMaterial, rColor, gColor, bColor);
          patchShader(pommelMaterial, rColor, white, white);

          bladeMaterial.map = bladeMaskTexture;
          bladeMaterial.normalMap = bladeNormalTexture;
          bladeMaterial.aoMap = bladeAOTexture;
          bladeModel.traverse(child => { if(child.isMesh) { child.material = bladeMaterial; } });

          crossGuardMaterial.normalMap = crossGuardNormalTexture;
          crossGuardMaterial.aoMap = crossGuardAOTexture;
          crossGuardModel.traverse(child => { if(child.isMesh) { child.material = crossGuardMaterial; } });

          gripMaterial.map = gripMaskTexture;
          gripMaterial.normalMap = gripNormalTexture;
          gripMaterial.aoMap = gripAOTexture;
          gripModel.traverse(child => { if(child.isMesh) { child.material = gripMaterial; } });

          pommelMaterial.normalMap = pommelNormalTexture;
          pommelMaterial.aoMap = pommelAOTexture;
          pommelModel.traverse(child => { if(child.isMesh) { child.material = pommelMaterial; } });

          renderer.render(scene, camera);

          //console.log('Finished applying stuff');
        }/*,
        function () {
          console.log('Three Progress Update');
        },
        function () {
          console.log('Three loading error');
        }*/
      );
      const modelLoader = new FBXLoader(manager);
      const textureLoader = new Three.TextureLoader(manager);
      const cmLoader = new Three.CubeTextureLoader(manager);

      bladeMaskTexture = textureLoader.load( 'textures/swords/blades/Txt_Blade_' + blade + '_Mask.png' );
      bladeNormalTexture = textureLoader.load( 'textures/swords/blades/Txt_Blade_' + blade + '_Normal.png' );
      bladeAOTexture = textureLoader.load( 'textures/swords/blades/Txt_Blade_' + blade + '_AO.png' );

      crossGuardNormalTexture = textureLoader.load( 'textures/swords/crossguards/Txt_CrossGuard_' + crossGuard + '_Normal.png');
      crossGuardAOTexture = textureLoader.load( 'textures/swords/crossguards/Txt_CrossGuard_' + crossGuard + '_AO.png');

      gripMaskTexture = textureLoader.load( 'textures/swords/grips/Txt_Grip_' + grip + '_Mask.png');
      gripNormalTexture = textureLoader.load( 'textures/swords/grips/Txt_Grip_' + grip + '_Normal.png');
      gripAOTexture = textureLoader.load( 'textures/swords/grips/Txt_Grip_' + grip + '_AO.png');

      pommelNormalTexture = textureLoader.load( 'textures/swords/pommels/Txt_Pommel_' + pommel + '_Normal.png');
      pommelAOTexture = textureLoader.load( 'textures/swords/pommels/Txt_Pommel_' + pommel + '_AO.png');

      textureCube = cmLoader.load( [
        'textures/cubemap/001_natureHDRI_LookOut.hdr_Lef.png', 'textures/cubemap/001_natureHDRI_LookOut.hdr_Rig.png',
        'textures/cubemap/001_natureHDRI_LookOut.hdr_Top.png', 'textures/cubemap/001_natureHDRI_LookOut.hdr_Bot.png',
        'textures/cubemap/001_natureHDRI_LookOut.hdr_Fro.png', 'textures/cubemap/001_natureHDRI_LookOut.hdr_Bak.png'
      ] );

      modelLoader.load('models/blades/Blade_' + blade + '.FBX', model => {

        transformModel(model, swordspecs['GRIP_'+grip].top
          + (swordspecs['CROSSGUARD_'+crossGuard].top - swordspecs['CROSSGUARD_'+crossGuard].bottom));
        this.blade = model;
        bladeModel = model;
        this.group.add(model);

      }, undefined, function ( error ) {
        console.error( error );
      } );

      modelLoader.load('models/crossguards/CrossGuard_' + crossGuard + '.FBX', model => {

        transformModel(model, swordspecs['GRIP_'+grip].top);
        this.crossGuard = model;
        crossGuardModel = model;
        this.group.add(model);

      }, undefined, function ( error ) {
        console.error( error );
      } );

      modelLoader.load('models/grips/Grip_' + grip + '.FBX', model => {

        transformModel(model, 0);// grip stays at origin 0,0
        this.grip = model;
        gripModel = model;
        this.group.add(model);

      }, undefined, function ( error ) {
        console.error( error );
      } );

      modelLoader.load('models/pommels/Pommel_' + pommel + '.FBX', model => {

        transformModel(model, swordspecs['GRIP_'+grip].bottom);
        this.pommel = model;
        pommelModel = model;
        this.group.add(model);

      }, undefined, function ( error ) {
        console.error( error );
      } );

    },
    animate() {
      requestAnimationFrame(this.animate);
      this.group.rotation.y += 0.02;
      this.renderer.render(this.scene, this.camera);
    }
  },

  mounted() {
    this.init();
    //this.animate();
  }
};

</script>

<style scoped>
.weapon-icon {
  width: 100%;
  height: 100%;

  position: relative;
}

.glow-container {
  border-radius: 50%;
  height: 96px;
  width: 96px;
  position: absolute;
  top: 0;
  z-index: 540;
}

.glow-0 {
  animation: none;
}

.glow-1 {
  animation: glow-1 800ms ease-out infinite alternate;
}

.glow-2 {
  animation: glow-2 700ms ease-out infinite alternate;
}

.glow-3 {
  animation: glow-3 600ms ease-out infinite alternate;
}

.glow-4 {
  animation: glow-4 500ms ease-out infinite alternate;
}

@keyframes glow-1 {
  0% {
    box-shadow: inset 0 0 10px #00a;
  }
  100% {
    box-shadow: inset 0 0 15px #00a;
  }
}

@keyframes glow-2 {
  0% {
    box-shadow: inset 0 0 10px #a0a;
  }
  100% {
    box-shadow: inset 0 0 20px #a0a;
  }
}

@keyframes glow-3 {
  0% {
    box-shadow: inset 0 0 10px #f60;
  }
  100% {
    box-shadow: inset 0 0 25px #f60;
  }
}

@keyframes glow-4 {
  0% {
    box-shadow: inset 0 0 10px #a00;
  }
  100% {
    box-shadow: inset 0 0 30px #a00;
  }
}
</style>
