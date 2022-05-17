import {
  IState,
} from '@/interfaces';

const defaultCallOptions = (rootState:  IState) => ({ from: rootState.defaultAccount });

const land = {
  namespaced: true,
  actions: {
    async fetchOwnedLands({rootState}: {rootState: IState}) {
      const CBKLand = rootState.contracts().CBKLand!;

      if (!rootState.defaultAccount || !CBKLand) return;

      const landsIds = await CBKLand.methods
        .getOwned(rootState.defaultAccount)
        .call(defaultCallOptions(rootState));

      return await Promise.all(landsIds.map(landId => CBKLand.methods.get(landId).call(defaultCallOptions(rootState))));
    },

    async fetchOwnedLandIdsWithTier({rootState}: {rootState: IState}) {
      const CBKLand = rootState.contracts().CBKLand!;

      if (!rootState.defaultAccount || !CBKLand) return;

      const landsIds = await CBKLand.methods
        .getOwned(rootState.defaultAccount)
        .call(defaultCallOptions(rootState));

      const landIdsWithTier = await Promise.all(landsIds.map(async (landId: string) =>
      {
        const land = await CBKLand.methods.get(landId).call(defaultCallOptions(rootState));
        return { id: landId, tier: land[0] };
      }));

      return landIdsWithTier;
    },
  },
};


export default land;