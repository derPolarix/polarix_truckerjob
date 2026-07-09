<template>
  <div style="display:flex;flex-direction:column;gap:20px">
    <!-- Garage -->
    <div>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
        <div>
          <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">Your garage</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">{{ store.config.vehiclesOwned.length }} vehicles owned</div>
        </div>
      </div>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:14px">
        <div v-for="v in store.config.vehiclesOwned" :key="v.slot" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden;display:flex;flex-direction:column">
          <div style="width:100%;height:150px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;overflow:hidden">
            <img v-if="v.model && vehicleImages[v.model]" :src="vehicleImages[v.model]" :alt="v.name" style="width:100%;height:100%;object-fit:contain" />
            <iconify-icon v-else icon="tabler:truck" width="48" style="color:#aab0b8"></iconify-icon>
          </div>
          <div style="padding:15px 16px">
            <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:10px">
              <div style="font-size:15px;font-weight:700;color:#1b1f24;line-height:1.2">{{ v.name }}</div>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.06em;padding:3px 7px;border-radius:6px;background:#f1f2f4;color:#6b7280;white-space:nowrap">{{ v.cls }}</span>
            </div>
            <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:14px;padding-top:14px;border-top:1px solid #eef0f2">
              <div style="text-align:center">
                <iconify-icon icon="tabler:gauge" width="16" style="color:#9aa1ab"></iconify-icon>
                <div style="font-size:13px;font-weight:700;color:#1b1f24;margin-top:4px">{{ v.speed }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:8px;letter-spacing:0.06em;text-transform:uppercase;color:#9aa1ab">km/h</div>
              </div>
              <div style="text-align:center">
                <iconify-icon icon="tabler:weight" width="16" style="color:#9aa1ab"></iconify-icon>
                <div style="font-size:13px;font-weight:700;color:#1b1f24;margin-top:4px">{{ v.cap }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:8px;letter-spacing:0.06em;text-transform:uppercase;color:#9aa1ab">capacity</div>
              </div>
              <div style="text-align:center">
                <iconify-icon icon="tabler:gas-station" width="16" style="color:#9aa1ab"></iconify-icon>
                <div style="font-size:13px;font-weight:700;color:#1b1f24;margin-top:4px">{{ v.fuel }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:8px;letter-spacing:0.06em;text-transform:uppercase;color:#9aa1ab">tank</div>
              </div>
            </div>
            <div v-if="v.equipped && v.slot === store.config.spawnedVehicleSlot" style="margin-top:14px;width:100%;text-align:center;padding:10px;border-radius:10px;background:rgba(47,158,99,0.12);color:#2f9e63;font-weight:700;font-size:13px;display:inline-flex;align-items:center;justify-content:center;gap:7px">
              <iconify-icon icon="tabler:circle-check-filled" width="16"></iconify-icon>Equipped
            </div>
            <button v-else class="equip-btn" style="margin-top:14px;width:100%;padding:10px;border-radius:10px;border:1px solid #dfe2e6;background:#fff;color:#3c424b;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="equipVehicle(v.slot)">{{ v.equipped ? 'Call vehicle' : 'Equip' }}</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Shop -->
    <div>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
        <div>
          <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">Vehicle shop</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">Balance · ${{ store.config.balance.toLocaleString() }}</div>
        </div>
      </div>
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:14px">
        <div v-for="v in store.config.vehiclesShop" :key="v.slot" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden;display:flex;flex-direction:column">
          <div style="position:relative">
            <div style="width:100%;height:128px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;overflow:hidden">
              <img v-if="v.model && vehicleImages[v.model]" :src="vehicleImages[v.model]" :alt="v.name" style="width:100%;height:100%;object-fit:contain" />
              <iconify-icon v-else icon="tabler:truck" width="40" style="color:#aab0b8"></iconify-icon>
            </div>
            <div v-if="v.locked" style="position:absolute;inset:0;background:rgba(34,38,45,0.55);display:flex;align-items:center;justify-content:center">
              <iconify-icon icon="tabler:lock" width="26" style="color:#fff"></iconify-icon>
            </div>
          </div>
          <div style="padding:14px;display:flex;flex-direction:column;flex:1">
            <div style="font-size:14px;font-weight:700;color:#1b1f24;line-height:1.2">{{ v.name }}</div>
            <span style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.06em;color:#9aa1ab;margin-top:5px">{{ v.cls }}</span>
            <div style="display:flex;gap:12px;margin-top:12px;padding-top:12px;border-top:1px solid #eef0f2">
              <span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;color:#6b7280"><iconify-icon icon="tabler:gauge" width="14" style="color:#aab0b8"></iconify-icon>{{ v.speed }}</span>
              <span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;color:#6b7280"><iconify-icon icon="tabler:weight" width="14" style="color:#aab0b8"></iconify-icon>{{ v.cap }}</span>
              <span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;color:#6b7280"><iconify-icon icon="tabler:gas-station" width="14" style="color:#aab0b8"></iconify-icon>{{ v.fuel }}</span>
            </div>
            <div style="margin-top:14px;display:flex;align-items:center;justify-content:space-between;gap:8px">
              <span style="font-size:15px;font-weight:800;color:#1b1f24">{{ v.price }}</span>
              <span v-if="v.locked" style="font-family:'IBM Plex Mono',monospace;font-size:10px;padding:7px 11px;border-radius:9px;background:#f1f2f4;color:#9aa1ab">{{ v.lvl }}</span>
              <button v-else class="accent-btn" style="padding:8px 15px;font-size:12px" @click="buyVehicle(v.slot)">Buy</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
        <div>
          <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">Your trailers</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">{{ store.config.trailersOwned.length }} trailers owned · selected trailer parks with your vehicle automatically</div>
        </div>
      </div>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:14px">
        <div v-for="t in store.config.trailersOwned" :key="t.slot" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden;display:flex;flex-direction:column">
          <div style="width:100%;height:150px;background:#f3f4f6;display:flex;align-items:center;justify-content:center">
            <iconify-icon icon="tabler:container" width="48" style="color:#aab0b8"></iconify-icon>
          </div>
          <div style="padding:15px 16px">
            <div style="font-size:15px;font-weight:700;color:#1b1f24;line-height:1.2">{{ t.name }}</div>
            <div style="display:flex;align-items:center;gap:6px;margin-top:14px;padding-top:14px;border-top:1px solid #eef0f2;font-size:12px;color:#6b7280">
              <iconify-icon icon="tabler:stack-2" width="16" style="color:#9aa1ab"></iconify-icon>{{ t.maxPallets }} pallet slots
            </div>
            <div v-if="t.equipped" style="margin-top:14px;width:100%;text-align:center;padding:10px;border-radius:10px;background:rgba(47,158,99,0.12);color:#2f9e63;font-weight:700;font-size:13px;display:inline-flex;align-items:center;justify-content:center;gap:7px">
              <iconify-icon icon="tabler:circle-check-filled" width="16"></iconify-icon>{{ t.slot === store.config.spawnedTrailerSlot ? 'Attached' : 'Selected' }}
            </div>
            <button v-else class="equip-btn" style="margin-top:14px;width:100%;padding:10px;border-radius:10px;border:1px solid #dfe2e6;background:#fff;color:#3c424b;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="equipTrailer(t.slot)">Select</button>
          </div>
        </div>
      </div>
    </div>

    <div>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
        <div>
          <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">Trailer shop</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">Balance · ${{ store.config.balance.toLocaleString() }}</div>
        </div>
      </div>
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:14px">
        <div v-for="t in store.config.trailersShop" :key="t.slot" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden;display:flex;flex-direction:column">
          <div style="position:relative">
            <div style="width:100%;height:128px;background:#f3f4f6;display:flex;align-items:center;justify-content:center">
              <iconify-icon icon="tabler:container" width="40" style="color:#aab0b8"></iconify-icon>
            </div>
            <div v-if="t.locked" style="position:absolute;inset:0;background:rgba(34,38,45,0.55);display:flex;align-items:center;justify-content:center">
              <iconify-icon icon="tabler:lock" width="26" style="color:#fff"></iconify-icon>
            </div>
          </div>
          <div style="padding:14px;display:flex;flex-direction:column;flex:1">
            <div style="font-size:14px;font-weight:700;color:#1b1f24;line-height:1.2">{{ t.name }}</div>
            <div style="display:flex;gap:12px;margin-top:12px;padding-top:12px;border-top:1px solid #eef0f2">
              <span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;color:#6b7280"><iconify-icon icon="tabler:stack-2" width="14" style="color:#aab0b8"></iconify-icon>{{ t.maxPallets }} slots</span>
            </div>
            <div style="margin-top:14px;display:flex;align-items:center;justify-content:space-between;gap:8px">
              <span style="font-size:15px;font-weight:800;color:#1b1f24">{{ t.price }}</span>
              <span v-if="t.locked" style="font-family:'IBM Plex Mono',monospace;font-size:10px;padding:7px 11px;border-radius:9px;background:#f1f2f4;color:#9aa1ab">{{ t.lvl }}</span>
              <button v-else class="accent-btn" style="padding:8px 15px;font-size:12px" @click="buyTrailer(t.slot)">Buy</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useDashboardStore } from "@/stores/dashboardStore";
import { nuiCallback } from "@/nui/nuiCallbacks";

const store = useDashboardStore();

const vehicleImageFiles = import.meta.glob<{ default: string }>("@/assets/vehicles/*.png", { eager: true });
const vehicleImages: Record<string, string> = {};
for (const path in vehicleImageFiles) {
  const model = path.split("/").pop()!.replace(".png", "");
  vehicleImages[model] = vehicleImageFiles[path].default;
}

async function equipVehicle(slot: string) {
  await nuiCallback("equipVehicle", { slot });
}

async function buyVehicle(slot: string) {
  await nuiCallback("buyVehicle", { slot });
}

async function equipTrailer(slot: string) {
  await nuiCallback("equipTrailer", { slot });
}

async function buyTrailer(slot: string) {
  await nuiCallback("buyTrailer", { slot });
}
</script>

<style scoped>
.equip-btn:hover {
  border-color: var(--accent) !important;
}
</style>
