<template>
  <b-tab v-if="initialized" :class="hasTabAccess ? '' : 'disabled'">
    <template #title>
      {{ $t(`admin.tabs.${title}`) }}
      <Hint v-if="!hasTabAccess" :text="$t('admin.doNotHaveAccessTooltip')"/>
    </template>
    <RoleGranter v-if="contract && contract.methods.DEFAULT_ADMIN_ROLE" :contract="contract"
                 :roleMethod="contract.methods.DEFAULT_ADMIN_ROLE" roleName="DEFAULT_ADMIN"/>
    <RoleRevoker v-if="contract && contract.methods.DEFAULT_ADMIN_ROLE" :contract="contract"
                 :roleMethod="contract.methods.DEFAULT_ADMIN_ROLE" roleName="DEFAULT_ADMIN"/>
    <RoleGranter v-if="contract && contract.methods.GAME_ADMIN" :contract="contract"
                 :roleMethod="contract.methods.GAME_ADMIN" roleName="GAME_ADMIN"/>
    <RoleRevoker v-if="contract && contract.methods.GAME_ADMIN" :contract="contract"
                 :roleMethod="contract.methods.GAME_ADMIN" roleName="GAME_ADMIN"/>
    <RoleGranter v-if="contract && contract.methods.MINTER_ROLE" :contract="contract"
                 :roleMethod="contract.methods.MINTER_ROLE" roleName="MINTER_ROLE"/>
    <RoleRevoker v-if="contract && contract.methods.MINTER_ROLE" :contract="contract"
                 :roleMethod="contract.methods.MINTER_ROLE" roleName="MINTER_ROLE"/>
    <component :is="component" :contract="contract"/>
  </b-tab>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapActions, mapState} from 'vuex';
import {Contract} from '@/interfaces';
import {PropType} from 'vue/types/options';
import RoleGranter from '@/components/smart/RoleGranter.vue';
import RoleRevoker from '@/components/smart/RoleRevoker.vue';
import Hint from '@/components/Hint.vue';
import QuestsAdmin from './AdminTabs/QuestsAdmin.vue';
import CBKLandAdmin from './AdminTabs/CBKLandAdmin.vue';
import WeaponsAdmin from './AdminTabs/WeaponsAdmin.vue';
import BurningManagerAdmin from './AdminTabs/BurningManagerAdmin.vue';
import PartnerVaultAdmin from './AdminTabs/PartnerVaultAdmin.vue';
import TreasuryAdmin from './AdminTabs/TreasuryAdmin.vue';
import CryptoBladesAdmin from './AdminTabs/CryptoBladesAdmin.vue';
import BlacksmithAdmin from './AdminTabs/BlacksmithAdmin.vue';
import RaidAdmin from './AdminTabs/RaidAdmin.vue';
import SpecialWeaponsManagerAdmin from './AdminTabs/SpecialWeaponsManagerAdmin.vue';

interface StoreMappedActions {
  userHasDefaultAdminAccess(payload: { contract: Contract<any> }): Promise<boolean>;

  userHasGameAdminAccess(payload: { contract: Contract<any> }): Promise<boolean>;

  userHasMinterAccess(payload: { contract: Contract<any> }): Promise<boolean>;
}

interface Data {
  hasTabAccess: boolean;
  initialized: boolean;
}

export default Vue.extend({
  components: {
    Hint,
    RoleGranter,
    RoleRevoker,
    QuestsAdmin,
    CBKLandAdmin,
    WeaponsAdmin,
    BurningManagerAdmin,
    PartnerVaultAdmin,
    TreasuryAdmin,
    CryptoBladesAdmin,
    BlacksmithAdmin,
    RaidAdmin,
    SpecialWeaponsManagerAdmin,
  },
  props: {
    title: {
      type: String as PropType<string>,
      required: true,
    },
    contract: {
      type: Object as PropType<Contract<any>>,
      required: true,
    },
    component: {
      type: String as PropType<string>,
      required: true,
    },
  },

  data() {
    return {
      hasTabAccess: false,
      initialized: false,
    } as Data;
  },

  computed: {
    ...mapState(['defaultAccount']),
  },

  methods: {
    ...mapActions(['userHasDefaultAdminAccess', 'userHasGameAdminAccess', 'userHasMinterAccess']) as StoreMappedActions,

    async fetchData() {
      this.hasTabAccess = await this.userHasDefaultAdminAccess({contract: this.contract})
        || await this.userHasGameAdminAccess({contract: this.contract})
        || await this.userHasMinterAccess({contract: this.contract});
    },
  },

  async mounted() {
    await this.fetchData();
    this.initialized = true;
  },

  watch: {
    async defaultAccount(newVal) {
      if (newVal) {
        await this.fetchData();
      }
    },
  }
});
</script>

<style scoped lang="scss">
.disabled {
  color: gray !important;
  pointer-events: none;
}
</style>
