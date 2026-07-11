import { defineStore } from "pinia";
import { nuiCallbackAsync } from "@/nui/nuiCallbacks";

// Feldnamen bewusst 1:1 wie die DB-Spalten (snake_case) — kein Mapping-Layer wie im
// dashboardStore, da dieser Store nur von Admins genutzt wird und die Nähe zum Schema
// Wartung vereinfacht (siehe admin-mission-editor-plan.md: "so simpel wie möglich").

export interface PalletCoord {
  x: number;
  y: number;
  z: number;
}

export interface AdminOrder {
  id: string | null;
  name: string;
  cargo: string;
  cargo_type: string;
  weight_kg: number;
  distance_km: number;
  reward_base: number;
  xp_base: number;
  time_minutes: number;
  pickup_label: string;
  pickup_city: string;
  pickup_x: number | null;
  pickup_y: number | null;
  pickup_z: number | null;
  pickup_heading: number;
  pickup_pallet_coords: PalletCoord[];
  dropoff_label: string;
  dropoff_city: string;
  dropoff_x: number | null;
  dropoff_y: number | null;
  dropoff_z: number | null;
  dropoff_heading: number;
  comment: string;
  tag: string;
  tag_color: string;
  tag_bg: string;
  icon: string;
  level_required: number;
  requires_hazmat: boolean;
  requires_long_hauler: boolean;
  is_active: boolean;
  delivery_count: number;
  created_by: string | null;
  updated_by: string | null;
  updated_at: string | null;
}

export interface CargoTypePreset {
  label: string;
  cargo: string;
  tag: string;
  tag_color: string;
  tag_bg: string;
  icon: string;
}

// Werte übernommen aus server/sample_missions.lua (siehe admin-mission-editor-plan.md
// "Cargo-Type-Presets"). "valuable" steht zwar im Plantext, hat aber kein Sample-Mission-Gegenstück —
// Preset hier mit plausiblen Werten ergänzt (offene Frage, siehe Plan-Dokumentation Phase D).
export const CARGO_TYPE_PRESETS: Record<string, CargoTypePreset> = {
  standard: { label: "Standard", cargo: "Standard", tag: "STD", tag_color: "#3b82f6", tag_bg: "rgba(59,130,246,0.16)", icon: "tabler:package" },
  fragile: { label: "Fragile", cargo: "Fragile", tag: "FRAGILE", tag_color: "#b58a05", tag_bg: "rgba(232,180,8,0.16)", icon: "tabler:bottle" },
  hazmat: { label: "Hazmat", cargo: "Hazmat", tag: "HAZMAT", tag_color: "#dc2626", tag_bg: "rgba(220,38,38,0.16)", icon: "tabler:biohazard" },
  heavy: { label: "Heavy", cargo: "Heavy", tag: "HEAVY", tag_color: "#6b7280", tag_bg: "rgba(107,114,128,0.16)", icon: "tabler:crane" },
  live: { label: "Live Animals", cargo: "Live Animals", tag: "LIVE", tag_color: "#16a34a", tag_bg: "rgba(22,163,74,0.16)", icon: "tabler:paw" },
  valuable: { label: "Valuable", cargo: "High Value", tag: "VALUABLE", tag_color: "#8b5cf6", tag_bg: "rgba(139,92,246,0.16)", icon: "tabler:diamond" },
};

function emptyOrder(): AdminOrder {
  return {
    id: null,
    name: "",
    cargo_type: "standard",
    weight_kg: 1000,
    distance_km: 0,
    reward_base: 0,
    xp_base: 1,
    time_minutes: 60,
    pickup_label: "",
    pickup_city: "",
    pickup_x: null,
    pickup_y: null,
    pickup_z: null,
    pickup_heading: 0,
    pickup_pallet_coords: [],
    dropoff_label: "",
    dropoff_city: "",
    dropoff_x: null,
    dropoff_y: null,
    dropoff_z: null,
    dropoff_heading: 0,
    comment: "",
    ...CARGO_TYPE_PRESETS.standard,
    level_required: 1,
    requires_hazmat: false,
    requires_long_hauler: false,
    is_active: true,
    delivery_count: 0,
    created_by: null,
    updated_by: null,
    updated_at: null,
  };
}

// 1:1-Duplikat von shared/cargo.lua Cargo.CalcPalletCount — web/ kann kein Lua einbinden,
// PalletWeightKg/MaxPalletsPerOrder kommen daher als Zahlen aus dem openAdminMissions-Payload.
export function calcPalletCount(weightKg: number, palletWeightKg: number, maxPalletsPerOrder: number): number {
  const count = Math.ceil((weightKg || 0) / (palletWeightKg || 1000));
  return Math.max(1, Math.min(count, maxPalletsPerOrder || 10));
}

