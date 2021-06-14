

declare module '*.vue' {
  import Vue from 'vue';
  export default Vue;
}

declare module '*.png' {
  const value: string;
  export default value;
}

declare module 'bootstrap-vue-dialog';

declare module 'vue/types/vue' {
  import Vue from 'vue';

  interface Vue {
    $dialog: any;
  }
}
