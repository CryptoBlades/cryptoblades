<template>
  <div
    class="weapon-icon"
    :style="{ backgroundImage: `url(${getWeaponArt(weapon)})` }"
    :title="JSON.stringify(weapon, null, '  ')"
    ref="el"
  >
  
  </div>
</template>

<script>
import { getWeaponArt } from "../weapon-arts-placeholder";
import * as Three from 'three';
import { FBXLoader } from "three/examples/jsm/loaders/FBXLoader.js";

const bladeCount = 24;
const crossGuardCount = 24;
const gripCount = 24;
const pommelCount = 24;
const modelScale = 1/75;
const modelRotationZ = Math.PI / 4;
const modelOffsetY = -0.625;
const modelOffsetX = -0.625;

export default {
  props: ["weapon"],

  data() {
    return {
      camera: null,
      scene: null,
      renderer: null,
      pommel: null,
      grip: null,
      crossGuard: null,
      blade: null
    }
  },
  methods: {
    getWeaponArt,

    init: function() {
        let container = this.$refs.el;

        this.camera = new Three.PerspectiveCamera(70, container.clientWidth/container.clientHeight, 0.01, 1000);
        this.camera.position.z = 2;

        this.scene = new Three.Scene();

        var loader = new FBXLoader();
        var textureLoader = new Three.TextureLoader();


        var blade = this.weapon.blade % bladeCount;
        var crossGuard = this.weapon.crossguard % crossGuardCount;
        var grip = this.weapon.grip % gripCount;
        var pommel = this.weapon.pommel % pommelCount;

        loader.load("models/blades/Blade_".concat(blade).concat(".fbx"), model => {

          model.scale.set( modelScale,modelScale,modelScale );
          model.rotation.set(0, 0, modelRotationZ);
          model.position.y = modelOffsetY;
          model.position.x = modelOffsetX;
          this.blade = model;
          this.scene.add(model);
          //console.log(this.mesh);
          this.renderer.render(this.scene, this.camera);
          textureLoader.load( "models/blades/0.png", texture => {
            var material = new Three.MeshLambertMaterial( { map: texture} );
            this.blade.traverse(child => { if(child.isMesh) { child.material = material; } })
            this.renderer.render(this.scene, this.camera);
            }
          );
        }, undefined, function ( error ) {
          console.error( error );
        } );
        
        loader.load("models/crossguards/CrossGuard_".concat(crossGuard).concat(".fbx"), model => {

          model.scale.set( modelScale,modelScale,modelScale );
          model.rotation.set(0, 0, modelRotationZ);
          model.position.y = modelOffsetY;
          model.position.x = modelOffsetX;
          this.crossGuard = model;
          this.scene.add(model);
          //console.log(this.mesh);
          this.renderer.render(this.scene, this.camera);
          textureLoader.load( "models/crossguards/0.png", texture => {
            var material = new Three.MeshLambertMaterial( { map: texture} );
            this.crossGuard.traverse(child => { if(child.isMesh) { child.material = material; } })
            this.renderer.render(this.scene, this.camera);
            }
          );
        }, undefined, function ( error ) {
          console.error( error );
        } );
        
        loader.load("models/grips/Grip_".concat(grip).concat(".fbx"), model => {
          
          model.scale.set( modelScale,modelScale,modelScale );
          model.rotation.set(0, 0, modelRotationZ);
          model.position.y = modelOffsetY;
          model.position.x = modelOffsetX;
          this.grip = model;
          this.scene.add(model);
          //console.log(this.mesh);
          this.renderer.render(this.scene, this.camera);
          textureLoader.load( "models/grips/0.png", texture => {
            var material = new Three.MeshLambertMaterial( { map: texture} );
            this.grip.traverse(child => { if(child.isMesh) { child.material = material; } })
            this.renderer.render(this.scene, this.camera);
            }
          );
        }, undefined, function ( error ) {
          console.error( error );
        } );
        
        loader.load("models/pommels/Pommel_".concat(pommel).concat(".fbx"), model => {

          model.scale.set( modelScale,modelScale,modelScale );
          model.rotation.set(0, 0, modelRotationZ);
          model.position.y = modelOffsetY;
          model.position.x = modelOffsetX;
          this.pommel = model;
          this.scene.add(model);
          //console.log(this.mesh);
          this.renderer.render(this.scene, this.camera);
          textureLoader.load( "models/pommels/0.png", texture => {
            var material = new Three.MeshLambertMaterial( { map: texture} );
            this.pommel.traverse(child => { if(child.isMesh) { child.material = material; } })
            this.renderer.render(this.scene, this.camera);
            }
          );
        }, undefined, function ( error ) {
          console.error( error );
        } );
        
        const light = new Three.AmbientLight( 0x808080 );
        this.scene.add( light );
        this.renderer = new Three.WebGLRenderer({antialias: true, alpha:true});
        this.renderer.setClearColor( 0x000000, 0 );
        this.renderer.setSize(container.clientWidth, container.clientHeight);
        container.appendChild(this.renderer.domElement);
    },
    animate: function() {
        requestAnimationFrame(this.animate);
        /*this.mesh.rotation.x += 0.01;
        this.mesh.rotation.y += 0.02;*/
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
}
</style>
