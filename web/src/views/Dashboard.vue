<template>
  <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px" :style="{ '--accent': store.config.accentColor }">
    <div style="width:1434px;height:968px;display:flex;background:#e7e9ec;border-radius:22px;overflow:hidden;box-shadow:0 40px 120px rgba(0,0,0,0.55),0 0 0 1px rgba(255,255,255,0.04);font-size:14px;color:#1b1f24;font-family:'Archivo',system-ui,sans-serif">

      <!-- SIDEBAR -->
      <aside style="width:242px;flex-shrink:0;background:#22262d;display:flex;flex-direction:column;color:#c9ced6">
        <!-- Logo -->
        <div style="padding:18px 18px 13px;display:flex;align-items:center;gap:12px">
          <div style="width:40px;height:40px;border-radius:12px;background:var(--accent);display:flex;align-items:center;justify-content:center;flex-shrink:0">
            <iconify-icon icon="tabler:steering-wheel" width="23" style="color:#22262d"></iconify-icon>
          </div>
          <div style="flex:1;min-width:0">
            <div style="font-weight:700;font-size:16px;color:#fff;line-height:1.05">{{ store.config.brandName }}</div>
            <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.16em;text-transform:uppercase;color:#7a818c;margin-top:2px">{{ t('dashboard.trucker_os') }}</div>
          </div>
          <iconify-icon icon="tabler:layout-sidebar-left-collapse" width="18" style="color:#5b626c"></iconify-icon>
        </div>
        <div style="height:3px;margin:2px 18px 0;border-radius:2px;background:repeating-linear-gradient(45deg,var(--accent) 0 8px,#2e333b 8px 16px);opacity:0.55"></div>

        <!-- Nav -->
        <nav style="flex:1;overflow-y:auto;padding:16px 12px;display:flex;flex-direction:column;gap:3px">
          <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.16em;text-transform:uppercase;color:#5b626c;padding:0 10px 8px">Menu</div>
          <button
            v-for="item in navItems"
            :key="item.key"
            style="position:relative;display:flex;align-items:center;gap:12px;width:100%;padding:10px 13px;border:none;border-radius:10px;cursor:pointer;font-family:inherit;font-size:14px;text-align:left"
            :style="{ background: store.tab === item.key ? 'rgba(232,180,8,0.12)' : 'transparent', color: store.tab === item.key ? '#ffffff' : '#9aa1ab' }"
            @click="store.setTab(item.key)"
          >
            <span style="position:absolute;left:-12px;top:9px;bottom:9px;width:3px;border-radius:0 3px 3px 0;background:var(--accent)" :style="{ opacity: store.tab === item.key ? '1' : '0' }"></span>
            <iconify-icon :icon="item.icon" width="19" :style="{ color: store.tab === item.key ? store.config.accentColor : '#7a818c', flexShrink: '0' }"></iconify-icon>
            <span style="flex:1" :style="{ fontWeight: store.tab === item.key ? '600' : '500' }">{{ item.label }}</span>
            <span v-if="item.badge" style="font-family:'IBM Plex Mono',monospace;font-size:10px;font-weight:600;min-width:18px;text-align:center;padding:1px 6px;border-radius:8px;background:var(--accent);color:#22262d">{{ item.badge }}</span>
          </button>
        </nav>

        <!-- Driver card -->
        <div style="padding:0 12px 6px">
          <div style="padding:12px;border-radius:14px;background:#2b3039;border:1px solid #353b45">
            <div style="display:flex;align-items:center;gap:10px">
              <div style="width:38px;height:38px;border-radius:11px;background:var(--accent);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:16px;color:#22262d;flex-shrink:0">{{ store.config.driverName[0] }}</div>
              <div style="flex:1;min-width:0">
                <div style="font-weight:600;font-size:13px;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ store.config.driverName }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.1em;text-transform:uppercase;color:#7a818c;margin-top:1px">{{ store.config.driverLevelTitle }} · {{ t('app.level_short', { lvl: store.config.driverLevel }) }}</div>
              </div>
            </div>
            <div style="margin-top:11px;display:flex;align-items:center;gap:8px">
              <div style="flex:1;height:5px;border-radius:3px;background:#3a414b;overflow:hidden">
                <div style="height:100%;background:var(--accent)" :style="{ width: xpPct + '%' }"></div>
              </div>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#7a818c">{{ store.config.driverXp }} XP</span>
            </div>
          </div>
        </div>
        <button style="margin:6px 12px 14px;display:flex;align-items:center;gap:10px;padding:10px 13px;border:none;background:transparent;color:#7a818c;font-family:inherit;font-size:13px;cursor:pointer;border-radius:10px" @click="closeNui">
          <iconify-icon icon="tabler:logout" width="18"></iconify-icon> {{ t('dashboard.exit') }}
        </button>
      </aside>

      <!-- MAIN -->
      <main class="px-main" style="flex:1;display:flex;flex-direction:column;min-width:0;background:#e7e9ec">
        <!-- Header -->
        <header style="height:62px;flex-shrink:0;display:flex;align-items:center;gap:14px;padding:0 22px;background:#fff;border-bottom:1px solid #dfe2e6">
          <div style="display:flex;align-items:center;gap:10px;height:38px;width:380px;max-width:42%;padding:9px 14px;border-radius:11px;background:#f1f2f4;border:1px solid #e4e6e9">
            <iconify-icon icon="tabler:search" width="17" style="color:#9aa1ab"></iconify-icon>
            <input :placeholder="t('dashboard.search_placeholder')" style="flex:1;border:none;background:transparent;outline:none;font-size:13px;color:#1b1f24;font-family:inherit" />
          </div>
          <div style="flex:1"></div>
          <div style="display:flex;align-items:center;gap:7px;padding:6px 8px 6px 12px;border-radius:20px;background:#f1f2f4;border:1px solid #e4e6e9">
            <iconify-icon icon="tabler:bolt" width="15" style="color:var(--accent)"></iconify-icon>
            <span style="font-size:12px;color:#6b7280;font-weight:500">{{ t('dashboard.skill_points') }}</span>
            <span style="font-family:'IBM Plex Mono',monospace;font-size:12px;font-weight:600;color:#1b1f24;background:#fff;border:1px solid #e4e6e9;border-radius:10px;padding:1px 8px">{{ store.config.skillPoints }}</span>
          </div>
          <div style="text-align:right;line-height:1.15;padding:0 4px">
            <div style="font-family:'IBM Plex Mono',monospace;font-size:13px;font-weight:600;color:#1b1f24">{{ time }}</div>
            <div style="font-size:10px;color:#9aa1ab">{{ date }}</div>
          </div>
          <PartyDropdown />
          <NotificationsDropdown />
          <button style="width:36px;height:36px;border-radius:10px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#6b7280" @click="closeNui"><iconify-icon icon="tabler:x" width="18"></iconify-icon></button>
        </header>

        <!-- Content -->
        <div style="flex:1;overflow-y:auto;padding:24px">
          <DashboardTab v-if="store.tab === 'dashboard'" />
          <OrdersTab v-else-if="store.tab === 'orders'" />
          <VehiclesTab v-else-if="store.tab === 'vehicles'" />
          <SkillsTab v-else-if="store.tab === 'skills'" />
          <CompanyTab v-else-if="store.tab === 'company'" />
          <LeaderboardTab v-else-if="store.tab === 'leaderboard'" />
          <HistoryTab v-else-if="store.tab === 'history'" />
          <!-- Coming soon fallback -->
          <div v-else style="display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;height:100%;min-height:420px">
            <div style="width:70px;height:70px;border-radius:20px;background:#fff;border:1px solid #dfe2e6;display:flex;align-items:center;justify-content:center"><iconify-icon icon="tabler:tools" width="34" style="color:#aab0b8"></iconify-icon></div>
            <div style="font-size:17px;font-weight:700;color:#3c424b;margin-top:18px">{{ t('dashboard.coming_soon') }}</div>
            <div style="font-size:13px;color:#9aa1ab;margin-top:5px">{{ t('dashboard.section_being_built') }}</div>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useDashboardStore } from "@/stores/dashboardStore";
