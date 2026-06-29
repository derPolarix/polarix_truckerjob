<!-- Iconify Test-Komponente (Beispiel) -->

<template>
  <!-- Hier ist ein Beispiel, um die Icon Library zu verwenden. Eine Liste mit Icons findest du auf https://iconify.design/ -->
  <!-- Das Komponent wird über ein Prop mit dem Icon das es darstellen bestückt (In der Defaultpage.vue)-->
  <div>
    <h1 class="flex items-center gap-2">
      <Icon :icon="props.icon" class="w-6 h-6" aria-hidden="true" />
      <span>Startseite</span>
    </h1>
    <p class="mt-2 text-sm opacity-80">
      Beispiel Icon das angezeigt wird: <code>{{ props.icon }}</code>
    </p>
  </div>
</template>

<script setup lang="ts">
import { Icon } from "@iconify/vue";

// Definiere die Props mit Standardwerten
const props = withDefaults(
  defineProps<{
    icon?: string;
  }>(),
  {
    icon: "mdi:home",
  }
);
</script>
