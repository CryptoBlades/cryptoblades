<template>
  <span class="hint"
    v-tooltip="{
      'content': text,
      'trigger': 'click, hover',
      'placement': 'auto',
      }">
    <i class="far fa-question-circle hint" />
  </span>
</template>

<script lang="ts">
import {PropType} from 'vue/types/options';

type Placement =
'auto' | 'auto-start' | 'auto-end' |
'top' | 'top-start' | 'top-end' |
'right' | 'right-start' | 'right-end' |
'bottom' | 'bottom-start' | 'bottom-end'|
'left' | 'left-start' | 'left-end';

export default {
  props: {
    text: {
      type: String,
      required: true,
    },
    placement: {
      type: Object as PropType<Placement>,
    },
  },
};
</script>

<style>
.hint {
  font-size: 0.85em;
}
</style>
