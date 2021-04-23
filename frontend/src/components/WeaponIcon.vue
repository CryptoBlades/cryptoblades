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

let baseMaterial;

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
        ${Array(this.weapon.stars + 1).fill('★').join('')}
        <br>
        Level ${this.weapon.level}
        <br>
        Stat1 +${this.weapon.stat1}
        <br>
        Stat2 +${this.weapon.stat2}
        <br>
        Stat3 +${this.weapon.stat3}
        <br>
        blade +${this.weapon.blade}
        <br>
        Crossguard +${this.weapon.crossguard}
        <br>
        Grip +${this.weapon.grip}
        <br>
        Pommel +${this.weapon.pommel}
      `;
    }
  },

  data() {
    return {
      camera: null,
      scene: null,
      renderer: null,
      loadCount: 0,
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

      this.renderer = new Three.WebGLRenderer({antialias: true, alpha:true});
      this.renderer.setClearColor( 0x000000, 0 );
      this.renderer.setSize(container.clientWidth, container.clientHeight);
      this.renderer.getContext().canvas.addEventListener('webglcontextlost', (event) => {
        event.preventDefault();
        this.setupModel();
      }, false);

      container.appendChild(this.renderer.domElement);

      if(baseMaterial === undefined) {
        baseMaterial = new Three.MeshPhysicalMaterial();
        baseMaterial.aoMapIntensity = 0.375;
        baseMaterial.envMapIntensity = 0.75;
        baseMaterial.metalness = 1.0;
        baseMaterial.roughness = 0.5;

        const cmLoader = new Three.CubeTextureLoader();
        cmLoader.load( [
          'textures/cubemap/001_natureHDRI_LookOut.hdr_Lef.png', 'textures/cubemap/001_natureHDRI_LookOut.hdr_Rig.png',
          'textures/cubemap/001_natureHDRI_LookOut.hdr_Top.png', 'textures/cubemap/001_natureHDRI_LookOut.hdr_Bot.png',
          'textures/cubemap/001_natureHDRI_LookOut.hdr_Fro.png', 'textures/cubemap/001_natureHDRI_LookOut.hdr_Bak.png'
        ], (cube) => {
          baseMaterial.envMap = cube;
        });
      }

      this.setupModel();
    },
    setupModel() {
      this.loadCount = 0;

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

    },
    loadingProgress() {
      if(++this.loadCount >= 14) {
        this.loadingFinished();
      }
    },
    loadingFinished() {

      const bladeMaterial = baseMaterial.clone();
      const crossGuardMaterial = baseMaterial.clone();
      const gripMaterial = baseMaterial.clone();
      const pommelMaterial = baseMaterial.clone();
      patchShader(bladeMaterial, rColor, gColor, bColor);
      patchShader(crossGuardMaterial, rColor, white, white);
      patchShader(gripMaterial, rColor, gColor, bColor);
      patchShader(pommelMaterial, rColor, white, white);

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

      //console.log( this.weapon.id + ' >> Finished applying stuff');
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
  border-radius: 5px;
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
