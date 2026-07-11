<template>
  <div
    v-if="store.rentalPrompt"
    style="position:fixed;inset:0;background:rgba(15,17,21,0.55);display:flex;align-items:center;justify-content:center;z-index:9999;font-family:'Archivo',system-ui,sans-serif"
    @click.self="store.closeRentalPrompt()"
  >
    <div style="background:#fff;border-radius:16px;padding:26px 28px;max-width:420px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,0.25)">
      <div style="width:52px;height:52px;border-radius:14px;background:rgba(232,180,8,0.14);display:flex;align-items:center;justify-content:center;margin-bottom:16px">
        <iconify-icon icon="tabler:truck" width="26" style="color:#b58a05"></iconify-icon>
      </div>
      <div style="font-size:17px;font-weight:800;color:#1b1f24">{{ t('app.rental_prompt_title') }}</div>
      <div style="font-size:13px;color:#6b7280;margin-top:8px;line-height:1.6">
        {{ t('app.rental_prompt_intro') }}
        <strong>{{ store.rentalPrompt.vehicleName }}</strong> + <strong>{{ store.rentalPrompt.trailerName }}</strong>
        {{ t('app.rental_prompt_cost', { cost: store.rentalPrompt.intervalCost.toLocaleString(), minutes: store.rentalPrompt.intervalMinutes }) }}
      </div>
      <div style="display:flex;gap:10px;margin-top:20px">
        <button
          :disabled="isRenting"
          style="flex:1;background:#E8B408;color:#1b1f24;border:none;border-radius:11px;padding:12px;font-family:inherit;font-weight:700;font-size:13px;cursor:pointer"
          @click="confirmRent"
        >
          {{ isRenting ? t('app.renting') : t('app.rent_now') }}
        </button>
        <button
          :disabled="isRenting"
          style="flex:1;background:#fff;color:#6b7280;border:1px solid #e4e6e9;border-radius:11px;padding:12px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer"
          @click="store.closeRentalPrompt()"
        >
          {{ t('app.cancel') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { useI18n } from "vue-i18n";
import { useDashboardStore } from "@/stores/dashboardStore";
import { nuiCallback } from "@/nui/nuiCallbacks";

const store = useDashboardStore();
const isRenting = ref(false);
const { t } = useI18n();

async function confirmRent() {
  if (!store.rentalPrompt) return;
  isRenting.value = true;
  await nuiCallback("rentBundle", { orderId: store.rentalPrompt.orderId, mode: store.rentalPrompt.mode ?? 'solo' });
  isRenting.value = false;
  store.closeRentalPrompt();
}
</script>
