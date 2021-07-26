<template>
  <div class="character-art" v-tooltip="tooltipHtml(character)" ref="el">
    <div class="trait" v-if="!portrait">
      <span :class="trait.toLowerCase() + '-icon circle-element'"></span>
    </div>

    <div class="placeholder d-flex align-items-start justify-content-center p-1"
      >
      <div class="w-100" :style="{
        'background-image': 'url(' + getCharacterArt(character) + ')',
      }"
      :class="{
        'h-100': !isMarket,
        'h-75': isMarket
      }">

      </div>
      <!--<small-button class="button" :text="`Purchase`" v-if="isMarket"/>-->
    </div>

    <div class="loading-container" v-if="!allLoaded">
      <i class="fas fa-spinner fa-spin"></i>
    </div>

    <div class="name-lvl-container">
      <div class="name black-outline" v-if="!portrait">{{ getCharacterName(character.id) }} </div>
      <div v-if="!portrait">Lv.<span class="white">{{ character.level + 1 }}</span></div>
    </div>
    <div class="score-id-container">
    <div class="black-outline" v-if="!portrait">ID <span class="white">{{ character.id }}</span></div>
    <div class="black-outline" v-if="!portrait">
      Score <span class="white">{{ heroScore.toLocaleString() }}</span>
      <b-icon-question-circle class="centered-icon" scale="0.8" v-tooltip.bottom="`Hero score is a measure of your hero's combat prowess so far.
        It goes up when you win and down when you lose. It is also temporarily disabled!`"/>
    </div>
    </div>

    <div v-if="!portrait && isMarket" class="small-stamina-char"
      :style="`--staminaReady: ${(timestampToStamina(character.staminaTimestamp)/maxStamina)*100}%;`"
      v-tooltip.bottom="staminaToolTipHtml(timeUntilCharacterHasMaxStamina(character.id))">
      <div class="stamina-text black-outline">STA {{ timestampToStamina(character.staminaTimestamp) }} / 200</div>
    </div>

    <div class="xp" v-if="!portrait">
      <b-progress :max="RequiredXp(character.level)" variant="success"
      v-tooltip.bottom="`Claimable XP ${this.getCharacterUnclaimedXp(character.id)}`">
        <strong class="outline xp-text">{{ character.xp || 0 }} / {{ RequiredXp(character.level) }} XP</strong>
        <b-progress-bar :value="character.xp || 0"></b-progress-bar>
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
import { mapGetters, mapState } from 'vuex';
//import SmallButton from './SmallButton.vue';

const headCount = 13;
const armsCount = 45;
const torsoCount = 61;
const legsCount = 41;
const bootsCount = 22;
//const raceCount = 2; // separate genders of each race!

const modelScale = 1 / 100;

function transformModel(model) {
  model.getObjectByName('Base_HumanRUpperarm1').rotation.y += (75.0 / 180.0) * Math.PI; // flipped only in threejs..
  model.getObjectByName('Base_HumanLUpperarm1').rotation.y -= (75.0 / 180.0) * Math.PI;
  model.scale.set(modelScale, modelScale, modelScale);
}

export default {
  props: ['character', 'portrait', 'isMarket'],
  components: {
    //SmallButton,
  },
  watch: {
    character() {
      this.clearScene();
      this.setupModel();
    },
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
      heroScore: 0
    };
  },

  computed: {
    ...mapState(['maxStamina']),
    ...mapGetters([
      'getCharacterName',
      'transferCooldownOfCharacterId',
      'getCharacterUnclaimedXp',
      'timeUntilCharacterHasMaxStamina'
    ]),
  },

  methods: {
    RequiredXp,

    tooltipHtml(character) {
      if (!character) return '';

      const cooldown = this.transferCooldownOfCharacterId(this.character.id);
      if (cooldown) {
        if (cooldown === 86400)
          // edge case for when it's exactly 1 day and the iso string cant display
          return 'May not be traded for: 1 day';
        else return `May not be traded for: ${new Date(cooldown * 1000).toISOString().substr(11, 8)}`;
      }

      return '';
    },

    staminaToolTipHtml(time) {
      return 'Regenerates 1 point every 5 minutes, stamina bar will be full at: ' + time;
    },

    timestampToStamina(timestamp) {
      if(timestamp > Math.floor(Date.now()/1000)) return 0;
      return +Math.min((Math.floor(Date.now()/1000) - timestamp) / 300, 200).toFixed(0);
    },

    getCharacterArt,

    init() {
      const container = this.$refs.el;

      this.camera = new Three.PerspectiveCamera(70, container.clientWidth / container.clientHeight, 0.01, 1000);
      this.camera.position.z = 1.65;

      this.scene = new Three.Scene();

      this.renderer = new Three.WebGLRenderer({ antialias: true, alpha: true });
      this.renderer.setPixelRatio(window.devicePixelRatio);
      this.renderer.setClearColor(0x000000, 0);
      this.renderer.setSize(container.clientWidth, container.clientHeight);
      this.renderer.getContext().canvas.addEventListener(
        'webglcontextlost',
        (event) => {
          event.preventDefault();
          this.setupModel();
        },
        false,
      );

      container.appendChild(this.renderer.domElement);

      if (this.baseMaterial === null) {
        this.baseMaterial = new Three.MeshPhysicalMaterial();
        this.baseMaterial.skinning = true; // required for the mesh to be distorted by the bones
        this.baseMaterial.aoMapIntensity = 1.0;
        this.baseMaterial.envMapIntensity = 1.0;
        this.baseMaterial.metalness = 0.25;
        this.baseMaterial.roughness = 0.5;

        const cmLoader = new Three.CubeTextureLoader();
        cmLoader.load(
          [
            // correct order: +x (right), -x (left), +y (top), -y (bottom), +z (front), -z (back)
            'textures/cubemap/001_studioHDRI.hdr_Rig.png',
            'textures/cubemap/001_studioHDRI.hdr_Lef.png',
            'textures/cubemap/001_studioHDRI.hdr_Top.png',
            'textures/cubemap/001_studioHDRI.hdr_Bot.png',
            'textures/cubemap/001_studioHDRI.hdr_Fro.png',
            'textures/cubemap/001_studioHDRI.hdr_Bak.png',
          ],
          (cube) => {
            this.baseMaterial.envMap = cube;
          },
          undefined,
          function(error) {
            console.error(error);
          },
        );
      }

      this.setupModel();
    },
    clearScene() {
      if (this.scene !== undefined && this.scene !== null) {
        this.scene.clear();
        this.renderer.render(this.scene, this.camera);
      }
    },
    setupLighting() {
      const directionalLight = new Three.DirectionalLight(0xffffff, 1.0 * 1.5);
      directionalLight.position.x = -0.375;
      directionalLight.position.y = 1.375;
      directionalLight.position.z = 2.0;
      this.scene.add(directionalLight);

      const light = new Three.AmbientLight(0x202020); // soft white light
      this.scene.add(light);
    },
    setupModel() {
      this.setupLighting();
      this.allLoaded = false;
      this.allLoadStarted = false;
      this.loadCount = 0;
      this.loadCountTotal = 0;

      this.group = new Three.Group();
      this.group.rotation.y = -Math.PI / 8;
      this.group.rotation.x = Math.PI / 16;
      this.group.position.y = -1.0;
      this.scene.add(this.group);

      if (this.portrait) {
        this.camera.position.z = 0.7;
        this.camera.position.y = 0.65;
        this.group.rotation.y = Math.PI / 8;
      }

      const gender = this.character.race % 2 === 1 ? 'female' : 'male';

      this.modelLoader = new FBXLoader();
      this.modelLoader.setPath('models/characters/' + gender + '/');
      this.textureLoader = new Three.TextureLoader();
      this.textureLoader.setPath('textures/characters/');

      this.loadCountTotal++;
      this.modelLoader.load(
        'body/Body_' + gender + '.FBX',
        (model) => {
          transformModel(model);
          this.body = model;
          this.group.add(model);

          const bodyMaterial = this.baseMaterial.clone();
          bodyMaterial.metalness = 0.0;
          // BODY ALBEDO/COLOR MAP
          this.loadCountTotal++;
          this.textureLoader.load(
            'body/Body_' + gender + '_Albedo.png',
            (texture) => {
              bodyMaterial.map = texture;
              this.loadingProgress();
            },
            undefined,
            function(error) {
              console.error(error);
            },
          );
          // BODY NORMAL MAP
          this.loadCountTotal++;
          this.textureLoader.load(
            'body/Body_' + gender + '_Normal.png',
            (texture) => {
              bodyMaterial.normalMap = texture;
              this.loadingProgress();
            },
            undefined,
            function(error) {
              console.error(error);
            },
          );

          const headMaterial = this.baseMaterial.clone();
          headMaterial.metalness = 0.0;
          // HEAD ALBEDO/COLOR MAP
          this.loadCountTotal++;
          this.textureLoader.load(
            'body/Head_' + gender + '_Albedo.png',
            (texture) => {
              headMaterial.map = texture;
              this.loadingProgress();
            },
            undefined,
            function(error) {
              console.error(error);
            },
          );
          // HEAD NORMAL MAP
          this.loadCountTotal++;
          this.textureLoader.load(
            'body/Head_' + gender + '_Normal.png',
            (texture) => {
              headMaterial.normalMap = texture;
              this.loadingProgress();
            },
            undefined,
            function(error) {
              console.error(error);
            },
          );

          const eyebrowMaterial = new Three.MeshBasicMaterial();
          eyebrowMaterial.color = new Three.Color(0x583a25);
          eyebrowMaterial.opacity = 0.825;
          eyebrowMaterial.transparent = true;
          const eyeMaterial = new Three.MeshBasicMaterial();
          eyeMaterial.color = new Three.Color(0x000000);
          const bodyMats = [
            bodyMaterial,
            headMaterial,
            null, //mouth
            eyebrowMaterial, //eyebrow
            eyeMaterial /*,//eye
          null*/, //eyereflection
          ];
          this.body.traverse((child) => {
            if (child.isMesh) {
              child.material = bodyMats;
            }
          });

          this.loadingProgress();
        },
        undefined,
        function(error) {
          console.error(error);
        },
      );

      // head
      for (let i = 0; i < heads[this.character.head % headCount].length; i++) {
        if (prefabs[heads[this.character.head % headCount][i]] === undefined || prefabs[heads[this.character.head % headCount][i]] === null)
          console.error('missing prefab: ' + heads[this.character.head % headCount][i]);
        this.loadModel(prefabs[heads[this.character.head % headCount][i]]);
      }
      // arms
      for (let i = 0; i < arms[this.character.arms % armsCount].length; i++) {
        if (prefabs[arms[this.character.arms % armsCount][i]] === undefined || prefabs[arms[this.character.arms % armsCount][i]] === null)
          console.error('missing prefab: ' + arms[this.character.arms % armsCount][i]);
        this.loadModel(prefabs[arms[this.character.arms % armsCount][i]]);
      }
      // torso
      for (let i = 0; i < torsos[this.character.torso % torsoCount].length; i++) {
        if (prefabs[torsos[this.character.torso % torsoCount][i]] === undefined || prefabs[torsos[this.character.torso % torsoCount][i]] === null)
          console.error('missing prefab: ' + torsos[this.character.torso % torsoCount][i]);
        this.loadModel(prefabs[torsos[this.character.torso % torsoCount][i]]);
      }
      // legs
      for (let i = 0; i < legs[this.character.legs % legsCount].length; i++) {
        if (prefabs[legs[this.character.legs % legsCount][i]] === undefined || prefabs[legs[this.character.legs % legsCount][i]] === null)
          console.error('missing prefab: ' + legs[this.character.legs % legsCount][i]);
        this.loadModel(prefabs[legs[this.character.legs % legsCount][i]]);
      }
      // boots
      for (let i = 0; i < boots[this.character.boots % bootsCount].length; i++) {
        if (prefabs[boots[this.character.boots % bootsCount][i]] === undefined || prefabs[boots[this.character.boots % bootsCount][i]] === null)
          console.error('missing prefab: ' + boots[this.character.boots % bootsCount][i]);
        this.loadModel(prefabs[boots[this.character.boots % bootsCount][i]]);
      }

      this.allLoadStarted = true;
    },
    loadModel(modelData) {
      let modelPath = modelData.model;

      if ((modelPath === undefined || modelPath === null) && this.character.race % 2 === 1) {
        if (modelData.femaleModel !== undefined && modelData.femaleModel !== null) modelPath = modelData.femaleModel;
        else return;
      }

      if ((modelPath === undefined || modelPath === null) && this.character.race % 2 === 0) {
        if (modelData.maleModel !== undefined && modelData.maleModel !== null) modelPath = modelData.maleModel;
        else return;
      }

      this.loadCountTotal++;

      this.modelLoader.load(
        modelPath,
        (model) => {
          transformModel(model);
          const modelMaterial = this.baseMaterial.clone();
          if (modelPath.includes('fur') || modelPath.includes('Fur') || modelPath.includes('hair') || modelPath.includes('Hair')) {
            modelMaterial.transparent = true;
            modelMaterial.side = Three.DoubleSide;
          }

          model.traverse((child) => {
            if (child.isMesh) {
              child.material = modelMaterial;
            }
          });

          // COLOR VALUE
          if (modelData.color !== null && modelData.color !== undefined) {
            const colorString = '#' + modelData.color.substring(0, 6);
            modelMaterial.color = new Three.Color(colorString);
          }

          // ALBEDO/COLOR MAP
          if (modelData.albedo !== null && modelData.albedo !== undefined) {
            this.loadCountTotal++;
            this.textureLoader.load(
              modelData.albedo,
              (texture) => {
                modelMaterial.map = texture;
                this.loadingProgress();
              },
              undefined,
              function(error) {
                console.error('ALBEDO TEXTURE ' + modelData.albedo + ' : ' + error);
              },
            );
          }

          // NORMAL MAP
          if (modelData.normal !== null && modelData.normal !== undefined) {
            this.loadCountTotal++;
            this.textureLoader.load(
              modelData.normal,
              (texture) => {
                modelMaterial.normalMap = texture;
                this.loadingProgress();
              },
              undefined,
              function(error) {
                console.error('NORMAL TEXTURE ' + modelData.normal + ' : ' + error);
              },
            );
          }

          // AO MAP
          if (modelData.ao !== null && modelData.ao !== undefined) {
            this.loadCountTotal++;
            this.textureLoader.load(
              modelData.ao,
              (texture) => {
                modelMaterial.aoMap = texture;
                this.loadingProgress();
              },
              undefined,
              function(error) {
                console.error('AO TEXTURE ' + modelData.ao + ' : ' + error);
              },
            );
          }

          // METALLIC/ROUGHNESS MAP
          if (modelData.spec !== null && modelData.spec !== undefined) {
            this.loadCountTotal++;
            this.textureLoader.load(
              modelData.spec,
              (texture) => {
                modelMaterial.roughnessMap = texture;
                modelMaterial.metalnessMap = texture;
                this.loadingProgress();
              },
              undefined,
              function(error) {
                console.error('SPEC TEXTURE ' + modelData.spec + ' : ' + error);
              },
            );
          }

          this.group.add(model);
          this.loadingProgress();
        },
        undefined,
        function(error) {
          console.error('MODEL ' + modelData.model + ' / ' + modelData.maleModel + ' / ' + modelData.femaleModel + ' : ' + error);
          console.error('MODELDATA: ' + modelData);
        },
      );
    },
    loadingProgress() {
      if (++this.loadCount >= this.loadCountTotal && this.allLoadStarted) {
        this.loadingFinished();
      }
    },
    loadingFinished() {
      this.renderer.render(this.scene, this.camera);
      this.allLoaded = true;
    },
    animate() {
      requestAnimationFrame(this.animate);
      if (this.allLoaded) {
        this.group.rotation.y += 0.02;
        this.renderer.render(this.scene, this.camera);
      }
    },

    async fetchScore() {
      /*
      try {
        const scoreData = await fetch(`https://api.cryptoblades.io/static/character/score/${this.character.id}`);
        const { score } = await scoreData.json();
        this.heroScore = score;
      } catch {
        console.error(`Could not fetch score for ID ${this.character.id}`);
      }
      */
    }
  },
  mounted() {
    this.fetchScore();

    if(localStorage.getItem('useGraphics') === 'false') {
      this.allLoaded = true;
      this.showPlaceholder = true;
      return;
    }

    this.init();
    //this.animate();
  },
};
</script>

