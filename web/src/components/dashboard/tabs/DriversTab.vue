<template>
  <div style="display:flex;flex-direction:column;gap:16px">
    <div>
      <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">{{ t('drivers.tab_title') }}</div>
      <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">{{ t('drivers.passive_income') }}</div>
    </div>

    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:14px">
      <div v-for="d in store.config.driverSlots" :key="d.slot" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden;display:flex;flex-direction:column">
        <div style="position:relative">
          <div style="width:100%;height:150px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;overflow:hidden;position:relative">
            <!-- portraits are full-body renders; enlarge + top-anchor so overflow:hidden crops the
                 bottom 15% (legs/feet), keeping the framing on the upper body -->
            <img v-if="driverImages[d.slot]" :src="driverImages[d.slot]" :alt="slotLabel(d.slot)" style="position:absolute;top:0;left:0;width:100%;height:117.65%;object-fit:contain" />
            <iconify-icon v-else icon="tabler:user" width="48" style="color:#aab0b8"></iconify-icon>
          </div>
          <div v-if="d.locked" style="position:absolute;inset:0;background:rgba(34,38,45,0.55);display:flex;align-items:center;justify-content:center">
            <iconify-icon icon="tabler:lock" width="26" style="color:#fff"></iconify-icon>
          </div>
        </div>
        <div style="padding:15px 16px;display:flex;flex-direction:column;flex:1">
          <div style="font-size:15px;font-weight:700;color:#1b1f24;line-height:1.2">{{ slotLabel(d.slot) }}</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;margin-top:5px">{{ t('drivers.income_per_interval', { amount: d.income, minutes: store.config.driverIncomeIntervalMinutes }) }}</div>

          <div style="margin-top:auto;padding-top:14px">
            <div v-if="d.hired" style="width:100%;text-align:center;padding:10px;border-radius:10px;background:rgba(47,158,99,0.12);color:#2f9e63;font-weight:700;font-size:13px;display:inline-flex;align-items:center;justify-content:center;gap:7px">
              <iconify-icon icon="tabler:circle-check-filled" width="16"></iconify-icon>{{ t('drivers.hired_badge') }}
            </div>
            <div v-else-if="d.locked" style="display:flex;align-items:center;justify-content:space-between;gap:8px">
              <span style="font-size:14px;font-weight:800;color:#1b1f24">{{ d.price }}</span>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;padding:7px 11px;border-radius:9px;background:#f1f2f4;color:#9aa1ab">{{ t('drivers.level_required', { level: d.levelRequired }) }}</span>
            </div>
            <button v-else class="accent-btn" style="width:100%;padding:10px;font-size:13px;justify-content:center" @click="hire(d.slot)">
              {{ t('drivers.hire') }} · {{ d.price }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from "vue-i18n";
import { useDashboardStore } from "@/stores/dashboardStore";
import { nuiCallback } from "@/nui/nuiCallbacks";

const store = useDashboardStore();
const { t } = useI18n();

const driverImageFiles = import.meta.glob<{ default: string }>("@/assets/drivers/*.png", { eager: true });
const driverImages: Record<string, string> = {};
for (const path in driverImageFiles) {
  const slot = path.split("/").pop()!.replace(".png", "");
  driverImages[slot] = driverImageFiles[path].default;
}

function slotLabel(slot: string): string {
  // internal slot keys (driver_0, driver_1, ...) stay 0-indexed for DB/config
  // stability - only the displayed label is shifted to a 1-based count.
  const n = parseInt(slot.split("_").pop() ?? "0", 10) + 1;
  return t('drivers.slot_label', { n });
}

async function hire(slot: string) {
  const res = await nuiCallback<{ ok: boolean }>('hireDriver', { slot });
  if (res?.ok) await nuiCallback('refetchDashboard');
}
</script>
