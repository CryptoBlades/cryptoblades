<template>
  <div
    class="character-art"
    v-tooltip="tooltipHtml(character)"
    ref="el">

    <div class="trait" v-if="!portrait">
      <span :class="trait.toLowerCase() + '-icon'"></span>
    </div>

    <img v-if="showPlaceholder && !portrait" class="placeholder" :src="getCharacterArt(character)" />

    <div class="loading-container" v-if="!allLoaded">
      <i class="fas fa-spinner fa-spin"></i>
    </div>

    <div class="id" v-if="advancedUI && !portrait">ID {{ character.id }}</div>

    <div class="name">
      {{ getCharacterName(character.id) }} Lv.{{ character.level + 1 }}
    </div>

    <div class="xp" v-if="advancedUI && !portrait">
      <b-progress :max="RequiredXp(character.level)" variant="success">
        <strong class="outline xp-text">{{ character.xp || 0 }} / {{ RequiredXp(character.level) }} XP</strong>
        <b-progress-bar :value="5"></b-progress-bar>
      </b-progress>
    </div>

  </div>
</template>

<script>
import { getCharacterArt } from '../character-arts-placeholder';
import * as Three from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';
import prefabs from '../assets/characterPrefabs.json';
import heads from '../assets/characterWardrobe_head.json';
import arms from '../assets/characterWardrobe_arms.json';
import torsos from '../assets/characterWardrobe_torso.json';
import legs from '../assets/characterWardrobe_legs.json';
import boots from '../assets/characterWardrobe_boots.json';
import { CharacterTrait, RequiredXp } from '../interfaces';
import { mapGetters } from 'vuex';

const headCount = 13;
const armsCount = 45;
const torsoCount = 61;
const legsCount = 41;
const bootsCount = 22;
//const raceCount = 2; // separate genders of each race!

const modelScale = 1/100;

function transformModel(model) {
  model.getObjectByName('Base_HumanRUpperarm1').rotation.y += (75.0 / 180.0) * Math.PI; // flipped only in threejs..
  model.getObjectByName('Base_HumanLUpperarm1').rotation.y -= (75.0 / 180.0) * Math.PI;
  model.scale.set(modelScale,modelScale,modelScale);
}

