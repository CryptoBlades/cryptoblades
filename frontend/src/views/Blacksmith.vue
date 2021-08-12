<template>
  <div class="body main-font">
    <b-tabs justified>
      <b-tab title="Weapons">
        <div class="blank-slate" v-if="ownWeapons.length === 0">
          You do not currently have any weapons.
          <br>
          You can forge one by clicking the button below.
          <br>
          <br>
          <big-button
            class="button"
            :mainText="`Forge sword for ${forgeCost} SKILL`"
            @click="onForgeWeapon"
          />
        </div>
        <div class="row mt-3" v-if="ownWeapons.length > 0">
          <div class="col">
            <div class="d-flex justify-content-space-between">
              <h1>Weapons ({{ ownWeapons.length }})</h1>
              <div class="d-flex justify-content-flex-end ml-auto">
                <b-button
                  variant="primary"
                  v-if="canRename()"
                  @click="openRenameWeapon"
                  tagname="rename_weapon"
                  v-tooltip="'Rename Weapon'">
                  Rename Weapon
                </b-button>
                <b-button
                        variant="primary"
                        class="ml-3"
                        v-if="reforgeWeaponId !== null && ownWeapons.length > 0"
                        @click="showReforge = true, showBlacksmith = false, showReforgeDust = false, showDustForge = false"
                        tagname="reforge_weapon"
                        v-tooltip="'Burn weapons to buff selected weapon'">
                  Reforge
                </b-button>
                <b-button
                        variant="primary"
                        class="ml-3"
                        v-if="reforgeWeaponId !== null && ownWeapons.length > 0"
                        @click="showReforge = true, showBlacksmith = false, showReforgeDust = true, showDustForge = false"
                        tagname="reforge_weapon"
                        v-tooltip="'Burn weapons to buff selected weapon'">
                  Reforge with Dust
                </b-button>
                <b-button
                        variant="primary"
                        class="ml-3"
                        @click="showReforge = true, showBlacksmith = false, showDustForge = true, showReforgeDust = false"
                        tagname="reforge_weapon"
                        v-tooltip="'Burn weapons to buff selected weapon'">
                  Create Dust
                </b-button>
                <b-button
                        variant="primary"
                        class="ml-3"
                        @click="onForgeWeapon"
                        :disabled="disableForge"
                        v-tooltip="'Forge new weapon'">
                  <span v-if="disableForge">Cooling forge...</span>
                  <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">Forge x1 ({{ forgeCost }} SKILL) <i class="fas fa-plus"></i></span>
                </b-button>
                <b-button
                        variant="primary"
                        class="ml-3"
                        @click="onForgeWeaponx10()"
                        :disabled="disableForge"
                        v-tooltip="'Forge new weapon'">
                  <span v-if="disableForge">Cooling forge...</span>
                  <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">x10 ({{ forgeCost*10 }} SKILL) <i class="fas fa-plus"></i></span>
                </b-button>

                <b-icon-question-circle class="centered-icon" scale="1.5"
                  v-on:click="onShowForgeDetails" v-tooltip.bottom="'Click for forge percentages'"/>

                <b-modal hide-footer ref="forge-details-modal" title="Forge Percentages">
                  <div>
                    5+ star @ 1% chance. Estimated cost {{Number.parseFloat(forgeCost * (1/0.01)).toFixed(2)}} SKILL.
                  </div>
                  <div>
                    4+ star @ 6% chance. Estimated cost {{Number.parseFloat(forgeCost * (1/0.06)).toFixed(2)}} SKILL.
                  </div>
                  <div>
                    3+ star @ 21% chance. Estimated cost {{Number.parseFloat(forgeCost * (1/0.21)).toFixed(2)}} SKILL.
                  </div>
                  <div>
                    2+ star @ 56% chance. Estimated cost {{Number.parseFloat(forgeCost * (1/0.56)).toFixed(2)}} SKILL.
                  </div>
                  <div>
                    1+ star @ 100% chance.
                  </div>
                </b-modal>

                <b-modal size="xl" class="centered-modal " ref="new-weapons" ok-only>
                  <template #modal-header>
                    <div v-if="!spin" class="new-weapon-header-text text-center">
                      <strong>A-hooooy! These things look shurpppp!</strong>
                    </div>
                    <div v-if="spin" class="new-weapon-header-text text-center">
                      <strong>Be patient, the elves are minting ....</strong>
                    </div>
                  </template>
                  <div class="text-center">
                    <b-spinner v-if="spin" type="grow" label="Loading..."></b-spinner>
                    <b-spinner v-if="spin" type="grow" label="Loading..."></b-spinner>
                    <b-spinner v-if="spin" type="grow" label="Loading..."></b-spinner>
                  </div>
                  <weapon-grid v-if="!spin" :showGivenWeaponIds="true" :weaponIds="newForged" :newWeapon="true"/>
                  <template #modal-footer></template>
                </b-modal>

                <b-modal class="centered-modal text-center" ref="reforge-confirmation-modal" title="Reforge Confirmation" @ok="onReforgeWeapon">
                  <div class="text-center" :hidden="burnWeaponId === null || !isWeaponRare()">
                    <b-icon icon="exclamation-circle" variant="danger" />
                    [WARNING] This is a rare weapon!
                  </div>
                  <div class="text-center" :hidden="burnWeaponId === null || !isWeaponReforged()">
                    <b-icon icon="exclamation-circle" variant="danger" />
                    [WARNING] This item has been previously reforged and only half of each bonus will carry over!
                  </div>
                  <div class="row">
                    <div class="headings">
                      <h2 class="text-center">Upgrade</h2>
                      <div class="weapon" v-if="reforgeWeaponId">
                        <div v-if="$slots.above || $scopedSlots.above">
                          <slot name="above" :weapon="getWeaponToUpgrade()"></slot>
                        </div>
                        <div class="weapon-icon-wrapper">
                          <weapon-icon v-if="getWeaponToUpgrade()" class="weapon-icon" :weapon="getWeaponToUpgrade()" />
                        </div>
                      </div>
                    </div>
                    <div class="headings">
                      <h2 class="text-center">Burn</h2>
                      <div class="weapon" v-if="burnWeaponId">
                        <div v-if="$slots.above || $scopedSlots.above">
                          <slot name="above" :weapon="getWeaponToBurn()"></slot>
                          <slot name="above"></slot>
                        </div>
                        <div class="weapon-icon-wrapper">
                          <weapon-icon v-if="getWeaponToBurn()" class="weapon-icon" :weapon="getWeaponToBurn()" />
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="text-center" v-text="'Are you sure you want to reforge with this weapon?'" />
                  <div class="text-center">
                    <b-icon icon="exclamation-circle" variant="danger" /> This process cannot be undone!
                  </div>
                </b-modal>

                <b-modal class="centered-modal text-center" ref="dustreforge-confirmation-modal"
                         title="Dust Reforge Confirmation" @ok="onReforgeWeaponWithDust">
                  <div class="row">
                    <div class="headings">
                      <h2 class="text-center">Upgrade</h2>
                      <div class="weapon" v-if="reforgeWeaponId">
                        <div v-if="$slots.above || $scopedSlots.above">
                          <slot name="above" :weapon="getWeaponToUpgrade()"></slot>
                        </div>
                        <div class="weapon-icon-wrapper">
                          <weapon-icon v-if="getWeaponToUpgrade()" class="weapon-icon" :weapon="getWeaponToUpgrade()" />
                        </div>
                      </div>
                    </div>
                  </div>
                  <br/>
                  <div class="text-center" v-text="'Are you sure you want to reforge this weapon using:'" />
                  <p class="text-center">
                    {{this.lesserDust}}: Lesser Dust
                    <br>
                    {{this.greaterDust}}: Greater Dust
                    <br>
                    {{this.powerfulDust}}: Powerful Dust
                  </p>
                  <div class="text-center">
                    <b-icon icon="exclamation-circle" variant="danger" /> This process cannot be undone!
                  </div>
                </b-modal>

                <b-modal class="centered-modal text-center" ref="dust-confirmation-modal" title="Reforge Confirmation" @ok="onBurnWeapon">
                  <div class="text-center" :hidden="burnWeaponId === null || !isWeaponRare()">
                    <b-icon icon="exclamation-circle" variant="danger" /> [WARNING] This is a rare weapon!
                  </div>
                  <div class="text-center" :hidden="burnWeaponId === null || !isWeaponReforged()">
                    <b-icon icon="exclamation-circle" variant="danger" /> [WARNING] This item has been previously reforged are you sure you want to destroy?
                  </div>
                  <div class="row">
                    <div class="headings">
                      <h2 class="text-center">Burn to Dust</h2>
                      <div class="weapon" v-if="burnWeaponId">
                        <div v-if="$slots.above || $scopedSlots.above">
                          <slot name="above" :weapon="getWeaponToBurn()"></slot>
                          <slot name="above"></slot>
                        </div>
                        <div class="weapon-icon-wrapper">
                          <weapon-icon v-if="getWeaponToBurn()" class="weapon-icon" :weapon="getWeaponToBurn()" />
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="text-center" v-text="'Are you sure you want to turn this weapon to dust?'" />
                  <div class="text-center">
                    <b-icon icon="exclamation-circle" variant="danger" /> This process cannot be undone!
                  </div>
                </b-modal>

                <b-modal class="centered-modal text-center" ref="mass-dust-confirmation-modal" title="Reforge Confirmation" @ok="onMassBurnWeapons">
                  <div class="text-center" :hidden="burnWeaponId === null || !isWeaponRare()">
                    <b-icon icon="exclamation-circle" variant="danger" /> [WARNING] This is a rare weapon!
                  </div>
                  <div class="text-center" :hidden="burnWeaponId === null || !isWeaponReforged()">
                    <b-icon icon="exclamation-circle" variant="danger" /> [WARNING] This item has been previously reforged are you sure you want to destroy?
                  </div>
                  <div class="text-center" v-text="'Are you sure you want to turn all these weapons into dust?'" />
                  <div class="text-center">
                    <b-icon icon="exclamation-circle" variant="danger" /> This process cannot be undone! No Refunds!
                  </div>
                </b-modal>

                <b-modal class="centered-text-modal" ref="reforge-bonuses-modal" title="Reforge Bonuses">
                  <div>
                    5* Burn: 1 5B (75 Bonus Power / 600 Max).
                  </div>
                  <div>
                    4* Burn: 1 4B (30 Bonus Power/ 750 Max).
                  </div>
                  <div>
                    3* Burn: 3 LB (45 Bonus Power/ 1500 Max).
                  </div>
                  <div>
                    2* Burn: 2 LB (30 Bonus Power/ 1500 Max).
                  </div>
                  <div>
                    1* Burn: 1 LB (15 Bonus Power/ 1500 Max).
                  </div>
                </b-modal>
              </div>
            </div>
            <div class="" v-if="showBlacksmith">
              <weapon-grid v-model="reforgeWeaponId" />
            </div>
          </div>

          <div class="col-md-12" v-if="showReforge && showReforgeDust === true">
            <div>
              <div class="col-lg-12 weapon-container">
                <div class="col-lg-12">
                  <h1 class="text-center">Select the amount of dust you want to use to reforge this weapon!</h1>
                </div>
                <div class="row">
                  <div class="col-lg-2"></div>
                  <div class="col-lg-2 dust-container" align="center">
                    <div class="dust">
                      LB: <span class="text-warning">15</span>
                      <div class="dust-image1"></div>
                    </div>
                    <h2 class="text-center">Lesser</h2>
                    <div class="boxed">
                      <h2>{{this.getOwnedDust().slice(0, 1).shift()}}</h2>
                    </div>
                    <div class="range">
                      <div class="sliderValue">
                        <span>100</span>
                      </div>
                      <div class="field">
                        <div class="value left">0</div>
                        <input id="myRange" type="range" min="0" max="100" value="0" steps="1">
                        <div class="value right">100</div>
                      </div>
                    </div>
                  </div>
                  <div class="col-lg-2 dust-container" align="center">
                    <div class="dust">
                      4B: <span class="text-warning">30</span>
                      <div class="dust-image2"></div>
                    </div>
                    <h2 class="text-center">Greater</h2>
                    <div class="boxed">
                      <h2>{{this.getOwnedDust().slice(1, 2).shift()}}</h2>
                    </div>
                    <div class="range">
                      <div class="sliderValue">
                        <span>100</span>
                      </div>
                      <div class="field">
                        <div class="value left">0</div>
                        <input id="myRange2" type="range" min="0" max="25" value="0" steps="1">
                        <div class="value right">25</div>
                      </div>
                      <b-button
                              variant="primary"
                              tagname="confirm_forge_weapon"
                              class="confirmReforge"
                              @click="useDust()"
                              v-tooltip="'Update dust used'">
                        Press to update the amount of dust used.
                      </b-button>
                    </div>
                  </div>
                  <div class="col-lg-2 weapon-container dust-container" align="center">
                    <div class="dust">
                      5B: <span class="text-warning">75</span>
                      <div class="dust-image3"></div>
                    </div>
                    <h2 class="text-center">Powerful</h2>
                    <div class="boxed">
                      <h2>{{this.getOwnedDust().slice(2, 3).shift()}}</h2>
                    </div>
                    <div class="range">
                      <div class="sliderValue">
                        <span>0</span>
                      </div>
                      <div class="field">
                        <div class="value left">0</div>
                        <input id="myRange3" type="range" min="0" max="15" value="0" steps="1">
                        <div class="value right">15</div>
                      </div>
                    </div>
                  </div>
                  <div class="col-lg-3">
                    <div v-if="showReforge && showDustForge === false">
                      <div class="confirmReforge">
                        <div class="weapon" :hidden="reforgeWeaponId === null">
                          <div v-if="$slots.above || $scopedSlots.above">
                            <slot name="above" :weapon="getWeaponToUpgrade()"></slot>
                          </div>
                          <div class="weapon-icon-wrapper">
                            <weapon-icon v-if="getWeaponToUpgrade()" class="weapon-icon" :weapon="getWeaponToUpgrade()" />
                          </div>
                          <div class="text-center" :hidden="burnWeaponId === 0"></div>
                        </div>
                        <b-button
                                variant="primary"
                                tagname="confirm_forge_weapon"
                                class="confirmReforge"
                                @click="showDustReforgeConfirmation"
                                v-tooltip="'Reforge selected weapon with dust'">
                          Confirm Reforge
                          <br>
                          Use: {{this.lesserDust}} Lesser
                          <br>
                          Use: {{this.greaterDust}} Greater
                          <br>
                          Use:{{this.powerfulDust}} Powerful
                          <br>
                          ({{ dustReforgeCost }} SKILL)
                        </b-button>
                        <b-button
                                variant="primary"
                                tagname="confirm_forge_weapon"
                                class="confirmReforge"
                                @click="showReforge = false, showBlacksmith = true"
                                v-tooltip="'Cancel Reforge'">
                          Cancel Reforge
                        </b-button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="col-md-12" v-if="showReforge && showReforgeDust === false">
            <div>
              <div class="col-lg-12">
                <div class="row mobile-flip">
                  <div class="col-lg-5 col-sm-12 weapon-container" align="center">
                    <h1 class="text-center">Select the weapon you wish to burn</h1>
                    <weapon-grid v-model="burnWeaponId" :ignore="reforgeWeaponId"
                             :showReforgedWeaponsDefVal="false" :showFavoriteWeaponsDefVal="false" :showFilters="false" />
                  </div>
                  <div class="col-lg-2 col-sm-12 weapon-container">
                    <div class="headings">
                        <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn()" class="weapon-icon" :weapon="getWeaponsToBurn()" />
                        </div>
                        <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn2()" class="weapon-icon" :weapon="getWeaponsToBurn2()" />
                        </div>
                          <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn3()" class="weapon-icon" :weapon="getWeaponsToBurn3()" />
                          </div>
                        <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn4()" class="weapon-icon" :weapon="getWeaponsToBurn4()" />
                        </div>
                        <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn5()" class="weapon-icon" :weapon="getWeaponsToBurn5()" />
                        </div>
                    </div>
                  </div>
                  <div class="col-lg-2 col-sm-12">
                    <div class="headings">
                        <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn6()" class="weapon-icon" :weapon="getWeaponsToBurn6()" />
                        </div>
                        <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn7()" class="weapon-icon" :weapon="getWeaponsToBurn7()" />
                        </div>
                        <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn8()" class="weapon-icon" :weapon="getWeaponsToBurn8()" />
                        </div>
                        <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn9()" class="weapon-icon" :weapon="getWeaponsToBurn9()" />
                        </div>
                        <div class="weapon-icon-wrapper weapon">
                          <weapon-icon v-if="getWeaponsToBurn10()" class="weapon-icon" :weapon="getWeaponsToBurn10()" />
                        </div>
                    </div>
                  </div>
                  <div class="col-lg-3 col-sm-12 upgrade-container">
                    <div v-if="showReforge && showDustForge === false">
                      <div class="confirmReforge">
                        <h2 class="text-center">Upgrade</h2>
                        <div class="weapon" :hidden="reforgeWeaponId === null">
                          <div v-if="$slots.above || $scopedSlots.above">
                        <slot name="above" :weapon="getWeaponToUpgrade()"></slot>
                          </div>
                          <div class="weapon-icon-wrapper">
                            <weapon-icon v-if="getWeaponToUpgrade()" class="weapon-icon" :weapon="getWeaponToUpgrade()" />
                          </div>
                          <div class="text-center" :hidden="burnWeaponId === 0"></div>
                        </div>
                        <b-button
                           variant="primary"
                           tagname="confirm_forge_weapon"
                           class="confirmReforge"
                           @click="showReforgeConfirmation"
                           :disabled="canReforge"
                           v-tooltip="'Reforge selected weapon'">
                          Confirm Reforge
                          <br>
                          ({{ reforgeCost }} SKILL)
                    </b-button>
                    <b-button
                       variant="primary"
                       tagname="confirm_forge_weapon"
                       class="confirmReforge"
                       @click="showReforgeBonuses"
                       v-tooltip="'Show reforge bonuses'">
                      Show Bonuses
                    </b-button>
                    <b-button
                      variant="primary"
                      tagname="confirm_forge_weapon"
                      class="confirmReforge"
                      @click="showReforge = false, showBlacksmith = true"
                      v-tooltip="'Cancel Reforge'">
                      Cancel Reforge
                    </b-button>
                  </div>
                </div>
                <div v-if="showReforge && showDustForge === true">
                  <div class="confirmReforge">
                    <h2 class="text-center">Create Dust</h2>
                    <div class="weapon" v-if="burnWeaponId">
                      <div v-if="$slots.above || $scopedSlots.above">
                        <slot name="above" :weapon="getWeaponToBurn()"></slot>
                        <slot name="above"></slot>
                      </div>
                      <div class="weapon-icon-wrapper">
                        <weapon-icon v-if="getWeaponToBurn()" class="weapon-icon" :weapon="getWeaponToBurn()" />
                      </div>
                    </div>
                    <b-button
                            variant="primary"
                            tagname="confirm_forge_weapon"
                            class="confirmReforge"
                            @click="showDustConfirmation"
                            v-tooltip="'Reforge selected weapon with dust'">
                            Create Dust
                            <br>
                            ({{ burnCost }} SKILL)
                    </b-button>
                    <b-button
                            variant="primary"
                            tagname="confirm_forge_weapon"
                            class="confirmReforge"
                            @click="showMassDustConfirmation"
                            v-tooltip="'Reforge selected weapon with dust'">
                      Mass Burn
                      <br>
                      ({{ burnCost }} SKILL per weapon)
                    </b-button>
                    <b-button
                            variant="primary"
                            tagname="confirm_forge_weapon"
                            class="confirmReforge"
                            @click="showReforge = false, showBlacksmith = true, showDustForge = false, showReforgeDust,false"
                            v-tooltip="'Cancel Reforge'">
                            Cancel
                    </b-button>
                    <b-button
                            variant="primary"
                            tagname="confirm_forge_weapon"
                            class="confirmReforge"
                            @click="getCurrentBurntWeapons()"
                            v-tooltip="'Update dust used'"
                            :disabled="burnWeaponId === null">
                            Add Weapon for multi-forging
                    </b-button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
      </b-tab>
      <b-tab>
        <template #title>
          Shields <b-icon-question-circle class="centered-icon" scale="0.8" v-tooltip.bottom="`You can buy shield in Skill shop tab in the market!`"/>
        </template>
        <div class="row mt-3">
          <div class="col">
            <div class="d-flex justify-content-space-between">
              <h1>Equipment ({{ nftsCount }})</h1>
            </div>
            <nft-list v-if="nftsCount > 0" v-model="selectedNft"/>
          </div>
        </div>
      </b-tab>
      <b-tab>
        <template #title>
          Dust Storage <b-icon-question-circle class="centered-icon" scale="0.8" v-tooltip.bottom="`Dust is gained by destroying weapons!`"/>
        </template>
        <dust-balance-display/>
      </b-tab>
    </b-tabs>
    <b-modal class="centered-modal" ref="weapon-rename-modal"
                  @ok="renameWeaponCall()">
                  <template #modal-title>
                    Rename Weapon
                  </template>
                  <b-form-input type="string"
                    class="modal-input" v-model="weaponRename" placeholder="New Name" />
      </b-modal>
  </div>