import { nuiCallbackAsync } from "@/nui/nuiCallbacks";
import { usePersistantStore } from "@/stores/persistantStore";
import DashboardTab from "@/components/dashboard/tabs/DashboardTab.vue";
import OrdersTab from "@/components/dashboard/tabs/OrdersTab.vue";
import VehiclesTab from "@/components/dashboard/tabs/VehiclesTab.vue";
import SkillsTab from "@/components/dashboard/tabs/SkillsTab.vue";
import CompanyTab from "@/components/dashboard/tabs/CompanyTab.vue";
import LeaderboardTab from "@/components/dashboard/tabs/LeaderboardTab.vue";
import HistoryTab from "@/components/dashboard/tabs/HistoryTab.vue";
import NotificationsDropdown from "@/components/app/NotificationsDropdown.vue";
import PartyDropdown from "@/components/app/PartyDropdown.vue";

const store = useDashboardStore();
const persistantStore = usePersistantStore();
const { t } = useI18n();

const now = ref(new Date());
let timer: ReturnType<typeof setInterval>;
onMounted(() => { timer = setInterval(() => { now.value = new Date(); }, 1000); });
onUnmounted(() => clearInterval(timer));

const time = computed(() => now.value.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }));
const date = computed(() => now.value.toLocaleDateString([], { weekday: "short", month: "short", day: "numeric" }));

const xpPct = computed(() => Math.round((store.config.driverXp / store.config.driverXpMax) * 100));

const navItems = computed(() => [
  { key: "dashboard", label: t('dashboard.nav_dashboard'), icon: "tabler:layout-dashboard", badge: "" },
  { key: "orders", label: t('dashboard.nav_orders'), icon: "tabler:package", badge: String(store.config.openOrders) },
  { key: "vehicles", label: t('dashboard.nav_vehicles'), icon: "tabler:truck", badge: "" },
  { key: "skills", label: t('dashboard.nav_skills'), icon: "tabler:bolt", badge: "" },
  { key: "company", label: t('dashboard.nav_company'), icon: "tabler:building-warehouse", badge: String(store.config.companyMembers) },
  { key: "leaderboard", label: t('dashboard.nav_leaderboard'), icon: "tabler:trophy", badge: "" },
  { key: "history", label: t('dashboard.nav_history'), icon: "tabler:history", badge: "" },
]);

async function closeNui() {
  store.close();
  try {
    await persistantStore.closeNui();
  } catch { /* dev mode */ }
}
</script>

<style>
iconify-icon { display: inline-flex; }

.accent-btn {
  background: var(--accent);
  color: #1b1f24;
  border: none;
  border-radius: 11px;
  font-family: inherit;
  font-weight: 700;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 9px;
}
.accent-btn:hover {
  filter: brightness(0.92);
}

.px-main ::-webkit-scrollbar { width: 9px; height: 9px; }
.px-main ::-webkit-scrollbar-thumb { background: #c9cdd3; border-radius: 8px; }
.px-main ::-webkit-scrollbar-track { background: transparent; }
</style>
