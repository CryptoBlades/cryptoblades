export function settableForMutation(paramName, methodName) {
  return {
    get() {
      return this[paramName];
    },

    set(newValue) {
      this[methodName](newValue);
    }
  };
}