</template>

<script lang='ts'>
import BN from 'bignumber.js';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import BigButton from '../components/BigButton.vue';
import Vue from 'vue';
import { mapActions, mapGetters, mapState } from 'vuex';
import WeaponIcon from '../components/WeaponIcon.vue';
import { BModal } from 'bootstrap-vue';
import NftList from '@/components/smart/NftList.vue';
import { Contracts, IState } from '@/interfaces';
import { Accessors } from 'vue/types/options';
import DustBalanceDisplay from '@/components/smart/DustBalanceDisplay.vue';

type StoreMappedState = Pick<IState, 'defaultAccount'| 'ownedWeaponIds'>;

interface StoreMappedGetters {
  contracts: Contracts;
  ownWeapons: any[];
  nftsCount: number;
}

interface Data {
  showReforge: boolean;
  showBlacksmith: boolean,
  showDustForge: boolean,
  reforgeWeaponId: string | null;
  burnWeaponId: string | null;
  selectedNft: string | null;
  forgeCost: string;
  reforgeCost: string;
  dustReforgeCost: string,
  burnCost: string,
  disableForge: boolean;
  newForged: number[];
  currentListofWeapons: string[];
  spin: boolean;
  lesserDust: string,
  greaterDust: string,
  powerfulDust: string,
  dust: string[],
  allowDustForge: false,
  burnWeaponIds: any[],
  weaponRename: string;
  haveRename: string;
  onError: boolean;
}

