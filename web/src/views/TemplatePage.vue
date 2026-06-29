<!-- Diese Datei ist eine geladene Vue-Datei die über den Router geladen wird, mit dieser Art können viele verschiedene Seiten dargestellt werden -->

<template>
	<div class="p-4">
		<h1 class="bg-black text-white text-xl font-semibold">Template Page</h1>
    <Icon icon="mdi:home" class="w-6 h-6" aria-hidden="true" />
	</div>
</template>
s
<script setup lang="ts">
import { getCurrentInstance } from "vue"; // Import um auf die globalen Properties zuzugreifen
import { nuiCallback, nuiCallbackAsync } from "@/nui/nuiCallbacks"; // Imports für NUI Callbacks
import { Icon } from "@iconify/vue"; // Zur Darstellung von Icons von https://iconify.design/

// Hier werden die Komponents importiert, sodass sie verwendet werden können

//Standard Zugriffe auf globale Properties welche den persistantStore und den Router bereitstellen ohne diese immer neu importieren zu müssen
const proxy = getCurrentInstance()!.proxy!;
const persistantStore = proxy.$persistantStore;
const router = proxy.$router;

//Imports für eigene Stores anhand des persistantStoreExample.ts Beispiels
// import { useExampleStore } from "@/stores/persistantStoreExample";
// const exampleStore = useExampleStore();

</script>
