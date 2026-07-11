<template>
  <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px">
    <div style="width:900px;height:640px;display:flex;background:#e7e9ec;border-radius:20px;overflow:hidden;box-shadow:0 40px 120px rgba(0,0,0,0.55),0 0 0 1px rgba(255,255,255,0.04);font-size:13px;color:#1b1f24;font-family:'Archivo',system-ui,sans-serif">

      <!-- LIST -->
      <aside style="width:230px;flex-shrink:0;background:#22262d;display:flex;flex-direction:column;color:#c9ced6">
        <div style="padding:16px 16px 10px;display:flex;align-items:center;gap:10px;border-bottom:1px solid #2e333b">
          <iconify-icon icon="tabler:map-cog" width="20" style="color:#e8b408"></iconify-icon>
          <div style="font-weight:700;font-size:14px;color:#fff">{{ t('admin.mission_editor_title') }}</div>
        </div>
        <div style="padding:10px 12px">
          <input v-model="search" :placeholder="t('admin.search_placeholder')" style="width:100%;padding:7px 10px;border-radius:8px;border:1px solid #3a414b;background:#2b3039;color:#fff;font-family:inherit;font-size:12px;outline:none" />
          <label class="chk chk-dark" style="margin-top:8px">
            <input type="checkbox" v-model="onlyActive" /><span class="chk-box"></span> {{ t('admin.only_active') }}
          </label>
        </div>
        <nav style="flex:1;overflow-y:auto;padding:4px 8px">
          <button
            v-for="o in filteredOrders"
            :key="o.id ?? ''"
            @click="select(o.id!)"
            style="display:block;width:100%;text-align:left;padding:9px 10px;border:none;border-radius:8px;cursor:pointer;font-family:inherit;margin-bottom:2px"
            :style="{ background: store.selectedId === o.id ? 'rgba(232,180,8,0.14)' : 'transparent', color: store.selectedId === o.id ? '#fff' : '#c9ced6', opacity: o.is_active ? 1 : 0.55 }"
          >
            <div style="font-size:12.5px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">{{ o.name || t('admin.unnamed') }}</div>
            <div style="font-size:10px;color:#7a818c;margin-top:2px">{{ o.pickup_city || '?' }} → {{ o.dropoff_city || '?' }}{{ o.is_active ? '' : t('admin.inactive_suffix') }}</div>
          </button>
        </nav>
        <button @click="store.newOrder()" style="margin:10px 12px 14px;padding:9px;border:none;border-radius:9px;background:#e8b408;color:#22262d;font-weight:700;font-family:inherit;cursor:pointer">{{ t('admin.new_mission_button') }}</button>
      </aside>

      <!-- FORM -->
      <main style="flex:1;display:flex;flex-direction:column;min-width:0;background:#fff">
        <header style="height:48px;flex-shrink:0;display:flex;align-items:center;gap:10px;padding:0 16px;border-bottom:1px solid #dfe2e6">
          <div style="flex:1;font-weight:700;font-size:14px">{{ store.isNew ? t('admin.new_mission_title') : (store.form?.name || t('admin.edit_mission_title')) }}</div>
          <button @click="closeEditor" style="width:30px;height:30px;border-radius:8px;border:1px solid #e4e6e9;background:#fff;cursor:pointer;color:#6b7280"><iconify-icon icon="tabler:x" width="16"></iconify-icon></button>
        </header>

        <div v-if="!store.form" style="flex:1;display:flex;align-items:center;justify-content:center;color:#9aa1ab;flex-direction:column;gap:10px">
          <iconify-icon icon="tabler:route" width="34"></iconify-icon>
          {{ t('admin.select_or_create_hint') }}
        </div>

        <div v-else style="flex:1;overflow-y:auto;overflow-x:hidden;padding:16px" class="admin-form-scroll">
          <div v-if="store.error" style="padding:8px 12px;border-radius:8px;background:rgba(220,38,38,0.1);color:#dc2626;font-size:12px;margin-bottom:12px">{{ store.error }}</div>

          <div style="display:grid;grid-template-columns:2fr 1fr;gap:10px">
            <label class="field-label">{{ t('admin.name_label') }}<input v-model="store.form.name" class="fld" /></label>
            <label class="field-label">{{ t('admin.cargo_type_label') }}
              <select :value="store.form.cargo_type" @change="onCargoTypeChange(($event.target as HTMLSelectElement).value)" class="fld">
                <option v-for="(preset, key) in CARGO_TYPE_PRESETS" :key="key" :value="key">{{ preset.label }}</option>
              </select>
            </label>
          </div>

          <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:10px">
            <label class="field-label">{{ t('admin.weight_kg_label') }}<input type="number" v-model.number="store.form.weight_kg" class="fld" /></label>
            <label class="field-label">{{ t('admin.reward_label') }}<input type="number" v-model.number="store.form.reward_base" class="fld" /></label>
            <label class="field-label">{{ t('admin.xp_label') }}<input type="number" v-model.number="store.form.xp_base" class="fld" /></label>
            <label class="field-label">{{ t('admin.time_min_label') }}<input type="number" v-model.number="store.form.time_minutes" class="fld" /></label>
          </div>
          <div style="font-size:11px;color:#9aa1ab;margin-top:4px">{{ t('admin.pallets_preview', { count: store.palletPreview, max: store.maxPalletsPerOrder }) }}</div>

          <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-top:10px">
            <label class="field-label">{{ t('admin.level_required_label') }}<input type="number" min="1" v-model.number="store.form.level_required" class="fld" /></label>
            <label class="chk" style="margin-top:18px"><input type="checkbox" v-model="store.form.requires_hazmat" /><span class="chk-box"></span> {{ t('admin.hazmat_required') }}</label>
            <label class="chk" style="margin-top:18px"><input type="checkbox" v-model="store.form.requires_long_hauler" /><span class="chk-box"></span> {{ t('admin.long_hauler_required') }}</label>
          </div>

          <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.1em;text-transform:uppercase;color:#9aa1ab;margin:18px 0 8px">{{ t('admin.pickup_heading') }}</div>
          <div style="display:grid;grid-template-columns:2fr 1fr;gap:10px;align-items:end">
            <label class="field-label">{{ t('admin.label_field') }}<input v-model="store.form.pickup_label" class="fld" /></label>
            <label class="field-label">{{ t('admin.city_field') }}<input v-model="store.form.pickup_city" class="fld" /></label>
          </div>
          <div style="display:grid;grid-template-columns:repeat(4,1fr) auto;gap:8px;margin-top:8px;align-items:center">
            <input type="number" step="0.1" v-model.number="store.form.pickup_x" class="fld" placeholder="X" title="X" />
            <input type="number" step="0.1" v-model.number="store.form.pickup_y" class="fld" placeholder="Y" title="Y" />
            <input type="number" step="0.1" v-model.number="store.form.pickup_z" class="fld" placeholder="Z" title="Z" />
            <input type="number" step="0.1" v-model.number="store.form.pickup_heading" class="fld" :placeholder="t('admin.heading_field')" :title="t('admin.heading_field')" />
            <button @click="store.useCurrentPositionForPickup()" class="icon-btn" :title="t('admin.use_current_position')" :data-tooltip="t('admin.use_current_position')"><iconify-icon icon="tabler:crosshair" width="16"></iconify-icon></button>
          </div>

          <div style="display:flex;align-items:center;gap:8px;margin-top:10px">
            <div style="font-size:11px;font-weight:600;color:#6b7280;flex:1">{{ t('admin.pallets_count_label', { count: store.form.pickup_pallet_coords.length }) }}</div>
            <button @click="store.generateGrid()" class="mini-btn" :disabled="store.form.pickup_x == null" :title="t('admin.auto_grid_tooltip')" :data-tooltip="t('admin.auto_grid_tooltip')">{{ t('admin.auto_grid_button') }}</button>
            <button @click="store.addPalletRow()" class="mini-btn">{{ t('admin.manual_add_button') }}</button>
          </div>
          <div v-for="(p, idx) in store.form.pickup_pallet_coords" :key="idx" style="display:flex;align-items:center;gap:8px;margin-top:6px">
            <div style="flex:1;font-size:11px;color:#3c424b;background:#f6f7f8;border:1px solid #eef0f2;border-radius:7px;padding:5px 8px">#{{ idx + 1 }} — {{ p.x.toFixed(1) }}, {{ p.y.toFixed(1) }}, {{ p.z.toFixed(1) }}</div>
            <button @click="store.useCurrentPositionForPallet(idx)" class="icon-btn" :title="t('admin.use_position_tooltip')" :data-tooltip="t('admin.use_position_tooltip')"><iconify-icon icon="tabler:crosshair" width="16"></iconify-icon></button>
            <button @click="store.confirmPallet(idx)" class="mini-btn">{{ t('admin.confirm_button') }}</button>
            <button @click="store.removePalletRow(idx)" class="mini-btn danger">✕</button>
          </div>

          <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.1em;text-transform:uppercase;color:#9aa1ab;margin:18px 0 8px">{{ t('admin.dropoff_heading') }}</div>
          <div style="display:grid;grid-template-columns:2fr 1fr;gap:10px;align-items:end">
            <label class="field-label">{{ t('admin.label_field') }}<input v-model="store.form.dropoff_label" class="fld" /></label>
            <label class="field-label">{{ t('admin.city_field') }}<input v-model="store.form.dropoff_city" class="fld" /></label>
          </div>
          <div style="display:grid;grid-template-columns:repeat(4,1fr) auto;gap:8px;margin-top:8px;align-items:center">
            <input type="number" step="0.1" v-model.number="store.form.dropoff_x" @change="onDropoffCoordsChange" class="fld" placeholder="X" title="X" />
            <input type="number" step="0.1" v-model.number="store.form.dropoff_y" @change="onDropoffCoordsChange" class="fld" placeholder="Y" title="Y" />
            <input type="number" step="0.1" v-model.number="store.form.dropoff_z" @change="onDropoffCoordsChange" class="fld" placeholder="Z" title="Z" />
            <input type="number" step="0.1" v-model.number="store.form.dropoff_heading" @change="onDropoffCoordsChange" class="fld" :placeholder="t('admin.heading_field')" :title="t('admin.heading_field')" />
            <button @click="store.useCurrentPositionForDropoff()" class="icon-btn" :title="t('admin.use_current_position')" :data-tooltip="t('admin.use_current_position')"><iconify-icon icon="tabler:crosshair" width="16"></iconify-icon></button>
          </div>
          <div style="font-size:10px;color:#9aa1ab;margin-top:4px" v-if="store.form.dropoff_x != null">{{ t('admin.red_outline_hint') }}</div>

          <div style="display:grid;grid-template-columns:1fr auto;gap:10px;margin-top:10px;align-items:end">
            <label class="field-label">{{ t('admin.distance_km_label') }}<input type="number" step="0.1" v-model.number="store.form.distance_km" :disabled="!distanceOverride" class="fld" /></label>
            <label class="chk" style="margin-bottom:8px"><input type="checkbox" v-model="distanceOverride" /><span class="chk-box"></span> {{ t('admin.override_manually') }}</label>
          </div>

          <label class="field-label" style="margin-top:10px">{{ t('admin.comment_label') }}<textarea v-model="store.form.comment" rows="2" class="fld" style="resize:vertical" /></label>

          <div v-if="!store.isNew" style="font-size:10px;color:#aab0b8;margin-top:14px">
            {{ t('admin.created_by', { name: store.form.created_by || '—' }) }} · {{ t('admin.last_modified_by', { name: store.form.updated_by || '—' }) }}
            <span v-if="store.form.delivery_count > 0">{{ t('admin.delivery_count_blocked', { count: store.form.delivery_count }) }}</span>
          </div>
        </div>

        <footer v-if="store.form" style="flex-shrink:0;padding:12px 16px;border-top:1px solid #dfe2e6;display:flex;gap:8px;flex-wrap:wrap">
          <button @click="onSave" class="accent-btn" style="padding:10px 16px;font-size:12.5px" :disabled="store.saving">{{ store.saving ? t('admin.saving') : t('admin.save_button') }}</button>
          <button v-if="!store.isNew" @click="store.clone(store.form.id!)" class="mini-btn">{{ t('admin.duplicate_button') }}</button>
          <button v-if="!store.isNew" @click="store.setActive(store.form.id!, !store.form.is_active)" class="mini-btn">{{ store.form.is_active ? t('admin.deactivate_button') : t('admin.activate_button') }}</button>
          <button
            v-if="!store.isNew"
            @click="onDelete"
            class="mini-btn danger"
            :disabled="store.form.delivery_count > 0"
            :title="store.form.delivery_count > 0 ? t('admin.delivery_history_blocks_delete') : ''"
          >{{ t('admin.delete_button') }}</button>
          <div style="flex:1"></div>
          <button v-if="!store.isNew" @click="onTestRun" class="mini-btn" style="border-color:#e8b408;color:#8a6a00">{{ t('admin.test_mission_button') }}</button>
        </footer>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import { useAdminMissionsStore, CARGO_TYPE_PRESETS } from "@/stores/adminMissionsStore";
