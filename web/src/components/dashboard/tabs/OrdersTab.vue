<template>
  <!-- Orders list -->
  <div v-if="!store.orderId" style="display:flex;flex-direction:column;gap:16px">
    <div style="display:flex;align-items:flex-end;justify-content:space-between;gap:16px">
      <div>
        <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">Available orders</div>
        <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">ui.dashboard.orders_open · {{ store.config.orders.length }} contracts</div>
      </div>
      <div style="display:flex;gap:8px">
        <span style="font-size:12px;font-weight:600;padding:8px 14px;border-radius:9px;background:#22262d;color:#fff">All</span>
        <span style="font-size:12px;font-weight:500;padding:8px 14px;border-radius:9px;background:#fff;border:1px solid #dfe2e6;color:#6b7280">Light</span>
        <span style="font-size:12px;font-weight:500;padding:8px 14px;border-radius:9px;background:#fff;border:1px solid #dfe2e6;color:#6b7280">Heavy</span>
        <span style="font-size:12px;font-weight:500;padding:8px 14px;border-radius:9px;background:#fff;border:1px solid #dfe2e6;color:#6b7280">Hazmat</span>
      </div>
    </div>
    <button
      v-for="o in store.config.orders"
      :key="o.id"
      class="order-row"
      style="display:flex;align-items:center;gap:18px;width:100%;text-align:left;background:#fff;border:1px solid #dfe2e6;border-radius:14px;padding:16px 18px;cursor:pointer;font-family:inherit"
      @click="store.openOrder(o.id)"
    >
      <div style="width:52px;height:52px;border-radius:13px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;flex-shrink:0">
        <iconify-icon :icon="o.icon" width="26" style="color:#5b626c"></iconify-icon>
      </div>
      <div style="width:200px;flex-shrink:0">
        <div style="display:flex;align-items:center;gap:9px">
          <span style="font-size:16px;font-weight:700;color:#1b1f24">{{ o.name }}</span>
          <span style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.06em;padding:2px 7px;border-radius:6px" :style="{ background: o.tagBg, color: o.tagColor }">{{ o.tag }}</span>
        </div>
        <div v-if="o.lvlReq" style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;margin-top:5px">{{ o.lvlReq }} required</div>
      </div>
      <div style="flex:1;display:grid;grid-template-columns:repeat(4,1fr);gap:14px">
        <div v-for="col in orderCols(o)" :key="col.label">
          <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab">{{ col.label }}</div>
          <template v-if="col.pill">
            <span style="display:inline-block;font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.06em;font-weight:600;padding:3px 8px;border-radius:6px;margin-top:4px" :style="{ background: col.pillBg, color: col.pillColor }">{{ col.value }}</span>
          </template>
          <div v-else style="font-size:14px;font-weight:700;margin-top:3px" :style="{ color: col.accent ? 'var(--accent)' : '#3c424b' }">{{ col.value }}</div>
        </div>
      </div>
      <iconify-icon icon="tabler:chevron-right" width="22" style="color:#c2c7ce;flex-shrink:0"></iconify-icon>
    </button>
  </div>

  <!-- Order detail -->
  <div v-else style="display:grid;grid-template-columns:7fr 3fr;gap:16px;min-height:860px">
    <div style="background:#fff;border:1px solid #dfe2e6;border-radius:16px;padding:20px 22px;display:flex;flex-direction:column;overflow-y:auto">
      <button style="align-self:flex-start;display:inline-flex;align-items:center;gap:7px;background:transparent;border:none;cursor:pointer;font-family:inherit;font-size:13px;font-weight:600;color:#6b7280;padding:0;margin-bottom:16px" @click="store.closeOrder()">
        <iconify-icon icon="tabler:arrow-left" width="17"></iconify-icon> Back to list
      </button>

      <div style="position:relative;height:150px;border-radius:13px;overflow:hidden;background:repeating-linear-gradient(135deg,#eef0f2 0 12px,#e7e9ec 12px 24px);display:flex;align-items:center;justify-content:center">
        <span style="position:absolute;top:12px;left:12px;font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;padding:3px 8px;border-radius:6px" :style="{ background: order.tagBg, color: order.tagColor }">{{ order.tag }}</span>
        <div style="text-align:center">
          <iconify-icon :icon="order.icon" width="44" style="color:#aab0b8"></iconify-icon>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.1em;text-transform:uppercase;color:#aab0b8;margin-top:8px">cargo render</div>
        </div>
      </div>

      <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:16px;margin-top:18px">
        <div style="font-size:24px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">{{ order.name }}</div>
        <span v-if="order.lvlReq" style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;white-space:nowrap;margin-top:6px">{{ order.lvlReq }} required</span>
      </div>
      <div style="display:flex;align-items:center;gap:20px;margin-top:10px;color:#6b7280;font-size:13px">
        <span style="display:inline-flex;align-items:center;gap:7px"><iconify-icon icon="tabler:clock" width="16" style="color:#9aa1ab"></iconify-icon>{{ order.time }}</span>
        <span style="display:inline-flex;align-items:center;gap:7px"><iconify-icon icon="tabler:weight" width="16" style="color:#9aa1ab"></iconify-icon>{{ order.weight }}</span>
        <span style="display:inline-flex;align-items:center;gap:7px"><iconify-icon icon="tabler:route" width="16" style="color:#9aa1ab"></iconify-icon>{{ order.distance }}</span>
      </div>

      <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.1em;text-transform:uppercase;color:#9aa1ab;margin:22px 0 14px">Route</div>
      <div style="display:flex;flex-direction:column">
        <!-- Pickup -->
        <div style="display:flex;gap:14px">
          <div style="display:flex;flex-direction:column;align-items:center">
            <div style="width:26px;height:26px;border-radius:50%;background:rgba(47,158,99,0.14);display:flex;align-items:center;justify-content:center"><iconify-icon icon="tabler:map-pin-filled" width="15" style="color:#2f9e63"></iconify-icon></div>
            <div style="width:2px;flex:1;background:repeating-linear-gradient(#cfd3d8 0 4px,transparent 4px 8px);margin:4px 0"></div>
          </div>
          <div style="flex:1;padding-bottom:18px;display:flex;justify-content:space-between;gap:12px">
            <div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.1em;text-transform:uppercase;color:#2f9e63">Pickup · A</div>
              <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-top:3px">{{ order.pickup }}</div>
              <div style="font-size:12px;color:#9aa1ab;margin-top:2px">{{ order.pickupCity }}</div>
            </div>
            <div style="text-align:right;flex-shrink:0">
              <div style="font-size:14px;font-weight:700;color:#3c424b">{{ order.pickupKm }}</div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab;margin-top:2px">to pickup</div>
            </div>
          </div>
        </div>
        <!-- Drive -->
        <div style="display:flex;gap:14px">
          <div style="display:flex;flex-direction:column;align-items:center">
            <div style="width:26px;height:26px;border-radius:50%;background:#f1f2f4;display:flex;align-items:center;justify-content:center"><iconify-icon icon="tabler:steering-wheel" width="15" style="color:#9aa1ab"></iconify-icon></div>
            <div style="width:2px;flex:1;background:repeating-linear-gradient(#cfd3d8 0 4px,transparent 4px 8px);margin:4px 0"></div>
          </div>
          <div style="flex:1;padding-bottom:18px;min-height:56px">
            <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.1em;text-transform:uppercase;color:#9aa1ab">Drive</div>
            <div style="font-size:13px;font-weight:600;color:#6b7280;margin-top:3px">{{ order.driveKm }} · est. {{ order.driveTime }}</div>
          </div>
        </div>
        <!-- Dropoff -->
        <div style="display:flex;gap:14px">
          <div style="display:flex;flex-direction:column;align-items:center">
            <div style="width:26px;height:26px;border-radius:50%;background:#22262d;display:flex;align-items:center;justify-content:center"><iconify-icon icon="tabler:flag-filled" width="13" style="color:#fff"></iconify-icon></div>
          </div>
          <div style="flex:1;display:flex;justify-content:space-between;gap:12px">
            <div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.1em;text-transform:uppercase;color:#1b1f24">Drop-off · B</div>
              <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-top:3px">{{ order.dropoff }}</div>
              <div style="font-size:12px;color:#9aa1ab;margin-top:2px">{{ order.dropoffCity }}</div>
            </div>
            <div style="text-align:right;flex-shrink:0">
              <div style="font-size:14px;font-weight:700;color:#3c424b">{{ order.dropoffKm }}</div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab;margin-top:2px">total</div>
            </div>
          </div>
        </div>
      </div>

      <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.1em;text-transform:uppercase;color:#9aa1ab;margin:22px 0 8px">Order comment</div>
      <div style="font-size:13px;color:#3c424b;background:#f6f7f8;border:1px solid #eef0f2;border-radius:11px;padding:13px 15px;display:flex;align-items:center;gap:10px">
        <iconify-icon icon="tabler:info-circle" width="18" style="color:var(--accent);flex-shrink:0"></iconify-icon>
        {{ order.comment }}
      </div>

      <div style="margin-top:auto;padding-top:22px;display:flex;align-items:center;gap:16px">
        <div style="flex:1">
          <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.1em;text-transform:uppercase;color:#9aa1ab">Reward</div>
          <div style="display:flex;align-items:baseline;gap:10px;margin-top:2px">
            <span style="font-size:26px;font-weight:800;letter-spacing:-0.02em;color:#1b1f24">{{ order.reward }}</span>
            <span style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab">{{ order.perKm }}</span>
          </div>
        </div>
        <div style="text-align:center;padding-right:4px">
          <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.1em;text-transform:uppercase;color:#9aa1ab">XP</div>
          <div style="display:inline-flex;align-items:center;gap:5px;margin-top:3px;font-size:16px;font-weight:700;color:#8b5cf6">
            <iconify-icon icon="tabler:star-filled" width="15"></iconify-icon>{{ order.xp }}
          </div>
        </div>
      </div>
      <button
        v-if="!inParty || isLeader"
        class="accent-btn"
        style="margin-top:14px;width:100%;padding:15px;font-size:15px;justify-content:center"
        @click="acceptOrder"
      >
        {{ inParty ? 'Start convoy mission' : 'Accept challenge' }} <iconify-icon icon="tabler:chevron-right" width="19"></iconify-icon>
      </button>
      <div v-else style="margin-top:14px;width:100%;padding:15px;font-size:13px;text-align:center;color:#9aa1ab;background:#f6f7f8;border:1px solid #eef0f2;border-radius:12px">
        Only the convoy leader can start a mission.
      </div>
    </div>

    <!-- Map placeholder -->
    <div style="position:relative;border-radius:16px;overflow:hidden;border:1px solid #dfe2e6;background:#dfe1e4;display:flex;align-items:center;justify-content:center">
      <div style="text-align:center;color:#aab0b8">
        <iconify-icon icon="tabler:map" width="48"></iconify-icon>
        <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;margin-top:8px">Live route</div>
      </div>
      <div style="position:absolute;bottom:14px;left:14px;width:34px;height:34px;border-radius:50%;background:var(--accent);display:flex;align-items:center;justify-content:center;box-shadow:0 4px 14px rgba(0,0,0,0.25)">
        <iconify-icon icon="tabler:flag-filled" width="16" style="color:#22262d"></iconify-icon>
      </div>
      <div style="position:absolute;top:12px;left:12px;font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#6b7280;background:rgba(255,255,255,0.85);padding:4px 9px;border-radius:7px">Live route</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useDashboardStore } from "@/stores/dashboardStore";
