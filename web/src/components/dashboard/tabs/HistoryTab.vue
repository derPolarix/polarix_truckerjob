<template>
  <div style="display:flex;flex-direction:column;gap:16px">
    <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden">
      <div style="display:flex;align-items:center;justify-content:space-between;padding:18px 20px 14px">
        <div style="font-size:15px;font-weight:700;color:#1b1f24">Delivery history</div>
        <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ store.config.recentRuns.length }} runs</span>
      </div>
      <div style="display:grid;grid-template-columns:2.2fr 1fr 1fr 1fr;gap:12px;padding:11px 20px;background:#f6f7f8;border-bottom:1px solid #eef0f2;font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab">
        <span>Route</span><span>Status</span><span>Reward</span><span>When</span>
      </div>
      <div
        v-for="r in store.config.recentRuns"
        :key="r.code"
        style="display:grid;grid-template-columns:2.2fr 1fr 1fr 1fr;gap:12px;padding:13px 20px;border-bottom:1px solid #f1f2f4;align-items:center"
      >
        <div style="display:flex;align-items:center;gap:10px;min-width:0">
          <div style="width:32px;height:32px;border-radius:9px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;flex-shrink:0">
            <iconify-icon :icon="r.icon" width="16" style="color:#6b7280"></iconify-icon>
          </div>
          <div style="min-width:0">
            <div style="font-size:13px;font-weight:600;color:#1b1f24;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ r.route }}</div>
            <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab">{{ r.code }}</div>
          </div>
        </div>
        <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.06em" :style="{ color: r.failed ? '#d24b3a' : '#2f9e63' }">{{ r.tag }}</span>
        <span style="font-size:13px;font-weight:700" :style="{ color: r.failed ? '#d24b3a' : '#1b1f24' }">{{ r.reward }}</span>
        <span style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab">{{ r.when }}</span>
      </div>
      <div v-if="store.config.recentRuns.length === 0" style="padding:32px 20px;text-align:center;font-size:13px;color:#9aa1ab">No deliveries yet.</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useDashboardStore } from "@/stores/dashboardStore";

const store = useDashboardStore();
</script>