import { usePersistantStore } from "@/stores/persistantStore";

const store = useAdminMissionsStore();
const persistantStore = usePersistantStore();
const { t } = useI18n();

const search = ref("");
const onlyActive = ref(false);
const distanceOverride = ref(false);

const filteredOrders = computed(() => {
  const term = search.value.trim().toLowerCase();
  return store.orders.filter((o) => {
    if (onlyActive.value && !o.is_active) return false;
    if (!term) return true;
    return (o.name ?? "").toLowerCase().includes(term) || (o.pickup_city ?? "").toLowerCase().includes(term) || (o.dropoff_city ?? "").toLowerCase().includes(term);
  });
});

function select(id: string) {
  store.selectOrder(id);
  distanceOverride.value = false;
}

function onCargoTypeChange(type: string) {
  store.applyCargoType(type);
}

function onDropoffCoordsChange() {
  if (store.form?.dropoff_x != null) store.setDropoffPreview(true);
}

// Distanz automatisch nachziehen, solange der Admin sie nicht manuell überschreibt.
watch(
  () => [store.form?.pickup_x, store.form?.pickup_y, store.form?.pickup_z, store.form?.dropoff_x, store.form?.dropoff_y, store.form?.dropoff_z],
  () => { if (!distanceOverride.value) store.recalcDistance(); },
);

