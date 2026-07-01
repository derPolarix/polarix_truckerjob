<!-- This is a Vue 3 single-file component -->
<template>
	<div class="w-full h-screen relative overflow-hidden">
		<!-- Dieses div fügt eine Development Sidebar hinzu. Über diese kann man zwischen verschiedenen Seiten navigieren.-->
		<!-- Schaue ins Komponent rein um neue routen zu aktivieren die in router/index.ts definiert sind.-->
		<!-- Dort kannst du bevor die route gesetzt wird auch noch eigenen Code im Switch Case einfügen.-->
		<div v-if="isDev" class="absolute inset-y-0 left-0 z-50">
			<Sidebar />
		</div>

		<main v-if="persistantStore.IsNuiOpen || isDev" class="w-full h-full">
			<router-view />
		</main>
	</div>
</template>

<script setup lang="ts">
// Alle Imports die hier getätigt werden sind global verfügbar im gesamten NUI Projekt
import { getCurrentInstance, onMounted } from "vue";
import type { NuiMessage } from "./type";
import { isDev } from "./main";
import Sidebar from "@/components/app/Sidebar.vue";
import { useDashboardStore } from "@/stores/dashboardStore";
import type { DashboardConfig } from "@/stores/dashboardStore";

// Standard Zugriffe auf globale Properties welche den persistantStore und den Router bereitstellen ohne diese immer neu importieren zu müssen
const proxy = getCurrentInstance()!.proxy!;
const router = proxy.$router;
const persistantStore = proxy.$persistantStore;
const dashboardStore = useDashboardStore();

// Einzige stelle an der handleMessage verwendet werden darf, sonst wird es später im Kompilierprozess immer wieder überschrieben
// und damit bis auf in einer zufälligen Datei nutzbar, während alle anderne Unbrauchbar werden.

const handleMessage = (event: MessageEvent) => {
	// Extrahiere die Action aus der Nachricht
	// Setze die Nachrichtendaten in const data um sie einfacher verwenden zu können
	// Entferne diese beiden nicht!
	const raw = event.data as NuiMessage;
	const action = raw.action;

	// Verarbeite die Nachricht basierend auf der Action
	// Greife auf die Daten aus "data" zu, z.B. raw.data?.message
	switch (action) {
		case "openNui":
			persistantStore.IsNuiOpen = true;
			dashboardStore.open(raw.data as Partial<DashboardConfig>);
			router.push("/dashboard");
			break;
		case "updateMessage":
			persistantStore.MessageData = (raw.data as { message?: string })?.message ?? null;
			break;
		default:
			break;
	}
};

// Handle ESC key um das UI zu schließen
const handleEscape = async (event: KeyboardEvent) => {
	if (event.key === "Escape" && persistantStore.IsNuiOpen) {
		try {
			await persistantStore.closeNui();
		} catch (error) {
			console.error("closeNUI failed:", error);
		}
	}
};

// Setup event listeners
onMounted(() => {
	window.addEventListener("message", handleMessage);
	window.addEventListener("keydown", handleEscape);
});
</script>