export default {
  props: ['character', 'portrait'],
  watch: {
    character() {
      this.clearScene();
      this.setupModel();
    }
  },

  data() {
    return {
      allLoaded: false,
      allLoadStarted: false,
      camera: null,
      scene: null,
      renderer: null,
      baseMaterial: null,
      loadCount: 0,
      loadCountTotal: 0,
      modelLoader: null,
      textureLoader: null,
      body: null,
      trait: CharacterTrait[this.character.trait],
      showPlaceholder: false,
      advancedUI: this.advancedUI
    };
  },

  computed: {
    ...mapGetters(['getCharacterName']),
  },

  methods: {

    RequiredXp,

    tooltipHtml(character) {
      if(!character) return '';

      const wrapInSpan = (spanClass, text) => {
        return `<span class="${spanClass.toLowerCase()}">${text}</span><span class="${spanClass.toLowerCase()+'-icon'}"></span>`;
      };

      return `
        ID: ${character.id}
        <br>
        Level ${character.level + 1}
        <br>
        XP ${character.xp} / ${RequiredXp(character.level)}
        <br>
        Trait: ${wrapInSpan(CharacterTrait[character.trait], CharacterTrait[character.trait])}
      `;
    },

    getCharacterArt,

    init() {
      const container = this.$refs.el;

      this.camera = new Three.PerspectiveCamera(70, container.clientWidth/container.clientHeight, 0.01, 1000);
      this.camera.position.z = 1.65;

      this.scene = new Three.Scene();

      this.renderer = new Three.WebGLRenderer({antialias: true, alpha:true});
      this.renderer.setPixelRatio( window.devicePixelRatio);
      this.renderer.setClearColor( 0x000000, 0 );
      this.renderer.setSize(container.clientWidth, container.clientHeight);
      this.renderer.getContext().canvas.addEventListener('webglcontextlost', (event) => {
        event.preventDefault();
        this.setupModel();
      }, false);

      container.appendChild(this.renderer.domElement);

      if(this.baseMaterial === null) {
        this.baseMaterial = new Three.MeshPhysicalMaterial();
        this.baseMaterial.skinning = true; // required for the mesh to be distorted by the bones
        this.baseMaterial.aoMapIntensity = 1.0;
        this.baseMaterial.envMapIntensity = 1.0;
        this.baseMaterial.metalness = 0.25;
        this.baseMaterial.roughness = 0.5;

        const cmLoader = new Three.CubeTextureLoader();
        cmLoader.load( [
          // correct order: +x (right), -x (left), +y (top), -y (bottom), +z (front), -z (back)
          'textures/cubemap/001_studioHDRI.hdr_Rig.png', 'textures/cubemap/001_studioHDRI.hdr_Lef.png',
          'textures/cubemap/001_studioHDRI.hdr_Top.png', 'textures/cubemap/001_studioHDRI.hdr_Bot.png',
          'textures/cubemap/001_studioHDRI.hdr_Fro.png', 'textures/cubemap/001_studioHDRI.hdr_Bak.png'
        ], (cube) => {
          this.baseMaterial.envMap = cube;
        }, undefined, function ( error ) {
          console.error( error );
        } );
      }

      this.setupModel();
    },
    clearScene() {
      if(this.scene !== undefined && this.scene !== null) {
        this.scene.clear();
        this.renderer.render(this.scene, this.camera);
      }
    },
    setupLighting() {

      const directionalLight = new Three.DirectionalLight( 0xffffff, 1.0 * 1.5 );
      directionalLight.position.x = -0.375;
      directionalLight.position.y = 1.375;
      directionalLight.position.z = 2.0;
      this.scene.add( directionalLight );

      const light = new Three.AmbientLight( 0x202020 ); // soft white light
      this.scene.add( light );
    },
    setupModel() {
      this.setupLighting();
      this.allLoaded = false;
      this.allLoadStarted = false;
      this.loadCount = 0;
      this.loadCountTotal = 0;

      this.group = new Three.Group();
      this.group.rotation.y = -Math.PI/8;
      this.group.rotation.x = Math.PI/16;
      this.group.position.y = -1.0;
      this.scene.add(this.group);

      if(this.portrait) {
        this.camera.position.z = 0.7;
        this.camera.position.y = 0.65;
        this.group.rotation.y = Math.PI/8;
      }

      const gender = (this.character.race % 2) === 1 ? 'female' : 'male';

      this.modelLoader = new FBXLoader();
      this.modelLoader.setPath('models/characters/'+gender+'/');
      this.textureLoader = new Three.TextureLoader();
      this.textureLoader.setPath('textures/characters/');

      this.loadCountTotal++;
      this.modelLoader.load('body/Body_' + gender + '.FBX', model => {

        transformModel(model);
        this.body = model;
        this.group.add(model);

        const bodyMaterial = this.baseMaterial.clone();
        bodyMaterial.metalness = 0.0;
        // BODY ALBEDO/COLOR MAP
        this.loadCountTotal++;
        this.textureLoader.load('body/Body_'+gender+'_Albedo.png' , texture => {
          bodyMaterial.map = texture;
          this.loadingProgress();
        }, undefined, function ( error ) {
          console.error( error );
        } );
        // BODY NORMAL MAP
        this.loadCountTotal++;
        this.textureLoader.load('body/Body_'+gender+'_Normal.png' , texture => {
          bodyMaterial.normalMap = texture;
          this.loadingProgress();
        }, undefined, function ( error ) {
          console.error( error );
        } );

        const headMaterial = this.baseMaterial.clone();
        headMaterial.metalness = 0.0;
        // HEAD ALBEDO/COLOR MAP
        this.loadCountTotal++;
        this.textureLoader.load('body/Head_'+gender+'_Albedo.png' , texture => {
          headMaterial.map = texture;
          this.loadingProgress();
        }, undefined, function ( error ) {
          console.error( error );
        } );
        // HEAD NORMAL MAP
        this.loadCountTotal++;
        this.textureLoader.load('body/Head_'+gender+'_Normal.png' , texture => {
          headMaterial.normalMap = texture;
          this.loadingProgress();
        }, undefined, function ( error ) {
          console.error( error );
        } );

        const eyebrowMaterial = new Three.MeshBasicMaterial();
        eyebrowMaterial.color = new Three.Color(0x583a25);
        eyebrowMaterial.opacity = 0.825;
        eyebrowMaterial.transparent = true;
        const eyeMaterial = new Three.MeshBasicMaterial();
        eyeMaterial.color = new Three.Color(0x000000);
        const bodyMats = [
          bodyMaterial,
          headMaterial,
          null,//mouth
          eyebrowMaterial,//eyebrow
          eyeMaterial/*,//eye
          null*///eyereflection
        ];
        this.body.traverse(child => { if(child.isMesh) { child.material = bodyMats; } });

        this.loadingProgress();

      }, undefined, function ( error ) {
        console.error( error );
      } );

      // head
      for(let i = 0; i < heads[this.character.head%headCount].length; i++) {
        if(prefabs[heads[this.character.head%headCount][i]] === undefined || prefabs[heads[this.character.head%headCount][i]] === null)
          console.error('missing prefab: ' + heads[this.character.head%headCount][i]);
        this.loadModel(prefabs[heads[this.character.head%headCount][i]]);
      }
      // arms
      for(let i = 0; i < arms[this.character.arms%armsCount].length; i++) {
        if(prefabs[arms[this.character.arms%armsCount][i]] === undefined || prefabs[arms[this.character.arms%armsCount][i]] === null)
          console.error('missing prefab: ' + arms[this.character.arms%armsCount][i]);
        this.loadModel(prefabs[arms[this.character.arms%armsCount][i]]);
      }
      // torso
      for(let i = 0; i < torsos[this.character.torso%torsoCount].length; i++) {
        if(prefabs[torsos[this.character.torso%torsoCount][i]] === undefined || prefabs[torsos[this.character.torso%torsoCount][i]] === null)
          console.error('missing prefab: ' + torsos[this.character.torso%torsoCount][i]);
        this.loadModel(prefabs[torsos[this.character.torso%torsoCount][i]]);
      }
      // legs
      for(let i = 0; i < legs[this.character.legs%legsCount].length; i++) {
        if(prefabs[legs[this.character.legs%legsCount][i]] === undefined || prefabs[legs[this.character.legs%legsCount][i]] === null)
          console.error('missing prefab: ' + legs[this.character.legs%legsCount][i]);
        this.loadModel(prefabs[legs[this.character.legs%legsCount][i]]);
      }
      // boots
      for(let i = 0; i < boots[this.character.boots%bootsCount].length; i++) {
        if(prefabs[boots[this.character.boots%bootsCount][i]] === undefined || prefabs[boots[this.character.boots%bootsCount][i]] === null)
          console.error('missing prefab: ' + boots[this.character.boots%bootsCount][i]);
        this.loadModel(prefabs[boots[this.character.boots%bootsCount][i]]);
      }

      this.allLoadStarted = true;
    },
    loadModel(modelData) {
      let modelPath = modelData.model;


      if((modelPath === undefined || modelPath === null) && (this.character.race % 2) === 1) {
        if(modelData.femaleModel !== undefined && modelData.femaleModel !== null)
          modelPath = modelData.femaleModel;
        else
          return;
      }

      if((modelPath === undefined || modelPath === null) && (this.character.race % 2) === 0) {
        if(modelData.maleModel !== undefined && modelData.maleModel !== null)
          modelPath = modelData.maleModel;
        else
          return;
      }

      this.loadCountTotal++;

      this.modelLoader.load(modelPath, model => {

        transformModel(model);
        const modelMaterial = this.baseMaterial.clone();
        if(modelPath.includes('fur') || modelPath.includes('Fur')
        || modelPath.includes('hair') || modelPath.includes('Hair')) {
          modelMaterial.transparent = true;
          modelMaterial.side = Three.DoubleSide;
        }

        model.traverse(child => { if(child.isMesh) { child.material = modelMaterial; } });

        // COLOR VALUE
        if(modelData.color !== null && modelData.color !== undefined) {
          const colorString = '#' + modelData.color.substring(0,6);
          modelMaterial.color = new Three.Color(colorString);
        }

        // ALBEDO/COLOR MAP
        if(modelData.albedo !== null && modelData.albedo !== undefined) {
          this.loadCountTotal++;
          this.textureLoader.load(modelData.albedo , texture => {
            modelMaterial.map = texture;
            this.loadingProgress();
          }, undefined, function ( error ) {
            console.error('ALBEDO TEXTURE ' + modelData.albedo + ' : ' + error );
          } );
        }

        // NORMAL MAP
        if(modelData.normal !== null && modelData.normal !== undefined) {
          this.loadCountTotal++;
          this.textureLoader.load(modelData.normal , texture => {
            modelMaterial.normalMap = texture;
            this.loadingProgress();
          }, undefined, function ( error ) {
            console.error('NORMAL TEXTURE ' + modelData.normal + ' : ' + error );
          } );
        }

        // AO MAP
        if(modelData.ao !== null && modelData.ao !== undefined) {
          this.loadCountTotal++;
          this.textureLoader.load(modelData.ao , texture => {
            modelMaterial.aoMap = texture;
            this.loadingProgress();
          }, undefined, function ( error ) {
            console.error('AO TEXTURE ' + modelData.ao + ' : ' + error );
          } );
        }

        // METALLIC/ROUGHNESS MAP
        if(modelData.spec !== null && modelData.spec !== undefined) {
          this.loadCountTotal++;
          this.textureLoader.load(modelData.spec , texture => {
            modelMaterial.roughnessMap = texture;
            modelMaterial.metalnessMap = texture;
            this.loadingProgress();
          }, undefined, function ( error ) {
            console.error('SPEC TEXTURE ' + modelData.spec + ' : ' + error );
          } );
        }

        this.group.add(model);
        this.loadingProgress();
      }, undefined, function ( error ) {
        console.error('MODEL ' + modelData.model + ' / ' + modelData.maleModel + ' / ' + modelData.femaleModel + ' : ' + error );
        console.error('MODELDATA: '+modelData);
      } );
    },
    loadingProgress() {
      if(++this.loadCount >= this.loadCountTotal && this.allLoadStarted) {
        this.loadingFinished();
      }
    },
    loadingFinished() {
      this.renderer.render(this.scene, this.camera);
      this.allLoaded = true;

      //console.log( this.character.id + ' >> Finished applying stuff');
    },
    animate() {
      requestAnimationFrame(this.animate);
      if(this.allLoaded) {
        this.group.rotation.y += 0.02;
        this.renderer.render(this.scene, this.camera);
      }
    }
  },
  mounted() {
    this.advancedUI = !localStorage.getItem('advanced');

    if(localStorage.getItem('graphics')) {
      this.allLoaded = true;
      this.showPlaceholder = true;
      return;
    }

    this.init();
    //this.animate();
  }
};

</script>

<style scoped>

.character-art {
  width: 100%;
  height: 100%;
  position: relative;
  display: flex;
  justify-content: center;
}

.trait, .id, .name, .xp {
  position: absolute;
}

.trait {
  top: 5px;
  left: 5px;
}

.id {
  top: 5px;
  right: 5px;
  font-style: italic;
}

.name {
  bottom: 20px;
  left: 0;
  right: 0;
  font-size: 0.9em;
  text-align: center;
}

.xp {
  bottom: 0;
  left: 0;
  right: 0;
}

.xp-text {
  padding-top: 7px;
  width: 100%;
  text-align: center;
  position: absolute;
}

.placeholder {
  padding: 10px;
  max-width: 100%;
  height: 90%;
  padding-top: 10%;
  object-fit: contain;
}

</style>
