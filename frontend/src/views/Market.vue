<template>
  <div class="body main-font">

    <b-tabs justified>
      <b-tab @click="clearData();browseTabActive = true;skillShopTabActive = false">
        <template #title>
          {{$t('market.browseNfts')}}
          <hint class="hint" :text="$t('market.nftHint')" />
        </template>

        <div class="row mt-3">
          <div class="col">

            <div class="row button-row">
              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllCharacterListings(currentPage - 1)"  class="gtag-link-others" tagname="browse_characters">
                  {{$t('market.browseChars')}}
                </b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllWeaponListings(currentPage - 1)"  class="gtag-link-others" tagname="browse_weapons">{{$t('market.browseWeapons')}}</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllShieldListings(currentPage - 1)"  class="gtag-link-others" tagname="browse_shields">{{$t('market.browseShields')}}</b-button>
              </div>

              <div class="col"></div>
            </div>

            <div class="search-results">
              <b-pagination class="customPagination"
                v-visible="allSearchResults && allSearchResults.length > 0"
                align="center" v-model="currentPage"
                :total-rows="allListingsAmount"
                :per-page="nftListingPageSize()"
                first-number
                last-number
                v-on:click.native="(activeType == 'weapon' && searchAllWeaponListings(currentPage - 1)) ||
                  (activeType == 'character' && searchAllCharacterListings(currentPage - 1)) ||
                  (activeType == 'shield' && searchAllShieldListings(currentPage - 1))"
              ></b-pagination>

              <weapon-grid
                v-on:weapon-filters-changed="searchAllWeaponListings(0)"
                v-if="activeType === 'weapon'"
                :showGivenWeaponIds="true"
                :weaponIds="allSearchResults"
                :showLimit="weaponShowLimit"
                :showReforgedToggle="false"
                :showFavoriteToggle="false"
                :canFavorite="false"
                :isMarket="true"
                :showNftOptions="true"
                v-model="selectedNftId">

                <template #above="{ weapon: { id } }">
                  <div class="d-flex flex-column align-items-center justify-content-center m-top-negative-5">
                    <span class="d-block text-center fix-h24" v-if="nftPricesById[id]">
                      <span v-if="convertWeiToSkill(nftPricesById[id]) !== '0'"
                      v-tooltip.top="{ content: maxPrecisionSkill(nftPricesById[id]) , trigger: (isMobile() ? 'click' : 'hover') }"
                      @mouseover="hover = !isMobile() || true"
                      @mouseleave="hover = !isMobile()"
                      >
                        <strong>{{$t('market.price')}}</strong>: <CurrencyConverter :skill="convertWeiToSkill(nftPricesById[id])"/>
                      </span>
                    </span>
                    <span class="d-block text-center" v-else>{{$t('market.loadingPrice')}}</span>
                    <b-button
                      :hidden="convertWeiToSkill(nftPricesById[id]) === '0'"
                      @click="selectedNftId = id; purchaseNft();"
                      variant="primary"
                      class="gtag-link-others">
                      {{ convertWeiToSkill(nftPricesById[id]) !== '0' ? 'Purchase' : 'Sold' }}
                    </b-button>
                  </div>
                </template>

                <template #sold="{ weapon: { id } }">
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>{{$t('market.sold')}}</span></div>
                </template>

              </weapon-grid>

              <character-list
                v-on:character-filters-changed="searchAllCharacterListings(0)"
                v-if="activeType === 'character'"
                :showFilters="true"
                :showGivenCharacterIds="true"
                :characterIds="allSearchResults"
                :showLimit="characterShowLimit"
                :isMarket="true"
                :showNftOptions="true"
                v-model="selectedNftId">

                <template #above="{ character: { id } }">
                  <div class="token-price d-flex flex-column align-items-center justify-content-center m-top-negative-50">
                    <span class="d-block text-center fix-h24" v-if="nftPricesById[id]">
                      <span v-if="convertWeiToSkill(nftPricesById[id]) !== '0'"
                      v-tooltip.top="{ content: maxPrecisionSkill(nftPricesById[id]) , trigger: (isMobile() ? 'click' : 'hover') }"
                      @mouseover="hover = !isMobile() || true"
                      @mouseleave="hover = !isMobile()"
                      >
                      <CurrencyConverter :skill="convertWeiToSkill(nftPricesById[id])"/>
                      </span>
                    </span>

                    <span class="d-block text-center" v-else>{{$t('market.loadingPrice')}}</span>
                    <b-button
                      :hidden="convertWeiToSkill(nftPricesById[id]) === '0'"
                      @click="selectedNftId = id; canPurchase && purchaseNft();"
                      variant="primary"
                      v-bind:class="[!canPurchase ? 'disabled-button' : '']"
                      class="gtag-link-others" tagname="confirm_purchase">
                      {{ convertWeiToSkill(nftPricesById[id]) !== '0' ? 'Purchase' : 'Sold' }} <b-icon-question-circle v-if="!canPurchase"
                      v-tooltip.bottom="$t('market.maxChars')"/>
                    </b-button>
                  </div>
                </template>

                <template #sold="{ character: { id } }">
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>{{$t('market.sold')}}</span></div>
                </template>
              </character-list>

              <nft-list
                v-on:nft-filters-changed="searchAllShieldListings(0)"
                v-if="activeType === 'shield'"
                :showGivenNftIdTypes="true"
                :nftIdTypes="allSearchResults.map(id => { return { id: id, type: 'shield' }; })"
                :showLimit="shieldShowLimit"
                :showReforgedToggle="false"
                :showFavoriteToggle="false"
                :isMarket="true"
                :showNftOptions="true"
                v-model="selectedNftId"
                :canFavorite="false">

                <template #above="{ nft: { id } }">
                  <div class="d-flex flex-column align-items-center justify-content-center m-top-negative-5">
                    <span class="d-block text-center fix-h24" v-if="nftPricesById[id]">
                      <span v-if="convertWeiToSkill(nftPricesById[id]) !== '0'"
                      v-tooltip.top="{ content: maxPrecisionSkill(nftPricesById[id]) , trigger: (isMobile() ? 'click' : 'hover') }"
                      @mouseover="hover = !isMobile() || true"
                      @mouseleave="hover = !isMobile()"
                      >
                        <strong>Price</strong>: <CurrencyConverter :skill="convertWeiToSkill(nftPricesById[id])"/>
                      </span>
                    </span>
                    <span class="d-block text-center" v-else>{{$t('market.loadingPrice')}}</span>
                    <b-button
                      :hidden="convertWeiToSkill(nftPricesById[id]) === '0'"
                      @click="selectedNftId = id; purchaseNft();"
                      variant="primary"
                      class="gtag-link-others">
                      {{ convertWeiToSkill(nftPricesById[id]) !== '0' ? 'Purchase' : 'Sold' }}
                    </b-button>
                  </div>
                </template>

                <template #sold="{ nft: { id } }">
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>{{$t('market.sold')}}</span></div>
                </template>

              </nft-list>

              <b-pagination class="customPagination"
                v-if="allSearchResults && allSearchResults.length > 0"
                align="center" v-model="currentPage"
                :total-rows="allListingsAmount"
                :per-page="nftListingPageSize()"
                first-number
                last-number
                v-on:click.native="(activeType == 'weapon' && searchAllWeaponListings(currentPage - 1)) ||
                  (activeType == 'character' && searchAllCharacterListings(currentPage - 1)) ||
                  (activeType == 'shield' && searchAllShieldListings(currentPage - 1))"
              ></b-pagination>
            </div>

          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              {{$t('market.loading')}}
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab @click="clearData();loadMarketTaxes(),browseTabActive = false;skillShopTabActive = false">
        <template #title>
          {{$t('market.searchNfts')}}
          <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons, Shields and Characters are NFTs of the ERC721 standard" />
        </template>

        <div class="row mt-3">
          <div class="col">
            <div class="d-flex justify-content-center">
               <input class="form-control search w-50" type="text" v-model.trim="search" :placeholder="$t('market.searchPlaceholder')" />
            </div>

            <div class="row buttons-row mt-3">
              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('character')"  class="gtag-link-others" tagname="search_character_id">{{$t('market.searchCharID')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('weapon')"  class="gtag-link-others" tagname="search_weapon_id">{{$t('market.searchWeaponID')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('weapon')"  class="gtag-link-others" tagname="weapons_seller">{{$t('market.weaponsBySeller')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('character')"  class="gtag-link-others" tagname="characters_seller">{{$t('market.charsBySeller')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('shield')"  class="gtag-link-others" tagname="search_shield_id">{{$t('market.searchShieldID')}}</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('shield')"  class="gtag-link-others" tagname="shields_seller">{{$t('market.shieldsBySeller')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('weapon')"  class="gtag-link-others" tagname="search_own_weapons">{{$t('market.searchMyWeapons')}}</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchPrivateWeaponListings()" class="gtag-link-others" tagname="weapons_private">{{$t('market.weaponsPrivateTrades')}}</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchPrivateCharacterListings()" class="gtag-link-others" tagname="characters_private">{{$t('market.charsPrivateTrades')}}</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchPrivateShieldListings()" class="gtag-link-others" tagname="characters_private">{{$t('market.shieldsPrivateTrades')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('character')"  class="gtag-link-others" tagname="search_own_characters">{{$t('market.searchMyChars')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('shield')"  class="gtag-link-others" tagname="search_own_shields">{{$t('market.searchMyShields')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  @click="showListingSetupModal(true)" class="gtag-link-others" tagname="change_price">{{$t('market.changePrice')}}</b-button>
              </div>

              <div class="col-4 col-md-3">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  @click="updateNftListingTargetBuyer()"  class="gtag-link-others" tagname="change_price">{{$t('market.changeTargetBuyer')}}</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  v-tooltip="$t('market.cancelTooltip')"
                  @click="cancelNftListing()"  class="gtag-link-others" tagname="cancel_listing">{{$t('market.cancelListing')}}</b-button>
              </div>
            </div>

            <div class="search-results">
              <weapon-grid
                v-if="activeType === 'weapon'"
                :showGivenWeaponIds="true"
                :showReforgedToggle="false"
                :showFavoriteToggle="false"
                :canFavorite="false"
                :weaponIds="searchResults"
                :isMarket="true"
                :showNftOptions="true"
                v-model="selectedNftId">

                <template #above="{ weapon: { id } }">
                  <div class="d-flex flex-column align-items-center justify-content-center m-top-negative-5">
                    <span class="d-block text-center fix-h24" v-if="nftPricesById[id]">
                      <span v-if="convertWeiToSkill(nftPricesById[id]) !== '0'"
                      v-tooltip.top="{ content: maxPrecisionSkill(nftPricesById[id]) , trigger: (isMobile() ? 'click' : 'hover') }"
                      @mouseover="hover = !isMobile() || true"
                      @mouseleave="hover = !isMobile()"
                      >
                        <strong>{{$t('market.price')}}</strong>: <CurrencyConverter :skill="convertWeiToSkill(nftPricesById[id])"/>
                      </span>
                    </span>
                    <span class="d-block text-center" v-else>{{$t('market.loadingPrice')}}</span>
                    <b-button
                        v-if="id !== null && !searchResultsOwned"
                        :hidden="convertWeiToSkill(nftPricesById[id]) === '0'"
                        @click="selectedNftId = id; purchaseNft();"
                        variant="primary"
                        class="gtag-link-others">
                        {{ convertWeiToSkill(nftPricesById[id]) !== '0' ? 'Purchase' : 'Sold' }}
                    </b-button>
                  </div>
                </template>

                <template #sold="{ weapon: { id } }">
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>{{$t('market.sold')}}</span></div>
                </template>

              </weapon-grid>

              <character-list
                :showFilters="true"
                v-if="activeType === 'character'"
                :showGivenCharacterIds="true"
                :characterIds="searchResults"
                :isMarket="true"
                :showNftOptions="true"
                v-model="selectedNftId">

                <template #above="{ character: { id } }">
                  <div class="token-price d-flex flex-column align-items-center justify-content-center m-top-negative-50">
                    <span class="d-block text-center fix-h24" v-if="nftPricesById[id]">
                      <span v-if="convertWeiToSkill(nftPricesById[id]) !== '0'"
                      v-tooltip.top="{ content: maxPrecisionSkill(nftPricesById[id]) , trigger: (isMobile() ? 'click' : 'hover') }"
                      @mouseover="hover = !isMobile() || true"
                      @mouseleave="hover = !isMobile()"
                      >
                        <CurrencyConverter :skill="convertWeiToSkill(nftPricesById[id])"/>
                      </span>
                    </span>
                    <span class="d-block text-center" v-else>{{$t('market.loadingPrice')}}</span>
                    <b-button
                      v-if="id !== null && !searchResultsOwned"
                      :hidden="convertWeiToSkill(nftPricesById[id]) === '0'"
                      @click="selectedNftId = id; canPurchase && purchaseNft();"
                      variant="primary"
                      v-bind:class="[!canPurchase ? 'disabled-button' : '']"
                      class="gtag-link-others" tagname="confirm_purchase">
                      {{ convertWeiToSkill(nftPricesById[id]) !== '0' ? 'Purchase' : 'Sold' }} <b-icon-question-circle v-if="!canPurchase"
                      v-tooltip.bottom="$t('market.maxChars')"/>
                    </b-button>
                  </div>
                </template>

                <template #sold="{ character: { id } }">
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>{{$t('market.sold')}}</span></div>
                </template>

              </character-list>

              <nft-list
                v-if="activeType === 'shield'"
                :showGivenNftIdTypes="true"
                :showReforgedToggle="false"
                :showFavoriteToggle="false"
                :nftIdTypes="searchResults.map(id => { return { id: id, type: 'shield' }; })"
                :showLimit="shieldShowLimit"
                :isMarket="true"
                v-model="selectedNftId"
                :showNftOptions="true"
                :canFavorite="false">

                <template #above="{ nft: { id } }">
                  <div class="d-flex flex-column align-items-center justify-content-center m-top-negative-5">
                    <span class="d-block text-center fix-h24" v-if="nftPricesById[id]">
                      <span v-if="convertWeiToSkill(nftPricesById[id]) !== '0'"
                      v-tooltip.top="{ content: maxPrecisionSkill(nftPricesById[id]) , trigger: (isMobile() ? 'click' : 'hover') }"
                      @mouseover="hover = !isMobile() || true"
                      @mouseleave="hover = !isMobile()"
                      >
                        <strong>{{$t('market.price')}}</strong>: <CurrencyConverter :skill="convertWeiToSkill(nftPricesById[id])"/>
                      </span>
                    </span>
                    <span class="d-block text-center" v-else>{{$t('market.loadingPrice')}}</span>
                    <b-button
                      v-if="id !== null && !searchResultsOwned"
                      :hidden="convertWeiToSkill(nftPricesById[id]) === '0'"
                      @click="selectedNftId = id; purchaseNft();"
                      variant="primary"
                      class="gtag-link-others">
                      {{ convertWeiToSkill(nftPricesById[id]) !== '0' ? 'Purchase' : 'Sold' }}
                    </b-button>
                  </div>
                </template>

                <template #sold="{ nft: { id } }">
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>{{$t('market.sold')}}</span></div>
                </template>

              </nft-list>
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              {{$t('market.loading')}}
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab @click="clearData();loadMarketTaxes();browseTabActive = false;skillShopTabActive = false">
        <template #title>
          {{$t('market.listNfts')}}
          <hint class="hint" :text="$t('market.listingHint')" />
        </template>

        <div class="row mt-3">
          <div class="col">
            <div class="row button-row">
              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  @click="activeType = 'weapon'"  class="gtag-link-others" tagname="show_weapons_market">{{$t('market.showWeapons')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  @click="activeType = 'character'"  class="gtag-link-others" tagname="show_characters_market">{{$t('market.showChars')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  @click="activeType = 'shield'"  class="gtag-link-others" tagname="show_shields_market">{{$t('market.showShields')}}</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  v-if="activeType === 'weapon'"
                   class="gtag-link-others" tagname="add_listing_weapon"
                  :disabled="selectedNftId === null"
                  @click="showListingSetupModal()">{{$t('market.listWeapon')}} <b-icon-question-circle :hidden=!weaponMarketTax
                  v-tooltip.bottom="weaponMarketTax + $t('market.listingTaxHint')"/></b-button>

                <b-button
                  variant="primary"
                  v-if="activeType === 'character'"
                  :disabled="selectedNftId === null"
                   class="gtag-link-others" tagname="add_listing_character"
                  @click="showListingSetupModal()">{{$t('market.listChar')}} <b-icon-question-circle :hidden=!characterMarketTax
                  v-tooltip.bottom="characterMarketTax + $t('market.listingTaxHint')"/></b-button>

                <b-button
                  variant="primary"
                  v-if="activeType === 'shield'"
                   class="gtag-link-others" tagname="add_listing_shield"
                  :disabled="selectedNftId === null || selectedNftOnCooldown"
                  @click="showListingSetupModal()">{{$t('market.listShield')}} <b-icon-question-circle :hidden=!shieldMarketTax
                  v-tooltip.bottom="shieldMarketTax + $t('market.listingTaxHint')"/></b-button>

                <b-modal class="centered-modal" ref="listing-setup-modal"
                  @ok="!priceChangeModal ? addListingForNft() : updateNftListingPrice()">
                  <template #modal-title>
                    {{!priceChangeModal ? $t('market.sellType', {activeType}) : $t('market.sellType', {changeTypePrice})}}
                  </template>
                  <b-form-input type="number" :max="10000"
                    class="modal-input" v-model="listingSellPrice" :placeholder="$t('market.sellPrice')" />
                  <b-form-input class="modal-input" v-model="listingTargetBuyer" :placeholder="$t('market.targetBuyerAddress')" />
                  <span v-if="listingSellPrice">
                    {{$t('market.listingConfirmation', {activeType})}}<CurrencyConverter :skill="Math.min(+listingSellPrice, 10000).toString()"/>?<br>
                  <i>{{$t('market.buyerFee', { activeListingMarketTax: activeListingMarketTax() })}}
                  <CurrencyConverter :skill="calculatedBuyerCost(Math.min(+listingSellPrice, 10000))"/></i></span>
                </b-modal>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                   class="gtag-link-others" tagname="show_weapons_sold"
                  @click="showWeaponsSoldModal()"> {{$t('market.weaponsSold')}}
                  <b-icon-question-circle v-tooltip.bottom="$t('market.viewWeapons')"/>
                </b-button>

                <b-modal class="centered-modal " ref="weapons-sold-modal">

                    <template #modal-header>
                         <div class="transaction-history-header-text">
                           {{$t('market.weaponTxHistory')}}
                         </div>
                    </template>
                    <div v-if="historyCounter > 0">
                      <b-table class="transaction-history-text" :items="weaponTransactionHistoryData" :fields="weaponTransactionHistoryHeader"></b-table>
                    </div>
                    <div v-if="historyCounter === 0">
                      <p>{{$t('market.nothingThere')}}</p>
                      <p>{{$t('market.tips')}} <strong><a href="https://cryptoblades.gitbook.io/wiki/market/marketplace#list-nfts" target="_blank">{{$t('market.link')}}</a></strong></p>
                    </div>
                    <template #modal-footer>
                    <b-button class="mt-3" block @click="resetTransactionHistoryValues('weapons-sold-modal')">{{$t('ok')}}</b-button>
                    </template>


                </b-modal>

              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                   class="gtag-link-others" tagname="show_characters_sold"
                  @click="showCharactersSoldModal()"> {{$t('market.charactersSold')}}
                  <b-icon-question-circle v-tooltip.bottom="$t('market.charactersSoldTooltip')"/>
                </b-button>

                <b-modal class="centered-modal " ref="characters-sold-modal">

                    <template #modal-header>
                         <div class="transaction-history-header-text">
                           {{$t('market.characterTxHistory')}}
                         </div>
                    </template>
                    <div v-if="historyCounter > 0">
                      <b-table class="transaction-history-text" :items="characterTransactionHistoryData" :fields="characterTransactionHistoryHeader"></b-table>
                    </div>
                    <div v-if="historyCounter === 0">
                      <p>{{$t('market.nothingThere')}}</p>
                      <p>{{$t('market.tips')}}<strong><a href="https://cryptoblades.gitbook.io/wiki/market/marketplace#list-nfts" target="_blank">{{$t('market.link')}}</a></strong></p>
                    </div>
                    <template #modal-footer>
                    <b-button class="mt-3" block @click="resetTransactionHistoryValues('characters-sold-modal')">{{$t('ok')}}</b-button>
                    </template>

                </b-modal>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                   class="gtag-link-others" tagname="show_shields_sold"
                  @click="showShieldsSoldModal()"> {{$t('market.shieldsSold')}}
                  <b-icon-question-circle v-tooltip.bottom="$t('market.shieldsSoldTooltip')"/>
                </b-button>

                <b-modal class="centered-modal " ref="shields-sold-modal">

                    <template #modal-header>
                         <div class="transaction-history-header-text">
                           {{$t('market.shieldsTxHistory')}}
                         </div>
                    </template>
                    <div v-if="historyCounter > 0">
                      <b-table class="transaction-history-text" :items="shieldTransactionHistoryData" :fields="sieldTransactionHistoryHeader"></b-table>
                    </div>
                    <div v-if="historyCounter === 0">
                      <p>{{$t('market.nothingThere')}}</p>
                      <p>{{$t('market.tips')}}<strong><a href="https://cryptoblades.gitbook.io/wiki/market/marketplace#list-nfts" target="_blank">{{$t('market.link')}}</a></strong></p>
                    </div>
                    <template #modal-footer>
                    <b-button class="mt-3" block @click="resetTransactionHistoryValues('shields-sold-modal')">{{$t('ok')}}</b-button>
                    </template>


                </b-modal>

              </div>

              <div class="col-4 col-md-3 col-lg-2">
              </div>
            </div>

            <div class="sell-grid" v-if="activeType === 'weapon'">
              <weapon-grid
                v-model="selectedNftId"
                :showReforgedWeaponsDefVal="false"
                :showFavoriteWeaponsDefVal="false"
                :canFavorite="false"
              />
            </div>

            <div class="sell-grid" v-if="activeType === 'character'">
              <character-list
                :showFilters="true"
                v-model="selectedNftId"
              />
            </div>

            <div class="sell-grid" v-if="activeType === 'shield'">
              <nft-list
                :isShop="false"
                v-model="selectedNftId"
                :canFavorite="false"
              />
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              {{$t('market.loading')}}
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab @click="clearData();browseTabActive = false;skillShopTabActive = true">
        <template #title>
          {{$t('market.skillShop')}}
          <hint class="hint" :text="$t('market.skillShophint')" />
        </template>

        <div>
          <div class="row">
            <div class="col-sm-4 centered-text">
              <h3>{{$t('market.specials')}}</h3>
            </div>
            <div class="col-sm-8 centered-text">
              <h3>{{$t('market.shop')}}</h3>
            </div>
            <img class="shop-horizontal-divider-top" src="../assets/divider4.png" />
          </div>
           <div class="row">
            <div class="col-sm-4 special-offer-items">
              <div class="special-offer-bg">
                 <nft-list :isShop="true" :nftIdTypes="specialOffersNftList" :isSpecials="true"/>
              </div>
            </div>
            <div class="col-sm-8 shop-items">
              <div class="shop-items">
                <nft-list :isShop="true" :nftIdTypes="shopOffersNftList"/>
              </div>
            </div>
            <img class="shop-horizontal-divider" src="../assets/divider4.png" />
          </div>
        </div>
      </b-tab>
    </b-tabs>
  </div>
</template>

<script lang="ts">
import assert from 'assert';
import Vue from 'vue';
import { BModal } from 'bootstrap-vue';
import CharacterList from '../components/smart/CharacterList.vue';
import WeaponGrid from '../components/smart/WeaponGrid.vue';
import Hint from '../components/Hint.vue';
import CurrencyConverter from '../components/CurrencyConverter.vue';
import Web3 from 'web3';
import { mapActions, mapGetters, mapState } from 'vuex';
import { Accessors } from 'vue/types/options';
import { Contract, Contracts, IState } from '../interfaces';
import { Characters, Weapons, Shields } from '../../../build/abi-interfaces';
import { SkillShopListing } from '../interfaces/SkillShopListing';
import BigNumber from 'bignumber.js';
import { traitNameToNumber } from '@/contract-models';
import { market_blockchain as useBlockchain } from './../feature-flags';
import { CharacterTransactionHistoryData, ICharacterHistory,
  IWeaponHistory, WeaponTransactionHistoryData,
  IShieldHistory, ShieldTransactionHistoryData } from '@/interfaces/History';
import { getShieldNameFromSeed } from '@/shield-name';
import { fromWeiEther, apiUrl } from '../utils/common';
import NftList, { NftIdType } from '@/components/smart/NftList.vue';
import { getCleanName } from '../rename-censor';
import i18n from '@/i18n';

type SellType = 'weapon' | 'character' | 'shield';
type WeaponId = string;
type CharacterId = string;
type ShieldId = string;
type NftId = WeaponId | CharacterId | ShieldId;
const defaultTargetBuyer = '0x0000000000000000000000000000000000000000';

interface Data {
  activeType: SellType;
  search: string;
  searchResults: CharacterId[] | WeaponId[] | NftIdType[];
  allSearchResults: CharacterId[] | WeaponId[] | NftIdType[];
  searchResultsOwned: boolean;
  selectedNftId: NftId | null;
  marketOutcome: string | null;
  waitingMarketOutcome: boolean;
  nftPricesById: Record<string, string>;
  characterMarketTax: string;
  weaponMarketTax: string ;
  shieldMarketTax: string;
  characterShowLimit: number;
  weaponShowLimit: number;
  shieldShowLimit: number;
  allListingsAmount: number;
  currentPage: number;
  browseTabActive: boolean;
  skillShopTabActive: boolean;
  listingSellPrice: string;
  listingTargetBuyer: string;
  priceChangeModal: boolean;
  weaponTransactionHistoryData: WeaponTransactionHistoryData[];
  weaponTransactionHistoryHeader: any;
  characterTransactionHistoryData: CharacterTransactionHistoryData[];
  characterTransactionHistoryHeader: any;
  shieldTransactionHistoryData: ShieldTransactionHistoryData[];
  shieldTransactionHistoryHeader: any;
  historyCounter: number;
  landSaleAllowed: boolean;
  reservedSaleAllowed: boolean;
}

type StoreMappedState = Pick<IState, 'defaultAccount' | 'weapons' | 'characters' | 'shields' | 'ownedCharacterIds' | 'ownedWeaponIds' | 'ownedShieldIds'>;

const defaultLimit = 40;

interface StoreMappedGetters {
  contracts: Contracts;
  ownCharacters: any[];
  totalShieldSupply: 0;
  getCharacterName(id: string): string;
  getWeaponName(id: string, stars: number): string;
}

export interface Nft {
  id: string;
  type: string;
  stars?: number;
  element?: string;
  stat1?: string;
  stat2?: string;
  stat3?: string;
  stat1Value?: number;
  stat2Value?: number;
  stat3Value?: number;
  nftPrice?: number;
  isConsumable: boolean;
  name: string;
  description: string;
  image: string;
}

interface StoreMappedActions {
  fetchAllMarketNftIds(payload: { nftContractAddr: string }): Promise<string[]>;
  fetchAllMarketCharacterNftIdsPage(payload: {
    nftContractAddr: string, limit: number, pageNumber: number, trait: number, minLevel: number, maxLevel: number
  }): Promise<string[]>;
  fetchAllMarketWeaponNftIdsPage(payload: { nftContractAddr: string, limit: number, pageNumber: number, trait: number, stars: number }): Promise<string[]>;
  fetchAllMarketShieldNftIdsPage(payload: { nftContractAddr: string, limit: number, pageNumber: number, trait: number, stars: number }): Promise<string[]>;
  fetchNumberOfWeaponListings(payload: { nftContractAddr: string, trait: number, stars: number }): Promise<number>;
  fetchNumberOfCharacterListings(payload: { nftContractAddr: string, trait: number, minLevel: number, maxLevel: number}): Promise<number>;
  fetchNumberOfShieldListings(payload: { nftContractAddr: string, trait: number, stars: number}): Promise<number>;
  fetchMarketNftIdsBySeller(payload: { nftContractAddr: string, sellerAddr: string }): Promise<string[]>;
  fetchMarketNftPrice(payload: { nftContractAddr: string, tokenId: string | number }): Promise<string>;
  fetchMarketNftTargetBuyer(payload: { nftContractAddr: string, tokenId: string | number }): Promise<string>;
  fetchMarketTax(payload: { nftContractAddr: string }): Promise<string>;
  checkMarketItemOwnership(payload: { nftContractAddr: string, tokenId: string | number}): Promise<string>;
  addMarketListing(
    payload: { nftContractAddr: string, tokenId: string, price: string, targetBuyer: string }
  ): Promise<{ seller: string, nftID: string, price: string, targetBuyer: string }>;
  changeMarketListingPrice(
    payload: { nftContractAddr: string, tokenId: string, newPrice: string }
  ): Promise<{ seller: string, nftID: string, newPrice: string }>;
  changeMarketListingTargetBuyer(
    payload: { nftContractAddr: string, tokenId: string, newTargetBuyer: string }
  ): Promise<{ seller: string, nftID: string, newTargetBuyer: string }>;
  cancelMarketListing(payload: { nftContractAddr: string, tokenId: string }): Promise<{ seller: string, nftID: string }>;
  purchaseMarketListing(payload: { nftContractAddr: string, tokenId: string, maxPrice: string }): Promise<{ seller: string, nftID: string, price: string }>;
  fetchSellerOfNft(payload: { nftContractAddr: string, tokenId: string }): Promise<string>;
  fetchTotalShieldSupply(): Promise<number>;
  setupWeaponsWithIdsRenames(weaponIds: string[]): Promise<void>;
  setupCharactersWithIdsRenames(weaponIds: string[]): Promise<void>;
  fetchIsLandSaleAllowed(): Promise<boolean>;
  reservedSalesAllowed(): Promise<boolean>;
}

export default Vue.extend({
  components: { CharacterList, WeaponGrid, Hint, CurrencyConverter, NftList },

  data() {
    return {
      activeType: 'weapon',
      search: '',
      searchResults: [],
      allSearchResults: [],
      searchResultsOwned: false,
      selectedNftId: null,
      marketOutcome: null,
      waitingMarketOutcome: false,
      nftPricesById: {},
      characterMarketTax: '',
      weaponMarketTax: '',
      shieldMarketTax: '',
      characterShowLimit: 40,
      weaponShowLimit: 60,
      shieldShowLimit: 60,
      allListingsAmount: 0,
      currentPage: 1,
      browseTabActive: true,
      skillShopTabActive: false,
      listingSellPrice: '',
      listingTargetBuyer: '',
      priceChangeModal: false,
      weaponTransactionHistoryData: [],
      weaponTransactionHistoryHeader: [],
      characterTransactionHistoryData: [],
      characterTransactionHistoryHeader: [],
      shieldTransactionHistoryData: [],
      shieldTransactionHistoryHeader: [],
      historyCounter: 0,
      landSaleAllowed: false,
      reservedSaleAllowed: false,
    } as Data;
  },

  computed: {
    ...(mapState([
      'defaultAccount', 'weapons', 'characters', 'shields', 'ownedCharacterIds', 'ownedWeaponIds', 'ownedShieldIds',
    ]) as Accessors<StoreMappedState>),
    ...(mapGetters([
      'contracts', 'ownCharacters', 'totalShieldSupply','getCharacterName','getWeaponName'
    ]) as Accessors<StoreMappedGetters>),

    Weapons(): Contract<Weapons> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Weapons!;
    },

    Characters(): Contract<Characters> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Characters!;
    },

    Shields(): Contract<Shields> {
      // we use x! here because we assert that they're set already in created()
      // this helps with typings
      return this.contracts.Shields!;
    },

    contractAddress(): string {
      return this.activeType === 'weapon'
        ? this.Weapons.options.address
        : (this.activeType === 'character' ? this.Characters.options.address
          : this.Shields.options.address);
    },

    buyableNftSelected(): boolean {
      return this.selectedNftId !== null
        && !this.searchResultsOwned;
    },

    ownListedNftSelected(): boolean {
      return this.selectedNftId !== null
        && this.searchResultsOwned;
    },

    canPurchase(): boolean {
      return this.activeType === 'weapon' || this.activeType === 'shield' || this.ownCharacters.length < 4 ;
    },

    specialOffersNftList(): SkillShopListing[] {
      const nftList = [
        {
          id: 'placeholder',
          type: 'shield',
          nftPrice: 3,
          name: 'Shield',
          description: 'A Legendary Defender Shield',
          image: '',
        },
      ] as SkillShopListing[];

      if(this.landSaleAllowed) {
        nftList.push({
          id: 't1land',
          type: 't1land',
          name: 'Tier 1 Land',
          description: 'A tier 1 land',
          image: '',
        } as SkillShopListing);
        nftList.push({
          id: 't2land',
          type: 't2land',
          name: 'Tier 2 Land',
          description: 'A tier 2 land',
          image: '',
        } as SkillShopListing);
        nftList.push({
          id: 't3land',
          type: 't3land',
          name: 'Tier 3 Land',
          description: 'A tier 3 land',
          image: '',
        } as SkillShopListing);
      }

      if(this.reservedSaleAllowed) {
        nftList.push({
          id: 'claimT2Land',
          type: 'claimT2Land',
          name: 'Tier 2 Claimable Land',
          description: 'A tier 2 claimable land',
          image: '',
        } as SkillShopListing);
        nftList.push({
          id: 'claimT3Land',
          type: 'claimT3Land',
          name: 'Tier 3 Claimable Land',
          description: 'A tier 3 claimable land',
          image: '',
        } as SkillShopListing);
      }

      return nftList;
    },

    shopOffersNftList(): SkillShopListing[] {
      const nftList = [
        {
          id: 0,
          type: 'CharacterRenameTag',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.characterRenameTag'),
          description: i18n.t('market.nftList.characterRenameTagDesc'),
          image: 'scroll_06_te.png'
        },
        {
          id: 0,
          type: 'CharacterRenameTagDeal',
          nftPrice: 0.225,
          name: i18n.t('market.nftList.characterRenameTagDeal'),
          description: i18n.t('market.nftList.characterRenameTagDealDesc'),
          image: 'scroll_06_te4.png'
        },
        {
          id: 1,
          type: 'WeaponRenameTag',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.weaponRenameTag'),
          description: i18n.t('market.nftList.weaponRenameTagDesc'),
          image: 'rune_05_te.png'
        },
        {
          id: 1,
          type: 'WeaponRenameTagDeal',
          nftPrice: 0.225,
          name: i18n.t('market.nftList.weaponRenameTagDeal'),
          description: i18n.t('market.nftList.weaponRenameTagDealDesc'),
          image: 'rune_05_te4.png'
        },
        {
          id: 1,
          type: 'CharacterEarthTraitChange',
          nftPrice: 0.15,
          name: i18n.t('market.nftList.characterEarthTraitChange'),
          description: i18n.t('market.nftList.characterEarthTraitChangeDesc'),
          image: 'potion_06_te.png'
        },
        {
          id: 1,
          type: 'CharacterFireTraitChange',
          nftPrice: 0.15,
          name: i18n.t('market.nftList.characterFireTraitChange'),
          description: i18n.t('market.nftList.characterFireTraitChangeDesc'),
          image: 'potion_09_te.png'
        },
        {
          id: 1,
          type: 'CharacterWaterTraitChange',
          nftPrice: 0.15,
          name: i18n.t('market.nftList.characterWaterTraitChange'),
          description: i18n.t('market.nftList.characterWaterTraitChangeDesc'),
          image: 'potion_07_te.png'
        },
        {
          id: 1,
          type: 'CharacterLightningTraitChange',
          nftPrice: 0.15,
          name: i18n.t('market.nftList.characterLightningTraitChange'),
          description: i18n.t('market.nftList.characterLightningTraitChangeDesc'),
          image: 'potion_05_te.png'
        },
        {
          id: 1,
          type: 'WeaponCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.weaponGrayscale'),
          description: i18n.t('market.nftList.weaponGrayscaleDesc'),
          image: ''
        },
        {
          id: 2,
          type: 'WeaponCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.weaponContrast'),
          description: i18n.t('market.nftList.weaponContrastDesc'),
          image: ''
        },
        {
          id: 3,
          type: 'WeaponCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.weaponSepia'),
          description: i18n.t('market.nftList.weaponSepiaDesc'),
          image: ''
        },
        {
          id: 4,
          type: 'WeaponCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.weaponInvert'),
          description: i18n.t('market.nftList.weaponInvertDesc'),
          image: ''
        },
        {
          id: 5,
          type: 'WeaponCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.weaponBlur'),
          description: i18n.t('market.nftList.weaponBlurDesc'),
          image: ''
        },
        {
          id: 6,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponFireglow'),
          description: i18n.t('market.nftList.weaponFireglowDesc'),
          image: ''
        },
        {
          id: 7,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponEarthglow'),
          description: i18n.t('market.nftList.weaponEarthglowDesc'),
          image: ''
        },
        {
          id: 8,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponLightningglow'),
          description: i18n.t('market.nftList.weaponLightningglowDesc'),
          image: ''
        },
        {
          id: 9,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponWaterglow'),
          description: i18n.t('market.nftList.weaponWaterglowDesc'),
          image: ''
        },
        {
          id: 10,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponRainbowglow'),
          description: i18n.t('market.nftList.weaponRainbowglowDesc'),
          image: ''
        },
        {
          id: 11,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponDarkglow'),
          description: i18n.t('market.nftList.weaponDarkglowDesc'),
          image: ''
        },
        {
          id: 12,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponGhost'),
          description: i18n.t('market.nftList.weaponGhostDesc'),
          image: ''
        },
        {
          id: 13,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponPolicelights'),
          description: i18n.t('market.nftList.weaponPolicelightsDesc'),
          image: ''
        },
        {
          id: 14,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponNeonborder'),
          description: i18n.t('market.nftList.weaponNeonborderDesc'),
          image: ''
        },
        {
          id: 15,
          type: 'WeaponCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.weaponRotatingNeonborder'),
          description: i18n.t('market.nftList.weaponRotatingNeonborderDesc'),
          image: ''
        },
        {
          id: 16,
          type: 'WeaponCosmetic',
          nftPrice: 0.3,
          name: i18n.t('market.nftList.weaponDiamondborder'),
          description: i18n.t('market.nftList.weaponDiamondborderDesc'),
          image: ''
        },
        {
          id: 17,
          type: 'WeaponCosmetic',
          nftPrice: 0.225,
          name: i18n.t('market.nftList.weaponGoldborder'),
          description: i18n.t('market.nftList.weaponGoldborderDesc'),
          image: ''
        },
        {
          id: 18,
          type: 'WeaponCosmetic',
          nftPrice: 0.15,
          name: i18n.t('market.nftList.weaponSilverborder'),
          description: i18n.t('market.nftList.weaponSilverborderDesc'),
          image: ''
        },
        {
          id: 19,
          type: 'WeaponCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.weaponBronzeborder'),
          description: i18n.t('market.nftList.weaponBronzeborderDesc'),
          image: ''
        },
        {
          id: 1,
          type: 'CharacterCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.characterGrayscale'),
          description: i18n.t('market.nftList.characterGrayscaleDesc'),
          image: ''
        },
        {
          id: 2,
          type: 'CharacterCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.characterContrast'),
          description: i18n.t('market.nftList.characterContrastDesc'),
          image: ''
        },
        {
          id: 3,
          type: 'CharacterCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.characterSepia'),
          description: i18n.t('market.nftList.characterSepiaDesc'),
          image: ''
        },
        {
          id: 4,
          type: 'CharacterCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.characterInvert'),
          description: i18n.t('market.nftList.characterInvertDesc'),
          image: ''
        },
        {
          id: 5,
          type: 'CharacterCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.characterBlur'),
          description: i18n.t('market.nftList.characterBlurDesc'),
          image: ''
        },
        {
          id: 6,
          type: 'CharacterCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.characterFireglow'),
          description: i18n.t('market.nftList.characterFireglowDesc'),
          image: ''
        },
        {
          id: 7,
          type: 'CharacterCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.characterEarthglow'),
          description: i18n.t('market.nftList.characterEarthglowDesc'),
          image: ''
        },
        {
          id: 8,
          type: 'CharacterCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.characterLightningglow'),
          description: i18n.t('market.nftList.characterLightningglowDesc'),
          image: ''
        },
        {
          id: 9,
          type: 'CharacterCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.characterWaterglow'),
          description: i18n.t('market.nftList.characterWaterglowDesc'),
          image: ''
        },
        {
          id: 10,
          type: 'CharacterCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.characterRainbowglow'),
          description: i18n.t('market.nftList.characterRainbowglowDesc'),
          image: ''
        },
        {
          id: 11,
          type: 'CharacterCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.characterDarkglow'),
          description: i18n.t('market.nftList.characterDarkglowDesc'),
          image: ''
        },
        {
          id: 12,
          type: 'CharacterCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.characterGhost'),
          description: i18n.t('market.nftList.characterGhostDesc'),
          image: ''
        },
        {
          id: 13,
          type: 'CharacterCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.characterPolice'),
          description: i18n.t('market.nftList.characterPoliceDesc'),
          image: ''
        },
        {
          id: 14,
          type: 'CharacterCosmetic',
          nftPrice: 0.375,
          name: i18n.t('market.nftList.characterNeonborder'),
          description: i18n.t('market.nftList.characterNeonborderDesc'),
          image: ''
        },
        {
          id: 15,
          type: 'CharacterCosmetic',
          nftPrice: 0.3,
          name: i18n.t('market.nftList.characterDiamondborder'),
          description: i18n.t('market.nftList.characterDiamondborderDesc'),
          image: ''
        },
        {
          id: 16,
          type: 'CharacterCosmetic',
          nftPrice: 0.225,
          name: i18n.t('market.nftList.characterGoldborder'),
          description: i18n.t('market.nftList.characterGoldborderDesc'),
          image: ''
        },
        {
          id: 17,
          type: 'CharacterCosmetic',
          nftPrice: 0.15,
          name: i18n.t('market.nftList.characterSilverborder'),
          description: i18n.t('market.nftList.characterSilverborderDesc'),
          image: ''
        },
        {
          id: 18,
          type: 'CharacterCosmetic',
          nftPrice: 0.075,
          name: i18n.t('market.nftList.characterBronzeborder'),
          description: i18n.t('market.nftList.characterBronzeborderDesc'),
          image: ''
        },
      ] as SkillShopListing[];

      return nftList;
    }
  },

  methods: {
    ...(mapActions([
      'fetchAllMarketNftIds',
      'fetchAllMarketCharacterNftIdsPage',
      'fetchAllMarketWeaponNftIdsPage',
      'fetchAllMarketShieldNftIdsPage',
      'fetchNumberOfWeaponListings',
      'fetchNumberOfCharacterListings',
      'fetchNumberOfShieldListings',
      'fetchMarketNftIdsBySeller',
      'fetchMarketNftPrice',
      'fetchMarketNftTargetBuyer',
      'fetchMarketTax',
      'checkMarketItemOwnership',
      'addMarketListing',
      'changeMarketListingPrice',
      'changeMarketListingTargetBuyer',
      'cancelMarketListing',
      'purchaseMarketListing',
      'fetchSellerOfNft',
      'fetchTotalShieldSupply',
      'setupWeaponsWithIdsRenames',
      'setupCharactersWithIdsRenames',
      'fetchIsLandSaleAllowed',
      'reservedSalesAllowed',
    ]) as StoreMappedActions),

    clearData() {
      this.activeType = 'weapon';
      this.search = '';
      this.searchResults = [];
      this.allSearchResults = [];
      this.searchResultsOwned = false;
      this.selectedNftId = null;
      this.marketOutcome = null;
      this.waitingMarketOutcome = false;
      this.nftPricesById = {};
      this.allListingsAmount = 0;
      this.currentPage = 1;
      this.listingSellPrice = '';
      this.listingTargetBuyer = '';
    },

    async loadMarketTaxes() {
      if(!this.characterMarketTax) {
        const tax = await this.getMarketTax(this.Characters.options.address) as string;
        this.characterMarketTax = this.convertMarketTax(tax);
      }
      if(!this.weaponMarketTax) {
        const tax = await this.getMarketTax(this.Weapons.options.address) as string;
        this.weaponMarketTax = this.convertMarketTax(tax);
      }
      if(!this.shieldMarketTax) {
        const tax = await this.getMarketTax(this.Shields.options.address) as string;
        this.shieldMarketTax = this.convertMarketTax(tax);
      }
    },

    convertMarketTax(tax: string): string {
      return new BigNumber(tax).div(new BigNumber(2).pow(64)).multipliedBy(100).integerValue(BigNumber.ROUND_CEIL).toString();
    },

    async getMarketTax(contractAddress: string) {
      if(!contractAddress) return;

      return await this.fetchMarketTax({
        nftContractAddr: contractAddress,
      });
    },

    async lookupNftPrice(id: NftId) {
      if(!this.contractAddress) return;

      return await this.fetchMarketNftPrice({
        nftContractAddr: this.contractAddress,
        tokenId: id,
      });
    },

    async lookupNftTargetBuyer(nftId: NftId) {
      if(!this.contractAddress) return;

      return await this.fetchMarketNftTargetBuyer({
        nftContractAddr: this.contractAddress,
        tokenId: nftId,
      });
    },

    async fetchNftPrices(nftIds: NftId[]) {
      if(!this.contractAddress) return;

      this.nftPricesById = {};
      await Promise.all(nftIds.map(async id => {
        const price = (await this.lookupNftPrice(id))!;

        void price;
        this.nftPricesById[id] = price;
      }));
    },

    async addListingForNft() {
      this.marketOutcome = null;
      if(this.selectedNftId === null) return;
      if(!this.listingSellPrice) return;

      const val = Math.min(+this.listingSellPrice, 10000);
      if(val <= 0 || !val || isNaN(val)) return;

      this.waitingMarketOutcome = true;

      const results = await this.addMarketListing({
        nftContractAddr: this.contractAddress,
        // nft-list keys have a typeid format, e.g. shield0
        tokenId: this.activeType === 'weapon' || this.activeType === 'character'
          ? this.selectedNftId
          : this.selectedNftId.split('.')[1],
        price: this.convertSkillToWei(val.toString()),
        targetBuyer: this.listingTargetBuyer || defaultTargetBuyer
      });

      this.selectedNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = `Successfully listed ${this.activeType} ${results.nftID} for ${this.convertWeiToSkill(results.price)} SKILL`
        +(this.listingTargetBuyer !== defaultTargetBuyer ? ` for ${this.listingTargetBuyer}` : '');
    },

    async updateNftListingPrice() {

      this.marketOutcome = null;
      if(this.selectedNftId === null) return;

      const val = Math.min(+this.listingSellPrice, 10000);
      if(val <= 0 || !val || isNaN(val)) return;

      this.waitingMarketOutcome = true;

      const results = await this.changeMarketListingPrice({
        nftContractAddr: this.contractAddress,
        tokenId: this.activeType === 'weapon' || this.activeType === 'character'
          ? this.selectedNftId
          : this.selectedNftId.split('.')[1],
        newPrice: this.convertSkillToWei(val.toString())
      });

      this.selectedNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = `Successfully changed price for ${this.activeType} ${results.nftID} to ${this.convertWeiToSkill(results.newPrice)} SKILL`;
    },

    async updateNftListingTargetBuyer() {

      this.marketOutcome = null;
      if(this.selectedNftId === null) return;

      let targetBuyer = await (this as any).$dialog.prompt({ title: `Sell ${this.activeType}`, text: 'Target Buyer Address (optional)' });
      if(!targetBuyer) targetBuyer = defaultTargetBuyer;

      this.waitingMarketOutcome = true;

      const results = await this.changeMarketListingTargetBuyer({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        newTargetBuyer: targetBuyer
      });

      this.selectedNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = `Successfully changed target buyer for ${this.activeType} ${results.nftID} to ${results.newTargetBuyer}`;
    },

    async purchaseNft() {
      this.marketOutcome = null;
      if(this.selectedNftId === null) return;

      const price = await this.lookupNftPrice(this.selectedNftId);
      if(!price) return;

      if(this.activeType !== 'weapon' && this.activeType !== 'character') {
        this.selectedNftId = this.selectedNftId.split('.')[1];
      }

      const skillChainPrice = this.convertStringToDecimal(this.convertWeiToSkill(price), 2);
      const skillUIPrice = this.convertStringToDecimal(this.convertWeiToSkill(this.nftPricesById[this.selectedNftId]), 2);

      if(skillChainPrice !== skillUIPrice) {
        (this as any).$dialog.notify.error('The price of the listing has changed. Please refresh listing and try again');
        return;
      }

      this.waitingMarketOutcome = true;

      const results: any = await this.purchaseMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.selectedNftId,
        maxPrice: price
      });

      const results2: any  = await this.fetchAllMarketNftIds({
        nftContractAddr: this.contractAddress
      });

      this.allSearchResults = await this.filterOutTargetBuyers(results2);

      this.allSearchResults = Array.from(this.allSearchResults as string[]).filter((x: any) => x.id !== this.selectedNftId);

      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully purchased '
        +this.activeType+' '+results.nftID+' for '+this.convertWeiToSkill(results.price)+' SKILL'
          +' from '+results.seller;
    },

    async cancelNftListing() {
      this.marketOutcome = null;

      if(this.selectedNftId === null) return;

      this.waitingMarketOutcome = true;

      const results = await this.cancelMarketListing({
        nftContractAddr: this.contractAddress,
        tokenId: this.activeType === 'weapon' || this.activeType === 'character'
          ? this.selectedNftId
          : this.selectedNftId.split('.')[1],
      });

      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully taken '
        +this.activeType+' '+results.nftID+' off the market.';

      await this.searchOwnListings(this.activeType);
    },

    async searchAllCharacterListings(page: number) {
      this.activeType = 'character';
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;
      this.currentPage = page + 1;

      if(useBlockchain){
        console.log('chain');
        await this.searchAllCharacterListingsThroughChain(page);
      }
      else{
        console.log('api');
        await this.searchAllCharacterListingsThroughAPI(page);
      }

      // searchResultsOwned does not mesh with this function
      // will need per-result checking of it, OR filtering out own NFTs
      //this.searchResultsOwned = nftSeller === this.defaultAccount;
      this.searchResultsOwned = false; // temp

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchAllCharacterListingsThroughAPI(page: number) {
      const url = new URL(apiUrl('static/market/character'));
      const params = {
        element: '' + this.upperFirstChar(this.characterTraitFilter()),
        minLevel: '' + this.characterMinLevelFilter(),
        maxLevel: '' + this.characterMaxLevelFilter(),
        sortBy: '' + this.characterPriceOrder() ? 'price' : '',
        sortDir: '' + this.characterPriceOrder(),
        minPrice: '' + this.characterMinPriceFilter(),
        maxPrice: '' + this.characterMaxPriceFilter(),
        pageSize: '' + (this.characterShowLimit || defaultLimit),
        pageNum: '' + page,
        network: this.activeChain(),
      };

      url.search = new URLSearchParams(params).toString();

      const charactersData = await fetch(url.toString());
      const characters = await charactersData.json();

      this.allListingsAmount = characters.page.total;
      this.allSearchResults = characters.idResults;
    },

    async searchAllCharacterListingsThroughChain(page: number) {
      this.allListingsAmount = await this.fetchNumberOfCharacterListings({
        nftContractAddr: this.contractAddress,
        trait: traitNameToNumber(this.characterTraitFilter()),
        minLevel: this.characterMinLevelFilter(),
        maxLevel: this.characterMaxLevelFilter()
      });

      const results = await this.fetchAllMarketCharacterNftIdsPage({
        nftContractAddr: this.contractAddress,
        limit: this.characterShowLimit || defaultLimit,
        pageNumber: page,
        trait: traitNameToNumber(this.characterTraitFilter()),
        minLevel: this.characterMinLevelFilter(),
        maxLevel: this.characterMaxLevelFilter()
      });

      this.allSearchResults = await this.filterOutTargetBuyers(results);
    },

    async searchAllWeaponListings(page: number) {
      this.activeType = 'weapon';
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;
      this.currentPage = page + 1;

      if(useBlockchain === true)
        await this.searchAllWeaponListingsThroughChain(page);
      else
        await this.searchAllWeaponListingsThroughAPI(page);

      // searchResultsOwned does not mesh with this function
      // will need per-result checking of it, OR filtering out own NFTs
      //this.searchResultsOwned = nftSeller === this.defaultAccount;
      this.searchResultsOwned = false; // temp
      // this.allSearchResults = await this.filterOutTargetBuyers(results) as string[];

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchAllWeaponListingsThroughChain(page: number) {
      const filterStar = this.weaponStarFilter() !== 0 ? this.weaponStarFilter() - 1 : 255;
      this.allListingsAmount = await this.fetchNumberOfWeaponListings({
        nftContractAddr: this.contractAddress,
        trait: traitNameToNumber(this.weaponTraitFilter()),
        stars: filterStar
      });

      const results = await this.fetchAllMarketWeaponNftIdsPage({
        nftContractAddr: this.contractAddress,
        limit: this.weaponShowLimit || defaultLimit,
        pageNumber: page,
        trait: traitNameToNumber(this.weaponTraitFilter()),
        stars: filterStar
      });

      this.allSearchResults = await this.filterOutTargetBuyers(results);
    },
    async searchAllWeaponListingsThroughAPI(page: number) {
      const url = new URL(apiUrl('static/market/weapon'));
      const params = {
        element: '' + this.upperFirstChar(this.weaponTraitFilter()),
        minStars: '' + (this.weaponStarFilter() !== 0 ?  this.weaponStarFilter() - 1 : 0),
        maxStars: '' + (this.weaponStarFilter() !== 0 ?  this.weaponStarFilter() - 1 : 4),
        sortBy: '' + this.weaponPriceOrder() ? 'price' : '',
        sortDir: '' + this.weaponPriceOrder(),
        minPrice: '' + this.weaponMinPriceFilter(),
        maxPrice: '' + this.weaponMaxPriceFilter(),
        pageSize: '' + (this.weaponShowLimit || defaultLimit),
        pageNum: '' + page,
        network: this.activeChain(),
      };

      url.search = new URLSearchParams(params).toString();

      const weaponsData = await fetch(url.toString());
      const weapons = await weaponsData.json();

      this.allListingsAmount = weapons.page.total;
      this.allSearchResults = weapons.idResults;
    },

    async searchAllShieldListings(page: number) {
      this.activeType = 'shield';
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;
      this.currentPage = page + 1;

      if(useBlockchain === true)
        await this.searchAllShieldListingsThroughChain(page);
      else
        await this.searchAllShieldListingsThroughAPI(page);

      // searchResultsOwned does not mesh with this function
      // will need per-result checking of it, OR filtering out own NFTs
      //this.searchResultsOwned = nftSeller === this.defaultAccount;
      this.searchResultsOwned = false; // temp

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchAllShieldListingsThroughChain(page: number) {
      const filterStar = this.nftStarFilter() !== 0 ? this.nftStarFilter() - 1 : 255;
      this.allListingsAmount = await this.fetchNumberOfShieldListings({
        nftContractAddr: this.contractAddress,
        trait: traitNameToNumber(this.nftTraitFilter()),
        stars: filterStar
      });

      this.allSearchResults = await this.fetchAllMarketShieldNftIdsPage({
        nftContractAddr: this.contractAddress,
        limit: this.shieldShowLimit || defaultLimit,
        pageNumber: page,
        trait: traitNameToNumber(this.nftTraitFilter()),
        stars: filterStar
      });
    },

    async searchAllShieldListingsThroughAPI(page: number) {
      const url = new URL(apiUrl('static/market/shield'));
      const params = {
        element: '' + this.upperFirstChar(this.nftTraitFilter()),
        minStars: '' + (this.nftStarFilter() !== 0 ?  this.nftStarFilter() - 1 : 0),
        maxStars: '' + (this.nftStarFilter() !== 0 ?  this.nftStarFilter() - 1 : 4),
        sortBy: '' + this.nftPriceOrder() ? 'price' : '',
        sortDir: '' + this.nftPriceOrder(),
        pageSize: '' + (this.shieldShowLimit || defaultLimit),
        pageNum: '' + page,
        network: this.activeChain(),
      };

      url.search = new URLSearchParams(params).toString();

      const shieldsData = await fetch(url.toString());
      const shields = await shieldsData.json();

      this.allListingsAmount = shields.page.total;
      this.allSearchResults = shields.idResults;
    },

    async searchListingsByNftId(type: SellType) {
      this.activeType = type;
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;

      const nftSeller = await this.fetchSellerOfNft({
        nftContractAddr: this.contractAddress,
        tokenId: this.search
      });
      this.searchResultsOwned = nftSeller === this.defaultAccount;
      const url = new URL('https://api.cryptoblades.io/static/wallet/banned/' + nftSeller);
      const data = await fetch(url.toString());
      const banned = await data.json();
      if(banned.banned) {
        (this as any).$dialog.notify.error('Item not available!');
      }

      const price = await this.lookupNftPrice(this.search);
      if(price !== '0' && !banned.banned) {
        this.searchResults = await this.filterOutTargetBuyers([this.search]);
      } else {
        this.searchResults = [];
      }

      this.waitingMarketOutcome = false;
      this.marketOutcome = null;
    },

    async searchListingsBySeller(type: SellType) {
      this.activeType = type;
      this.marketOutcome = null;
      this.waitingMarketOutcome = true;

      try {
        if(useBlockchain){
          await this.searchListingsBySellerThroughChain();
        }
        else {
          await this.searchListingsBySellerThroughAPI();
        }
      } catch {
        this.searchResultsOwned = false;
        this.waitingMarketOutcome = false;
        this.searchResults = [];
      }

      this.waitingMarketOutcome = false;
    },

    async searchListingsBySellerThroughChain(){
      this.searchResults = await this.fetchMarketNftIdsBySeller({
        nftContractAddr: this.contractAddress,
        sellerAddr: this.search
      });

      this.searchResultsOwned = this.search === this.defaultAccount;
      this.searchResults = await this.filterOutTargetBuyers(this.searchResults) as string[];
    },

    async searchListingsBySellerThroughAPI(){
      this.searchResults = this.activeType === 'weapon' ?
        await this.searchWeaponListingsBySeller(this.search)
        : (this.activeType === 'character' ?
          await this.searchCharacterListingsBySeller(this.search)
          : await this.searchShieldListingsBySeller(this.search));

      this.searchResultsOwned = false;
    },
    async searchOwnListings(type: SellType) {
      this.marketOutcome = null;
      this.activeType = type;

      if(!this.defaultAccount) {
        this.searchResults = [];
        return;
      }

      this.waitingMarketOutcome = true;

      if(useBlockchain){
        await this.searchOwnListingsThroughChain();
      }
      else {
        await this.searchOwnListingsThroughAPI();
      }

      this.searchResultsOwned = true;
      this.waitingMarketOutcome = false;
    },

    async searchOwnListingsThroughChain() {
      this.searchResults = await this.fetchMarketNftIdsBySeller({
        nftContractAddr: this.contractAddress,
        sellerAddr: this.defaultAccount as string
      });
    },

    async searchOwnListingsThroughAPI(){
      this.searchResults = this.activeType === 'weapon' ?
        await this.searchWeaponListingsBySeller(this.defaultAccount as string):
        (this.activeType === 'character' ?
          await this.searchCharacterListingsBySeller(this.defaultAccount as string)
          : await this.searchShieldListingsBySeller(this.defaultAccount as string));
    },

    async searchCharacterListingsBySeller(sellerAddress: string): Promise<string[]>{
      const url = new URL(apiUrl('static/market/character'));
      const params = {
        element: '' + this.upperFirstChar(this.characterTraitFilter()),
        minLevel: '' + this.characterMinLevelFilter(),
        maxLevel: '' + this.characterMaxLevelFilter(),
        sortBy: '' + this.characterPriceOrder() ? 'price' : '',
        minPrice: '' + this.characterMinPriceFilter(),
        maxPrice: '' + this.characterMaxPriceFilter(),
        sortDir: '' + this.characterPriceOrder(),
        sellerAddress: '' + sellerAddress,
        network: this.activeChain(),
      };

      url.search = new URLSearchParams(params).toString();

      const charactersData = await fetch(url.toString());
      const characters = await charactersData.json();
      return characters.idResults;
    },

    async searchWeaponListingsBySeller(sellerAddress: string): Promise<string[]>{
      const url = new URL(apiUrl('static/market/weapon'));
      const params = {
        element: '' + this.upperFirstChar(this.weaponTraitFilter()),
        minStars: '' + (this.weaponStarFilter() !== 0 ?  this.weaponStarFilter() - 1 : 0),
        maxStars: '' + (this.weaponStarFilter() !== 0 ?  this.weaponStarFilter() - 1 : 4),
        sortBy: '' + this.weaponPriceOrder() ? 'price' : '',
        sortDir: '' + this.weaponPriceOrder(),
        minPrice: '' + this.weaponMinPriceFilter(),
        maxPrice: '' + this.weaponMaxPriceFilter(),
        pageSize: '' + (this.weaponShowLimit || defaultLimit),
        sellerAddress: '' + sellerAddress,
        network: this.activeChain(),
      };

      url.search = new URLSearchParams(params).toString();

      const weaponsData = await fetch(url.toString());
      const weapons = await weaponsData.json();
      return weapons.idResults;
    },

    async searchShieldListingsBySeller(sellerAddress: string): Promise<NftIdType[]>{
      const url = new URL(apiUrl('static/market/shield'));
      const params = {
        element: '' + this.upperFirstChar(this.nftTraitFilter()),
        minStars: '' + (this.nftStarFilter() !== 0 ?  this.nftStarFilter() - 1 : 0),
        maxStars: '' + (this.nftStarFilter() !== 0 ?  this.nftStarFilter() - 1 : 4),
        sortBy: '' + this.nftPriceOrder() ? 'price' : '',
        sortDir: '' + this.nftPriceOrder(),
        pageSize: '' + (this.shieldShowLimit || defaultLimit),
        sellerAddress: '' + sellerAddress,
        network: this.activeChain(),
      };

      url.search = new URLSearchParams(params).toString();

      const shieldsData = await fetch(url.toString());
      const shields = await shieldsData.json();
      return shields.idResults;
    },

    async searchItemsSoldBySeller(sellerAddress: string): Promise<any[]>{
      const url = new URL(apiUrl(`static/market/transactions/${sellerAddress}`));

      const weaponsData = await fetch(url.toString());
      const weapons = await weaponsData.json();
      return weapons.results;
    },

    async showWeaponsSoldModal() {
      const weaponHistory: IWeaponHistory[] = await this.searchItemsSoldBySeller(this.defaultAccount as string);
      this.weaponTransactionHistoryHeader = [
        {
          key: 'weaponId',
          sortable: true,
          label: 'Weapon ID'
        },
        {
          key: 'weaponName',
          sortable: true,
          label: 'Name'
        },
        {
          key: 'weaponPrice',
          label: 'Price',
          sortable: true,
        }
      ];

      this.characterTransactionHistoryHeader = [
        {
          key: 'charId',
          sortable: true,
          label: 'Character ID'
        },
        {
          key: 'charName',
          sortable: true,
          label: 'Name'
        },
        {
          key: 'charPrice',
          label: 'Price',
          sortable: true,
        }
      ];
      if(weaponHistory.length === 0){
        this.historyCounter = 0;
      }
      else{
        this.historyCounter = weaponHistory.length;
        for (let i = 0; i<weaponHistory.length; ++i){
          if(weaponHistory[i].type === 'weapon' && weaponHistory !== undefined){
            // eslint-disable-next-line prefer-const
            let items: WeaponTransactionHistoryData = {
              weaponId: weaponHistory[i].weaponId,
              weaponName: getCleanName(this.getWeaponName(weaponHistory[i].weaponId, weaponHistory[i].weaponStars)),
              weaponPrice: weaponHistory[i].price
            };

            this.weaponTransactionHistoryData.push(items);
          }
        }
      }

      (this.$refs['weapons-sold-modal'] as BModal).show();
    },
    async showCharactersSoldModal() {
      const characterHistory: ICharacterHistory[] = await this.searchItemsSoldBySeller(this.defaultAccount as string);
      this.characterTransactionHistoryHeader = [
        {
          key: 'charId',
          sortable: true,
          label: 'Character ID'
        },
        {
          key: 'charName',
          sortable: true,
          label: 'Name'
        },
        {
          key: 'charPrice',
          label: 'Price',
          sortable: true,
        }
      ];
      if(characterHistory.length === 0){
        this.historyCounter = 0;
      }
      else{
        this.historyCounter = characterHistory.length;
        for (let i = 0; i<characterHistory.length; ++i){

          if(characterHistory[i].type === 'character' && characterHistory !== undefined){
            // eslint-disable-next-line prefer-const
            let items: CharacterTransactionHistoryData = {
              charId: characterHistory[i].charId,
              charName: getCleanName(this.getCharacterName(characterHistory[i].charId)),
              charPrice: characterHistory[i].price
            };

            this.characterTransactionHistoryData.push(items);
          }
        }
      }

      (this.$refs['characters-sold-modal'] as BModal).show();
    },
    async showShieldsSoldModal() {
      const shieldHistory: IShieldHistory[] = await this.searchItemsSoldBySeller(this.defaultAccount as string);
      this.shieldTransactionHistoryHeader = [
        {
          key: 'shieldId',
          sortable: true,
          label: 'Shield ID'
        },
        {
          key: 'shieldName',
          sortable: true,
          label: 'Name'
        },
        {
          key: 'shieldPrice',
          label: 'Price',
          sortable: true,
        }
      ];

      if(shieldHistory.length === 0){
        this.historyCounter = 0;
      }
      else{
        this.historyCounter = shieldHistory.length;
        for (let i = 0; i<shieldHistory.length; ++i){
          if(shieldHistory[i].type === 'shield' && shieldHistory !== undefined){
            // eslint-disable-next-line prefer-const
            let items: ShieldTransactionHistoryData = {
              shieldId: shieldHistory[i].shieldId,
              shieldName: getShieldNameFromSeed(parseInt(shieldHistory[i].shieldId,10),shieldHistory[i].shieldStars),
              shieldPrice: shieldHistory[i].price
            };

            this.shieldTransactionHistoryData.push(items);
          }
        }
      }

      (this.$refs['shields-sold-modal'] as BModal).show();
    },


    resetTransactionHistoryValues(modalName: string){
      this.characterTransactionHistoryData = [];
      this.weaponTransactionHistoryData = [];
      this.shieldTransactionHistoryData = [];
      (this.$refs[modalName] as BModal).hide();
    },

    showListingSetupModal(changingPrice: boolean = false) {
      this.clearInputs();
      this.priceChangeModal = changingPrice;
      (this.$refs['listing-setup-modal'] as BModal).show();
    },

    async searchPrivateWeaponListings(): Promise<string[]>{
      this.activeType = 'weapon';
      const url = new URL('https://api.cryptoblades.io/static/market/weapon');
      const params = {
        element: '' + this.upperFirstChar(this.weaponTraitFilter()),
        minStars: '' +  (this.weaponStarFilter() !== 0 ?  this.weaponStarFilter() - 1 : 0),
        maxStars: '' +  (this.weaponStarFilter() !== 0 ?  this.weaponStarFilter() - 1 : 0),
        sortBy: '' + this.weaponPriceOrder() ? 'price' : '',
        sortDir: '' + this.weaponPriceOrder(),
        minPrice: '' + this.weaponMinPriceFilter(),
        maxPrice: '' + this.weaponMaxPriceFilter(),
        pageSize: '' + (this.weaponShowLimit || defaultLimit),
        buyerAddress: '' + this.defaultAccount,
        network: this.activeChain(),
      };

      url.search = new URLSearchParams(params).toString();

      const weaponsData = await fetch(url.toString());
      const weapons = await weaponsData.json();
      return weapons.idResults;
    },

    async searchPrivateCharacterListings(): Promise<string[]> {
      this.activeType = 'character';
      const url = new URL('https://api.cryptoblades.io/static/market/character');
      const params = {
        element: '' + this.upperFirstChar(this.characterTraitFilter()),
        minLevel: '' + this.characterMinLevelFilter(),
        maxLevel: '' + this.characterMaxLevelFilter(),
        sortBy: '' + this.characterPriceOrder() ? 'price' : '',
        minPrice: '' + this.characterMinPriceFilter(),
        maxPrice: '' + this.characterMaxPriceFilter(),
        sortDir: '' + this.characterPriceOrder(),
        buyerAddress: '' + this.defaultAccount,
        network: this.activeChain(),
      };

      url.search = new URLSearchParams(params).toString();

      const charactersData = await fetch(url.toString());
      const characters = await charactersData.json();
      return characters.idResults;
    },

    async searchPrivateShieldListings(): Promise<string[]> {
      this.activeType = 'character';
      const url = new URL('https://api.cryptoblades.io/static/market/character');
      const params = {
        element: '' + this.upperFirstChar(this.nftTraitFilter()),
        minStars: '' + (this.nftStarFilter() !== 0 ?  this.nftStarFilter() - 1 : 0),
        maxStars: '' + (this.nftStarFilter() !== 0 ?  this.nftStarFilter() - 1 : 4),
        sortBy: '' + this.nftPriceOrder() ? 'price' : '',
        sortDir: '' + this.nftPriceOrder(),
        pageSize: '' + (this.shieldShowLimit || defaultLimit),
        buyerAddress: '' + this.defaultAccount,
        network: this.activeChain(),
      };

      url.search = new URLSearchParams(params).toString();

      const charactersData = await fetch(url.toString());
      const characters = await charactersData.json();
      return characters.idResults;
    },

    async filterOutTargetBuyers(nftIds: NftId[]) {
      if(!this.contractAddress) return [];
      const results: string[] = [];

      await Promise.all(nftIds.map(async nftId => {
        const targetBuyer = (await this.lookupNftTargetBuyer(nftId))!;
        if(targetBuyer === defaultTargetBuyer || targetBuyer === this.defaultAccount) {
          results.push(nftId);
        }
      }));

      return results;
    },

    clearInputs() {
      this.listingSellPrice = '';
      this.listingTargetBuyer = '';
    },

    convertWeiToSkill(wei: string) {
      return fromWeiEther(wei);
    },
    convertSkillToWei(skill: string) {
      return Web3.utils.toWei(skill);
    },
    activeChain(): string {
      return (localStorage.getItem('currentChain') || 'BSC').toLowerCase();
    },
    characterMinLevelFilter(): number {
      return sessionStorage.getItem('character-levelfilter') ? +(sessionStorage.getItem('character-levelfilter') as string) - 1 : 0;
    },

    characterMaxLevelFilter(): number {
      return sessionStorage.getItem('character-levelfilter') ? +(sessionStorage.getItem('character-levelfilter') as string) + 8 : 255;
    },

    characterTraitFilter(): string {
      return sessionStorage.getItem('character-elementfilter') ? (sessionStorage.getItem('character-elementfilter') as string).toLowerCase() : '';
    },

    characterPriceOrder(): string {
      return sessionStorage.getItem('character-price-order') ? (sessionStorage.getItem('character-price-order') as string) : '';
    },

    characterMinPriceFilter(): string {
      return sessionStorage.getItem('character-price-minfilter') ? (sessionStorage.getItem('character-price-minfilter') as string) : '';
    },
    characterMaxPriceFilter(): string {
      return sessionStorage.getItem('character-price-maxfilter') ? (sessionStorage.getItem('character-price-maxfilter') as string) : '';
    },

    weaponTraitFilter(): string {
      return sessionStorage.getItem('market-weapon-elementfilter') ? (sessionStorage.getItem('market-weapon-elementfilter') as string).toLowerCase() : '';
    },

    weaponStarFilter(): number {
      return sessionStorage.getItem('market-weapon-starfilter') ? +(sessionStorage.getItem('market-weapon-starfilter') as string) : 0;
    },

    weaponPriceOrder(): string {
      return sessionStorage.getItem('market-weapon-price-order') ? (sessionStorage.getItem('market-weapon-price-order') as string) : '';
    },

    weaponMinPriceFilter(): string {
      return sessionStorage.getItem('market-weapon-price-minfilter') ? (sessionStorage.getItem('market-weapon-price-minfilter') as string) : '';
    },
    weaponMaxPriceFilter(): string {
      return sessionStorage.getItem('market-weapon-price-maxfilter') ? (sessionStorage.getItem('market-weapon-price-maxfilter') as string) : '';
    },

    nftTypeFilter(): string {
      return sessionStorage.getItem('market-nft-elementfilter') ? (sessionStorage.getItem('market-nft-elementfilter') as string).toLowerCase() : '';    },

    nftTraitFilter(): string {
      return sessionStorage.getItem('market-nft-elementfilter') ? (sessionStorage.getItem('market-nft-elementfilter') as string).toLowerCase() : '';
    },

    nftStarFilter(): number {
      return sessionStorage.getItem('market-nft-starfilter') ? +(sessionStorage.getItem('market-nft-starfilter') as string) : 0;
    },

    nftPriceOrder(): string {
      return sessionStorage.getItem('market-nft-price-order') ? (sessionStorage.getItem('market-nft-price-order') as string) : '';
    },

    convertStringToDecimal(val: string, maxDecimals: number) {
      return new BigNumber(val).toFixed(maxDecimals);
    },
    activeListingMarketTax(): string{
      if(this.activeType === 'weapon'){
        return this.weaponMarketTax;
      }

      if(this.activeType === 'character'){
        return this.characterMarketTax;
      }

      if(this.activeType === 'shield'){
        return this.shieldMarketTax;
      }

      return '0';
    },

    calculatedBuyerCost(listedPrice: number): string {
      return (0.01 * listedPrice * (100 + parseFloat(this.activeListingMarketTax()))).toFixed(8).replace(/(\.0+|0+)$/, '');
    },

    maxPrecisionSkill(listedPrice: string): string {
      return this.convertStringToDecimal(this.convertWeiToSkill(listedPrice), 8);
    },

    nftListingPageSize(): number {
      if(this.activeType === 'weapon'){
        return this.weaponShowLimit;
      }

      if(this.activeType === 'character'){
        return this.characterShowLimit;
      }

      if(this.activeType === 'shield'){
        return this.shieldShowLimit;
      }

      return defaultLimit;
    },

    upperFirstChar(input: string): string {
      if(input === ''){
        return '';
      }

      return input[0].toUpperCase() + input.slice(1);
    }

  },

  watch: {

    async searchResults(nftIds: CharacterId[] | WeaponId[] | ShieldId[]) {
      this.selectedNftId = null;

      await this.fetchNftPrices(nftIds);
      if(this.activeType === 'weapon') {
        await this.setupWeaponsWithIdsRenames(nftIds);
      } else if(this.activeType === 'character') {
        await this.setupCharactersWithIdsRenames(nftIds);
      }
    },

    async allSearchResults(nftIds: CharacterId[] | WeaponId[] | ShieldId[]) {
      this.selectedNftId = null;

      await this.fetchNftPrices(nftIds);
      if(this.activeType === 'weapon') {
        await this.setupWeaponsWithIdsRenames(nftIds);
      } else if(this.activeType === 'character') {
        await this.setupCharactersWithIdsRenames(nftIds);
      }
    }
  },

  filters: {
    maxDecimals(val: string, maxDecimals: number) {
      return new BigNumber(val).toFixed(maxDecimals);
    },
    dynamicDecimals(val: string, minDecimals: number, maxDecimals: number) {
      const parsedVal = new BigNumber(val);

      if(parsedVal < new BigNumber(Math.pow(10, -maxDecimals))){
        return '< ' + Math.pow(10, -maxDecimals).toFixed(maxDecimals);
      }

      for(let i = maxDecimals - 1; i >= minDecimals; i--){
        if(parsedVal < new BigNumber(Math.pow(10, -i))){
          return new BigNumber(val).toFixed(i + 1);
        }
      }

      return new BigNumber(val).toFixed(minDecimals);
    }
  },

  async mounted() {
    assert.ok(this.contracts.Weapons && this.contracts.Characters && this.contracts.Shields, 'Expected required contracts to be available');
    this.landSaleAllowed = await this.fetchIsLandSaleAllowed();
    this.reservedSaleAllowed = await this.reservedSalesAllowed();
  },
});
</script>