export default Vue.extend({
  data() {
    return {
      showReforge: false,
      showBlacksmith: true,
      showDustForge: false,
      reforgeWeaponId: null,
      burnWeaponId: null,
      selectedNft: null,
      forgeCost: '0',
      reforgeCost: '0',
      dustReforgeCost: '0',
      burnCost: '0',
      disableForge: false,
      newForged: [],
      currentListofWeapons: [],
      spin: false,
      lesserDust: '0',
      greaterDust: '0',
      powerfulDust: '0',
      dust: [],
      allowDustForge: false,
      burnWeaponIds: [],
      weaponRename: '',
      haveRename: '0',
      onError: false,
    } as Data;
  },

  computed: {
    ...(mapState(['defaultAccount','ownedWeaponIds','ownedShieldIds']) as Accessors<StoreMappedState>),
    ...(mapGetters(['contracts', 'ownWeapons', 'nftsCount',  'ownShields', 'getOwnedDust']) as Accessors<StoreMappedGetters>),

    canReforge(): boolean {
      return (
        this.reforgeWeaponId === null ||
        this.burnWeaponId === null ||
        this.reforgeWeaponId === this.burnWeaponId
      );
    },
  },

  watch: {
    reforgeWeaponId() {
      this.showReforge = false;
      this.burnWeaponId = null;
    }
  },

  async created() {
    if(!this.contracts.CryptoBlades) return;
    const forgeCost = await this.contracts.CryptoBlades.methods.mintWeaponFee().call({ from: this.defaultAccount });
    const skillForgeCost = await this.contracts.CryptoBlades.methods.usdToSkill(forgeCost).call({ from: this.defaultAccount });
    this.forgeCost = new BN(skillForgeCost).div(new BN(10).pow(18)).toFixed(4);

    const reforgeCost = await this.contracts.CryptoBlades.methods.reforgeWeaponFee().call({ from: this.defaultAccount });
    const skillReforgeCost = await this.contracts.CryptoBlades.methods.usdToSkill(reforgeCost).call({ from: this.defaultAccount });
    this.reforgeCost = new BN(skillReforgeCost).div(new BN(10).pow(18)).toFixed(4);

    const reforgeDustCost = await this.contracts.CryptoBlades.methods.reforgeWeaponWithDustFee().call({ from: this.defaultAccount });
    const skillDustReforgeCost = await this.contracts.CryptoBlades.methods.usdToSkill(reforgeDustCost).call({ from: this.defaultAccount });
    this.dustReforgeCost = new BN(skillDustReforgeCost).div(new BN(10).pow(18)).toFixed(4);

    const burnCost = await this.contracts.CryptoBlades.methods.burnWeaponFee().call({ from: this.defaultAccount });
    const skillBurnCost = await this.contracts.CryptoBlades.methods.usdToSkill(burnCost).call({ from: this.defaultAccount });
    this.burnCost = new BN(skillBurnCost).div(new BN(10).pow(18)).toFixed(4);

    if(!this.contracts.WeaponRenameTagConsumables) return;
    this.haveRename = await this.contracts.WeaponRenameTagConsumables.methods.getItemCount().call({ from: this.defaultAccount });
  },

  methods: {
    ...mapActions(['mintWeapon', 'reforgeWeapon', 'mintWeaponN', 'renameWeapon',
      'fetchTotalWeaponRenameTags', 'burnWeapon', 'reforgeWeaponWithDust', 'massBurnWeapons']),

    async onForgeWeapon() {
      if(this.disableForge) return;

      const forgeMultiplier = 1;

      this.disableForge = true;
      // Incase the network or mm are having issues, after 1 min we reshow
      const failbackTimeout = setTimeout(() => {
        this.disableForge = false;
      }, 30000);

      try {
        await this.mintWeapon();

      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error('Could not forge sword: insuffucient funds or transaction denied.');
      } finally {
        clearTimeout(failbackTimeout);
        this.disableForge = false;
      }
      this.relayFunction(forgeMultiplier);
    },

    async onForgeWeaponx10(){
      if(this.disableForge) return;

      this.disableForge = true;
      const forgeMultiplier = 10;

      // Incase the network or mm are having issues, after 1 min we reshow
      const failbackTimeout = setTimeout(() => {
        this.disableForge = false;
      }, 30000);

      try {
        await this.mintWeaponN({num: forgeMultiplier});

      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error('Could not forge sword: insuffucient funds or transaction denied.');
      } finally {
        clearTimeout(failbackTimeout);
        this.disableForge = false;
      }
      this.relayFunction(forgeMultiplier);

    },

    relayFunction(offset: number){
      try{
        this.viewNewWeapons(offset);
      } catch (e) {
        console.error(e);
        this.onError = true;
      }
    },

    onShowForgeDetails() {
      (this.$refs['forge-details-modal'] as BModal).show();
    },

    showReforgeConfirmation() {
      (this.$refs['reforge-confirmation-modal'] as BModal).show();
    },

    showDustReforgeConfirmation() {
      (this.$refs['dustreforge-confirmation-modal'] as BModal).show();
    },

    showDustConfirmation() {
      (this.$refs['dust-confirmation-modal'] as BModal).show();
    },

    showMassDustConfirmation() {
      (this.$refs['mass-dust-confirmation-modal'] as BModal).show();
    },

    showReforgeBonuses() {
      (this.$refs['reforge-bonuses-modal']as BModal).show();
    },

    isWeaponRare() {
      const weapon = this.getWeaponToBurn();
      if(!weapon) return false;
      return weapon.stars >= 3;
    },

    isWeaponReforged() {
      const weapon = this.getWeaponToBurn();
      if(!weapon) return false;
      return weapon.bonusPower > 0;
    },

    getWeaponToBurn() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id === this.burnWeaponId);
    },

    getWeaponsToBurn() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(0, 1).shift());
    },
    getWeaponsToBurn2() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(1, 2).shift());
    },
    getWeaponsToBurn3() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(2, 3).shift());
    },
    getWeaponsToBurn4() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(3, 4).shift());
    },
    getWeaponsToBurn5() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(4, 5).shift());
    },
    getWeaponsToBurn6() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(5, 6).shift());
    },
    getWeaponsToBurn7() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(6, 7).shift());
    },
    getWeaponsToBurn8() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(7, 8).shift());
    },
    getWeaponsToBurn9() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(8, 9).shift());
    },
    getWeaponsToBurn10() {
      if(!this.burnWeaponId) return null;
      return this.ownWeapons.find(x => x.id ===  this.burnWeaponIds.slice(9, 10).shift());
    },
    getWeaponToUpgrade() {
      return this.ownWeapons.find(x => x.id === this.reforgeWeaponId);
    },

    useDust(){
      this.lesserDust = (document.getElementById('myRange')! as HTMLInputElement).value;
      this.greaterDust = (document.getElementById('myRange2')! as HTMLInputElement).value;
      this.powerfulDust = (document.getElementById('myRange3')! as HTMLInputElement).value;
    },

    getCurrentBurntWeapons(){
      let test = false;
      if (test === false) {
        this.burnWeaponIds.push(this.burnWeaponId);
        this.burnWeaponId = null;
        test = true;
      }
    },

    viewNewWeapons(offset: number){
      this.newForged = [];
      this.ownedWeaponIds.forEach(x => {
        this.newForged.push(x);
      });

      this.newForged.splice(0, this.ownedWeaponIds.length - offset + 1);


      // eslint-disable-next-line no-constant-condition
      if (this.newForged.length > 0 && !this.onError){
        this.spin = true;
        (this.$refs['new-weapons'] as BModal).show();

        setTimeout(() => {
          this.spin = false;
        }, 10000);
      }


    },

    async onReforgeWeapon() {
      try {
        await this.reforgeWeapon({
          burnWeaponId: this.burnWeaponId,
          reforgeWeaponId: this.reforgeWeaponId,
        });

        this.burnWeaponId = null;
      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error('Could not forge sword: insuffucient funds or transaction denied.');
      }
    },

    async onReforgeWeaponWithDust() {
      try {
        this.useDust();
        await this.reforgeWeaponWithDust({
          reforgeWeaponId: this.reforgeWeaponId,
          lesserDust: this.lesserDust,
          greaterDust: this.greaterDust,
          powerfulDust:this.powerfulDust
        });

        this.lesserDust = '0';
        this.greaterDust = '0';
        this.powerfulDust = '0';

      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error('Could not ReForge sword: insufficient funds / Dust or transaction denied.');
      }
    },

    async onBurnWeapon() {
      try {
        await this.burnWeapon({
          burnWeaponId: this.burnWeaponId,
        });
        this.burnWeaponId = null;
      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error('Could not burn sword: insufficient funds or transaction denied.');
      }
    },

    async onMassBurnWeapons() {
      try {
        await this.massBurnWeapons({
          burnWeaponIds: this.burnWeaponIds,
        });
        this.burnWeaponIds = [];
        this.burnWeaponId = null;
      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error('Could not burn sword: insufficient funds or transaction denied.');
      }
    },
    canRename() {
      return this.reforgeWeaponId !== null && +this.haveRename > 0;
    },
    openRenameWeapon() {
      (this.$refs['weapon-rename-modal'] as BModal).show();
    },
    async renameWeaponCall() {
      if(this.weaponRename === '' || this.reforgeWeaponId === null){
        return;
      }

      await this.renameWeapon({id: this.reforgeWeaponId, name: this.weaponRename});
      if(this.contracts.WeaponRenameTagConsumables) {
        this.haveRename = await this.contracts.WeaponRenameTagConsumables.methods.getItemCount().call({ from: this.defaultAccount });
      }
    }
  },

  components: {
    DustBalanceDisplay,
    WeaponGrid,
    BigButton,
    WeaponIcon,
    BModal,
    NftList,
  },
});
</script>

