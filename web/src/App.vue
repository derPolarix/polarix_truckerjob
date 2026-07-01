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
import type { DashboardConfig, Order, VehicleOwned, VehicleShop, SkillBranch, SkillNode } from "@/stores/dashboardStore";

// Standard Zugriffe auf globale Properties welche den persistantStore und den Router bereitstellen ohne diese immer neu importieren zu müssen
const proxy = getCurrentInstance()!.proxy!;
const router = proxy.$router;
const persistantStore = proxy.$persistantStore;
const dashboardStore = useDashboardStore();

function mapServerResponse(data: any): Partial<DashboardConfig> {
	const p = data.player ?? {};
	const rawOrders: any[] = data.orders ?? [];
	const rawOwned: any[] = data.ownedVehicles ?? [];
	const rawShop: any[] = data.vehicleShop ?? [];
	const rawBranches: any[] = data.skillBranches ?? [];
	const playerSkills: string[] = p.skills ?? [];
	const equippedSlot: string = p.equipped_vehicle ?? '';
	const xpThresholds: number[] = data.xpThresholds ?? [];

	const fmtMoney = (v: number) => `$${(v ?? 0).toLocaleString()}`;
	const fmtMin = (m: number) => {
		if (!m) return '';
		const h = Math.floor(m / 60), r = m % 60;
		return h > 0 ? `${h}h${r > 0 ? ` ${r}m` : ''}` : `${r}m`;
	};

	const orders: Order[] = rawOrders.map((o: any) => ({
		id: String(o.id),
		name: o.name ?? '',
		cargo: o.cargo ?? '',
		weight: `${((o.weight_kg ?? 0) / 1000).toFixed(1)} t`,
		distance: `${(o.distance_km ?? 0).toFixed(1)} km`,
		reward: fmtMoney(o.reward_base),
		xp: `+${o.xp_base ?? 0}`,
		time: fmtMin(o.time_minutes),
		perKm: o.distance_km ? `${fmtMoney(Math.round((o.reward_base ?? 0) / o.distance_km))} / km` : '',
		lvlReq: `Lvl ${o.level_required ?? 1}`,
		pickup: o.pickup_label ?? '',
		pickupCity: o.pickup_city ?? '',
		pickupKm: '',
		driveKm: `${(o.distance_km ?? 0).toFixed(1)} km`,
		driveTime: fmtMin(o.time_minutes),
		dropoff: o.dropoff_label ?? '',
		dropoffCity: o.dropoff_city ?? '',
		dropoffKm: `${(o.distance_km ?? 0).toFixed(1)} km`,
		comment: o.comment ?? '',
		tag: o.tag ?? '',
		tagColor: o.tag_color ?? '#9aa1ab',
		tagBg: o.tag_bg ?? '#f1f2f4',
		icon: o.icon ?? 'tabler:package',
	}));

	const vehiclesOwned: VehicleOwned[] = rawOwned.map((v: any) => {
		const shopEntry = rawShop.find((s: any) => s.slot === v.vehicle_slot);
		return {
			name:     shopEntry?.name ?? v.vehicle_slot,
			cls:      shopEntry?.cls ?? '',
			slot:     v.vehicle_slot,
			speed:    String(shopEntry?.speed ?? ''),
			cap:      shopEntry?.cap_kg ? `${(shopEntry.cap_kg / 1000).toFixed(0)} t` : '',
			fuel:     shopEntry?.fuel_l ? `${shopEntry.fuel_l} L` : '',
			equipped: v.vehicle_slot === equippedSlot,
		};
	});

	const vehiclesShop: VehicleShop[] = rawShop.map((v: any) => ({
		name: v.name ?? '',
		cls: v.cls ?? '',
		slot: v.slot ?? '',
		speed: String(v.speed ?? ''),
		cap: `${((v.cap_kg ?? 0) / 1000).toFixed(0)} t`,
		fuel: `${v.fuel_l ?? 0} L`,
		price: fmtMoney(v.price),
		locked: (p.level ?? 1) < (v.level_required ?? 1),
		lvl: (v.level_required ?? 1) > 1 ? `Lvl ${v.level_required}` : '',
	}));

	const branches: SkillBranch[] = rawBranches.map((branch: any) => ({
		name: branch.name ?? '',
		icon: branch.icon ?? '',
		skills: (branch.skills ?? []).map((skill: any) => {
			const acquired = playerSkills.includes(skill.id);
			const prereqMet = !skill.requires || playerSkills.includes(skill.requires);
			return {
				id: skill.id,
				name: skill.name ?? '',
				desc: skill.desc ?? '',
				state: acquired ? 'acquired' : (prereqMet ? 'available' : 'locked'),
			} as SkillNode;
		}),
	}));

	const totalDeliveries = (p.total_deliveries ?? 0) + (p.failed_deliveries ?? 0);

	return {
		driverName: p.name ?? '',
		driverLevel: p.level ?? 1,
		driverXp: p.xp ?? 0,
		driverXpMax: xpThresholds[p.level ?? 1] ?? (p.xp ?? 0),
		skillPoints: p.skill_points ?? 0,
		balance: p.balance ?? 0,
		openOrders: orders.length,
		completedOrders: p.total_deliveries ?? 0,
		successRate: totalDeliveries > 0
			? `${Math.round((p.total_deliveries / totalDeliveries) * 100)}%`
			: '—',
		earnings: fmtMoney(p.total_earnings),
		orders,
		vehiclesOwned,
		vehiclesShop,
		branches,
	};
}

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
			router.push("/dashboard");
			dashboardStore.open(
				(raw.data as any)?.player !== undefined
					? mapServerResponse(raw.data)
					: (raw.data as Partial<DashboardConfig> | undefined)
			);
			break;
		case "updateOwnedVehicles": {
			const d = raw.data as { ownedVehicles: any[]; equippedSlot: string };
			const slot = d.equippedSlot ?? '';
			dashboardStore.config.vehiclesOwned = (d.ownedVehicles ?? []).map((v: any) => {
				const shopEntry = dashboardStore.config.vehiclesShop.find(s => s.slot === v.vehicle_slot);
				return {
					name:     shopEntry?.name ?? v.vehicle_slot,
					cls:      shopEntry?.cls ?? '',
					slot:     v.vehicle_slot,
					speed:    shopEntry?.speed ?? '',
					cap:      shopEntry?.cap ?? '',
					fuel:     shopEntry?.fuel ?? '',
					equipped: v.vehicle_slot === slot,
				} as VehicleOwned;
			});
			break;
		}
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
