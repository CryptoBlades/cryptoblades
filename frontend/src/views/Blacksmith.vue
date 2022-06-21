<template>
  <div class="main-font blacksmith-page">
    <div class="blind-background position-absolute w-100 h-100 opacity-75"></div>
    <div class="mobile-menu">
      <span :class="activeTab == 'forge' ? 'active' : ''"
      @click="displayBlacksmith()"><span id="forge"></span> {{$t('blacksmith.forge').toUpperCase()}}</span>
      <span :class="activeTab == 'salvage' ? 'active' : ''"
      @click="displayDustCreation()"><span id="salvage"></span>{{$t('blacksmith.salvage').toUpperCase()}}</span>
    </div>
    <right-menu :activeTab="activeTab" :dusts="{lesser: lesser,greater: greater, powerful: powerful}"  :key="ctr" :showReforgeDust="showReforgeDust" />

    <!-- MODAL NEW UI -->
    <b-modal size="md" class="centered-modal" centered ref="confirm-reforge" hide-footer hide-header>
      <div class="header-close">
        <h4>{{$t('blacksmith.dustConfirm')}}</h4>
      </div>
      <div class="forge-content">
        <div>
          <span class="reforge-img" :style="`content:url('.${getWeaponArt(getWeaponToUpgrade())}')`"></span>
        </div>
          <div>
            <b-row class="power-rolled">
              <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
                <h5>{{$t('blacksmith.lb')}}</h5>
              </b-col>
              <b-col cols="4" lg="2" sm="4" md="4" class="win-details">
                <img src="../assets/arrow-right.png" alt="">
              </b-col>
              <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
                <h5>{{lesserDust}}</h5>
              </b-col>
            </b-row>
            <b-row class="power-rolled">
              <b-col cols="4"  lg="5" sm="4" md="4" class="win-details">
                <h5>{{$t('blacksmith.4b')}}</h5>
              </b-col>
              <b-col cols="4" lg="2" sm="4" md="4" class="win-details">
                <img src="../assets/arrow-right.png" alt="">
              </b-col>
              <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
                <h5>{{greaterDust}}</h5>
              </b-col>
            </b-row>
            <b-row class="power-rolled">
              <b-col cols="4"  lg="5" sm="4" md="4" class="win-details">
                <h5>{{$t('blacksmith.5b')}}</h5>
              </b-col>
              <b-col cols="4" lg="2" sm="4" md="4" class="win-details">
                <img src="../assets/arrow-right.png" alt="">
              </b-col>
              <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
                <h5>{{powerfulDust}}</h5>
              </b-col>
            </b-row>
         </div>
      </div>
      <div class="footer-btn mb-4">
        <div class="d-flex align-items-center info text-center">
          <b-icon icon="exclamation-circle" variant="danger" /> <span class="ml-2">{{$t('blacksmith.cantBeUndone')}}</span>
        </div>
        <button class="close-btn"  @click="onReforgeWeaponWithDust()">{{$t('blacksmith.confirm')}}</button>
      </div>
      <div class="footer-close" @click="$refs['confirm-reforge'].hide()">
        <p class="tapAny mt-4">{{$t('blacksmith.tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>


    <b-modal ref="succesful-reforge" class="centered-modal" centered hide-footer hide-header @hide="clearDust">
      <div class="forge-header" v-if="modalType == 'successReforge'">
        <h3>{{$t('blacksmith.reforgeSucces')}}</h3>
      </div>
      <div class="forge-content">
          <div>
            <span class="reforge-img" :style="`content:url('.${getWeaponArt(getWeaponToUpgrade())}')`"></span>
          </div>
          <div>
            <b-row class="power-rolled">
              <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
                <h5>{{$t('blacksmith.lb')}}</h5>
              </b-col>
              <b-col cols="4" lg="2" sm="4" md="4" class="win-details">
                <img src="../assets/arrow-right.png" alt="">
              </b-col>
              <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
                <h5>{{lesserDust}}</h5>
              </b-col>
            </b-row>
            <b-row class="power-rolled">
              <b-col cols="4"  lg="5" sm="4" md="4" class="win-details">
                <h5>{{$t('blacksmith.4b')}}</h5>
              </b-col>
              <b-col cols="4" lg="2" sm="4" md="4" class="win-details">
                <img src="../assets/arrow-right.png" alt="">
              </b-col>
              <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
                <h5>{{greaterDust}}</h5>
              </b-col>
            </b-row>
             <b-row class="power-rolled">
              <b-col cols="4"  lg="5" sm="4" md="4" class="win-details">
                <h5>{{$t('blacksmith.5b')}}</h5>
              </b-col>
              <b-col cols="4" lg="2" sm="4" md="4" class="win-details">
                <img src="../assets/arrow-right.png" alt="">
              </b-col>
              <b-col cols="4" lg="5" sm="4" md="4" class="win-details">
                <h5>{{powerfulDust}}</h5>
              </b-col>
            </b-row>
            <b-row class="power-rolled" v-if="modalType == 'successReforge'">
              <b-col cols="12"  lg="12" sm="12" md="12" class="win-details reforge-bonus">
                <h5>{{$t('blacksmith.bonusOfReforge')}}: {{getWeaponInfo('bonusPower')}}
                <span>(<b-icon icon="caret-up-fill" variant="danger" />{{ totalBonusPower}})</span></h5>
              </b-col>
            </b-row>
          </div>
      </div>
      <div class="footer-btn mb-4" v-if="modalType == 'successReforge'">
        <button class="close-btn"   @click="closeModal('succesful-reforge')">{{$t('blacksmith.confirm')}}</button>
      </div>
      <div class="footer-close" @click="$refs['succesful-reforge'].hide()">
        <p class="tapAny mt-4">{{$t('blacksmith.tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>

    <Transition name="slide-fade">
      <div class="forging-modal" v-if="showModal" v-on:click.self="closeModal()">
        <div class="forge-loading" v-if="spin && modalType == 'forge'">
          <div class="row new-weapons">
            <h3>{{$t('blacksmith.forging')}}</h3>
          </div>
          <div class="forging">
            <div class="spinning-box">
              <div class="inner-spin"></div>
              <div class="diamond-box"></div>
              <span class="hammer-loading"></span>
            </div>
          </div>
        </div>
      </div>
    </Transition>
    <div class="blacksmith-content">
      <blacksmith-nav
        class="none-mobile"
        :isLoading="isLoading"
        :disableForge="disableForge"
        :disableX10ForgeWithStaked="disableX10ForgeWithStaked"
        :disableUseStakedForForge="disableUseStakedForForge"
        @onClickForge="onClickForge"
        @onClickSpecialForge="onClickSpecialForge"
        @setStakedForForgeValue="setStakedForForgeValue"
        @toggle="activeTab = $event"
        @onShowForgeDetails="onShowForgeDetails"
        @displayDustReforge="displayDustReforge()"
        :activeTab="activeTab"
        :ownWeapons="ownWeapons"
        :reforgeWeaponId="reforgeWeaponId"
        v-bind:forgeCost="forgeCost"></blacksmith-nav>
      <b-modal hide-footer class="centered-modal" centered aria-label="" ref="forge-details-modal" :title="$t('blacksmith.forgePercentages')">
        <div>
          {{$t('blacksmith.forgePercentage.5star')}} {{Number.parseFloat(forgeCost * (1/0.01)).toFixed(2)}} SKILL.
        </div>
        <div>
          {{$t('blacksmith.forgePercentage.4star')}} {{Number.parseFloat(forgeCost * (1/0.06)).toFixed(2)}} SKILL.
        </div>
        <div>
          {{$t('blacksmith.forgePercentage.3star')}} {{Number.parseFloat(forgeCost * (1/0.21)).toFixed(2)}} SKILL.
        </div>
        <div>
          {{$t('blacksmith.forgePercentage.2star')}} {{Number.parseFloat(forgeCost * (1/0.56)).toFixed(2)}} SKILL.
        </div>
        <div>
          {{$t('blacksmith.forgePercentage.1star')}}
        </div>
        <div class="footer-close" @click="$refs['forge-details-modal'].hide()">
          <p class="tapAny mt-4">{{$t('blacksmith.tapAnyWhere')}}</p>
          <p class="close-icon"></p>
        </div>
      </b-modal>

      <b-modal size="lg" class="centered-modal" centered hide-footer hide-header ref="new-forge-weapon">
        <div class="row new-weapons">
          <img src="../assets/header-line.png" alt="">
          <h3>{{$t('blacksmith.dwarvesForge')}}</h3>
        </div>
        <div class="weapon-list">
          <weapon-grid :showGivenWeaponIds="true" :weaponIds="newForged" :newWeapon="true" :noPagination="true"/>
        </div>
        <div class="footer-close" @click="$refs['new-forge-weapon'].hide()">
          <p class="tapAny mt-4">{{$t('blacksmith.tapAnyWhere')}}</p>
          <p class="close-icon"></p>
        </div>
      </b-modal>

      <b-modal class="centered-modal" centered size="lg" hide-footer hide-header ref="forge-element-selector-modal">
        <div class="row justify-content-center">
          <h4 class="select-el">{{$t('blacksmith.selectElement')}}</h4>
        </div>
        <div class="row justify-content-center select-elements-container" ref="forgeWeapon">
          <div id="random-border" v-on:click="setChosenElement($event, 100)"> </div>
          <div class="line-sep"></div>
          <div id="fire-border" v-on:click="setChosenElement($event, 0)"> </div>
          <div class="line-sep"></div>
          <div id="earth-border" v-on:click="setChosenElement($event, 1)"> </div>
          <div class="line-sep"></div>
          <div id="lightning-border" v-on:click="setChosenElement($event, 2)"> </div>
          <div class="line-sep"></div>
          <div id="water-border" v-on:click="setChosenElement($event, 3)"> </div>
        </div>
        <div v-if="activeSpecialWeaponEventsIds.length > 0"
          class="row justify-content-center select-elements-container align-items-baseline mt-4">
          <h5>{{$t('blacksmith.pickSpecialEvent')}}:</h5>
          <h6 class="mt-2">{{$t('blacksmith.specialEvent')}}:</h6>
          <b-form-select class="w-50 ml-1" size="sm" v-model="selectedSpecialWeaponEventId"
            :value="selectedSpecialWeaponEventId" @change="updateSpecialWeaponEventId($event)">
            <b-form-select-option v-for="id in activeSpecialWeaponEventsIds" :key="id" :value="id">
              {{specialWeaponEvents[id] && specialWeaponEvents[id].name}}
            </b-form-select-option>
          </b-form-select>
        </div>
        <div class="row justify-content-center align-items-baseline mt-4">
          <b-checkbox
            variant="primary"
            class="my-auto"
            v-model="mintSlippageApproved">
            <span><b>{{$t('blacksmith.approveMintSlippage')}}</b></span>
          </b-checkbox>
          <b-icon-question-circle class="centered-icon" v-tooltip.bottom="$t('blacksmith.mintSlippageDetails')"/>
        </div>
        <div class="row justify-content-center margin-top">
          <button
            v-if="clickedForgeButton === 0"
            variant="primary"
            class="row justify-content-center forge-btns"
            :class="disableConfirmButton ? 'disable-button' : ''"
            @click="onForgeWeapon(1)"
            :disabled="disableConfirmButton"
            v-tooltip="$t('blacksmith.forgeNew')">
              <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                {{$t('blacksmith.forge').toUpperCase()}}
              </span>
          </button>
          <b-icon-question-circle v-if="clickedForgeButton === 0"
            class="ml-4 centered-icon" v-tooltip.bottom="$t('blacksmith.dynamicPricesDetails',
              { increaseAmount: mintWeaponPriceIncrease, decreaseAmount: mintPriceDecreasePerHour, minimumPrice: mintWeaponMinPrice })"/>
          <button
            v-if="clickedForgeButton === 1"
            variant="primary"
            class="row justify-content-center forge-btns"
            :class="disableConfirmButton ? 'disable-button' : ''"
            @click="onForgeWeapon(10)"
            :disabled="disableConfirmButton"
            v-tooltip="$t('blacksmith.forge10New')">
            <span v-if="!disableForge" class="gtag-link-others" tagname="forge_weapon">
                {{$t('blacksmith.forge').toUpperCase()}}
              </span>
          </button>
          <b-icon-question-circle v-if="clickedForgeButton === 1"
            class="ml-4 centered-icon" v-tooltip.bottom="$t('blacksmith.dynamicPricesDetails',
              { increaseAmount: mintWeaponPriceIncrease, decreaseAmount: mintPriceDecreasePerHour, minimumPrice: mintWeaponMinPrice })"/>
        </div>
        <div class="footer-close" @click="$refs['forge-element-selector-modal'].hide()">
          <p class="tapAny mt-4">{{$t('blacksmith.tapAnyWhere')}}</p>
          <p class="close-icon"></p>
        </div>
      </b-modal>
    </div>
    <div class="bg-tint bg-dark"></div>
    <div class="weapon-body" v-if="$route.query.tab === 'weapon'">
        <div class="blank-slate" v-if="ownWeapons.length === 0">
          <span v-html="$t('blacksmith.noWeapons')"/>
          <br>
          <br>
          <big-button
            class="button"
            :mainText="$t('blacksmith.forgeSwordFor') + ` ${forgeCost} SKILL`"
            @click="onForgeWeapon(1)"
          />
        </div>
        <div class="mt-3" v-if="ownWeapons.length > 0 && !showReforge">
          <div style="padding-left: 0;" class="col-12">
            <div class="weapon-content" v-if="showBlacksmith">
              <weapon-grid :showNftOptions="true" :ownWeapons="ownWeapons.length" :noTitle="false" titleType="weapon-list" v-model="reforgeWeaponId" />
            </div>
          </div>
        </div>

      <!-- Reforge Dust Section -->
      <div style="margin: 0;" class="row mt-3" v-if="reforgeWeaponId && showReforge && showReforgeDust === true">
        <div class="col-lg-4 reforge-dust">
            <div class="magic-circle">
            <span class="inner" :class="magicCircleSpeed ? 'faster reverse' : 'slower reverse'"></span>
            <span class="outer" :class="magicCircleSpeed ? 'faster' : 'slower'"></span>
          </div>
          <span class="weapon-img" :style="`content:url('.${getWeaponArt(getWeaponToUpgrade())}')`"></span>
        </div>
        <div class="col-lg-8 weapon-menu">
          <div class="row">
            <div class="col-lg-12">
              <h2>{{getWeaponInfo('name')}}</h2>
              <div class="details">
                <span>
                  Battle Power:
                  <span>{{getWeaponInfo('stat2Value') + getWeaponInfo('stat1Value') + getWeaponInfo('stat3Value')}}</span>
                </span>
                <span>
                  Rarity:
                  <span>{{getWeaponInfo('rarity')}}</span>
                </span>
                <span>Element:
                  <span>{{getWeaponInfo('element')}}</span>
                </span>
              </div>

              <div class="power-status">
                <div v-if="getWeaponInfo('stat1Value') > 0">
                  <span :class="getWeaponInfo('stat1').toLowerCase() + '-icon'"></span>
                  <span>{{getWeaponInfo('stat1')}}</span>
                  <p>+{{getWeaponInfo('stat1Value')}}</p>
                </div>
                <div v-if="getWeaponInfo('stat2Value') > 0">
                  <span :class="getWeaponInfo('stat2').toLowerCase() + '-icon'"></span>
                  <span>{{getWeaponInfo('stat2')}}</span>
                  <p>+{{getWeaponInfo('stat2Value')}}</p>
                </div>
                <div v-if="getWeaponInfo('stat3Value') > 0">
                  <span :class="getWeaponInfo('stat3').toLowerCase() + '-icon'"></span>
                  <span>{{getWeaponInfo('stat3')}}</span>
                  <p>+{{getWeaponInfo('stat3Value')}}</p>
                </div>
              </div>
              <div class="row menus desktop">
                <div class="col-lg-3 col-sm-3 active-tab"> {{$t('blacksmith.reforge').toUpperCase()}} </div>
                <div class="col-lg-3 col-sm-3"> <span class="lock-icon"></span>{{$t('blacksmith.upgrade').toUpperCase()}}</div>
                <div class="col-lg-3 col-sm-3"> <span class="lock-icon"></span> {{$t('blacksmith.enchant').toUpperCase()}} </div>
                <div class="col-lg-3 col-sm-3"> <span class="lock-icon"></span> {{$t('blacksmith.skin')}} </div>
              </div>
              <div class="mobile">
                <div class="active-tab"> <span class="forge-icons"></span></div>
                <div> <span class="enchant-icons"></span></div>
                <div> <span class="skin-icons"></span></div>
                <div> <span class="upgrade-icons"></span></div>
              </div>
              <div class="desc-details">
                <span>
                  {{$t('blacksmith.reforgeNote')}}
                </span>
              </div>

              <!-- LB -->
              <div class="dust-gauge">
                <div>
                  <div class="dust-bg">
                    <span class="dust-img-lesser"></span>
                  </div>
                  <div>
                    <p class="p-0 m-0">(LB) {{$t('blacksmith.lb')}}</p>
                    <span>{{$t('blacksmith.15power')}}</span>
                  </div>
                </div>
                <div>
                  <input v-model="lesserDust" type="range" min="0" :max="getLesserDust()" value="0" steps="1">
                </div>
                <div>
                  <span>{{lesserDust}}/{{getLesserDust()}}</span>
                  <span class="cursor-p" @click="lesserDust = getLesserDust()">{{$t('blacksmith.max')}}</span>
                </div>
              </div>

              <!-- 4B -->
              <div class="dust-gauge">
                <div>
                  <div class="dust-bg">
                    <span class="dust-img-greater"></span>
                  </div>
                  <div>
                    <p class="p-0 m-0">(4B) {{$t('blacksmith.4b')}}</p>
                    <span>{{$t('blacksmith.30power')}}</span>
                  </div>
                </div>
                <div>
                  <input v-model="greaterDust" type="range" min="0" :max="getGreaterDust()" value="0" steps="1">
                </div>
                <div>
                  <span>{{greaterDust}}/{{getGreaterDust()}}</span>
                  <span class="cursor-p" @click="greaterDust = getGreaterDust()">{{$t('blacksmith.max')}}</span>
                </div>
              </div>

              <!-- 5B -->
              <div class="dust-gauge">
                <div>
                  <div class="dust-bg">
                    <span class="dust-img-powerful"></span>
                  </div>
                  <div>
                    <p class="p-0 m-0">(5B) {{$t('blacksmith.5b')}}</p>
                    <span>{{$t('blacksmith.75power')}}</span>
                  </div>
                </div>
                <div>
                  <input v-model="powerfulDust" type="range" min="0" :max="getPowerfulDust()" value="0" steps="1">
                </div>
                <div>
                  <span>{{powerfulDust}}/{{getPowerfulDust()}}</span>
                  <span class="cursor-p" @click="powerfulDust = getPowerfulDust()">{{$t('blacksmith.max')}}</span>
                </div>
              </div>
              <div class="btn-forge">
                <button class="ml-3 forge-btns"
                    tagname="confirm_forge_weapon"
                    :style="lesserDust == '0' && greaterDust == '0' && powerfulDust == '0' ? 'opacity:0.5' : 'opacity:1'"
                    :class="'confirmReforge'"
                    @click="showDustReforgeConfirmation"
                    :disabled="lesserDust == '0' && greaterDust == '0' && powerfulDust == '0'"
                    v-tooltip="$t('blacksmith.reforgeSelected')">
                    <span>{{$t('blacksmith.reforge').toUpperCase()}}</span>
                    <span>({{ dustReforgeCost }} SKILL)</span>
                </button>
                <div class="back-btn" @click="displayBlacksmith()">
                  <span class="menu-btn"></span>
                  <span class="text-uppercase">{{$t('blacksmith.changeEquipment')}}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div style="margin-right: 0" class="row mt-2" v-if="showReforge && showReforgeDust === false">
        <div class="col-md-9 col-xl-9 col-lg-7">
          <div class="weapon-content pr-0 pl-0">
            <weapon-grid v-model="burnWeaponId" :ignore="burnWeaponIds" :noTitle="false" titleType="burn-weapon"
                    :showGivenWeaponIds="true" :weaponIds="hideWeapons" @chooseweapon="addBurnWeapon" @selectAllWeapons="selectAllForBurn"
                    @currentFilteredWeapons="passFilteredItems"/>
          </div>
        </div>
        <div class="col-md-3 col-xl-3 col-lg-5 dust-area none-mobile">
          <div class="dust-content">
            <h4>{{$t('blacksmith.youWill').toUpperCase()}}</h4>
            <div class="create-dust flex-column">
              <div>
                <div class="dust-bg">
                  <span class="dust-img-powerful"></span>
                </div>
                <div>
                  <p class="p-0 m-0">{{$t('blacksmith.powerfulDust')}}</p>
                  <span> x{{powerful}}</span>
                </div>
              </div>
              <div>
                <div class="dust-bg">
                  <span class="dust-img-greater"></span>
                </div>
                <div>
                  <p class="p-0 m-0">{{$t('blacksmith.greaterDust')}}</p>
                  <span> x{{greater}}</span>
                </div>
              </div>
              <div>
                <div class="dust-bg">
                  <span class="dust-img-lesser"></span>
                </div>
                <div>
                  <p class="p-0 m-0">{{$t('blacksmith.lowerDust')}}</p>
                  <span> x{{lesser}}</span>
                </div>
              </div>
            </div>
            <div>
              <button class="forge-btns"
              @click="showMassDustConfirmation"
              >
                <span>{{$t('blacksmith.salvage').toUpperCase()}}</span>
                <span>({{(burnCost * burnWeaponIds.length).toFixed(4) }} SKILL)</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
      <b-col cols="12" v-if="$route.query.tab === 'equipment'">
        <div class="row equipment-body">
          <div class="col-xl-12 col-lg-12">
            <div class="d-flex justify-content-space-between">
              <h1>{{$t('equipment')}} ({{ nftsCount }})</h1>
            </div>
            <nft-list :showNftOptions="true" v-if="nftsCount > 0" v-model="selectedNft"/>
          </div>
        </div>
      </b-col>
      <b-col cols="12" v-if="$route.query.tab === 'dust'">
        <b-row class="dust-body">
          <dust-balance-display/>
        </b-row>
      </b-col>
      <b-col cols="12" v-if="$route.query.tab === 'land'">
        <div class="row mt-3 land-body">
          <div class="col-xl-12 col-lg-12">
            <nft-list :isLandTab="true" :showLimit="30" />
          </div>
        </div>
      </b-col>
    <b-modal centered class="centered-modal text-center" ref="dustreforge-confirmation-modal"
             :title="$t('blacksmith.dustReforgeConfirmation')" @ok="onReforgeWeaponWithDust">
      <div class="row">
        <div>
          {{$t('blacksmith.reforgeConfirmation')}}
        </div>
        <div class="headings">
          <h2 class="text-center">{{$t('blacksmith.upgrade')}}</h2>
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
      <div class="text-center" v-text="$t('blacksmith.reforgeConfirm')" />
      <p class="text-center">
        {{lesserDust}} {{$t('blacksmith.lesser')}} {{$t('blacksmith.dust')}}
        <br>
        {{greaterDust}} {{$t('blacksmith.greater')}} {{$t('blacksmith.dust')}}
        <br>
        {{powerfulDust}} {{$t('blacksmith.powerful')}} {{$t('blacksmith.dust')}}
      </p>
      <div class="text-center">
        <b-icon icon="exclamation-circle" variant="danger" /> {{$t('blacksmith.cantBeUndone')}}
      </div>
    </b-modal>

    <b-modal centered class="centered-modal text-center" size="lg" ref="mass-dust-confirmation-modal" hide-footer hide-header>
      <div class="dust-confirm">
        <h4>{{$t('blacksmith.createDustConfirm')}}</h4>
        <b-icon icon="exclamation-circle" variant="warning" />
        {{ $t('blacksmith.burnWarning', { weaponAmount: burnWeaponIds.length })}}
        {{ $t('blacksmith.cantBeUndone')}} <br>
        <b-icon icon="exclamation-circle" variant="warning" /> {{ $t('blacksmith.noRefunds')}}
        <button
          variant="primary"
          class="row justify-content-md-center forge-btns"
          @click="onMassBurnWeapons">
            <span v-if="!disableForge && !cooling" class="gtag-link-others" tagname="forge_weapon">
               {{$t('blacksmith.confirm')}} <br>
              <p class="dust-cost">({{burnCost * burnWeaponIds.length }} SKILL)</p>
            </span>
            <span v-if="!disableForge && cooling" class="gtag-link-others" tagname="forge_weapon">
               {{$t('blacksmith.loading')}}
            </span>
        </button>
      </div>
      <div class="footer-close" @click="$refs['mass-dust-confirmation-modal'].hide()">
        <p class="tapAny mt-4">{{$t('blacksmith.tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>

    <b-modal hide-footer hide-header class="centered-modal"
      centered aria-label="" ref="forge-details-modal">
      <h3 class="confirmation-title">{{$t('blacksmith.forgePercentages')}}</h3>
      <div>
        {{ $t('blacksmith.reforgeBonus.5star')}}
      </div>
      <div>
        {{ $t('blacksmith.reforgeBonus.4star')}}
      </div>
      <div>
        {{ $t('blacksmith.reforgeBonus.3star')}}
      </div>
      <div>
        {{ $t('blacksmith.reforgeBonus.2star')}}
      </div>
      <div>
        {{ $t('blacksmith.reforgeBonus.1star')}}
      </div>
      <div class="footer-close" @click="$refs['reforge-bonuses-modal'].hide()">
        <p class="tapAny mt-4">{{$t('blacksmith.tapAnyWhere')}}</p>
        <p class="close-icon"></p>
      </div>
    </b-modal>
    <SpecialWeaponForgeModal />
  </div>
</template>

<script lang='ts'>
import BN from 'bignumber.js';
import WeaponGrid from '../components/smart/WeaponGridNew.vue';
import RightMenu from '../components/RightMenu.vue';
import BigButton from '../components/BigButton.vue';
import { getWeaponArt } from '../weapon-arts-placeholder';
import { getWeaponRarity } from '../weapon-element';
import { getCleanName } from '../rename-censor';
import Vue from 'vue';
import { mapActions, mapGetters, mapMutations, mapState } from 'vuex';
import WeaponIcon from '../components/WeaponIconNew.vue';
import { BModal } from 'bootstrap-vue';
import NftList from '@/components/smart/NftList.vue';
import { Contracts, IState } from '@/interfaces';
import { ISpecialWeaponsManagerState } from '@/store/specialWeaponsManager';
import { Accessors } from 'vue/types/options';
import DustBalanceDisplay from '@/components/smart/DustBalanceDisplay.vue';
import { fromWeiEther, toBN } from '@/utils/common';
import i18n from '@/i18n';
import Events from '../events';
import SpecialWeaponForgeModal from '@/components/smart/SpecialWeaponForgeModal.vue';
import BlacksmithNav from '@/components/BlacksmithNav.vue';
type StoreMappedState = Pick<IState, 'defaultAccount' | 'ownedWeaponIds' | 'skillBalance' | 'inGameOnlyFunds' | 'skillRewards' >;

type StoreMappedSpecialWeaponsManagerState = Pick<ISpecialWeaponsManagerState, 'specialWeaponEvents' | 'activeSpecialWeaponEventsIds' | 'specialWeaponEventId'>;

interface StoreMappedGetters {
  contracts: Contracts;
  ownWeapons: any[];
  nftsCount: number;
}

interface Data {
  showReforge: boolean;
  showBlacksmith: boolean,
  showDustForge: boolean,
  showReforgeDust: boolean,
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
  selectedElement: number | null,
  chosenElementFee: number | null,
  clickedForgeButton: number | null,
  spin: boolean;
  lesserDust: string,
  greaterDust: string,
  powerfulDust: string,
  dust: string[],
  allowDustForge: false,
  burnWeaponIds: any[],
  onError: boolean;
  hideWeapons: any[];
  useStakedForForge: boolean;
  disableUseStakedForForge: boolean;
  disableX10ForgeWithStaked: boolean;
  forgeCostBN: BN;
  targetSkin: string;
  haveWeaponCosmetic1: number;
  haveWeaponCosmetic2: number;
  selectedSpecialWeaponEventId: number;
  showModal: boolean;
  modalType: string;
  magicCircleSpeed: boolean;
  totalBonusPower: number;
  lesser: number;
  greater: number;
  powerful: number;
  activeTab: string;
  ctr: number;
  updateInterval: ReturnType<typeof setInterval> | null;
  mintSlippageApproved: boolean;
  mintPriceDecreasePerHour: string;
  mintWeaponPriceIncrease: string;
  mintWeaponMinPrice: string;
  cooling: boolean;
  currentFilteredWeapons: any[];
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      showReforge: false,
      showBlacksmith: true,
      showDustForge: false,
      showReforgeDust: false,
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
      selectedElement: null,
      chosenElementFee: null,
      clickedForgeButton: null,
      spin: false,
      lesserDust: '0',
      greaterDust: '0',
      powerfulDust: '0',
      dust: [],
      allowDustForge: false,
      burnWeaponIds: [],
      onError: false,
      hideWeapons: [],
      useStakedForForge:false,
      disableUseStakedForForge: false,
      disableX10ForgeWithStaked: false,
      forgeCostBN: new BN(0),
      targetSkin: '',
      haveWeaponCosmetic1: 0,
      haveWeaponCosmetic2: 0,
      selectedSpecialWeaponEventId: 0,
      showModal: false,
      modalType: '',
      magicCircleSpeed: false,
      totalBonusPower: 0,
      lesser: 0,
      greater: 0,
      powerful: 0,
      activeTab: 'forge',
      ctr: 0,
      updateInterval: null as ReturnType<typeof setInterval> | null,
      mintSlippageApproved: false,
      mintPriceDecreasePerHour: '0',
      mintWeaponPriceIncrease: '0',
      mintWeaponMinPrice: '0',
      cooling: false,
      currentFilteredWeapons: [],
      isLoading: true
    } as Data;
  },

  computed: {
    ...mapState(['defaultAccount','ownedWeaponIds','ownedShieldIds','skillBalance', 'inGameOnlyFunds', 'skillRewards',
      'activeSpecialWeaponEventsIds', 'specialWeaponEvents', 'specialWeaponEventId']) as Accessors<StoreMappedState>,
    ...mapState('specialWeaponsManager',
      (['specialWeaponEvents', 'activeSpecialWeaponEventsIds','specialWeaponEventId'])) as Accessors<StoreMappedSpecialWeaponsManagerState>,
    ...(mapGetters([
      'contracts', 'ownWeapons', 'nftsCount', 'ownShields',
      'getPowerfulDust', 'getGreaterDust', 'getLesserDust',
    ]) as Accessors<StoreMappedGetters>),
    ...mapGetters([
      'getWeaponName'
    ]),
    ...(mapGetters('staking', ['stakedSkillBalanceThatCanBeSpent'])) as Accessors<{ stakedSkillBalanceThatCanBeSpent: BN }>,
    currentFilteredWeaponsIds(): string[] {
      return this.currentFilteredWeapons.map(w => w.id);
    },
    totalSkillBalance(): BN {
      console.log(toBN(fromWeiEther(this.skillRewards)).plus(toBN(fromWeiEther(this.inGameOnlyFunds))).plus(toBN(fromWeiEther(this.skillBalance))).toString());
      return toBN(fromWeiEther(this.skillRewards)).plus(toBN(fromWeiEther(this.inGameOnlyFunds))).plus(toBN(fromWeiEther(this.skillBalance)));
    },

    disableConfirmButton(): boolean {
      return this.selectedElement === null || !this.chosenElementFee ||
        this.totalSkillBalance.lt(this.forgeCostBN.times(this.chosenElementFee).times(this.clickedForgeButton ? 10 : 1));
    }
  },

  watch: {
    activeTab(data){
      if(data === 'forge'){
        this.displayBlacksmith();
      }else{
        this.displayDustCreation();
      }
    },
    currentFilteredWeapons(){
      const currentFilteredForBuringIds = this.currentFilteredWeaponsIds.filter(id => this.burnWeaponIds.includes(id));
      this.$root.$emit('select-all-button-labeler', currentFilteredForBuringIds.length > 0);
    },
    burnWeaponIds(data){
      const currentFilteredForBuringIds = this.currentFilteredWeaponsIds.filter(id => data.includes(id));
      this.$root.$emit('select-all-button-labeler', currentFilteredForBuringIds.length > 0);
    },
    reforgeWeaponId() {
      Events.$emit('hasSelected');
      this.showReforge = false;
      this.burnWeaponId = null;
    },
    stakedSkillBalanceThatCanBeSpent(){
      const stakedSkillBalanceThatCanBeSpentBN: BN = new BN(this.stakedSkillBalanceThatCanBeSpent).div(new BN(10).pow(18));

      if((stakedSkillBalanceThatCanBeSpentBN.minus(this.forgeCostBN.multipliedBy(0.8))).isLessThan(0)) {
        this.disableUseStakedForForge = true;
      }
      if((stakedSkillBalanceThatCanBeSpentBN.minus(this.forgeCostBN.multipliedBy(0.8).multipliedBy(10))).isLessThan(0)){
        this.disableX10ForgeWithStaked = true;
      }
    },
  },

  async created() {
    await this.fetchSpecialWeaponEvents();
    this.selectedSpecialWeaponEventId = +this.specialWeaponEventId;
    if(!this.contracts.CryptoBlades || !this.contracts.BurningManager) return;
    const stakedSkillBalanceThatCanBeSpentBN: BN = new BN(this.stakedSkillBalanceThatCanBeSpent).div(new BN(10).pow(18));

    if((stakedSkillBalanceThatCanBeSpentBN.minus(this.forgeCostBN.multipliedBy(0.8))).isLessThan(0)) {
      this.disableUseStakedForForge = true;
    }
    if((stakedSkillBalanceThatCanBeSpentBN.minus(this.forgeCostBN.multipliedBy(0.8).multipliedBy(10))).isLessThan(0)){
      this.disableX10ForgeWithStaked = true;
    }
    const reforgeCost = await this.contracts.BurningManager.methods.reforgeWeaponFee().call({ from: this.defaultAccount });
    const skillReforgeCost = await this.contracts.BurningManager.methods.usdToSkill(reforgeCost).call({ from: this.defaultAccount });
    this.reforgeCost = new BN(skillReforgeCost).div(new BN(10).pow(18)).toFixed(4);

    const reforgeDustCost = await this.contracts.BurningManager.methods.reforgeWeaponWithDustFee().call({ from: this.defaultAccount });
    const skillDustReforgeCost = await this.contracts.BurningManager.methods.usdToSkill(reforgeDustCost).call({ from: this.defaultAccount });
    this.dustReforgeCost = new BN(skillDustReforgeCost).div(new BN(10).pow(18)).toFixed(4);

    const burnCost = await this.contracts.BurningManager.methods.burnWeaponFee().call({ from: this.defaultAccount });
    const skillBurnCost = await this.contracts.BurningManager.methods.usdToSkill(burnCost).call({ from: this.defaultAccount });
    this.burnCost = new BN(skillBurnCost).div(new BN(10).pow(18)).toFixed(4);
    if(window.location.href.split('&').find(x => x === 'showSpecialForge')) {
      Events.$emit('show-special-forge-modal');
    }
    this.mintPriceDecreasePerHour = new BN(await this.fetchMintWeaponPriceDecreasePerSecond()).div(new BN(10).pow(18)).multipliedBy(60*60).toFixed(6);
    this.mintWeaponPriceIncrease = new BN(await this.fetchWeaponMintIncreasePrice()).div(new BN(10).pow(18)).toFixed(6);
    this.mintWeaponMinPrice = new BN(await this.fetchMintWeaponMinPrice()).div(new BN(10).pow(18)).toFixed(4);
  },

  destroyed() {
    if(this.updateInterval) {
      clearInterval(this.updateInterval);
    }
  },

  async mounted(){
    (this as any).$router.push({ path: 'blacksmith', query: { tab: 'weapon' }});
    await this.updateMintWeaponFee();
    this.updateInterval = setInterval(async () => { await this.updateMintWeaponFee(); }, 2000);
    Events.$on('forge-weapon', (id: number) =>{
      if(id === 0){
        this.onClickForge(id);
        (this.$refs['forge-element-selector-modal']as BModal).show();
      }else if(id === 1){
        this.onClickForge(id);
        (this.$refs['forge-element-selector-modal']as BModal).show();
      }else if(id === 2){
        Events.$emit('show-special-forge-modal');
      }else{
        this.displayDustReforge();
      }
    });

    Events.$on('create-dust', () =>{
      this.showMassDustConfirmation();
    });
  },

  methods: {
    ...mapActions(['mintWeapon', 'reforgeWeapon', 'mintWeaponN',
      'burnWeapon', 'massBurnWeapons',
      'reforgeWeaponWithDust', 'massBurnWeapons',
      'fetchMintWeaponPriceDecreasePerSecond', 'fetchWeaponMintIncreasePrice',
      'fetchMintWeaponMinPrice', 'fetchMintWeaponFee']),
    ...mapActions('specialWeaponsManager', ['fetchSpecialWeaponEvents']),
    ...mapMutations(['updateSpecialWeaponEventId']),
    setStakedForForgeValue(value: boolean){
      this.useStakedForForge = value;
    },
    passFilteredItems(data: any[]){
      this.currentFilteredWeapons = data;
    },
    toggleCheckbox() {
      this.useStakedForForge = !this.useStakedForForge;
      if (this.useStakedForForge) localStorage.setItem('useStakedForForge', 'true');
      else localStorage.setItem('useStakedForForge', 'false');
    },

    onClickSpecialForge() {
      Events.$emit('show-special-forge-modal');
    },

    getWeaponInfo(type: string): any{
      const weaponActive  = this.ownWeapons.find(x => x.id === this.reforgeWeaponId);
      this.totalBonusPower = Number(this.lesserDust) + Number(this.greaterDust) + Number(this.powerfulDust);

      if(type === 'name') return getCleanName(this.getWeaponName(weaponActive.id, weaponActive.stars));
      else if(type === 'rarity') return this.getWeaponRarity(weaponActive.stars);
      else if(type === 'element') return weaponActive.element;
      else if(type === 'stat1') return weaponActive.stat1;
      else if(type === 'stat1Type') return weaponActive.stat1Type;
      else if(type === 'stat1Value') return weaponActive.stat1Value;
      else if(type === 'stat2') return weaponActive.stat2;
      else if(type === 'stat2Type') return weaponActive.stat2Type;
      else if(type === 'stat2Value') return weaponActive.stat2Value;
      else if(type === 'stat3') return weaponActive.stat3;
      else if(type === 'stat3Type') return weaponActive.stat3Type;
      else if(type === 'stat3Value') return weaponActive.stat3Value;
      else if(type === 'bonusPower') return weaponActive.bonusPower;
    },

    async onForgeWeapon(amount: number) {
      this.disableForge = true;
      (this.$refs['forge-element-selector-modal']as BModal)?.hide();
      this.modalType = 'forge';
      this.showModal = true;
      this.spin = true;
      try {
        if(amount === 1){
          await this.mintWeapon({
            useStakedSkillOnly: this.useStakedForForge,
            chosenElement: this.selectedElement || 100,
            eventId: this.selectedSpecialWeaponEventId,
            mintSlippageApproved: this.mintSlippageApproved
          });
        }
        else{
          await await this.mintWeaponN({
            num: amount,
            useStakedSkillOnly: this.useStakedForForge,
            chosenElement: this.selectedElement,
            eventId: this.selectedSpecialWeaponEventId,
            mintSlippageApproved: this.mintSlippageApproved
          });
        }
        this.newForged = this.ownedWeaponIds.splice(this.ownedWeaponIds.length - amount, this.ownedWeaponIds.length);
        (this.$refs['new-forge-weapon'] as BModal).show();
      } catch (e) {
        console.log('Error while forging:', e);
        (this as any).$dialog.notify.error(i18n.t('blacksmith.couldNotForge'));
      } finally {
        this.disableForge = false;
        this.selectedElement = null;
        this.showModal = false;
        this.spin = false;
      }
    },

    computeDust(operator: string,star: number, lesser: number,greater: number,powerful: number){
      if(operator === 'add'){
        if(star <= 3) this.lesser = this.lesser + (star * 2);
        else if (star === 4) this.greater = this.greater + 2;
        else if (star === 5) this.powerful = this.powerful + 2;

        if(lesser > 0){
          this.lesser = this.lesser + Math.floor(lesser/2);
        }
        if(greater > 0){
          this.greater = this.greater + Math.floor(greater/2);
        }
        if(powerful > 0){
          this.powerful = this.powerful + Math.floor(powerful/2);
        }
      }else{
        if(star <= 3) this.lesser = this.lesser - (star * 2);
        else if (star === 4) this.greater = this.greater - 2;
        else if (star === 5) this.powerful = this.powerful - 2;

        if(lesser > 0){
          this.lesser = this.lesser - Math.floor(lesser/2);
        }
        if(greater > 0){
          this.greater = this.greater - Math.floor(greater/2);
        }
        if(powerful > 0){
          this.powerful = this.powerful - Math.floor(powerful/2);
        }
      }
    },

    onShowForgeDetails() {
      (this.$refs['forge-details-modal'] as BModal).show();
    },

    onClickForge(i: number) {
      if(+this.specialWeaponEventId === 0 && this.activeSpecialWeaponEventsIds.length > 0) {
        this.selectedSpecialWeaponEventId = +this.activeSpecialWeaponEventsIds[0];
      }
      else {
        this.selectedSpecialWeaponEventId = +this.specialWeaponEventId;
      }
      this.clickedForgeButton = i;
      this.chosenElementFee = null;
      (this.$refs['forge-element-selector-modal']as BModal).show();
    },

    setChosenElement(elementObject: any, selectedNumber: number) {
      if(selectedNumber === this.selectedElement) this.selectedElement = null;
      else this.selectedElement = selectedNumber;

      this.chosenElementFee = selectedNumber === 100 ? 1 : 2;
      elementObject.srcElement.classList.toggle('done');
      Array.from(elementObject.srcElement.parentNode.childNodes).forEach((child: any) => {
        if (child !== elementObject.srcElement && child.classList.contains('done') === true){
          child.classList.toggle('done');
        }
      });
    },

    showReforgeConfirmation() {
      (this.$refs['reforge-confirmation-modal'] as BModal).show();
    },

    showDustReforgeConfirmation() {
      if(this.lesserDust === '0' && this.greaterDust === '0' && this.powerfulDust === '0'){
        (this as any).$dialog.notify.error('No Dust Selected');
      }else{
        (this.$refs['confirm-reforge'] as BModal).show();
      }
    },

    showMassDustConfirmation() {
      (this.$refs['mass-dust-confirmation-modal'] as BModal).show();
    },

    displayDustReforge() {
      this.showReforge = true;
      this.showBlacksmith = false;
      this.showReforgeDust = true;
      this.showDustForge = false;
      this.lesserDust = '0';
      this.greaterDust = '0';
      this.powerfulDust = '0';
    },
    displayDustCreation(){
      this.activeTab = 'salvage';
      return this.showReforge = true,
      this.showBlacksmith = false,
      this.showDustForge = true,
      this.showReforgeDust = false,
      this.hideWeapons = this.ownedWeaponIds;
    },
    displayBlacksmith(){
      this.activeTab = 'forge';
      this.showReforge = false;
      this.showBlacksmith = true;
      this.showDustForge = false;
      this.showReforgeDust = false;
      this.lesser = 0;
      this.greater = 0;
      this.powerful = 0;
      this.burnWeaponIds = [];

    },
    cancelReforge() {
      this.showReforge = false;
      this.showBlacksmith = true;
      this.showDustForge = false;
      this.showReforgeDust = false;
      this.burnWeaponIds = [];
      this.hideWeapons = this.ownedWeaponIds;
      this.lesserDust = '0';
      this.greaterDust = '0';
      this.powerfulDust = '0';
    },
    clearAllMassBurn(){
      return this.burnWeaponIds = [],
      this.hideWeapons = this.ownedWeaponIds;
    },
    getWeaponToUpgrade() {
      if(this.reforgeWeaponId){
        return this.ownWeapons.find(x => x.id === this.reforgeWeaponId);
      }
    },

    selectAllForBurn(){
      const currentFilteredForBuringIds = this.currentFilteredWeaponsIds.filter(id => this.burnWeaponIds.includes(id));
      if(currentFilteredForBuringIds.length > 0){
        currentFilteredForBuringIds.forEach(id => {
          console.log(id);
          this.ctr += 1;
          const weaponDetails = this.ownWeapons.find(y => {
            if(y && +y.id === +id){
              return y;
            }
          });
          if(weaponDetails){
            this.computeDust('sub',(weaponDetails.stars + 1), weaponDetails.lowStarBurnPoints, weaponDetails.fourStarBurnPoints,
              weaponDetails.fiveStarBurnPoints);
          }
          this.burnWeaponIds = this.burnWeaponIds.filter(e => e !== id);
        });
        return;
      }
      const currentFilteredNotForBuringIds = this.currentFilteredWeaponsIds.filter(id => !this.burnWeaponIds.includes(id));
      currentFilteredNotForBuringIds.forEach(id => {
        this.burnWeaponIds.push(id);
        this.ctr += 1;
        const weaponDetails = this.ownWeapons.find(y => +y.id === +id);
        this.computeDust('add',(weaponDetails.stars + 1), weaponDetails.lowStarBurnPoints, weaponDetails.fourStarBurnPoints, weaponDetails.fiveStarBurnPoints);
      });
    },

    addBurnWeapon(id: number){
      this.ctr += 1;
      if(this.burnWeaponIds.includes(+id)){
        this.burnWeaponIds = this.burnWeaponIds.filter(val => +val !== +id);
        const weaponDetails = this.ownWeapons.find(y => y.id === id);
        this.computeDust('sub',(weaponDetails.stars + 1), weaponDetails.lowStarBurnPoints, weaponDetails.fourStarBurnPoints, weaponDetails.fiveStarBurnPoints);
      }else{
        this.burnWeaponIds.push(+id);
        const weaponDetails = this.ownWeapons.find(y => +y.id === +id);
        this.computeDust('add',(weaponDetails.stars + 1), weaponDetails.lowStarBurnPoints, weaponDetails.fourStarBurnPoints, weaponDetails.fiveStarBurnPoints);
      }
      this.burnWeaponId = null;
    },

    closeModal(modalType: string){
      (this.$refs[modalType] as BModal).hide();
    },

    getWeaponArt,
    getWeaponRarity,

    async onReforgeWeaponWithDust() {
      this.showModal = false;
      (this.$refs['confirm-reforge'] as BModal).hide();
      this.magicCircleSpeed = true;

      try {
        await this.reforgeWeaponWithDust({
          reforgeWeaponId: this.reforgeWeaponId,
          lesserDust: this.lesserDust,
          greaterDust: this.greaterDust,
          powerfulDust:this.powerfulDust
        });

        this.modalType = 'successReforge';
        (this.$refs['succesful-reforge'] as BModal).show();
        // this.showModal = true;
        this.magicCircleSpeed = false;
      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error(i18n.t('blacksmith.couldNotReforge'));
      }
    },

    clearDust(){
      this.showModal = false;
      if(this.modalType === 'successReforge'){
        this.lesserDust = '0';
        this.greaterDust = '0';
        this.powerfulDust = '0';
      }
    },

    async onMassBurnWeapons() {
      this.cooling = true;

      try {
        await this.massBurnWeapons({
          burnWeaponIds: this.burnWeaponIds,
        });
        this.burnWeaponIds = [];
        this.burnWeaponId = null;
        (this.$refs['mass-dust-confirmation-modal'] as BModal).hide();
        this.cooling = false;
      } catch (e) {
        console.error(e);
        (this as any).$dialog.notify.error(i18n.t('blacksmith.couldNotBurn'));
        this.cooling = false;
      }
    },

    async updateMintWeaponFee() {
      if(!this.contracts.CryptoBlades) return;
      const forgeCost = await this.fetchMintWeaponFee();
      const skillForgeCost = await this.contracts.CryptoBlades.methods.usdToSkill(forgeCost).call({ from: this.defaultAccount });
      this.forgeCost = new BN(skillForgeCost).div(new BN(10).pow(18)).toFixed(4);
      this.forgeCostBN = new BN(skillForgeCost).div(new BN(10).pow(18));
      this.isLoading = false;
    }
  },

  components: {
    DustBalanceDisplay,
    WeaponGrid,
    RightMenu,
    BigButton,
    WeaponIcon,
    BModal,
    NftList,
    SpecialWeaponForgeModal,
    BlacksmithNav
  },
});
</script>

<style scoped lang="scss">
.blacksmith-page > div:nth-child(1){
  background-color: rgba(0, 9, 26, 0.5);
  height: 100%;
  width: 100%;
  position: absolute;
}
#weapon-bg{
  background-image: url('../assets/blacksmith/blacksmith-bg.png');
}

.weapon-header{
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  z-index: 99;
}

.nav-icons div span:nth-child(2){
  color: rgba(255, 255, 255, 0.445);
}

.nav-icons div span:nth-child(2).active{
  color: rgb(255, 255, 255);
}

.buttons-panel > h2{
  font-family: 'Trajan', 'serif';
}

.forging-modal{
  position: absolute;
  background-image: linear-gradient(to bottom, rgba(0, 0, 0, 0.685), rgba(0, 0, 0, 0.897), rgba(0, 0, 0, 0.897), rgba(0, 0, 0, 0.87), #000);
  height:100%;
  width: 100%;
  z-index: 999;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;
  flex-direction: column
}

.mobile-menu{
  display: none;
}

.mobile-right-menu{
  display: none;
}

.weapon-list{
  animation: revealUp 1s;
}

@keyframes revealUp {
  0%   {bottom: 0px;}
  25%  {bottom: 100px;}
  50%  {bottom: 200px;}
  75%  {bottom: 300px;}
  100% {bottom: 500px;}
}


.weapon-list{
  width: 100%;
}

.forging-modal > .body-forge{
  width: 90%;
  margin-top: -170px;
}


.forging-modal > .forge-loading{
  width:fit-content;
  margin-top: -170px;
}

.forge-btns > span:nth-child(1){
  font-family: Oswald;
  font-size: 20px;
  color: #fff;
}

.spinning-box{
  height: 12em;
  width: 12em;
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: 3px;
}

.inner-spin{
  position: absolute;
  margin: auto;
  height: 7em;
  width: 7em;
  border: 2px solid #fff;
  -webkit-animation: rotating 2.5s linear infinite;
  -moz-animation: rotating 2.5s linear infinite;
  -ms-animation: rotating 2.5s linear infinite;
  -o-animation: rotating 2.5s linear infinite;
  animation: rotating 2.5s linear infinite;
}

.diamond-box{
  position: absolute;
  margin: auto;
  height: 7em;
  width: 7em;
  border: 2px solid #fff;
  transform: rotate(45deg);
  animation: blinkingBorder 1s infinite;
}


/* changing color border */
@keyframes blinkingBorder {
  from {boder: 2px solid #e9ca7a83;}
  to {border: 2px solid #e9ca7a10;}
}

/* rotating box */
@-webkit-keyframes rotating /* Safari and Chrome */ {
  from {
    -webkit-transform: rotate(0deg);
    -o-transform: rotate(0deg);
    transform: rotate(0deg);
  }
  to {
    -webkit-transform: rotate(360deg);
    -o-transform: rotate(360deg);
    transform: rotate(360deg);
  }
}

@keyframes rotating {
  from {
    -ms-transform: rotate(0deg);
    -moz-transform: rotate(0deg);
    -webkit-transform: rotate(0deg);
    -o-transform: rotate(0deg);
    transform: rotate(0deg);
  }
  to {
    -ms-transform: rotate(360deg);
    -moz-transform: rotate(360deg);
    -webkit-transform: rotate(360deg);
    -o-transform: rotate(360deg);
    transform: rotate(360deg);
  }
}



.wep-separator{
  justify-content: center;
  margin-bottom: 20px;
}

.wep-separator > img{
  width: 350px;
}

.hammer-loading{
  content: url('../assets/blacksmith/hammer.png');
  height: 80px;
  width: 80px;
}

.forging{
  width: 100%;
  display: flex;
  justify-content: center;
  margin: auto;
}


.forge-header{
  display: flex;
  flex-direction: column;
  width: 100%;
  margin: auto;
}


.forge-header > h3{
  font-family: Trajan;
  text-align: center;
  margin-top: 20px;
  margin-bottom: 20px;
}

.new-weapons > h3{
  font-family: Trajan;
  margin-bottom: 30px;
  font-weight: 500;
}

.new-weapons {
  display: flex;
  justify-content: center;
}

.footer-close-forge {
  margin: auto;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.header-close {
  margin: auto;
  width: 400px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.info{
  font-family: Roboto;
  color: rgba(255, 255, 255, 0.658);
  font-size: 13px !important;
  margin-bottom: 20px;
}

.reforge-bonus{
  margin-top: 20px;
  text-align: left !important;
}

.reforge-bonus > h5{
  color: #fff !important;
}

.reforge-bonus > h5 > span{
  color: #e9c97a !important;
  transition: all 1s ease-in-out;
}


/* MODAL TRANSITION */
.slide-fade-enter-active, .slide-fade-leave-active  {
  transition: all 0.2s ease-out;
}

.slide-fade-enter,
.slide-fade-leave-to {
  transform: translateY(20px);
  opacity: 0;
}



.header-close > h4{
  font-family: Trajan;
  width: 30vw;
  margin: auto;
  font-weight: 500;
  color: #EDCD90;
  text-transform: uppercase;
  margin-top: 1.1em;
  margin-bottom: 1.5em;
}


.close-icon{
  content: url('../assets/close-btn.png');
  height: 30px;
  width: 30px;
}

.footer-close-forge > span{
  font-family: Roboto;
  color: #fff;
  margin-top: 20px;
}

.footer-close-forge > h3{
  font-family: Trajan;
  width: 30vw;
  margin: auto;
  font-weight: 600;
  margin-top: 1.1em;
  margin-bottom: 1.5em;
}

.forge-btns > span:nth-child(2){
  font-size: 13px;
  color: #e9c97a;
}



.forge-btns{
  display: flex;
  flex-direction: column;
  border: none;
  width: 200px;
  height: 70px;
  align-items: center;
  vertical-align: middle;
  justify-content: center;
  background-image: url('../assets/buttonOutline.svg');
  background-color: transparent;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  -o-object-fit: fill;
  object-fit: fill;
  border: none !important;
}


.btn-forge{
  margin-top: 40px;
  display: flex;
  align-items: center;
}

.btn-forge > div > span {
  font-family: Oswald;
  font-size: 16px;
}

.btn-forge > div {
  margin-left: 20px;
  border-bottom: 1px solid #6b6969;
  padding-bottom: 10px;
  cursor: pointer;
}

.menu-btn{
  content: url('../assets/blacksmith/menu.svg');
  height: 15px;
  width: 15px;
  margin-right: 10px;
}

.button-div > button{
  width: 200px;
  height: 80px;
  background: transparent;
  background-image: url('../assets/btn-join.png');
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
  border: none;
  outline: none;
  color: #F0E2B6;
  font-weight: 500;
  font-family: 'Roboto', sans-serif;
  text-transform: uppercase;
}

@media (max-width: 1200px) {
  .weapon-header > .button-div{
    flex-wrap: wrap;
    justify-content: center;
  }

  .button-div > button{
    margin-top: 30px;
  }

  .button-div > button:hover{
    margin-top: 30px;
  }
}

.weapon-content{
  margin-top: 50px;
  border-radius: 5px;
}

.weapon-content > div{
  padding: 20px 25px;
}

.button-div > button >span{
  color: #e9c97a;
  font-family: "Roboto", sans-serif;
}

.reforgeDust > span{
  font-family: Oswald;
  font-size: 17px;
  color: #fff !important;
}


.button-div > button >span > span{
  font-family: Oswald;
  font-size: 20px;
  color: #fff;
}

.button-div > button:nth-child(1) >span > span{
  font-family: Oswald;
  font-size: 20px;
  color: #fff;
}


.nav-icons,.nav-icons> div {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.select-el{
  font-family: Trajan;
  font-size: 28px;
  margin-bottom: 30px;
  color: #e9c97a;
  text-transform: uppercase;
}

.line{
  margin: 0px 10px;
  background-color: rgba(255, 255, 255, 0.5);
  height: 2px;
  width: 5vw;
}

.nav-icons> div > span{
  font-family: Roboto;
  margin-right: 10px;
  color: #fff;
}

#forge {
  content: url("../assets/blacksmith/forge.png");
  height: 50px;
  width: 50px;
  background: rgba(0, 0, 0, 0.076);
}

#salvage {
  content: url("../assets/blacksmith/salvage.png");
  height: 50px;
  width: 50px;
  background: rgba(0, 0, 0, 0.076);
}


/* STYLING FOR WEAPON REFORGE */
.content .row .set-normal{
  padding-left: 0px !important;
  padding-right: 0px !important;
}

.blacksmith-page{
  background-image: url('../assets/blacksmith/cb-reforge-bg.jpg');
  background-size: cover;
  background-repeat: no-repeat;
  background-position: top right;
  min-height: calc(100vh - 120px);
  height: 100%;
  z-index: 0;
}

.reforge-dust{
  height: 90vh;
}

.bg-tint{
  width: 100%;
  position: absolute;
  opacity: 0.5;
}


.weapon-img{
  z-index: 4;
  height: 23vw;
  width: 23vw;
  position: absolute;
  top: 20px;
  left: 20px;
}


.weapon-menu > div > div > h2{
  font-family: Trajan;
  font-weight: 500;
}

.weapon-menu > div > div > .details{
  display: flex;
  font-family: Roboto;
  color: #fff;
  width: 80%;
}

.none-mobile > button > span{
  font-family: Oswald;
}


.weapon-menu > div > div > .details > span{
  border-right: 1px solid rgba(255, 255, 255, 0.445);
  padding-left: 30px;
  font-family: Roboto;
  padding-right: 30px;
}


.weapon-menu > div > div > .details{
  padding-bottom: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.356);
}

.weapon-menu > div > div > .details > span:nth-child(1){
  padding-left: 0px;
}

.weapon-menu > div > div > .details > span:nth-child(3){
  border-right: none;
}


.magic-circle{
  z-index: 3;
  height: 25em;
  width: 25em;
  position: absolute;
  top: 20px;
  left: 20px;
}

.add-glow{
  animation: addGlow 1s infinite linear;
}

@keyframes addGlow{
  0%   {-webkit-filter: drop-shadow(1px 1px 20px rgba(252, 252, 252, 0.075));}
  25%  {-webkit-filter: drop-shadow(1px 1px 20px rgba(252, 252, 252, 0.212));}
  50%  {-webkit-filter: drop-shadow(1px 1px 20px rgba(252, 252, 252, 0.534));}
  75%  {-webkit-filter: drop-shadow(1px 1px 20px rgba(252, 252, 252, 0.075));}
  100% {-webkit-filter: drop-shadow(1px 1px 20px rgba(252, 252, 252, 0.39));}
}

.inner{
  content: url('../assets/blacksmith/inner-circle.png');
  position: absolute;
  height: 23vw;
  width: 23vw;
}

.outer{
  content: url('../assets/blacksmith/outer-circle.png');
  position: absolute;
  height: 23vw;
  width: 23vw;
  animation-direction: reverse;
}

.slower{
  animation: rotating 25s infinite linear;
}

.faster{
  animation: rotating 5s infinite linear;
}

.reverse{
  animation-direction: reverse;
}

.power-status{
  margin-top: 2em;
  display: flex;
}

.dust-confirm > h4{
  text-align: center;
  font-family: Trajan;
  color: #e9c97a;
  padding: 10px 0px 20px 0px;
}

.dust-confirm{
  font-family: Roboto;
  text-align: center;
  color: rgba(255, 255, 255, 0.349);
}

.dust-confirm > button{
  margin: auto;
  margin-top: 50px;
}

.power-status > div{
  width: 15%;
}

.lock-icon{
  content: url('../assets/blacksmith/lock-icon.svg');
  height: 15px;
  width: 15px;
  margin-right: 5px;
}

.power-status > div > span:nth-child(2), .power-status > div > p{
  font-size: 16px;
  font-family: Oswald;
  color: #fff;
}

.cursor-p{
  cursor: pointer;
}

.forge-content{
  display: flex;
  justify-content: center;
}

.reforge-img{
  max-width: 10vw;
  min-width: 10vw;
}

.forge-content > div{
  height: max-content;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: stretch;
}

.forge-content > div > img{
  position: relative;
}

.body-forge .forge-header,.body-forge .forge-content{
    width: 55%;
    margin:auto;
}


.forge-loading{
  width: auto;
}

.power-rolled{
  border-bottom: none;
  margin: auto;
  width: 15vw;
}



.power-rolled .win-details:nth-child(1){
  text-align: right;
}

.power-rolled .win-details:nth-child(2){
  text-align: center;
}

.power-rolled .win-details:nth-child(3){
  text-align: left;
  flex-wrap:nowrap;
}


.power-status > div > span:nth-child(2){
  padding-left: 7px;
}

.power-status > div > p{
  font-size: 2em;
}


.menus{
  margin-top: 20px;
  width: 85%;
}

.desc-details{
  margin-top: 20px;
  width: 85%;
}

.desc-details > span{
  font-family: Roboto;
  font-size: 15px;
  color: rgba(255, 255, 255, 0.438);
}

.menus > div{
  display: flex;
  justify-content: center;
  align-items: center;
  text-align: center;
  font-family: Oswald;
  color: rgba(255, 255, 255, 0.397);
  border: 1px solid rgba(255, 255, 255, 0.39);
  padding: 10px;
  cursor: pointer;
}

.menus > div:nth-child(2), .menus > div:nth-child(3), .menus > div:nth-child(4){
  cursor: not-allowed;
}

.menus > div:nth-child(1){
  border-radius: 5px 0px 0px 5px;
}

.menus > div:nth-child(4){
  border-radius: 0px 5px 5px 0px;
}

.active-tab{
  color: #fff !important;
  background: #1168D0;
  border: none;
}

.create-dust > div {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
}

.dust-content{
  padding: 20px;
  margin-top: 5rem;
}

.dust-content > div:nth-child(3){
  border-top: 1px solid rgba(255, 255, 255, 0.322);
  padding-top: 30px;
}

.dust-content > h4{
  font-family: Trajan;
  border-bottom: 1px solid rgba(255, 255, 255, 0.322);
  padding-bottom: 20px;
  margin-bottom: 20px;
  margin-top: 50px;
}

.create-dust > div > div:nth-child(2) {
  padding-left: 20px;
}

.create-dust > div > div > span, .create-dust > div > div > p {
  font-family: Roboto;
  color: #fff;
}

.dust-gauge{
  margin-top: 20px;
  display: flex;
}

.dust-gauge > div{
  display: flex;
  align-items: center;
}

.dust-gauge > div:nth-child(2){
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  width: 45%;
}

.dust-gauge > div:nth-child(2) > input{
  width: 80%;
}

.dust-gauge > div:nth-child(2) > div{
  font-size: 12px;
}

.dust-gauge > div:nth-child(3) > span:nth-child(1){
  border: 1px solid rgba(255, 255, 255, 0.205);
  padding: 5px 10px;
  color: #fff;
  font-family: Roboto;
  border-radius: 5px;
  font-size: 12px;
  max-width: 60px;
  min-width: 80px;
  text-align: center;
  margin-right: 10px;
}

.dust-gauge > div:nth-child(3) > span:nth-child(2){
  border: 1px solid rgba(255, 255, 255, 0.205);
  padding: 5px 5px;
  color: #fff;
  font-family: Roboto;
  border-radius: 5px;
  max-width: 60px;
  font-size: 12px;
  min-width: 80px;
  text-align: center;
}

.dust-gauge > div:nth-child(2) > div{
  font-family: Roboto;
  color: rgba(255, 255, 255, 0.377);
}

.dust-gauge > div > div > p{
  font-family: Roboto;
  font-size: 17px;
  color: #fff;
}

.dust-gauge > div > div {
  padding-left: 15px;
}

.dust-gauge > div div:nth-child(2){
   width:200px;
}

.dust-gauge > div > div > span{
  font-family: Roboto;
  font-size: 15px;
  color: #fff;
}

.dust-bg{
  width: max-content;
  border-radius: 5px;
  padding: 8px 10px;
  background-color: #010D22;
  border: 1px solid rgba(0, 162, 255, 0.425);
}

.dust-img-lesser{
  content: url('../assets/dusts/lesserDust.png');
  height: 3em;
  width: 3em;
}

.dust-img-greater{
  content: url('../assets/dusts/greaterDust.png');
  height: 3em;
  width: 3em;
}

.dust-img-powerful{
  content: url('../assets/dusts/powerfulDust.png');
  height: 3em;
  width: 3em;
}

.new-btn{
  background-image: url('../assets/buttonOutline.svg');
  background-position: center;
}


.weapon-body{
  padding-left: 50px;
  width: 100%;
  margin-top: 20px;
}

.equipment-body{
  height: 90vh;
  padding-left: 50px;
}

.dust-body{
  height: 90vh;
  padding-left: 50px;
}

.land-body{
  height: 90vh;
  padding-left: 50px;
}



#random-border{
  background-image: url('../assets/questionmark-icon-45.png');
  background-size: 2em 2em;
  background-repeat: no-repeat;
  background-position: center;
  border: 1px solid white;
  width: 2.5em;
  height: 2.5em;
  margin-left: 1em;
  margin-right: 1em;
  transform: rotate(45deg);
}

#random-border:hover{
  background-image: url('../assets/questionmark-icon-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

#random-border.done {
  background-image: url('../assets/questionmark-icon-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

#fire-border{
  background-image: url('../assets/elements/fire-45.png');
  background-size: 2em 2em;
  background-repeat: no-repeat;
  background-position: center;
  width: 2.5em;
  height: 2.5em;
  margin-left: 1em;
  margin-right: 1em;
  border: 1px solid white;
  transform: rotate(45deg);
}

#fire-border:hover{
  background-image: url('../assets/elements/fire-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

#fire-border.done {
  background-image: url('../assets/elements/fire-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

#earth-border{
  background-image: url('../assets/elements/earth-45.png');
  background-size: 2em 2em;
  background-repeat: no-repeat;
  background-position: center;
  width: 2.5em;
  height: 2.5em;
  margin-left: 1em;
  margin-right: 1em;
  border: 1px solid white;
  transform: rotate(45deg);
}

#earth-border:hover{
  background-image: url('../assets/elements/earth-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

#earth-border.done {
  background-image: url('../assets/elements/earth-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

#lightning-border{
  background-image: url('../assets/elements/lightning-45.png');
  background-size: 2em 2em;
  background-repeat: no-repeat;
  background-position: center;
  width: 2.5em;
  height: 2.5em;
  margin-left: 1em;
  margin-right: 1em;
  border: 1px solid white;
  transform: rotate(45deg);
}

#lightning-border:hover{
  background-image: url('../assets/elements/lightning-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

#lightning-border.done {
  background-image: url('../assets/elements/lightning-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

#water-border{
  background-image: url('../assets/elements/water-45.png');
  background-size: 2em 2em;
  background-repeat: no-repeat;
  background-position: center;
  padding: 10px;
  width: 2.5em;
  height: 2.5em;
  margin-left: 1em;
  margin-right: 1em;
  border: 1px solid white;
  transform: rotate(45deg);
}

#water-border:hover{
  background-image: url('../assets/elements/water-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

#water-border.done {
  background-image: url('../assets/elements/water-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 2em 2em;
  width: 2.5em;
  height: 2.5em;
  transition: all 0.2s ease-in-out;
}

.new-weapon-header-text{
   color: #9e8a57;
  font-size: 34px;
}

.weapon-container {
  border-right: 1px solid #9e8a57;
}

.confirmReforge{
  border-radius:0.15em;
  text-decoration:none;
  font-weight:400;
  text-align:center;
  width: 12em;
}

.footer-btn > div > span{
  font-family: Roboto;
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

ul.weapon-grid li.active{
  border: 2px solid #e9c97a;
}

.multiForging {
  align-items: center;
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

.elements-modal{
  width: 10%;
  height: 10%;
  margin-left: 3%;
  margin-right: 3%;
}

img.elements-modal:hover {
  transform:scale(1.4)
}

.margin-top{
  margin-top: 4em;
}

.select-elements-container {
  margin-top: 0.7em;
  align-items: center;
}

.buttons-panel {
  display: flex;
  justify-content: space-between;
}

.disable-button{
  opacity: 0.5;
  cursor:not-allowed;
}

.line-sep{
  width: 2vw;
  height: 2px;
  background-color: rgba(255, 255, 255, 0.349);
}

.line-sep-2{
  width: 0vw;
}

.activate-line .line-sep{
  width: 0vw;
  transition: all 0.5s ease;
}

.active{
  color: #fff;
}

.activate-line .line-sep-2{
  width: 2vw;
  height: 2px;
  background-color: rgb(255, 255, 255);
  transition: all 0.5s ease;
}


.button-div {
  display: flex;
  justify-content: flex-end;
  margin-left: auto;
}

#water{
  content: url('../assets/elements/icon-water.svg');
  height: 20px;
  widows: 20px;
}

#fire{
  content: url('../assets/elements/icon-fire.svg');
  height: 20px;
  widows: 20px;
}

#earth{
  content: url('../assets/elements/icon-earth.svg');
  height: 20px;
  widows: 20px;
}

#lightning{
  content: url('../assets/elements/icon-thunder.svg');
  height: 20px;
  widows: 20px;
}

@media (max-width: 1000px) {
  .mobile-flip{
    display: flex;
    flex-flow: column-reverse;
  }
}

@media (max-width: 992px) {
  .reforge-dust{
    height: auto;
  }
}


 .dust-cost{
    display: none;
  }

@media (max-width: 576px) {
  .button-div {
    justify-content: center;
  }
  .buttons-panel {
    flex-direction: column;
  }

  .magic-circle{
    width: 100%;
  }

  .weapon-body, .equipment-body, .dust-body, .land-body{
    padding: 0px 20px;
    padding-top: 20px;
  }

  .equipment-body{
    padding: 0px 20px;
    padding-top: 30px;
  }

  .dust-body, .land-body{
    padding: 0px 20px;
    padding-top: 30px;
  }

  .blacksmith-page {
    display: block;
  }


  .header-close > h4{
    font-family: Trajan;
    width: 100%;
    margin: auto;
    font-weight: 500;
    margin-top: 1.1em;
    text-align: center;
    margin-bottom: 1.5em;
  }

  .reforge-bonus > h5{
    text-align: center;
  }

  .reforge-img{
    max-width: 50%;
    min-width: 50%;
    align-self: center;
  }

  .power-rolled{
    width: 100%;
  }

  .forge-content{
    flex-direction: column;
  }

  .header-close > img{
    width: 100%;
  }

  .header-close{
    width: 100%;
  }

  .dust-cost{
    display:inline-block;
    font-size: 16px;
    color: #e9c97a;
    margin: 0px;
    line-height: 0px;
  }

  .none-mobile{
    display: none;
  }

  .footer-close-forge{
    width: '';
  }

  .footer-close-forge > img, .new-weapons > img{
    width: 90vw;
  }

  .new-weapons  > h3{
    justify-content: center;
    text-align: center;
    font-size: 23px;
  }

  .mobile-right-menu{
      display: inline;
    }

    .body-forge > div > div > ul{
    height: 40vh;
  }



  .mobile-menu{
    display: flex;
    justify-content: space-evenly;
    padding: 10px 0px;
    align-items: center;
    background-color: #000E1D;
    border-bottom: 1px solid #43506A;
    z-index: 2;
    position: absolute;
    top:0;
    width: 100%;
  }

  .mobile-menu > span{
    font-family: Trajan;
    color: rgba(255, 255, 255, 0.459);
    display: flex;
    align-items: center;
  }

  .mobile-menu > span.active{
    font-family: Trajan;
    color: #fff;
    display: flex;
    align-items: center;
  }

  #salvage {
    content: url("../assets/blacksmith/salvage.png");
    height: 25px;
    width: 25px;
    background: rgba(0, 0, 0, 0.076);
  }

  #forge {
    content: url("../assets/blacksmith/forge.png");
    height: 25px;
    width: 25px;
    background: rgba(0, 0, 0, 0.076);
  }

  .weapon-content{
    padding: 10px 20px;
    margin-top: 20px;
  }

  .nav-icons > div:nth-child(1),.nav-icons > div:nth-child(3){
    flex-direction: column;
  }

  .reforge-dust{
    position: relative;
    height: 37vh;
  }

  .weapon-menu > div > div > h2{
    font-size: 2em;
  }

  .weapon-menu > div > div > .details{
    display: flex;
    width: 100%;
    justify-content: space-between;
  }

   .weapon-menu > div > div > .details > span{
     padding-right: 0px;
  }

  .mobile{
    display: flex;
    justify-content: space-between;
  }

  .mobile > div.active-tab{
    opacity: 1;
  }

  .forge-icons{
    content: url('../assets/blacksmith/reforge.svg');
    height: 1.5em;
    width: 1.5em;
  }

  .enchant-icons{
    content: url('../assets/blacksmith/enchant.svg');
    height: 1.5em;
    width: 1.5em;
  }

  .desc-details > span{
    font-size: 0.5m;
  }

  .dust-gauge > div:nth-child(2) {
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    width: 100%;
    padding: 10px 0px;
  }
  .dust-gauge{
    flex-direction: column;
    justify-content: flex-start;
  }

  .skin-icons{
    content: url('../assets/blacksmith/skin.svg');
    height: 1.5em;
    width: 1.5em;
  }

  .upgrade-icons{
    content: url('../assets/blacksmith/upgrade.svg');
    height: 1.5em;
    width: 1.5em;
  }

  .menus.desktop{
    display: none;
  }

  .menus.mobile{
    display: inline-block;
  }

  .mobile > div{
    border: 1px solid rgba(255, 255, 255, 0.322);
    width: 100%;
    text-align: center;
    padding: 7px 0px;
    opacity: 0.5;
  }

  .mobile > div:nth-child(1){
    border-radius: 5px 0px 0px 5px;
  }

  .mobile > div:nth-child(4){
    border-radius: 0px 5px 5px 0px;
  }



  .details > span{
    font-size: 0.8em;
    word-break: normal;
    padding: 0px;
  }

  .details > span > span{
    font-size: 1.2em;
    color:#e9c97a;
  }


  .weapon-img{
    margin-top: 15px;
    height: 62vw;
    width: 62vw;
  }

  .magic-circle > span{
    height: 68vw;
    width: 68vw;
  }


  #random-border{
  background-image: url('../assets/questionmark-icon-45.png');
  background-size: 1.5em 1.5em;
  background-repeat: no-repeat;
  background-position: center;
  border: 1px solid white;
  width: 2em;
  height: 2em;
  margin-left: 1em;
  margin-right: 1em;
  transform: rotate(45deg);
}

#random-border:hover{
  background-image: url('../assets/questionmark-icon-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}

#random-border.done {
  background-image: url('../assets/questionmark-icon-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}

#fire-border{
  background-image: url('../assets/elements/fire-45.png');
  background-repeat: no-repeat;
  background-position: center;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  margin-left: 1em;
  margin-right: 1em;
  border: 1px solid white;
  transform: rotate(45deg);
}

#fire-border:hover{
  background-image: url('../assets/elements/fire-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}

#fire-border.done {
  background-image: url('../assets/elements/fire-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}

#earth-border{
  background-image: url('../assets/elements/earth-45.png');
  background-repeat: no-repeat;
  background-position: center;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  margin-left: 1em;
  margin-right: 1em;
  border: 1px solid white;
  transform: rotate(45deg);
}

#earth-border:hover{
  background-image: url('../assets/elements/earth-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}

#earth-border.done {
  background-image: url('../assets/elements/earth-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}

#lightning-border{
  background-image: url('../assets/elements/lightning-45.png');
  background-repeat: no-repeat;
  background-position: center;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  margin-left: 1em;
  margin-right: 1em;
  border: 1px solid white;
  transform: rotate(45deg);
}

#lightning-border:hover{
  background-image: url('../assets/elements/lightning-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}

#lightning-border.done {
  background-image: url('../assets/elements/lightning-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}

#water-border{
  background-image: url('../assets/elements/water-45.png');
  background-repeat: no-repeat;
  background-position: center;
  padding: 10px;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  margin-left: 1em;
  margin-right: 1em;
  border: 1px solid white;
  transform: rotate(45deg);
}

#water-border:hover{
  background-image: url('../assets/elements/water-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}

#water-border.done {
  background-image: url('../assets/elements/water-45.png');
  background-position: center;
  transform: rotate(45deg);
  border: 3px solid #e9c97a;
  background-size: 1.5em 1.5em;
  width: 2em;
  height: 2em;
  transition: all 0.2s ease-in-out;
}
}
.blacksmith-content{
   div.menu-nav{
    height: 60px;
    padding-left: 50px;
    padding-right: 50px;
    padding-top: 10px;
    padding-bottom: 10px;
    border-bottom: 1px solid #424A59;
    background-color:#000E1D;
   }
 }

</style>