<style scoped>

.new-weapon-header-text{
   color: #9e8a57;
  font-size: 34px;
}

.weapon-container {
  border-right: 1px solid #9e8a57;
}

.confirmReforge{
  margin: 1em auto 2em;
  border-radius:0.15em;
  text-decoration:none;
  font-weight:400;
  text-align:center;
  width: 12em;
}
.confirmReforge:active{
  top:0.1em;
}

.weapon {
  min-height: 12em;
  max-height: 13em;
  border-style: dashed;
  border-color: #9e8a57;
  width: 12em;
  border-radius: 5px;
  cursor: pointer;
  margin-bottom: 2em;
}

.createDust {
  min-height: 12em;
  max-height: 13em;
  border-style: dashed;
  border-color: #9e8a57;
  width: 12em;
  border-radius: 5px;
  cursor: pointer;
  align-items :center;
}

.headings {
  min-height: 13em;
  min-width: 13em;
  max-height: 13em;
  max-width: 13em;
  border-radius:0.15em;
  box-sizing: border-box;
  font-weight:400;
  width: 13em;
  margin: 1em auto 2em;
}

.upgrade-container {
  border-top: 1px solid #9e8a57;
  border-left: 1px solid #9e8a57;
}

.centered-modal {
  display: inline-block;
}

.centered-text-modal {
  justify-content: center;
  text-align: center;
}

.centered-icon {
  align-self: center;
  margin-left: 5px;
}

@media (max-width: 1000px) {
  .mobile-flip{
    display: flex;
    flex-flow: column-reverse;
  }
}

</style>
