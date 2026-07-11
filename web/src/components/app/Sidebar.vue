<script setup lang="ts">
import { computed, getCurrentInstance, ref } from "vue";
import { Icon } from "@iconify/vue";

const proxy = getCurrentInstance()!.proxy!;
const router = proxy.$router;

const isOpen = ref(true);

// Derives the sidebar nav list from the router's registered routes
const navRoutes = computed(() =>
	router
		.getRoutes()
		.filter((r) => typeof r.name === "string" && typeof r.path === "string")
		.filter((r) => r.path !== "/" && !r.path.includes(":") && r.path !== "")
		.map((r) => ({
			path: r.path,
			label: (r.meta?.navLabel as string | undefined) ?? (r.name as string),
		})),
);

const navBarClick = (url: string) => {
	router.push(url);
};
</script>

<template>
	<aside
		class="h-full text-white flex flex-col overflow-hidden select-none transition-[width] duration-300 ease-in-out"
		:class="isOpen ? 'w-64' : 'w-12'"
	>
		<div
			class="h-12 flex items-center px-2"
			:class="isOpen ? 'justify-between' : 'justify-center'"
		>
			<button
				type="button"
				class="p-2 rounded-md bg-neutral-800/40 hover:bg-neutral-800/70 active:bg-neutral-800/80 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/20"
				aria-label="Toggle sidebar"
				@click="isOpen = !isOpen"
			>
				<Icon
					:icon="isOpen ? 'mdi:chevron-left' : 'mdi:chevron-right'"
					class="w-6 h-6 text-white/90"
					aria-hidden="true"
				/>
			</button>
		</div>

		<nav v-if="isOpen" class="mx-2 mb-2 p-2 space-y-1.5 rounded-md">
			<button
				v-for="r in navRoutes"
				:key="r.path"
				type="button"
				class="w-full text-left px-3 py-2 rounded-md bg-neutral-800/30 hover:bg-neutral-800/60 active:bg-neutral-800/70 transition-colors text-sm font-medium tracking-wide focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/20"
				@click="navBarClick(r.path)"
			>
				{{ r.label }}
			</button>
			<button
				type="button"
				class="w-full text-left px-3 py-2 rounded-md bg-neutral-800/30 hover:bg-neutral-800/60 active:bg-neutral-800/70 transition-colors text-sm font-medium tracking-wide focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/20"
				@click="$persistantStore.closeNui()"
			>
				Schließen
			</button>
		</nav>
	</aside>
</template>
