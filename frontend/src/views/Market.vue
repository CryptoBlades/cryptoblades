<template>
  <div class="body main-font">

    <b-tabs justified>
      <b-tab @click="clearData();browseTabActive = true;skillShopTabActive = false">
        <template #title>
          Browse NFTs
          <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons and Characters are NFTs of the ERC721 standard" />
        </template>

        <div class="row mt-3">
          <div class="col">

            <div class="row button-row">
              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllCharacterListings(currentPage - 1)"  class="gtag-link-others" tagname="browse_characters">Browse Characters</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllWeaponListings(currentPage - 1)"  class="gtag-link-others" tagname="browse_weapons">Browse Weapons</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  @click="searchAllShieldListings(currentPage - 1)"  class="gtag-link-others" tagname="browse_shields">Browse Shields</b-button>
              </div>

              <div class="col"></div>
            </div>

            <div class="search-results">
              <b-pagination class="customPagination"
                v-visible="allSearchResults && allSearchResults.length > 0"
                align="center" v-model="currentPage"
                :total-rows="allListingsAmount"
                :per-page="activeType === 'weapon' ? weaponShowLimit : characterShowLimit"
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
                v-model="selectedNftId">

                <template #above="{ weapon: { id } }">
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
                    <span class="d-block text-center" v-else>Loading price...</span>
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
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>sold</span></div>
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

                    <span class="d-block text-center" v-else>Loading price...</span>
                    <b-button
                      :hidden="convertWeiToSkill(nftPricesById[id]) === '0'"
                      @click="selectedNftId = id; canPurchase && purchaseNft();"
                      variant="primary"
                      v-bind:class="[!canPurchase ? 'disabled-button' : '']"
                      class="gtag-link-others" tagname="confirm_purchase">
                      {{ convertWeiToSkill(nftPricesById[id]) !== '0' ? 'Purchase' : 'Sold' }} <b-icon-question-circle v-if="!canPurchase"
                      v-tooltip.bottom="'You already have max amount of characters (4).'"/>
                    </b-button>
                  </div>
                </template>

                <template #sold="{ character: { id } }">
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>sold</span></div>
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
                    <span class="d-block text-center" v-else>Loading price...</span>
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
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>sold</span></div>
                </template>

              </nft-list>

              <b-pagination class="customPagination"
                v-if="allSearchResults && allSearchResults.length > 0"
                align="center" v-model="currentPage"
                :total-rows="allListingsAmount"
                :per-page="activeType === 'weapon' ? weaponShowLimit :
                  (activeType === 'character' ? characterShowLimit : shieldShowLimit)"
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
              Loading...
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab @click="clearData();loadMarketTaxes(),browseTabActive = false;skillShopTabActive = false">
        <template #title>
          Search NFTs
          <hint class="hint" text="NFT stands for Non Fungible Token.<br>Weapons, Shields and Characters are NFTs of the ERC721 standard" />
        </template>

        <div class="row mt-3">
          <div class="col">
            <div class="d-flex justify-content-center">
               <input class="form-control search w-50" type="text" v-model.trim="search" placeholder="Seller Address, NFT ID" />
            </div>

            <div class="row buttons-row mt-3">
              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('character')"  class="gtag-link-others" tagname="search_character_id">Search Character ID</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('weapon')"  class="gtag-link-others" tagname="search_weapon_id">Search Weapon ID</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('weapon')"  class="gtag-link-others" tagname="weapons_seller">Weapons by Seller</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('character')"  class="gtag-link-others" tagname="characters_seller">Characters by Seller</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsByNftId('shield')"  class="gtag-link-others" tagname="search_shield_id">Search Shield ID</b-button>
              </div>

              <div class="col">
                <b-button
                  variant="primary"
                  :disabled="!search"
                  @click="searchListingsBySeller('shield')"  class="gtag-link-others" tagname="shields_seller">Shields by Seller</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('weapon')"  class="gtag-link-others" tagname="search_own_weapons">Search My Weapons</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('character')"  class="gtag-link-others" tagname="search_own_characters">Search My Characters</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  @click="searchOwnListings('shield')"  class="gtag-link-others" tagname="search_own_shields">Search My Shields</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  @click="showListingSetupModal(true)" class="gtag-link-others" tagname="change_price">Change Price</b-button>
              </div>

              <div class="col-4 col-md-3">
                <b-button
                  variant="primary"
                  v-if="ownListedNftSelected"
                  v-tooltip="'Cancelled sales cannot be re-listed for 24 hours!'"
                  @click="cancelNftListing()"  class="gtag-link-others" tagname="cancel_listing">Cancel Listing</b-button>
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
                v-model="selectedNftId">

                <template #above="{ weapon: { id } }">
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
                    <span class="d-block text-center" v-else>Loading price...</span>
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
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>sold</span></div>
                </template>

              </weapon-grid>

              <character-list
                :showFilters="true"
                v-if="activeType === 'character'"
                :showGivenCharacterIds="true"
                :characterIds="searchResults"
                :isMarket="true"
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
                    <span class="d-block text-center" v-else>Loading price...</span>
                    <b-button
                      v-if="id !== null && !searchResultsOwned"
                      :hidden="convertWeiToSkill(nftPricesById[id]) === '0'"
                      @click="selectedNftId = id; canPurchase && purchaseNft();"
                      variant="primary"
                      v-bind:class="[!canPurchase ? 'disabled-button' : '']"
                      class="gtag-link-others" tagname="confirm_purchase">
                      {{ convertWeiToSkill(nftPricesById[id]) !== '0' ? 'Purchase' : 'Sold' }} <b-icon-question-circle v-if="!canPurchase"
                      v-tooltip.bottom="'You already have max amount of characters (4).'"/>
                    </b-button>
                  </div>
                </template>

                <template #sold="{ character: { id } }">
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>sold</span></div>
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
                    <span class="d-block text-center" v-else>Loading price...</span>
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
                  <div class="sold" v-if="nftPricesById[id] && convertWeiToSkill(nftPricesById[id]) === '0'"><span>sold</span></div>
                </template>

              </nft-list>
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="outcome" v-if="waitingMarketOutcome">
              <i class="fas fa-spinner fa-spin"></i>
              Loading...
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab @click="clearData();loadMarketTaxes();browseTabActive = false;skillShopTabActive = false">
        <template #title>
          List NFTs
          <hint class="hint" text="When you list an NFT for sale, it is transferred to the<br>market until someone buys it or you cancel the sale" />
        </template>

        <div class="row mt-3">
          <div class="col">
            <div class="row button-row">
              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  @click="activeType = 'weapon'"  class="gtag-link-others" tagname="show_weapons_market">Show Weapons</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  @click="activeType = 'character'"  class="gtag-link-others" tagname="show_characters_market">Show Characters</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  @click="activeType = 'shield'"  class="gtag-link-others" tagname="show_shields_market">Show Shields</b-button>
              </div>

              <div class="col-4 col-md-3 col-lg-2 mb-2">
                <b-button
                  variant="primary"
                  v-if="activeType === 'weapon'"
                   class="gtag-link-others" tagname="add_listing_weapon"
                  :disabled="selectedNftId === null || selectedNftOnCooldown"
                  @click="showListingSetupModal()">List Weapon <b-icon-question-circle :hidden=!weaponMarketTax
                  v-tooltip.bottom="weaponMarketTax + '% tax (paid by the buyer) will be added to the final price.'"/></b-button>

                <b-button
                  variant="primary"
                  v-if="activeType === 'character'"
                  :disabled="selectedNftId === null || selectedNftOnCooldown"
                   class="gtag-link-others" tagname="add_listing_character"
                  @click="showListingSetupModal()">List Character <b-icon-question-circle :hidden=!characterMarketTax
                  v-tooltip.bottom="characterMarketTax + '% tax (paid by the buyer) will be added to the final price.'"/></b-button>

                <b-button
                  variant="primary"
                  v-if="activeType === 'shield'"
                   class="gtag-link-others" tagname="add_listing_shield"
                  :disabled="selectedNftId === null || selectedNftOnCooldown"
                  @click="showListingSetupModal()">List Shield <b-icon-question-circle :hidden=!shieldMarketTax
                  v-tooltip.bottom="shieldMarketTax + '% tax (paid by the buyer) will be added to the final price.'"/></b-button>

                <b-modal class="centered-modal" ref="listing-setup-modal"
                  @ok="!priceChangeModal ? addListingForNft() : updateNftListingPrice()">
                  <template #modal-title>
                    {{!priceChangeModal ? `Sell ${activeType}` : `Change ${activeType} price`}}
                  </template>
                  <b-form-input type="number" :max="10000"
                    class="modal-input" v-model="listingSellPrice" placeholder="Sell Price (SKILL)" />

                  <span v-if="listingSellPrice">
                    Do you want to sell your {{activeType}} for <CurrencyConverter :skill="Math.min(+listingSellPrice, 10000)"/>?<br>
                  <i>The buyer will pay an extra {{activeListingMarketTax()}}% market fee for a total of
                  <CurrencyConverter :skill="calculatedBuyerCost(Math.min(+listingSellPrice, 10000))"/></i></span>
                </b-modal>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                   class="gtag-link-others" tagname="show_weapons_sold"
                  @click="showWeaponsSoldModal()"> Weapons Sold
                  <b-icon-question-circle v-tooltip.bottom="'View weapons you have sold.'"/>
                </b-button>

                <b-modal class="centered-modal " ref="weapons-sold-modal">

                    <template #modal-header>
                         <div class="transaction-history-header-text">
                           Weapon Transaction History
                         </div>
                    </template>
                    <div v-if="historyCounter > 0">
                      <b-table class="transaction-history-text" :items="weaponTransactionHistoryData" :fields="weaponTransactionHistoryHeader"></b-table>
                    </div>
                    <div v-if="historyCounter === 0">
                      <p>It's seems like there's nothing here.</p>
                      <p>For tips on how to list NFTs, you may click this <strong><a href="https://cryptoblades.gitbook.io/wiki/market/marketplace#list-nfts" target="_blank">link</a></strong></p>
                    </div>
                    <template #modal-footer>
                    <b-button class="mt-3" block @click="resetTransactionHistoryValues('weapons-sold-modal')">Ok</b-button>
                    </template>


                </b-modal>

              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                   class="gtag-link-others" tagname="show_characters_sold"
                  @click="showCharactersSoldModal()"> Characters Sold
                  <b-icon-question-circle v-tooltip.bottom="'View characters you have sold.'"/>
                </b-button>

                <b-modal class="centered-modal " ref="characters-sold-modal">

                    <template #modal-header>
                         <div class="transaction-history-header-text">
                           Character Transaction History
                         </div>
                    </template>
                    <div v-if="historyCounter > 0">
                      <b-table class="transaction-history-text" :items="characterTransactionHistoryData" :fields="characterTransactionHistoryHeader"></b-table>
                    </div>
                    <div v-if="historyCounter === 0">
                      <p>It's seems like there's nothing here.</p>
                      <p>For tips on how to list NFTs, you may click this <strong><a href="https://cryptoblades.gitbook.io/wiki/market/marketplace#list-nfts" target="_blank">link</a></strong></p>
                    </div>
                    <template #modal-footer>
                    <b-button class="mt-3" block @click="resetTransactionHistoryValues('characters-sold-modal')">Ok</b-button>
                    </template>

                </b-modal>
              </div>

              <div class="col-4 col-md-3 col-lg-2">
                <b-button
                  variant="primary"
                   class="gtag-link-others" tagname="show_shields_sold"
                  @click="showShieldsSoldModal()"> Shields Sold
                  <b-icon-question-circle v-tooltip.bottom="'View shields you have sold.'"/>
                </b-button>

                <b-modal class="centered-modal " ref="shields-sold-modal">

                    <template #modal-header>
                         <div class="transaction-history-header-text">
                           Shield Transaction History
                         </div>
                    </template>
                    <div v-if="historyCounter > 0">
                      <b-table class="transaction-history-text" :items="shieldTransactionHistoryData" :fields="sieldTransactionHistoryHeader"></b-table>
                    </div>
                    <div v-if="historyCounter === 0">
                      <p>It's seems like there's nothing here.</p>
                      <p>For tips on how to list NFTs, you may click this <strong><a href="https://cryptoblades.gitbook.io/wiki/market/marketplace#list-nfts" target="_blank">link</a></strong></p>
                    </div>
                    <template #modal-footer>
                    <b-button class="mt-3" block @click="resetTransactionHistoryValues('shields-sold-modal')">Ok</b-button>
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
              Loading...
            </div>

            <div class="outcome" v-if="marketOutcome !== null">{{ marketOutcome }}</div>
          </div>
        </div>
      </b-tab>

      <b-tab @click="clearData();browseTabActive = false;skillShopTabActive = true">
        <template #title>
          Skill Shop
          <hint class="hint" text="You can buy various goods in here" />
        </template>

        <div>
          <div class="row">
            <div class="col-sm-4 centered-text">
              <h3>Specials</h3>
            </div>
            <div class="col-sm-8 centered-text">
              <h3>Shop</h3>
            </div>
            <img class="shop-horizontal-divider-top" src="../assets/divider4.png" />
          </div>
           <div class="row">
            <div class="col-sm-4 special-offer-items">
              <div class="special-offer-bg">
                 <nft-list :isShop="true" :nftIdTypes="specialOffersNftList"/>
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
import { BModal } from 'bootstrap-vue';
import { traitNameToNumber } from '@/contract-models';
import { market_blockchain as useBlockchain } from './../feature-flags';
import { CharacterTransactionHistoryData, ICharacterHistory,
  IWeaponHistory, WeaponTransactionHistoryData,
  IShieldHistory, ShieldTransactionHistoryData } from '@/interfaces/History';