import { usePartyStore } from "@/stores/partyStore";
import { nuiCallback } from "@/nui/nuiCallbacks";
import type { Order } from "@/stores/dashboardStore";

const store = useDashboardStore();
const partyStore = usePartyStore();

const order = computed(() => store.config.orders.find(o => o.id === store.orderId) ?? store.config.orders[0]);
const inParty = computed(() => !!partyStore.party);
const isLeader = computed(() => !!partyStore.party?.members.some(m => m.isLeader && m.name === store.config.driverName));

function orderCols(o: Order) {
  return [
    { label: "Reward",   value: o.reward,   accent: true,  pill: false, pillBg: '',      pillColor: '' },
    { label: "Type",     value: o.cargo,    accent: false, pill: true,  pillBg: o.tagBg, pillColor: o.tagColor },
    { label: "Weight",   value: o.weight,   accent: false, pill: false, pillBg: '',      pillColor: '' },
    { label: "Distance", value: o.distance, accent: false, pill: false, pillBg: '',      pillColor: '' },
  ];
}

async function acceptOrder() {
  if (inParty.value) {
    await nuiCallback("startPartyMission", { orderId: order.value.id });
  } else {
    await nuiCallback("acceptOrder", { orderId: order.value.id });
  }
  store.closeOrder();
}
</script>

<style scoped>
.order-row:hover {
  border-color: var(--accent) !important;
}
</style>