async function onSave() {
  await store.save();
}

async function onDelete() {
  if (!store.form?.id) return;
  await store.remove(store.form.id);
}

async function onTestRun() {
  if (!store.form?.id) return;
  const res = await store.testRun(store.form.id);
  if (res.ok) await closeEditor();
}

async function closeEditor() {
  await store.clearGhosts();
  await store.setDropoffPreview(false);
  try {
    await persistantStore.closeNui();
  } catch { /* dev mode */ }
}
</script>

<style scoped>
.field-label {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 11px;
  color: #6b7280;
}
.fld {
  padding: 7px 9px;
  border-radius: 7px;
  border: 1px solid #e4e6e9;
  background: #fff;
  font-family: inherit;
  font-size: 12px;
  outline: none;
  color: #1b1f24;
  min-width: 0;
  width: 100%;
  box-sizing: border-box;
}
.mini-btn {
  padding: 7px 10px;
  border-radius: 7px;
  border: 1px solid #e4e6e9;
  background: #fff;
  font-family: inherit;
  font-size: 11.5px;
  font-weight: 600;
  cursor: pointer;
  color: #3c424b;
  white-space: nowrap;
  transition: background 0.15s, border-color 0.15s;
}
.mini-btn:hover:not(:disabled) {
  background: #eef0f2;
  border-color: #c8ccd2;
}
.mini-btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.mini-btn.danger {
  color: #dc2626;
  border-color: rgba(220, 38, 38, 0.3);
}
.mini-btn.danger:hover:not(:disabled) {
  background: rgba(220, 38, 38, 0.08);
  border-color: rgba(220, 38, 38, 0.5);
}
.icon-btn {
  width: 30px;
  height: 30px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 7px;
  border: 1px solid #e4e6e9;
  background: #fff;
  cursor: pointer;
  color: #3c424b;
  transition: background 0.15s, border-color 0.15s, color 0.15s;
}
.icon-btn:hover {
  background: #e8b408;
  border-color: #e8b408;
  color: #1b1f24;
}
[data-tooltip] {
  position: relative;
}
[data-tooltip]::after {
  content: attr(data-tooltip);
  position: absolute;
  bottom: calc(100% + 7px);
  right: 0;
  background: #1b1f24;
  color: #fff;
  font-size: 10.5px;
  font-weight: 600;
  line-height: 1.3;
  padding: 5px 8px;
  border-radius: 6px;
  white-space: normal;
  width: max-content;
  max-width: 220px;
  text-align: center;
  opacity: 0;
  visibility: hidden;
  pointer-events: none;
  transition: opacity 0.12s ease, visibility 0.12s ease;
  z-index: 30;
}
[data-tooltip]:hover::after {
  opacity: 1;
  visibility: visible;
}
.accent-btn {
  background: #e8b408;
  color: #1b1f24;
  border: none;
  border-radius: 9px;
  font-family: inherit;
  font-weight: 700;
  cursor: pointer;
}
.accent-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.admin-form-scroll::-webkit-scrollbar { width: 8px; }
.admin-form-scroll::-webkit-scrollbar-thumb { background: #c9cdd3; border-radius: 8px; }

/* Custom Checkbox — native input bleibt für a11y/Klickfläche, aber unsichtbar */
.chk {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 12px;
  color: #6b7280;
  cursor: pointer;
  user-select: none;
}
.chk input {
  position: absolute;
  width: 1px;
  height: 1px;
  opacity: 0;
  pointer-events: none;
}
.chk-box {
  position: relative;
  flex-shrink: 0;
  width: 16px;
  height: 16px;
  border-radius: 5px;
  border: 1px solid #d5d8dc;
  background: #fff;
  transition: background 0.12s, border-color 0.12s;
}
.chk-box::after {
  content: "";
  position: absolute;
  left: 5px;
  top: 1px;
  width: 4px;
  height: 8px;
  border: solid #1b1f24;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
  opacity: 0;
  transition: opacity 0.1s;
}
.chk input:checked + .chk-box {
  background: #e8b408;
  border-color: #e8b408;
}
.chk input:checked + .chk-box::after {
  opacity: 1;
}
.chk input:focus-visible + .chk-box {
  outline: 2px solid rgba(232, 180, 8, 0.45);
  outline-offset: 2px;
}
.chk-dark {
  color: #9aa1ab;
  font-size: 11px;
}
.chk-dark .chk-box {
  background: #2b3039;
  border-color: #3a414b;
}
.chk-dark input:checked + .chk-box::after {
  border-color: #22262d;
}
</style>
