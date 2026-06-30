<template>
  <div style="display:flex;flex-direction:column;gap:18px">
    <!-- Hero banner -->
    <div style="position:relative;border-radius:18px;overflow:hidden;background:#22262d;padding:26px 30px;display:flex;align-items:center;gap:24px">
      <div style="position:absolute;left:0;top:0;right:0;height:4px;background:repeating-linear-gradient(45deg,var(--accent) 0 11px,#1b1f24 11px 22px)"></div>
      <div style="flex:1;min-width:0">
        <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;letter-spacing:0.16em;text-transform:uppercase;color:var(--accent);margin-bottom:9px">Dashboard</div>
        <div style="font-size:30px;font-weight:800;color:#fff;letter-spacing:-0.02em;line-height:1.05">Welcome back, {{ store.config.driverName }}</div>
        <div style="margin-top:9px;font-size:13px;color:#9aa1ab;display:flex;align-items:center;gap:14px">
          <span>Lvl {{ store.config.driverLevel }}</span>
          <span style="color:#454c56">·</span>
          <span>{{ store.config.openOrders }} orders open</span>
          <span style="color:#454c56">·</span>
          <span style="display:inline-flex;align-items:center;gap:6px">
            <span style="width:7px;height:7px;border-radius:50%;background:#6b7280"></span>No active delivery
          </span>
        </div>
      </div>
      <button @click="store.setTab('orders')" class="accent-btn" style="padding:13px 20px;font-size:14px;display:inline-flex;align-items:center;gap:9px;white-space:nowrap">
        Browse orders <iconify-icon icon="tabler:arrow-right" width="18"></iconify-icon>
      </button>
    </div>

    <!-- Stat cards -->
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:14px">
      <div v-for="stat in stats" :key="stat.label" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
        <div style="width:40px;height:40px;border-radius:11px;display:flex;align-items:center;justify-content:center" :style="{ background: stat.tileBg }">
          <iconify-icon :icon="stat.icon" width="21" :style="{ color: stat.color }"></iconify-icon>
        </div>
        <div style="font-size:26px;font-weight:800;letter-spacing:-0.02em;color:#1b1f24;margin-top:16px">{{ stat.value }}</div>
        <div style="font-size:13px;font-weight:600;color:#3c424b;margin-top:2px">{{ stat.label }}</div>
        <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.04em;color:#9aa1ab;margin-top:6px">{{ stat.sub }}</div>
      </div>
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;align-items:start">
      <!-- Active delivery -->
      <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px 18px 0;min-height:330px;display:flex;flex-direction:column">
        <div style="display:flex;align-items:center;justify-content:space-between">
          <div style="font-size:15px;font-weight:700;color:#1b1f24">Active delivery</div>
          <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.06em;color:#9aa1ab;text-transform:uppercase">Idle</span>
        </div>
        <div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:24px 24px 30px">
          <div style="width:64px;height:64px;border-radius:18px;background:#f1f2f4;display:flex;align-items:center;justify-content:center">
            <iconify-icon icon="tabler:truck" width="32" style="color:#aab0b8"></iconify-icon>
          </div>
          <div style="font-size:15px;font-weight:600;color:#3c424b;margin-top:16px">No active delivery</div>
          <div style="font-size:13px;color:#9aa1ab;margin-top:4px">Accept an order to start earning</div>
          <button @click="store.setTab('orders')" style="margin-top:18px;background:#22262d;color:#fff;border:none;border-radius:10px;padding:10px 18px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer;display:inline-flex;align-items:center;gap:8px">
            Browse orders <iconify-icon icon="tabler:arrow-right" width="16"></iconify-icon>
          </button>
        </div>
      </div>

      <!-- Recent runs -->
      <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px">
          <div style="font-size:15px;font-weight:700;color:#1b1f24">Recent runs</div>
          <button @click="store.setTab('orders')" style="background:transparent;border:none;cursor:pointer;font-family:inherit;font-size:12px;font-weight:600;color:var(--accent);display:inline-flex;align-items:center;gap:4px">
            View all <iconify-icon icon="tabler:chevron-right" width="14"></iconify-icon>
          </button>
        </div>
        <div v-for="r in store.config.recentRuns" :key="r.code" style="display:flex;align-items:center;gap:12px;padding:11px 2px;border-bottom:1px solid #eef0f2">
          <div style="width:34px;height:34px;border-radius:9px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;flex-shrink:0">
            <iconify-icon :icon="r.icon" width="17" style="color:#6b7280"></iconify-icon>
          </div>
          <div style="flex:1;min-width:0">
            <div style="font-size:13px;font-weight:600;color:#1b1f24;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ r.route }}</div>
            <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;margin-top:2px">{{ r.code }}</div>
          </div>
          <div style="text-align:right;flex-shrink:0">
            <div style="font-weight:700;font-size:13px" :style="{ color: r.failed ? '#d24b3a' : '#1b1f24' }">{{ r.reward }}</div>
            <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;margin-top:2px" :style="{ color: r.failed ? '#d24b3a' : '#9aa1ab' }">{{ r.tag }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useDashboardStore } from "@/stores/dashboardStore";

const store = useDashboardStore();

const stats = computed(() => [
  { icon: "tabler:cash-banknote", value: store.config.earnings, label: "Total earnings", sub: "ui.common.earnings", color: "#b58a05", tileBg: "rgba(232,180,8,0.16)" },
  { icon: "tabler:checks", value: String(store.config.completedOrders), label: "Completed", sub: "ui.common.deliveries", color: "#2f9e63", tileBg: "rgba(47,158,99,0.14)" },
  { icon: "tabler:trending-up", value: store.config.successRate, label: "Success rate", sub: "haul stats", color: "#3b82f6", tileBg: "rgba(59,130,246,0.14)" },
  { icon: "tabler:package", value: String(store.config.openOrders), label: "Available", sub: "ui.dashboard.orders_open", color: "#8b5cf6", tileBg: "rgba(139,92,246,0.14)" },
]);
</script>