<style scoped>
.character-art {
  width: 100%;
  height: 100%;
  position: relative;
  display: flex;
  justify-content: center;
  flex-direction: column;
}

.xp {
  position: absolute;
}

.trait {
  top: -30px;
  justify-self: center;
  margin: 0 auto;
  position: relative;
  display: flex;
}

.id {
  top: 5px;
  right: 5px;
  font-style: italic;
}

.hero-score {
  top: 25px;
  right: 5px;
  font-style: italic;
}

.name {
  font-weight: 900;
  overflow: hidden;
  max-height: 24px;
  max-width: 170px;
  white-space: nowrap;
}

.xp {
  bottom: -30px;
  left: 30px;
  width: 150px;
  right: 0;
}

.xp-text {
  padding-top: 7px;
  width: 100%;
  text-align: center;
  position: absolute;
}

.placeholder {
  max-width: 100%;
  top: -15px;
  position: relative;
  height: 75%;
  padding-top: 0;
  -o-object-fit: contain;
  object-fit: contain;
}

.placeholder div{
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
}

.circle-element {
  width: 1.7em;
  height: 1.7em;
  border-radius: 50%;
}

.name-lvl-container, .score-id-container {
  display :flex;
  justify-content: space-around;
  position: relative;
}

.white {
  color : rgb(204, 204, 204)
}

.small-stamina-char {
  position: relative;
  margin-top: -10px;
  top: 7px;
  align-self: center;
  height :14px;
  width: 180px;
  border-radius: 2px;
  border: 0.5px solid rgb(216, 215, 215);
  background : linear-gradient(to right, rgb(236, 75, 75) var(--staminaReady), rgba(255, 255, 255, 0.1) 0);
}

.stamina-text {
  position: relative;
  top: -3px;
  font-size: 75%;
  left: 0;
  right: 0;
  text-align: center;
  color: #fff;
}
</style>
