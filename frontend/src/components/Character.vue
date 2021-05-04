<template>
  <div class="wrapper">
    <!-- <img src="../assets/chara.png" alt="Placeholder character"> -->
    <div
      class="image"
      ref="el"
      :style="{ backgroundImage: `url(${getCharacterArt(this.character)})` }"
    ></div>
  </div>
</template>

<script lang="ts">
import { getCharacterArt } from '../character-arts-placeholder';
import * as Three from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';

/*const modelScale = 1/100;
const modelRotationX = -Math.PI / 2;
const modelRotationY = 0;
const modelRotationZ = 0;*/

let baseMaterial;

export default {
  props: ['character'],

  data() {
    return {
      body: null,
    };
  },

  methods: {
    getCharacterArt,

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

      this.renderer = new Three.WebGLRenderer({antialias: true, alpha:false});
      //this.renderer.setClearColor( 0x000000, 0 );
      this.renderer.setSize(container.clientWidth, container.clientHeight);
      this.renderer.getContext().canvas.addEventListener('webglcontextlost', (event) => {
        event.preventDefault();
        this.setupModel();
      }, false);

      container.appendChild(this.renderer.domElement);

      if(baseMaterial === undefined) {
        baseMaterial = new Three.MeshPhysicalMaterial();
        /*baseMaterial.aoMapIntensity = 0.375;
        baseMaterial.envMapIntensity = 0.75;
        baseMaterial.metalness = 1.0;
        baseMaterial.roughness = 0.5;*/

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

      //const blade = (this.weapon.blade % bladeCount)+1;

      // i fucked up, their height is on Z axis (due to their original -90x rotation)
      /*const totalHeight = swordspecs['BLADE_'+blade].sizeZ
        + swordspecs['CROSSGUARD_'+crossGuard].sizeZ
        + swordspecs['GRIP_'+crossGuard].sizeZ
        + swordspecs['POMMEL_'+crossGuard].sizeZ;

      this.camera.position.y = (totalHeight / 2)
        - swordspecs['POMMEL_'+pommel].sizeZ
        + swordspecs['GRIP_'+grip].bottom;*/

      this.group = new Three.Group();
      this.scene.add(this.group);

      const modelLoader = new FBXLoader();
      //const textureLoader = new Three.TextureLoader();
      /*
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
      */
      /*modelLoader.load('models/blades/Blade_' + blade + '.FBX', model => {

        transformModel(model, swordspecs['GRIP_'+grip].top
          + (swordspecs['CROSSGUARD_'+crossGuard].top - swordspecs['CROSSGUARD_'+crossGuard].bottom));
        this.blade = model;
        this.group.add(model);
        this.loadingProgress();

      }, undefined, function ( error ) {
        console.error( error );
      } );*/

      modelLoader.load('models/characters/human/male.FBX', model => {

        this.body = model;
        this.group.add(model);
        this.loadingProgress();

      }, undefined, function ( error ) {
        console.error( error );
      } );

    },
    loadingProgress() {
      /*if(++this.loadCount >= 14) {
        this.loadingFinished();
      }*/
      this.loadingFinished();
    },
    loadingFinished() {

      /*const bladeMaterial = baseMaterial.clone();
      const crossGuardMaterial = baseMaterial.clone();
      const gripMaterial = baseMaterial.clone();
      const pommelMaterial = baseMaterial.clone();
      patchShader(bladeMaterial, rColor, gColor, bColor);*/

      /*bladeMaterial.map = this.bladeMaskTexture;
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
      this.pommel.traverse(child => { if(child.isMesh) { child.material = pommelMaterial; } });*/

      this.renderer.render(this.scene, this.camera);
      this.allLoaded = true;

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

<style>
.wrapper {
  margin: 0;
  display: flex;
  justify-content: center;
  align-content: center;
  background: url("../assets/chara-bg.png") center bottom no-repeat;
  padding: 5em;
  padding-bottom: 1em;
}

.image {
  width: 100%;
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
}
</style>
