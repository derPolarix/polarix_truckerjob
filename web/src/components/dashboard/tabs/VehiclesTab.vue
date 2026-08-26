<template>
  <div style="display:flex;flex-direction:column;gap:20px">
    <!-- Active rental -->
    <div v-if="store.config.rentalActive" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:16px 18px;display:flex;align-items:center;gap:16px;flex-wrap:wrap">
      <div style="display:flex;align-items:center;gap:10px;flex:1;min-width:220px">
        <div style="width:44px;height:44px;border-radius:11px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;overflow:hidden;flex-shrink:0">
          <img v-if="rentalVehicleImage" :src="rentalVehicleImage" :alt="store.config.rentalVehicleName" style="width:100%;height:100%;object-fit:contain" />
          <iconify-icon v-else icon="tabler:truck" width="22" style="color:#aab0b8"></iconify-icon>
        </div>
        <div style="width:44px;height:44px;border-radius:11px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;overflow:hidden;flex-shrink:0">
          <img v-if="rentalTrailerImage" :src="rentalTrailerImage" :alt="store.config.rentalTrailerName" style="width:100%;height:100%;object-fit:contain" />
          <iconify-icon v-else icon="tabler:container" width="22" style="color:#aab0b8"></iconify-icon>
        </div>
        <div>
          <div style="font-size:14px;font-weight:700;color:#1b1f24">{{ t('vehicles.active_rental') }} · {{ store.config.rentalVehicleName }} + {{ store.config.rentalTrailerName }}</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:3px">{{ t('vehicles.rental_interval_cost', { cost: store.config.rentalIntervalCost.toLocaleString(), minutes: store.config.rentalIntervalMinutes }) }}</div>
        </div>
      </div>
      <button class="park-btn" style="padding:10px 18px;border-radius:10px;border:1px solid #dfe2e6;background:#fff;color:#dc2626;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="returnRental()">{{ t('vehicles.return_rental') }}</button>
    </div>

    <!-- Return-rental confirm (mid-delivery) -->
    <div
      v-if="showReturnConfirm"
      style="position:fixed;inset:0;background:rgba(15,17,21,0.55);display:flex;align-items:center;justify-content:center;z-index:9999;font-family:'Archivo',system-ui,sans-serif"
      @click.self="showReturnConfirm = false"
    >
      <div style="background:#fff;border-radius:16px;padding:26px 28px;max-width:420px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,0.25)">
        <div style="font-size:17px;font-weight:800;color:#1b1f24">{{ t('vehicles.rental_return_confirm_title') }}</div>
        <div style="font-size:13px;color:#6b7280;margin-top:8px;line-height:1.6">{{ t('vehicles.rental_return_confirm_body') }}</div>
        <div style="display:flex;gap:10px;margin-top:20px">
          <button style="flex:1;background:#dc2626;color:#fff;border:none;border-radius:11px;padding:12px;font-family:inherit;font-weight:700;font-size:13px;cursor:pointer" @click="returnRental(true)">{{ t('vehicles.rental_return_confirm_action') }}</button>
          <button style="flex:1;background:#fff;color:#6b7280;border:1px solid #e4e6e9;border-radius:11px;padding:12px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="showReturnConfirm = false">{{ t('app.cancel') }}</button>
        </div>
      </div>
    </div>

    <!-- Garage -->
    <div>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
        <div>
          <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">{{ t('vehicles.your_garage') }}</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">{{ t('vehicles.vehicles_owned_count', { count: store.config.vehiclesOwned.length }) }}</div>
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
                <div style="font-family:'IBM Plex Mono',monospace;font-size:8px;letter-spacing:0.06em;text-transform:uppercase;color:#9aa1ab">{{ t('vehicles.capacity_label') }}</div>
              </div>
              <div style="text-align:center">
                <iconify-icon icon="tabler:gas-station" width="16" style="color:#9aa1ab"></iconify-icon>
                <div style="font-size:13px;font-weight:700;color:#1b1f24;margin-top:4px">{{ v.fuel }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:8px;letter-spacing:0.06em;text-transform:uppercase;color:#9aa1ab">{{ t('vehicles.tank_label') }}</div>
              </div>
            </div>
            <div v-if="v.equipped && v.slot === store.config.spawnedVehicleSlot" style="margin-top:14px;display:flex">
              <button class="equip-btn" style="flex:1;padding:10px;border-radius:10px 0 0 10px;border:1px solid #dfe2e6;border-right:none;background:#fff;color:#3c424b;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="equipVehicle(v.slot)">{{ t('vehicles.call_vehicle') }}</button>
              <button class="park-btn" style="flex:1;padding:10px;border-radius:0 10px 10px 0;border:1px solid #dfe2e6;background:#fff;color:#dc2626;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="parkVehicle()">{{ t('vehicles.park_vehicle') }}</button>
            </div>
            <button v-else class="equip-btn" style="margin-top:14px;width:100%;padding:10px;border-radius:10px;border:1px solid #dfe2e6;background:#fff;color:#3c424b;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="equipVehicle(v.slot)">{{ v.equipped ? t('vehicles.call_vehicle') : t('vehicles.equip') }}</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Shop -->
    <div>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
        <div>
          <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">{{ t('vehicles.vehicle_shop') }}</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">{{ t('vehicles.balance_label', { balance: store.config.balance.toLocaleString() }) }}</div>
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
              <button v-else class="accent-btn" style="padding:8px 15px;font-size:12px" @click="buyVehicle(v.slot)">{{ t('vehicles.buy') }}</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
        <div>
          <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">{{ t('vehicles.your_trailers') }}</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">{{ t('vehicles.trailers_owned_count', { count: store.config.trailersOwned.length }) }}</div>
        </div>
      </div>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:14px">
        <div v-for="tr in store.config.trailersOwned" :key="tr.slot" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden;display:flex;flex-direction:column">
          <div style="width:100%;height:150px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;overflow:hidden">
            <img v-if="tr.model && vehicleImages[tr.model]" :src="vehicleImages[tr.model]" :alt="tr.name" style="width:100%;height:100%;object-fit:contain" />
            <iconify-icon v-else icon="tabler:container" width="48" style="color:#aab0b8"></iconify-icon>
          </div>
          <div style="padding:15px 16px">
            <div style="font-size:15px;font-weight:700;color:#1b1f24;line-height:1.2">{{ tr.name }}</div>
            <div style="display:flex;align-items:center;gap:6px;margin-top:14px;padding-top:14px;border-top:1px solid #eef0f2;font-size:12px;color:#6b7280">
              <iconify-icon icon="tabler:stack-2" width="16" style="color:#9aa1ab"></iconify-icon>{{ t('vehicles.pallet_slots', { count: tr.maxPallets }) }}
            </div>
            <div v-if="tr.equipped && tr.slot === store.config.spawnedTrailerSlot" style="margin-top:14px;display:flex">
              <button class="equip-btn" style="flex:1;padding:10px;border-radius:10px 0 0 10px;border:1px solid #dfe2e6;border-right:none;background:#fff;color:#3c424b;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="equipTrailer(tr.slot)">{{ t('vehicles.call_trailer') }}</button>
              <button class="park-btn" style="flex:1;padding:10px;border-radius:0 10px 10px 0;border:1px solid #dfe2e6;background:#fff;color:#dc2626;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="parkTrailer()">{{ t('vehicles.park_trailer') }}</button>
            </div>
            <button v-else-if="tr.equipped" class="equip-btn" style="margin-top:14px;width:100%;padding:10px;border-radius:10px;border:1px solid #dfe2e6;background:#fff;color:#3c424b;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="equipTrailer(tr.slot)">{{ t('vehicles.call_trailer') }}</button>
            <button v-else class="equip-btn" style="margin-top:14px;width:100%;padding:10px;border-radius:10px;border:1px solid #dfe2e6;background:#fff;color:#3c424b;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="equipTrailer(tr.slot)">{{ t('vehicles.select') }}</button>
          </div>
        </div>
      </div>
    </div>

    <div>
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
        <div>
          <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">{{ t('vehicles.trailer_shop') }}</div>
          <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">{{ t('vehicles.balance_label', { balance: store.config.balance.toLocaleString() }) }}</div>
        </div>
      </div>
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:14px">
        <div v-for="tr in store.config.trailersShop" :key="tr.slot" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden;display:flex;flex-direction:column">
          <div style="position:relative">
            <div style="width:100%;height:128px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;overflow:hidden">
              <img v-if="tr.model && vehicleImages[tr.model]" :src="vehicleImages[tr.model]" :alt="tr.name" style="width:100%;height:100%;object-fit:contain" />
              <iconify-icon v-else icon="tabler:container" width="40" style="color:#aab0b8"></iconify-icon>
            </div>
            <div v-if="tr.locked" style="position:absolute;inset:0;background:rgba(34,38,45,0.55);display:flex;align-items:center;justify-content:center">
              <iconify-icon icon="tabler:lock" width="26" style="color:#fff"></iconify-icon>
            </div>
          </div>
          <div style="padding:14px;display:flex;flex-direction:column;flex:1">
            <div style="font-size:14px;font-weight:700;color:#1b1f24;line-height:1.2">{{ tr.name }}</div>
            <div style="display:flex;gap:12px;margin-top:12px;padding-top:12px;border-top:1px solid #eef0f2">
              <span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;color:#6b7280"><iconify-icon icon="tabler:stack-2" width="14" style="color:#aab0b8"></iconify-icon>{{ t('vehicles.slots_suffix', { count: tr.maxPallets }) }}</span>
            </div>
            <div style="margin-top:14px;display:flex;align-items:center;justify-content:space-between;gap:8px">
              <span style="font-size:15px;font-weight:800;color:#1b1f24">{{ tr.price }}</span>
              <span v-if="tr.locked" style="font-family:'IBM Plex Mono',monospace;font-size:10px;padding:7px 11px;border-radius:9px;background:#f1f2f4;color:#9aa1ab">{{ tr.lvl }}</span>
              <button v-else class="accent-btn" style="padding:8px 15px;font-size:12px" @click="buyTrailer(tr.slot)">{{ t('vehicles.buy') }}</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useDashboardStore } from "@/stores/dashboardStore";