function mapRawOrder(raw: any): AdminOrder {
  return {
    id: raw.id ?? null,
    name: raw.name ?? "",
    cargo: raw.cargo ?? "",
    cargo_type: raw.cargo_type ?? "standard",
    weight_kg: raw.weight_kg ?? 0,
    distance_km: raw.distance_km ?? 0,
    reward_base: raw.reward_base ?? 0,
    xp_base: raw.xp_base ?? 0,
    time_minutes: raw.time_minutes ?? 0,
    pickup_label: raw.pickup_label ?? "",
    pickup_city: raw.pickup_city ?? "",
    pickup_x: raw.pickup_x ?? null,
    pickup_y: raw.pickup_y ?? null,
    pickup_z: raw.pickup_z ?? null,
    pickup_heading: raw.pickup_heading ?? 0,
    pickup_pallet_coords: Array.isArray(raw.pickup_pallet_coords) ? raw.pickup_pallet_coords : [],
    dropoff_label: raw.dropoff_label ?? "",
    dropoff_city: raw.dropoff_city ?? "",
    dropoff_x: raw.dropoff_x ?? null,
    dropoff_y: raw.dropoff_y ?? null,
    dropoff_z: raw.dropoff_z ?? null,
    dropoff_heading: raw.dropoff_heading ?? 0,
    comment: raw.comment ?? "",
    tag: raw.tag ?? "",
    tag_color: raw.tag_color ?? "#9aa1ab",
    tag_bg: raw.tag_bg ?? "#f1f2f4",
    icon: raw.icon ?? "tabler:package",
    level_required: raw.level_required ?? 1,
    requires_hazmat: !!raw.requires_hazmat,
    requires_long_hauler: !!raw.requires_long_hauler,
    is_active: raw.is_active === undefined ? true : !!raw.is_active,
    delivery_count: raw.delivery_count ?? 0,
    created_by: raw.created_by ?? null,
    updated_by: raw.updated_by ?? null,
    updated_at: raw.updated_at ?? null,
  };
}

