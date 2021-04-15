<template>
  <div
    class="weapon-icon"
    :title="JSON.stringify(weapon, null, '  ')"
    ref="el"
  >

  </div>
</template>

<script>
import { getWeaponArt } from '../weapon-arts-placeholder';
import * as Three from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';
import swordspecs from '../assets/swordspecs.json';

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
      baseMaterial.metalness = 0.35;
      baseMaterial.roughness = 0.25;

      loader.load('models/blades/Blade_'.concat(blade).concat('.FBX'), model => {

        model.scale.set( modelScale,modelScale,modelScale );
        model.rotation.set(modelRotationX, modelRotationY, modelRotationZ);
        model.position.y = swordspecs['GRIP_'+grip].top
          + (swordspecs['CROSSGUARD_'+crossGuard].top - swordspecs['CROSSGUARD_'+crossGuard].bottom);

        this.blade = model;
        this.group.add(model);

        const material = baseMaterial.clone();
        const normalMap = textureLoader.load( '../assets/swords/blades/Txt_Blade_'.concat(blade).concat('_Normal.TGA'));
        const aoMap = textureLoader.load( '../assets/swords/blades/Txt_Blade_'.concat(blade).concat('_AO.BMP'));
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
        const normalMap = textureLoader.load( '../assets/swords/grips/Txt_Grip_'.concat(grip).concat('_Normal.TGA'));
        const aoMap = textureLoader.load( '../assets/swords/grips/Txt_Grip_'.concat(grip).concat('_AO.BMP'));
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
        const normalMap = textureLoader.load( '../assets/swords/pommels/Txt_Pommel_'.concat(pommel).concat('_Normal.TGA'));
        const aoMap = textureLoader.load( '../assets/swords/pommels/Txt_Pommel_'.concat(pommel).concat('_AO.BMP'));
        material.normalMap = normalMap;
        material.aoMap = aoMap;

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
      this.renderer = new Three.WebGLRenderer({antialias: true, alpha:true});
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
  background-size: cover;
  background-image: url("../assets/iconGlow.png");
}
</style>
