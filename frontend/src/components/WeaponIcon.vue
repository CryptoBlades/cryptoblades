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

      const loader = new FBXLoader();
      const textureLoader = new Three.TextureLoader();


      const blade = (this.weapon.blade % bladeCount)+1;
      const crossGuard = (this.weapon.crossguard % crossGuardCount)+1;
      const grip = (this.weapon.grip % gripCount)+1;
      const pommel = (this.weapon.pommel % pommelCount)+1;

      const cmLoader = new Three.CubeTextureLoader();

      const textureCube = cmLoader.load( [
        '../assets/cubemap/001_natureHDRI_LookOut.hdr_Lef.png', '../assets/cubemap/001_natureHDRI_LookOut.hdr_Rig.png',
        '../assets/cubemap/001_natureHDRI_LookOut.hdr_Top.png', '../assets/cubemap/001_natureHDRI_LookOut.hdr_Bot.png',
        '../assets/cubemap/001_natureHDRI_LookOut.hdr_Fro.png', '../assets/cubemap/001_natureHDRI_LookOut.hdr_Bak.png'
      ] );

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
      baseMaterial.envMap = textureCube;
      baseMaterial.envMapIntensity = 1;
      baseMaterial.metalness = 1.0;
      baseMaterial.roughness = 0.5;

      loader.load('models/blades/Blade_'.concat(blade).concat('.FBX'), model => {

        model.scale.set( modelScale,modelScale,modelScale );
        model.rotation.set(modelRotationX, modelRotationY, modelRotationZ);
        model.position.y = swordspecs['GRIP_'+grip].top
          + (swordspecs['CROSSGUARD_'+crossGuard].top - swordspecs['CROSSGUARD_'+crossGuard].bottom);

        this.blade = model;
        this.group.add(model);

        const material = baseMaterial.clone();
        material.userData.maskR = { value: 0.5 };
        material.userData.maskG = { value: 0.5 };
        material.userData.maskB = { value: 0.5 };
        material.onBeforeCompile = shader => {
          shader.uniforms.maskR = material.userData.maskR;
          shader.uniforms.maskG = material.userData.maskG;
          shader.uniforms.maskB = material.userData.maskB;
          shader.fragmentShader = 'uniform float maskR;\nuniform float maskG;\nuniform float maskB;\n' + shader.fragmentShader;
          shader.fragmentShader =
            shader.fragmentShader.replace(
              '#include <map_fragment>',
              maskChroma
            );
        };

        const maskMap = textureLoader.load( '../assets/swords/blades/Txt_Blade_'.concat(blade).concat('_Mask.TGA'));
        const normalMap = textureLoader.load( '../assets/swords/blades/Txt_Blade_'.concat(blade).concat('_Normal.TGA'));
        const aoMap = textureLoader.load( '../assets/swords/blades/Txt_Blade_'.concat(blade).concat('_AO.BMP'));
        material.map = maskMap;
        material.normalMap = normalMap;
        material.aoMap = aoMap;

        this.blade.traverse(child => { if(child.isMesh) { child.material = material; } });
        this.renderer.render(this.scene, this.camera);
      }, undefined, function ( error ) {
        console.error( error );
      } );

      loader.load('models/crossguards/CrossGuard_'.concat(crossGuard).concat('.FBX'), model => {

        model.scale.set( modelScale,modelScale,modelScale );
        model.rotation.set(modelRotationX, modelRotationY, modelRotationZ);
        model.position.y = swordspecs['GRIP_'+grip].top;

        this.crossGuard = model;
        this.group.add(model);

        const material = baseMaterial.clone();
        material.userData.maskR = { value: 0.5 };
        material.userData.maskG = { value: 0.5 };
        material.userData.maskB = { value: 0.5 };
        material.onBeforeCompile = shader => {
          shader.uniforms.maskR = material.userData.maskR;
          shader.uniforms.maskG = material.userData.maskG;
          shader.uniforms.maskB = material.userData.maskB;
          shader.fragmentShader = 'uniform float maskR;\nuniform float maskG;\nuniform float maskB;\n' + shader.fragmentShader;
          shader.fragmentShader =
            shader.fragmentShader.replace(
              '#include <map_fragment>',
              maskChroma
            );
        };

        const normalMap = textureLoader.load( '../assets/swords/crossguards/Txt_CrossGuard_'.concat(crossGuard).concat('_Normal.TGA'));
        const aoMap = textureLoader.load( '../assets/swords/crossguards/Txt_CrossGuard_'.concat(crossGuard).concat('_AO.BMP'));
        material.normalMap = normalMap;
        material.aoMap = aoMap;

        this.crossGuard.traverse(child => { if(child.isMesh) { child.material = material; } });
        this.renderer.render(this.scene, this.camera);
      }, undefined, function ( error ) {
        console.error( error );
      } );

      loader.load('models/grips/Grip_'.concat(grip).concat('.FBX'), model => {

        model.scale.set( modelScale,modelScale,modelScale );
        model.rotation.set(modelRotationX, modelRotationY, modelRotationZ);
        // grip stays at origin 0,0

        this.grip = model;
        this.group.add(model);

        const material = baseMaterial.clone();
        material.userData.maskR = { value: 0.5 };
        material.userData.maskG = { value: 0.5 };
        material.userData.maskB = { value: 0.5 };
        material.onBeforeCompile = shader => {
          shader.uniforms.maskR = material.userData.maskR;
          shader.uniforms.maskG = material.userData.maskG;
          shader.uniforms.maskB = material.userData.maskB;
          shader.fragmentShader = 'uniform float maskR;\nuniform float maskG;\nuniform float maskB;\n' + shader.fragmentShader;
          shader.fragmentShader =
            shader.fragmentShader.replace(
              '#include <map_fragment>',
              maskChroma
            );
        };

        const maskMap = textureLoader.load( '../assets/swords/grips/Txt_Grip_'.concat(grip).concat('_Mask.TGA'));
        const normalMap = textureLoader.load( '../assets/swords/grips/Txt_Grip_'.concat(grip).concat('_Normal.TGA'));
        const aoMap = textureLoader.load( '../assets/swords/grips/Txt_Grip_'.concat(grip).concat('_AO.BMP'));
        material.map = maskMap;
        material.normalMap = normalMap;
        material.aoMap = aoMap;

        this.grip.traverse(child => { if(child.isMesh) { child.material = material; } });
        this.renderer.render(this.scene, this.camera);
      }, undefined, function ( error ) {
        console.error( error );
      } );

      loader.load('models/pommels/Pommel_'.concat(pommel).concat('.FBX'), model => {

        model.scale.set( modelScale,modelScale,modelScale );
        model.rotation.set(modelRotationX, modelRotationY, modelRotationZ);
        model.position.y = swordspecs['GRIP_'+grip].bottom;

        this.pommel = model;
        this.group.add(model);

        const material = baseMaterial.clone();
        material.userData.maskR = { value: 0.5 };
        material.userData.maskG = { value: 0.5 };
        material.userData.maskB = { value: 0.5 };
        material.onBeforeCompile = shader => {
          shader.uniforms.maskR = material.userData.maskR;
          shader.uniforms.maskG = material.userData.maskG;
          shader.uniforms.maskB = material.userData.maskB;
          shader.fragmentShader = 'uniform float maskR;\nuniform float maskG;\nuniform float maskB;\n' + shader.fragmentShader;
          shader.fragmentShader =
            shader.fragmentShader.replace(
              '#include <map_fragment>',
              maskChroma
            );
        };

        const normalMap = textureLoader.load( '../assets/swords/pommels/Txt_Pommel_'.concat(pommel).concat('_Normal.TGA'));
        const aoMap = textureLoader.load( '../assets/swords/pommels/Txt_Pommel_'.concat(pommel).concat('_AO.BMP'));
        material.normalMap = normalMap;
        material.aoMap = aoMap;
        material.color = new Three.Color(0xff0000);

        this.pommel.traverse(child => { if(child.isMesh) { child.material = material; } });
        this.renderer.render(this.scene, this.camera);
      }, undefined, function ( error ) {
        console.error( error );
      } );

      const light = new Three.AmbientLight( 0x808080 );
      this.scene.add( light );
      const directionalLight = new Three.DirectionalLight( 0xffffff, 0.5 );
      directionalLight.position.x = -0.375;
      directionalLight.position.y = 1.375;
      directionalLight.position.z = 2.0;
      this.scene.add( directionalLight );
      this.renderer = new Three.WebGLRenderer({antialias: false, alpha:true});
      this.renderer.setClearColor( 0x000000, 0 );
      this.renderer.setSize(container.clientWidth, container.clientHeight);
      container.appendChild(this.renderer.domElement);
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