export const useAdminMissionsStore = defineStore("adminMissions", {
  state: () => ({
    orders: [] as AdminOrder[],
    selectedId: null as string | null, // null + isNew=true => neue Order
    isNew: false,
    form: null as AdminOrder | null,
    palletWeightKg: 1000,
    maxPalletsPerOrder: 10,
    saving: false,
    error: null as string | null,
  }),
  getters: {
    palletPreview(state): number {
      if (!state.form) return 0;
      return calcPalletCount(state.form.weight_kg, state.palletWeightKg, state.maxPalletsPerOrder);
    },
  },
  actions: {
    setOrders(rawOrders: any[], palletWeightKg?: number, maxPalletsPerOrder?: number) {
      this.orders = (rawOrders ?? []).map(mapRawOrder);
      if (palletWeightKg) this.palletWeightKg = palletWeightKg;
      if (maxPalletsPerOrder) this.maxPalletsPerOrder = maxPalletsPerOrder;
    },
    selectOrder(id: string) {
      const order = this.orders.find((o) => o.id === id);
      if (!order) return;
      this.selectedId = id;
      this.isNew = false;
      this.form = { ...order, pickup_pallet_coords: order.pickup_pallet_coords.map((c) => ({ ...c })) };
      this.error = null;
    },
    newOrder() {
      this.selectedId = null;
      this.isNew = true;
      this.form = emptyOrder();
      this.error = null;
    },
    applyCargoType(type: string) {
      if (!this.form) return;
      const preset = CARGO_TYPE_PRESETS[type];
      if (!preset) return;
      this.form.cargo_type = type;
      this.form.cargo = preset.cargo;
      this.form.tag = preset.tag;
      this.form.tag_color = preset.tag_color;
      this.form.tag_bg = preset.tag_bg;
      this.form.icon = preset.icon;
    },
    recalcDistance() {
      if (!this.form) return;
      const f = this.form;
      if (f.pickup_x == null || f.dropoff_x == null) return;
      const dx = (f.dropoff_x ?? 0) - (f.pickup_x ?? 0);
      const dy = (f.dropoff_y ?? 0) - (f.pickup_y ?? 0);
      const dz = (f.dropoff_z ?? 0) - (f.pickup_z ?? 0);
      f.distance_km = Math.round((Math.sqrt(dx * dx + dy * dy + dz * dz) / 1000) * 10) / 10;
    },
    async useCurrentPositionForPickup() {
      const pos = await nuiCallbackAsync<{ x: number; y: number; z: number; heading: number }>("getCurrentPosition");
      if (!this.form) return;
      this.form.pickup_x = pos.x;
      this.form.pickup_y = pos.y;
      this.form.pickup_z = pos.z;
      this.form.pickup_heading = pos.heading;
      this.recalcDistance();
    },
    async useCurrentPositionForDropoff() {
      const pos = await nuiCallbackAsync<{ x: number; y: number; z: number; heading: number }>("getCurrentPosition");
      if (!this.form) return;
      this.form.dropoff_x = pos.x;
      this.form.dropoff_y = pos.y;
      this.form.dropoff_z = pos.z;
      this.form.dropoff_heading = pos.heading;
      this.recalcDistance();
      await this.setDropoffPreview(true);
    },
    async useCurrentPositionForPallet(index: number) {
      const pos = await nuiCallbackAsync<{ x: number; y: number; z: number; heading: number }>("getCurrentPosition");
      if (!this.form) return;
      this.form.pickup_pallet_coords[index] = { x: pos.x, y: pos.y, z: pos.z };
      await nuiCallbackAsync("adminPreviewPallet", { index, x: pos.x, y: pos.y, z: pos.z, heading: this.form.pickup_heading });
    },
    addPalletRow() {
      if (!this.form) return;
      this.form.pickup_pallet_coords.push({ x: this.form.pickup_x ?? 0, y: this.form.pickup_y ?? 0, z: this.form.pickup_z ?? 0 });
    },
    async removePalletRow(index: number) {
      if (!this.form) return;
      this.form.pickup_pallet_coords.splice(index, 1);
      await nuiCallbackAsync("adminConfirmPallet", { index });
    },
    async confirmPallet(index: number) {
      await nuiCallbackAsync("adminConfirmPallet", { index });
    },
    async clearGhosts() {
      await nuiCallbackAsync("adminClearGhosts");
    },
    async setDropoffPreview(active: boolean) {
      if (!this.form) return;
      await nuiCallbackAsync("adminSetDropoffPreview", {
        active,
        x: this.form.dropoff_x,
        y: this.form.dropoff_y,
        z: this.form.dropoff_z,
        heading: this.form.dropoff_heading,
      });
    },
    async generateGrid() {
      if (!this.form || this.form.pickup_x == null) return;
      const count = calcPalletCount(this.form.weight_kg, this.palletWeightKg, this.maxPalletsPerOrder);
      const res = await nuiCallbackAsync<{ ok: boolean; coords: PalletCoord[] }>("adminGenerateGrid", {
        x: this.form.pickup_x,
        y: this.form.pickup_y,
        z: this.form.pickup_z,
        heading: this.form.pickup_heading,
        count,
      });
      this.form.pickup_pallet_coords = res.coords ?? [];
    },
    async save(): Promise<boolean> {
      if (!this.form) return false;
      this.saving = true;
      this.error = null;
      try {
        if (this.isNew) {
          const res = await nuiCallbackAsync<{ ok: boolean; orderId?: string; err?: string }>("adminCreateOrder", { order: this.form });
          if (!res.ok) { this.error = res.err ?? "Erstellen fehlgeschlagen."; return false; }
        } else {
          const res = await nuiCallbackAsync<{ ok: boolean; err?: string }>("adminUpdateOrder", { orderId: this.form.id, order: this.form });
          if (!res.ok) { this.error = res.err ?? "Speichern fehlgeschlagen."; return false; }
        }
        await this.clearGhosts();
        await this.setDropoffPreview(false);
        await this.refetch();
        return true;
      } finally {
        this.saving = false;
      }
    },
    async setActive(orderId: string, isActive: boolean) {
      const res = await nuiCallbackAsync<{ ok: boolean }>("adminSetOrderActive", { orderId, isActive });
      if (res.ok) await this.refetch();
    },
    async remove(orderId: string) {
      const res = await nuiCallbackAsync<{ ok: boolean; err?: string }>("adminDeleteOrder", { orderId });
      if (res.ok) {
        this.selectedId = null;
        this.form = null;
        await this.refetch();
      } else {
        this.error = res.err ?? "Löschen fehlgeschlagen.";
      }
    },
    async forceRemove(orderId: string) {
      const res = await nuiCallbackAsync<{ ok: boolean; err?: string }>("adminForceDeleteOrder", { orderId });
      if (res.ok) {
        this.selectedId = null;
        this.form = null;
        await this.refetch();
      } else {
        this.error = res.err ?? "Löschen fehlgeschlagen.";
      }
    },
    async clone(orderId: string) {
      const res = await nuiCallbackAsync<{ ok: boolean; order?: any }>("adminCloneOrder", { orderId });
      if (res.ok && res.order) {
        this.selectedId = null;
        this.isNew = true;
        this.form = mapRawOrder(res.order);
      }
    },
    async testRun(orderId: string) {
      return await nuiCallbackAsync<{ ok: boolean }>("adminTestRunOrder", { orderId });
    },
    async importSampleMissions() {
      const res = await nuiCallbackAsync<{ ok: boolean }>("adminImportSampleMissions");
      if (res.ok) await this.refetch();
      return res.ok;
    },
    async refetch() {
      const res = await nuiCallbackAsync<{ ok: boolean; orders: any[] }>("adminListOrders");
      this.setOrders(res.orders ?? []);
      if (this.form?.id) {
        const stillThere = this.orders.find((o) => o.id === this.form?.id);
        if (stillThere) this.selectOrder(stillThere.id as string);
      }
    },
  },
});
