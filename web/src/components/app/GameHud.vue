<template>
  <div v-if="visible" style="position:fixed;left:50%;transform:translateX(-50%);bottom:3vh;z-index:9998;pointer-events:none;font-family:'Archivo',system-ui,sans-serif;display:flex;flex-direction:column;align-items:center;gap:8px">
    <div v-if="heldAction" style="display:flex;align-items:center;gap:14px;padding:10px 20px;border-radius:12px;background:rgba(22,38,45,0.96);border-left:3px solid #E8B408;box-shadow:0 16px 50px rgba(0,0,0,0.45)">
      <div style="display:flex;align-items:center;gap:10px">
        <span style="font-weight:700;color:#fff;font-size:14px">{{ heldAction.name }}</span>
        <span v-if="heldAction.hint" style="color:#7a818c">•</span>
        <span v-if="heldAction.hint" style="color:#c9ced6;font-size:13px">{{ heldAction.hint }}</span>
      </div>
      <div style="width:1px;height:18px;background:rgba(255,255,255,0.12)"></div>
      <span style="font-size:13px;color:#9aa1ab">[<span style="color:#E8B408;font-weight:700">{{ heldAction.primaryKey }}</span>] {{ heldAction.primaryAction }}</span>
    </div>

    <div v-if="store.visible" style="display:flex;align-items:center;gap:18px;padding:12px 22px;border-radius:12px;background:rgba(22,38,45,0.94);border:1px solid rgba(255,255,255,0.06);box-shadow:0 16px 50px rgba(0,0,0,0.45)">
      <template v-if="store.phase">
        <span style="font-weight:800;font-size:14px;letter-spacing:0.04em;color:#E8B408">{{ statusText }}</span>
        <div style="width:1px;height:20px;background:rgba(255,255,255,0.12)"></div>
        <span style="font-size:13px;color:#c9ced6">{{ store.cargo }} → {{ store.city }}</span>
        <div style="width:1px;height:20px;background:rgba(255,255,255,0.12)"></div>
        <span style="font-family:'IBM Plex Mono',monospace;font-size:12px;color:#c9ced6">{{ store.distanceKm }} km · {{ store.speedKmh }} km/h</span>
      </template>

      <template v-if="store.palletsRequired > 0">
        <div v-if="store.phase" style="width:1px;height:20px;background:rgba(255,255,255,0.12)"></div>
        <span style="display:inline-flex;align-items:center;gap:6px;font-family:'IBM Plex Mono',monospace;font-size:12px;color:#c9ced6">
          <iconify-icon icon="tabler:stack-2" width="14" style="color:#9aa1ab"></iconify-icon>
          {{ store.palletsLoaded }} / {{ store.palletsRequired }} Paletten
        </span>
      </template>

      <template v-if="store.damage > 0">
        <div style="width:1px;height:20px;background:rgba(255,255,255,0.12)"></div>
        <span :style="{ fontFamily: `'IBM Plex Mono',monospace`, fontSize: '12px', fontWeight: 700, color: store.damage > 500 ? '#d24b3a' : '#E8B408' }">DMG: {{ store.damage }}</span>
      </template>

      <template v-if="store.inForklift">
        <div style="width:1px;height:20px;background:rgba(255,255,255,0.12)"></div>
        <span style="display:inline-flex;align-items:center;gap:6px;font-size:12px;color:#c9ced6">
          <iconify-icon icon="tabler:forklift" width="15" style="color:#E8B408"></iconify-icon>
          {{ store.forkliftCarrying ? 'Palette an Gabel' : 'Gabel leer' }}
        </span>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import { useGameHudStore } from "@/stores/gameHudStore";

const store = useGameHudStore();
const proxy = getCurrentInstance()!.proxy!;
const persistantStore = proxy.$persistantStore;

const statusText = computed(() => (store.phase === "pickup" ? "PICKUP" : store.phase === "delivering" ? "DELIVERING" : ""));
const heldAction = computed(() => (persistantStore?.isHoldingAction ? persistantStore.heldAction : null));
const visible = computed(() => store.visible || heldAction.value !== null);
</script>
