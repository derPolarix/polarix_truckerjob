<template>
  <div style="display:flex;flex-direction:column;gap:16px">
    <div style="display:grid;grid-template-columns:1.4fr 1fr;gap:14px;align-items:start">
      <!-- Drivers -->
      <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden">
        <div style="padding:16px 20px 12px;display:flex;align-items:center;gap:9px">
          <iconify-icon icon="tabler:trophy" width="18" style="color:var(--accent)"></iconify-icon>
          <div style="font-size:15px;font-weight:700;color:#1b1f24">Top drivers</div>
        </div>
        <div style="display:grid;grid-template-columns:0.5fr 2fr 0.8fr 1fr 1fr;gap:12px;padding:11px 20px;background:#f6f7f8;border-bottom:1px solid #eef0f2;font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab">
          <span>#</span><span>Driver</span><span>Lvl</span><span>Deliveries</span><span>Earned</span>
        </div>
        <div
          v-for="r in store.config.leaderboard"
          :key="r.rank"
          style="display:grid;grid-template-columns:0.5fr 2fr 0.8fr 1fr 1fr;gap:12px;padding:13px 20px;border-bottom:1px solid #f1f2f4;align-items:center"
          :style="{ background: r.isYou ? 'rgba(232,180,8,0.06)' : '#ffffff' }"
        >
          <span style="font-family:'IBM Plex Mono',monospace;font-size:13px;font-weight:700" :style="{ color: rankColor(r.rank) }">{{ r.rank }}</span>
          <div style="display:flex;align-items:center;gap:10px;min-width:0">
            <div style="width:30px;height:30px;border-radius:9px;background:#f1f2f4;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;color:#6b7280;flex-shrink:0">{{ r.name[0] }}</div>
            <span style="font-size:13px;font-weight:600;color:#1b1f24;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ r.name }}</span>
          </div>
          <span style="font-size:13px;color:#3c424b">{{ r.level }}</span>
          <span style="font-size:13px;color:#3c424b">{{ r.deliveries }}</span>
          <span style="font-size:13px;font-weight:600;color:#1b1f24">{{ r.earned }}</span>
        </div>
        <div v-if="store.config.leaderboard.length === 0" style="padding:24px 20px;text-align:center;font-size:13px;color:#9aa1ab">No drivers ranked yet.</div>
      </div>

      <!-- Companies -->
      <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden">
        <div style="padding:16px 20px 12px;display:flex;align-items:center;gap:9px">
          <iconify-icon icon="tabler:building-warehouse" width="18" style="color:var(--accent)"></iconify-icon>
          <div style="font-size:15px;font-weight:700;color:#1b1f24">Top companies</div>
        </div>
        <div v-for="c in store.config.companyLeaderboard" :key="c.rank" style="display:flex;align-items:center;gap:12px;padding:12px 20px;border-bottom:1px solid #f1f2f4">
          <span style="font-family:'IBM Plex Mono',monospace;font-size:13px;font-weight:700;width:16px" :style="{ color: rankColor(c.rank) }">{{ c.rank }}</span>
          <div style="flex:1;min-width:0">
            <div style="font-size:13px;font-weight:600;color:#1b1f24;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ c.name }}</div>
            <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab">{{ c.tag }} · Lvl {{ c.level }} · {{ c.deliveries }} deliveries</div>
          </div>
          <span style="font-size:13px;font-weight:600;color:#1b1f24;flex-shrink:0">{{ c.earned }}</span>
        </div>
        <div v-if="store.config.companyLeaderboard.length === 0" style="padding:24px 20px;text-align:center;font-size:13px;color:#9aa1ab">No companies ranked yet.</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useDashboardStore } from "@/stores/dashboardStore";

const store = useDashboardStore();

function rankColor(rank: number) {
  if (rank === 1) return "#e8b408";
  if (rank === 2) return "#9aa1ab";
  if (rank === 3) return "#b5651d";
  return "#c9cdd3";
}
</script>
