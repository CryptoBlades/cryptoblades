export function settableForMutation(paramName: string, methodName: string) {
  return {
    get(): any {
      return (this as any)[paramName];
    },

    set(newValue: any) {
      (this as any)[methodName](newValue);
    }
  };
}