<style scoped>
.body {
  margin-top: 10px;
}

.button + .button {
  margin-left: 10px;
}

.search {
  width: 100%;
}

.search-buttons, .self-buttons {
  margin-top: 10px;
  display: flex;
  justify-content: space-around;
}

.result-weaponHistory {
  max-width: 12em;
}

.result-selected {
  outline: solid currentcolor 2px;
}

.sell-grid {
  display: flex;
  justify-content: center;
  flex-direction: column;
}

.outcome {
  margin: auto;
  text-align: center;
  font-size: 1em;
}

.modal-input {
  margin-bottom: 5px;
  margin-top: 5px;
}

.disabled-button {
  opacity: 0.65;
}

.transaction-history-text{
  color: #9e8a57 !important;
}

.transaction-history-header-text{
   color: #9e8a57;
  font-size: 34px;
}
.m-top-negative-5{
  margin-top: -5px;
}

.m-top-negative-50{
  margin-top: -50px;
}

.centered-text {
  text-align: center;
  padding: 10px;
}

.shop-horizontal-divider-top {
  margin-top: -10px;
  height: fit-content;
  width: 100%;
}

.shop-horizontal-divider {
  width: 100%;
}

.special-offer-items {
  height: 100%;
  width: 100%;
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}

.shop-items {
  height: 100%;
  width: 100%;
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}

.special-offer-bg {
  margin-top: -5px;
}

</style>