import { nuiCallback } from "@/nui/nuiCallbacks";

const store = useDashboardStore();
const { t } = useI18n();

const vehicleImageFiles = import.meta.glob<{ default: string }>("@/assets/vehicles/*.png", { eager: true });
const vehicleImages: Record<string, string> = {};
for (const path in vehicleImageFiles) {
  const model = path.split("/").pop()!.replace(".png", "");
  vehicleImages[model] = vehicleImageFiles[path].default;
}

const rentalVehicleImage = computed(() => vehicleImages[store.config.rentalVehicleModel]);
const rentalTrailerImage = computed(() => vehicleImages[store.config.rentalTrailerModel]);

const showReturnConfirm = ref(false);

async function returnRental(confirmed = false) {
  const res = await nuiCallback<{ ok: boolean; needsConfirm?: boolean }>("returnRental", { confirmed });
  if (res?.needsConfirm) {
    showReturnConfirm.value = true;
    return;
  }
  showReturnConfirm.value = false;
}

async function equipVehicle(slot: string) {
  await nuiCallback("equipVehicle", { slot });
}

async function parkVehicle() {
  await nuiCallback("parkVehicle");
}

async function buyVehicle(slot: string) {
  await nuiCallback("buyVehicle", { slot });
}

async function equipTrailer(slot: string) {
  await nuiCallback("equipTrailer", { slot });
}

async function parkTrailer() {
  await nuiCallback("parkTrailer");
}

async function buyTrailer(slot: string) {
  await nuiCallback("buyTrailer", { slot });
}
</script>

<style scoped>
.equip-btn:hover {
  border-color: var(--accent) !important;
}
.park-btn:hover {
  border-color: #dc2626 !important;
  background: rgba(220, 38, 38, 0.06) !important;
}
</style>
