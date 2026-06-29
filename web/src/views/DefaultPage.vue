<!-- Diese Datei ist eine geladene Vue-Datei die über den Router geladen wird, mit dieser Art können viele verschiedene Seiten dargestellt werden -->

<template>
	<div class="p-4 bg-blue-600">
		<!-- Dies ist ein Beispielkomponent, diese werden verwendet, um Teilübersichten innerhalb einer Seite auszulagern-->
		<!-- Ziel ist es eine bessere Struktur und Wiederverwendbarkeit zu erreichen. Abegelgt werden sie in -->
		<!-- dem components Ordner wie folgt: /components/{pagename}/{component} -->
		<h1>{{ persistantStore.MessageData || "Keine Nachricht verfügbar" }}</h1>
		<IconifyTest icon="mdi:home" />
	</div>
</template>

<script setup lang="ts">
import { getCurrentInstance } from "vue";
import { nuiCallback, nuiCallbackAsync } from "@/nui/nuiCallbacks";
// Hier werden die Komponents importiert, sodass sie verwendet werden können
import IconifyTest from "@/components/defaultpage/TestIconify.vue";

//Standard Zugriffe auf globale Properties welche den persistantStore und den Router bereitstellen ohne diese immer neu importieren zu müssen
const proxy = getCurrentInstance()!.proxy!;
const persistantStore = proxy.$persistantStore;

//Imports für eigene Stores anhand des persistantStoreExample.ts Beispiels

// import { useExampleStore } from "@/stores/persistantStoreExample";
// const exampleStore = useExampleStore();



</script>
