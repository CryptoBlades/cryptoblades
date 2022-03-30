<template>
  <div class="p-1">
    <h2 class="mt-3">{{ $t('admin.treasury.addNewPartnerProject') }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-form-input v-model="newPartnerProject.name" :placeholder="$t('admin.treasury.projectName')"/>
      <b-form-input v-model="newPartnerProject.tokenSymbol" :placeholder="$t('admin.treasury.tokenSymbol')"/>
      <b-form-input v-model="newPartnerProject.tokenAddress" :placeholder="$t('admin.treasury.tokenAddress')"/>
      <b-form-input v-model="newPartnerProject.tokenSupply" type="number" number
                    :placeholder="$t('admin.treasury.tokenSupply')"/>
      <b-form-input v-model="newPartnerProject.tokenPrice" type="number" number
                    :placeholder="$t('admin.treasury.tokenPrice')"/>
      <b-form-input v-model="newPartnerProject.distributionTime" type="number" number
                    :placeholder="$t('admin.treasury.distributionTime')"/>
      <b-form-checkbox v-model="newPartnerProject.isActive">{{ $t('admin.treasury.isProjectActive') }}</b-form-checkbox>
      <b-form-input v-model="newPartnerProject.logo" :placeholder="$t('admin.treasury.logoUrl')"/>
      <b-form-input v-model="newPartnerProject.details" :placeholder="$t('admin.treasury.details')"/>
      <b-form-input v-model="newPartnerProject.website" :placeholder="$t('admin.treasury.websiteUrl')"/>
      <b-form-input v-model="newPartnerProject.note" :placeholder="$t('admin.treasury.noteOptional')"/>
      <b-button @click="addNewPartnerProject()" :disabled="addNewPartnerProjectButtonDisabled" variant="primary"
                class="text-nowrap">
        {{ $t('admin.treasury.addNewPartnerProject') }}
      </b-button>
    </div>
    <h2 class="mt-3">{{ $t('admin.treasury.findActivePartnerProjects') }}</h2>
    <div class="d-flex align-items-center gap-3 flex-wrap">
      <b-button @click="getActiveProjects()" :disabled="isLoading" variant="primary"
                class="text-nowrap">
        {{ $t('admin.treasury.findActivePartnerProjects') }}
      </b-button>
      <table class="table text-white" v-if="activeProjects.length">
        <thead>
        <tr>
          <th>{{ $t('admin.treasury.name') }}</th>
          <th>{{ $t('admin.treasury.symbol') }}</th>
          <th>{{ $t('admin.treasury.id') }}</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="activeProject in activeProjects" :key="activeProject.id">
          <td>{{ activeProject.name }}</td>
          <td>{{ activeProject.tokenSymbol }}</td>
          <td>{{ activeProject.id }}</td>
        </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions} from 'vuex';
import {isValidWeb3Address} from '../../../utils/common';

interface NewPartnerProject {
  name: string;
  tokenSymbol: string;
  tokenAddress: string;
  tokenSupply?: number;
  tokensClaimed?: number;
  tokenPrice?: number;
  distributionTime?: number;
  isActive: boolean;
  logo: string;
  details: string;
  website: string;
  note: string;
}

interface StoreMappedActions {
  addPartnerProject(payload: { partnerProject: NewPartnerProject }): Promise<void>;

  getActivePartnerProjects(): Promise<NewPartnerProject[]>;
}

interface Data {
  newPartnerProject: NewPartnerProject,
  activeProjects: NewPartnerProject[],
  isLoading: boolean;
}

export default Vue.extend({
  data() {
    return {
      newPartnerProject: {
        name: '',
        tokenSymbol: '',
        tokenAddress: '',
        tokenSupply: undefined,
        tokensClaimed: 0,
        tokenPrice: undefined,
        distributionTime: undefined,
        isActive: true,
        logo: '',
        details: '',
        website: '',
        note: '',
      },
      activeProjects: [],
      isLoading: false,
    } as Data;
  },

  computed: {
    addNewPartnerProjectButtonDisabled(): boolean {
      return !isValidWeb3Address(this.newPartnerProject.tokenAddress)
        || this.newPartnerProject.name === ''
        || this.newPartnerProject.tokenSymbol === ''
        || this.newPartnerProject.tokenSupply === undefined
        || this.newPartnerProject.tokensClaimed === undefined
        || this.newPartnerProject.tokenPrice === undefined
        || this.newPartnerProject.distributionTime === undefined
        || this.newPartnerProject.logo === ''
        || this.newPartnerProject.details === ''
        || this.newPartnerProject.website === ''
        || this.isLoading;
    },
  },

  methods: {
    ...mapActions([
      'addPartnerProject',
      'getActivePartnerProjects',
    ]) as StoreMappedActions,

    async getActiveProjects() {
      try {
        this.isLoading = true;
        this.activeProjects = await this.getActivePartnerProjects();
      } finally {
        this.isLoading = false;
      }
    },

    async addNewPartnerProject() {
      if (this.addNewPartnerProjectButtonDisabled) return;
      try {
        this.isLoading = true;
        await this.addPartnerProject({partnerProject: this.newPartnerProject});
        this.clearInputs();
      } finally {
        this.isLoading = false;
      }
    },

    clearInputs() {
      this.newPartnerProject.name = '';
      this.newPartnerProject.tokenSymbol = '';
      this.newPartnerProject.tokenAddress = '';
      this.newPartnerProject.tokenSupply = undefined;
      this.newPartnerProject.tokensClaimed = undefined;
      this.newPartnerProject.tokenPrice = undefined;
      this.newPartnerProject.distributionTime = undefined;
      this.newPartnerProject.logo = '';
      this.newPartnerProject.details = '';
      this.newPartnerProject.website = '';
      this.newPartnerProject.note = '';
    }
  },
});
</script>

<style scoped>
</style>
