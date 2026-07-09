<template>
  <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px">
    <div style="width:900px;height:640px;display:flex;background:#e7e9ec;border-radius:20px;overflow:hidden;box-shadow:0 40px 120px rgba(0,0,0,0.55),0 0 0 1px rgba(255,255,255,0.04);font-size:13px;color:#1b1f24;font-family:'Archivo',system-ui,sans-serif">

      <!-- LIST -->
      <aside style="width:230px;flex-shrink:0;background:#22262d;display:flex;flex-direction:column;color:#c9ced6">
        <div style="padding:16px 16px 10px;display:flex;align-items:center;gap:10px;border-bottom:1px solid #2e333b">
          <iconify-icon icon="tabler:map-cog" width="20" style="color:#e8b408"></iconify-icon>
          <div style="font-weight:700;font-size:14px;color:#fff">Mission-Editor</div>
        </div>
        <div style="padding:10px 12px">
          <input v-model="search" placeholder="Suche…" style="width:100%;padding:7px 10px;border-radius:8px;border:1px solid #3a414b;background:#2b3039;color:#fff;font-family:inherit;font-size:12px;outline:none" />
          <label class="chk chk-dark" style="margin-top:8px">
            <input type="checkbox" v-model="onlyActive" /><span class="chk-box"></span> Nur aktiv
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
            <div style="font-size:12.5px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">{{ o.name || '(unbenannt)' }}</div>
            <div style="font-size:10px;color:#7a818c;margin-top:2px">{{ o.pickup_city || '?' }} → {{ o.dropoff_city || '?' }}{{ o.is_active ? '' : ' · inaktiv' }}</div>
          </button>
        </nav>
        <button @click="store.newOrder()" style="margin:10px 12px 14px;padding:9px;border:none;border-radius:9px;background:#e8b408;color:#22262d;font-weight:700;font-family:inherit;cursor:pointer">+ Neue Mission</button>
      </aside>

      <!-- FORM -->
      <main style="flex:1;display:flex;flex-direction:column;min-width:0;background:#fff">
        <header style="height:48px;flex-shrink:0;display:flex;align-items:center;gap:10px;padding:0 16px;border-bottom:1px solid #dfe2e6">
          <div style="flex:1;font-weight:700;font-size:14px">{{ store.isNew ? 'Neue Mission' : (store.form?.name || 'Mission bearbeiten') }}</div>
          <button @click="closeEditor" style="width:30px;height:30px;border-radius:8px;border:1px solid #e4e6e9;background:#fff;cursor:pointer;color:#6b7280"><iconify-icon icon="tabler:x" width="16"></iconify-icon></button>
        </header>

        <div v-if="!store.form" style="flex:1;display:flex;align-items:center;justify-content:center;color:#9aa1ab;flex-direction:column;gap:10px">
          <iconify-icon icon="tabler:route" width="34"></iconify-icon>
          Mission auswählen oder neu anlegen.
        </div>

        <div v-else style="flex:1;overflow-y:auto;padding:16px" class="admin-form-scroll">
          <div v-if="store.error" style="padding:8px 12px;border-radius:8px;background:rgba(220,38,38,0.1);color:#dc2626;font-size:12px;margin-bottom:12px">{{ store.error }}</div>

          <div style="display:grid;grid-template-columns:2fr 1fr;gap:10px">
            <label class="field-label">Name<input v-model="store.form.name" class="fld" /></label>
            <label class="field-label">Cargo-Typ
              <select :value="store.form.cargo_type" @change="onCargoTypeChange(($event.target as HTMLSelectElement).value)" class="fld">
                <option v-for="(preset, key) in CARGO_TYPE_PRESETS" :key="key" :value="key">{{ preset.label }}</option>
              </select>
            </label>
          </div>

          <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:10px">
            <label class="field-label">Gewicht (kg)<input type="number" v-model.number="store.form.weight_kg" class="fld" /></label>
            <label class="field-label">Reward ($)<input type="number" v-model.number="store.form.reward_base" class="fld" /></label>
            <label class="field-label">XP<input type="number" v-model.number="store.form.xp_base" class="fld" /></label>
            <label class="field-label">Zeit (min)<input type="number" v-model.number="store.form.time_minutes" class="fld" /></label>
          </div>
          <div style="font-size:11px;color:#9aa1ab;margin-top:4px">≈ {{ store.palletPreview }} Paletten (max {{ store.maxPalletsPerOrder }})</div>

          <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-top:10px">
            <label class="field-label">Level erforderlich<input type="number" min="1" v-model.number="store.form.level_required" class="fld" /></label>
            <label class="chk" style="margin-top:18px"><input type="checkbox" v-model="store.form.requires_hazmat" /><span class="chk-box"></span> Hazmat nötig</label>
            <label class="chk" style="margin-top:18px"><input type="checkbox" v-model="store.form.requires_long_hauler" /><span class="chk-box"></span> Long-Hauler nötig</label>
          </div>

          <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.1em;text-transform:uppercase;color:#9aa1ab;margin:18px 0 8px">Pickup</div>
          <div style="display:grid;grid-template-columns:2fr 1fr auto;gap:10px;align-items:end">
            <label class="field-label">Label<input v-model="store.form.pickup_label" class="fld" /></label>
            <label class="field-label">Stadt<input v-model="store.form.pickup_city" class="fld" /></label>
            <button @click="store.useCurrentPositionForPickup()" class="mini-btn">Aktuelle Position nutzen</button>
          </div>
          <div style="font-size:11px;color:#9aa1ab;margin-top:6px" v-if="store.form.pickup_x != null">
            {{ store.form.pickup_x?.toFixed(1) }}, {{ store.form.pickup_y?.toFixed(1) }}, {{ store.form.pickup_z?.toFixed(1) }} · Heading {{ store.form.pickup_heading.toFixed(0) }}°
          </div>

          <div style="display:flex;align-items:center;gap:8px;margin-top:10px">
            <div style="font-size:11px;font-weight:600;color:#6b7280;flex:1">Paletten ({{ store.form.pickup_pallet_coords.length }})</div>
            <button @click="store.generateGrid()" class="mini-btn" :disabled="store.form.pickup_x == null">Auto-Grid generieren</button>
            <button @click="store.addPalletRow()" class="mini-btn">+ manuell</button>
          </div>
          <div v-for="(p, idx) in store.form.pickup_pallet_coords" :key="idx" style="display:flex;align-items:center;gap:8px;margin-top:6px">
            <div style="flex:1;font-size:11px;color:#3c424b;background:#f6f7f8;border:1px solid #eef0f2;border-radius:7px;padding:5px 8px">#{{ idx + 1 }} — {{ p.x.toFixed(1) }}, {{ p.y.toFixed(1) }}, {{ p.z.toFixed(1) }}</div>
            <button @click="store.useCurrentPositionForPallet(idx)" class="mini-btn">Position nutzen</button>
            <button @click="store.confirmPallet(idx)" class="mini-btn">Bestätigen</button>
            <button @click="store.removePalletRow(idx)" class="mini-btn danger">✕</button>
          </div>

          <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.1em;text-transform:uppercase;color:#9aa1ab;margin:18px 0 8px">Dropoff</div>
          <div style="display:grid;grid-template-columns:2fr 1fr auto;gap:10px;align-items:end">
            <label class="field-label">Label<input v-model="store.form.dropoff_label" class="fld" /></label>
            <label class="field-label">Stadt<input v-model="store.form.dropoff_city" class="fld" /></label>
            <button @click="store.useCurrentPositionForDropoff()" class="mini-btn">Aktuelle Position nutzen</button>
          </div>
          <div style="font-size:11px;color:#9aa1ab;margin-top:6px" v-if="store.form.dropoff_x != null">
            {{ store.form.dropoff_x?.toFixed(1) }}, {{ store.form.dropoff_y?.toFixed(1) }}, {{ store.form.dropoff_z?.toFixed(1) }} · Heading {{ store.form.dropoff_heading.toFixed(0) }}° · rotes Outline live in-game
          </div>

          <div style="display:grid;grid-template-columns:1fr auto;gap:10px;margin-top:10px;align-items:end">
            <label class="field-label">Distanz (km)<input type="number" step="0.1" v-model.number="store.form.distance_km" :disabled="!distanceOverride" class="fld" /></label>
            <label class="chk" style="margin-bottom:8px"><input type="checkbox" v-model="distanceOverride" /><span class="chk-box"></span> Manuell überschreiben</label>
          </div>

          <label class="field-label" style="margin-top:10px">Kommentar<textarea v-model="store.form.comment" rows="2" class="fld" style="resize:vertical" /></label>

          <div v-if="!store.isNew" style="font-size:10px;color:#aab0b8;margin-top:14px">
            Erstellt von {{ store.form.created_by || '—' }} · Zuletzt geändert von {{ store.form.updated_by || '—' }}
            <span v-if="store.form.delivery_count > 0"> · {{ store.form.delivery_count }} Lieferung(en) — Hard-Delete blockiert</span>
          </div>
        </div>

        <footer v-if="store.form" style="flex-shrink:0;padding:12px 16px;border-top:1px solid #dfe2e6;display:flex;gap:8px;flex-wrap:wrap">
          <button @click="onSave" class="accent-btn" style="padding:10px 16px;font-size:12.5px" :disabled="store.saving">{{ store.saving ? 'Speichert…' : 'Speichern' }}</button>
          <button v-if="!store.isNew" @click="store.clone(store.form.id!)" class="mini-btn">Duplizieren</button>
          <button v-if="!store.isNew" @click="store.setActive(store.form.id!, !store.form.is_active)" class="mini-btn">{{ store.form.is_active ? 'Deaktivieren' : 'Aktivieren' }}</button>
          <button
            v-if="!store.isNew"
            @click="onDelete"
            class="mini-btn danger"
            :disabled="store.form.delivery_count > 0"
            :title="store.form.delivery_count > 0 ? 'Mission hat Lieferhistorie — nur deaktivieren' : ''"
          >Löschen</button>
          <div style="flex:1"></div>
          <button v-if="!store.isNew" @click="onTestRun" class="mini-btn" style="border-color:#e8b408;color:#8a6a00">Mission testen</button>
        </footer>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useAdminMissionsStore, CARGO_TYPE_PRESETS } from "@/stores/adminMissionsStore";
import { usePersistantStore } from "@/stores/persistantStore";

const store = useAdminMissionsStore();
const persistantStore = usePersistantStore();

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
}
.mini-btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.mini-btn.danger {
  color: #dc2626;
  border-color: rgba(220, 38, 38, 0.3);
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
