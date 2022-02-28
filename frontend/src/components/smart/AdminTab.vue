<template>
  <b-tab v-if="initialized" :class="hasTabAccess ? '' : 'disabled'">
    <template #title>
      {{ $t(`admin.tabs.${title}`) }}
      <Hint v-if="!hasTabAccess" :text="$t('admin.doNotHaveAccessTooltip')"/>
    </template>
    <RoleGranter v-if="contract" :contract="contract" :roleMethod="contract.methods.GAME_ADMIN" roleName="GAME_ADMIN"/>
    <RoleRevoker v-if="contract" :contract="contract" :roleMethod="contract.methods.GAME_ADMIN" roleName="GAME_ADMIN"/>
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
import QuestsAdmin from './AdminTabs/QuestsAdmin.vue';
import Hint from '@/components/Hint.vue';
import CBKLandAdmin from './AdminTabs/CBKLandAdmin.vue';
import WeaponsAdmin from './AdminTabs/WeaponsAdmin.vue';
import BurningManagerAdmin from './AdminTabs/BurningManagerAdmin.vue';
import PartnerVaultAdmin from './AdminTabs/PartnerVaultAdmin.vue';
import RoleRevoker from '@/components/smart/RoleRevoker.vue';

interface StoreMappedActions {
  userHasAdminAccess(payload: { contract: Contract<any> }): Promise<boolean>;

  userHasMinterAccess(payload: { contract: Contract<any> }): Promise<boolean>;
}

interface Data {
  hasTabAccess: boolean;
  initialized: boolean;
}

export default Vue.extend({
  components: {Hint, RoleGranter, RoleRevoker, QuestsAdmin, CBKLandAdmin, WeaponsAdmin, BurningManagerAdmin, PartnerVaultAdmin},
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
    ...mapActions(['userHasAdminAccess', 'userHasMinterAccess']) as StoreMappedActions,

    async fetchData() {
      this.hasTabAccess = await this.userHasAdminAccess({contract: this.contract}) || await this.userHasMinterAccess({contract: this.contract});
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