import { getShieldNameFromSeed } from '@/shield-name';
import { fromWeiEther, apiUrl } from '../utils/common';
import NftList, { NftIdType } from '@/components/smart/NftList.vue';
import { getCleanName } from '../rename-censor';

type SellType = 'weapon' | 'character' | 'shield';
type WeaponId = string;
type CharacterId = string;
type ShieldId = string;
type NftId = WeaponId | CharacterId | ShieldId;

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
  priceChangeModal: boolean;
  weaponTransactionHistoryData: WeaponTransactionHistoryData[];
  weaponTransactionHistoryHeader: any;
  characterTransactionHistoryData: CharacterTransactionHistoryData[];
  characterTransactionHistoryHeader: any;
  shieldTransactionHistoryData: ShieldTransactionHistoryData[];
  shieldTransactionHistoryHeader: any;
  historyCounter: number;
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
  fetchMarketTax(payload: { nftContractAddr: string }): Promise<string>;
  checkMarketItemOwnership(payload: { nftContractAddr: string, tokenId: string | number}): Promise<string>;
  addMarketListing(payload: { nftContractAddr: string, tokenId: string, price: string }): Promise<{ seller: string, nftID: string, price: string }>;
  changeMarketListingPrice(
    payload: { nftContractAddr: string, tokenId: string, newPrice: string }
  ): Promise<{ seller: string, nftID: string, newPrice: string }>;
  cancelMarketListing(payload: { nftContractAddr: string, tokenId: string }): Promise<{ seller: string, nftID: string }>;
  purchaseMarketListing(payload: { nftContractAddr: string, tokenId: string, maxPrice: string }): Promise<{ seller: string, nftID: string, price: string }>;
  fetchSellerOfNft(payload: { nftContractAddr: string, tokenId: string }): Promise<string>;
  fetchTotalShieldSupply(): Promise<number>;
  setupWeaponsWithIdsRenames(weaponIds: string[]): Promise<void>;
  setupCharactersWithIdsRenames(weaponIds: string[]): Promise<void>;
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
      priceChangeModal: false,
      weaponTransactionHistoryData: [],
      weaponTransactionHistoryHeader: [],
      characterTransactionHistoryData: [],
      characterTransactionHistoryHeader: [],
      shieldTransactionHistoryData: [],
      shieldTransactionHistoryHeader: [],
      historyCounter: 0
    } as Data;
  },

  computed: {
    ...(mapState([
      'defaultAccount', 'weapons', 'characters', 'shields', 'ownedCharacterIds', 'ownedWeaponIds', 'ownedShieldIds',
    ]) as Accessors<StoreMappedState>),
    ...(mapGetters([
      'contracts', 'ownCharacters', 'totalShieldSupply','getCharacterName','getWeaponName'
    ]) as Accessors<StoreMappedGetters>),
    ...mapGetters(['transferCooldownOfCharacterId']),

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

    selectedNftOnCooldown(): boolean {
      return this.selectedNftId !== null
      && (this.activeType === 'weapon' || this.activeType === 'shield'
        ? false
        : (this.transferCooldownOfCharacterId(+this.selectedNftId) > 0));
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

      return nftList;
    },

    shopOffersNftList(): SkillShopListing[] {
      const nftList = [
        {
          id: 0,
          type: 'CharacterRenameTag',
          nftPrice: 0.1,
          name: 'Rename Tag',
          description: 'Renames one character.',
          image: 'scroll_06_te.png'
        },
        {
          id: 0,
          type: 'CharacterRenameTagDeal',
          nftPrice: 0.3,
          name: 'Rename Tag Deal',
          description: 'Renames 4 characters for the price of 3.',
          image: 'scroll_06_te4.png'
        },
        {
          id: 1,
          type: 'WeaponRenameTag',
          nftPrice: 0.1,
          name: 'Weapon Tag',
          description: 'Renames a weapon.',
          image: 'rune_05_te.png'
        },
        {
          id: 1,
          type: 'WeaponRenameTagDeal',
          nftPrice: 0.3,
          name: 'Weapon Tag Deal',
          description: 'Renames 4 weapons for the price of 3.',
          image: 'rune_05_te4.png'
        },
        {
          id: 1,
          type: 'CharacterEarthTraitChange',
          nftPrice: 0.2,
          name: 'Earth Character Trait',
          description: 'Changes character\'s trait to Earth.',
          image: 'potion_06_te.png'
        },
        {
          id: 1,
          type: 'CharacterFireTraitChange',
          nftPrice: 0.2,
          name: 'Fire Character Trait',
          description: 'Changes character\'s trait to Fire.',
          image: 'potion_09_te.png'
        },
        {
          id: 1,
          type: 'CharacterWaterTraitChange',
          nftPrice: 0.2,
          name: 'Water Character Trait',
          description: 'Changes character\'s trait to Water.',
          image: 'potion_07_te.png'
        },
        {
          id: 1,
          type: 'CharacterLightningTraitChange',
          nftPrice: 0.2,
          name: 'Lightning Character Trait',
          description: 'Changes character\'s trait to Lightning.',
          image: 'potion_05_te.png'
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
      'fetchMarketTax',
      'checkMarketItemOwnership',
      'addMarketListing',
      'changeMarketListingPrice',
      'cancelMarketListing',
      'purchaseMarketListing',
      'fetchSellerOfNft',
      'fetchTotalShieldSupply',
      'setupWeaponsWithIdsRenames',
      'setupCharactersWithIdsRenames',
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
      });

      this.selectedNftId = null;
      this.waitingMarketOutcome = false;
      this.marketOutcome = 'Successfully listed '
        +this.activeType+' '+results.nftID+' for '+this.convertWeiToSkill(results.price)+' SKILL';
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
      this.marketOutcome = 'Successfully changed price for '
        +this.activeType+' '+results.nftID+' to '+this.convertWeiToSkill(results.newPrice)+' SKILL';
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

      this.allSearchResults = results2;

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
        await this.searchAllCharacterListingsThroughChain(page);
      }
      else{
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
        element: '' + this.characterTraitFilter(),
        minLevel: '' + this.characterMinLevelFilter(),
        maxLevel: '' + this.characterMaxLevelFilter(),
        sortBy: '' + this.characterPriceOrder() ? 'price' : '',
        sortDir: '' + this.characterPriceOrder(),
        minPrice: '' + this.characterMinPriceFilter(),
        maxPrice: '' + this.characterMaxPriceFilter(),
        pageSize: '' + (this.characterShowLimit || defaultLimit),
        pageNum: '' + page,
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

      this.allSearchResults = await this.fetchAllMarketCharacterNftIdsPage({
        nftContractAddr: this.contractAddress,
        limit: this.characterShowLimit || defaultLimit,
        pageNumber: page,
        trait: traitNameToNumber(this.characterTraitFilter()),
        minLevel: this.characterMinLevelFilter(),
        maxLevel: this.characterMaxLevelFilter()
      });
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

      this.allSearchResults = await this.fetchAllMarketWeaponNftIdsPage({
        nftContractAddr: this.contractAddress,
        limit: this.weaponShowLimit || defaultLimit,
        pageNumber: page,
        trait: traitNameToNumber(this.weaponTraitFilter()),
        stars: filterStar
      });
    },
    async searchAllWeaponListingsThroughAPI(page: number) {
      const url = new URL(apiUrl('static/market/weapon'));
      const params = {
        element: '' + this.weaponTraitFilter(),
        minStars: '' + this.weaponStarFilter(),
        maxStars: '' + this.weaponStarFilter(),
        sortBy: '' + this.weaponPriceOrder() ? 'price' : '',
        sortDir: '' + this.weaponPriceOrder(),
        minPrice: '' + this.weaponMinPriceFilter(),
        maxPrice: '' + this.weaponMaxPriceFilter(),
        pageSize: '' + (this.weaponShowLimit || defaultLimit),
        pageNum: '' + page,
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
        element: '' + this.nftTraitFilter(),
        minStars: '' + this.nftStarFilter(),
        maxStars: '' + this.nftStarFilter(),
        sortBy: '' + this.nftPriceOrder() ? 'price' : '',
        sortDir: '' + this.nftPriceOrder(),
        pageSize: '' + (this.shieldShowLimit || defaultLimit),
        pageNum: '' + page,
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
        this.searchResults = [this.search];
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
        element: '' + this.characterTraitFilter(),
        minLevel: '' + this.characterMinLevelFilter(),
        maxLevel: '' + this.characterMaxLevelFilter(),
        sortBy: '' + this.characterPriceOrder() ? 'price' : '',
        minPrice: '' + this.characterMinPriceFilter(),
        maxPrice: '' + this.characterMaxPriceFilter(),
        sortDir: '' + this.characterPriceOrder(),
        sellerAddress: '' + sellerAddress,
      };

      url.search = new URLSearchParams(params).toString();

      const charactersData = await fetch(url.toString());
      const characters = await charactersData.json();
      return characters.idResults;
    },

    async searchWeaponListingsBySeller(sellerAddress: string): Promise<string[]>{
      const url = new URL(apiUrl('static/market/weapon'));
      const params = {
        element: '' + this.weaponTraitFilter(),
        minStars: '' + this.weaponStarFilter(),
        maxStars: '' + this.weaponStarFilter(),
        sortBy: '' + this.weaponPriceOrder() ? 'price' : '',
        sortDir: '' + this.weaponPriceOrder(),
        minPrice: '' + this.weaponMinPriceFilter(),
        maxPrice: '' + this.weaponMaxPriceFilter(),
        pageSize: '' + (this.weaponShowLimit || defaultLimit),
        sellerAddress: '' + sellerAddress,
      };

      url.search = new URLSearchParams(params).toString();

      const weaponsData = await fetch(url.toString());
      const weapons = await weaponsData.json();
      return weapons.idResults;
    },

    async searchShieldListingsBySeller(sellerAddress: string): Promise<NftIdType[]>{
      const url = new URL(apiUrl('static/market/shield'));
      const params = {
        element: '' + this.nftTraitFilter(),
        minStars: '' + this.nftStarFilter(),
        maxStars: '' + this.nftStarFilter(),
        sortBy: '' + this.nftPriceOrder() ? 'price' : '',
        sortDir: '' + this.nftPriceOrder(),
        pageSize: '' + (this.shieldShowLimit || defaultLimit),
        sellerAddress: '' + sellerAddress,
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

    clearInputs() {
      this.listingSellPrice = '';
    },

    convertWeiToSkill(wei: string) {
      return fromWeiEther(wei);
    },
    convertSkillToWei(skill: string) {
      return Web3.utils.toWei(skill);
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

  mounted() {
    assert.ok(this.contracts.Weapons && this.contracts.Characters && this.contracts.Shields, 'Expected required contracts to be available');
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
