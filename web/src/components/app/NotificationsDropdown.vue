<template>
  <div ref="rootEl" style="position:relative">
    <button
      style="width:36px;height:36px;border-radius:10px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#6b7280;position:relative"
      @click="store.toggle()"
    >
      <iconify-icon icon="tabler:bell" width="18"></iconify-icon>
      <span
        v-if="store.unreadCount > 0"
        style="position:absolute;top:-4px;right:-4px;min-width:16px;height:16px;padding:0 4px;border-radius:999px;background:#d24b3a;color:#fff;font-size:10px;font-weight:700;line-height:16px;text-align:center;font-family:'IBM Plex Mono',monospace"
      >{{ store.unreadCount > 9 ? '9+' : store.unreadCount }}</span>
    </button>

    <div
      v-if="store.isOpen"
      style="position:absolute;top:44px;right:0;width:340px;max-height:420px;display:flex;flex-direction:column;background:#fff;border-radius:14px;border:1px solid #e4e6e9;box-shadow:0 20px 60px rgba(0,0,0,0.18);z-index:1000;font-family:'Archivo',system-ui,sans-serif"
    >
      <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 16px;border-bottom:1px solid #eef0f2;flex-shrink:0">
        <span style="font-size:14px;font-weight:700;color:#1b1f24">{{ t('app.notifications_title') }}</span>
        <button
          v-if="store.unreadCount > 0"
          style="border:none;background:transparent;color:#6b7280;font-size:12px;font-weight:600;cursor:pointer;font-family:inherit"
          @click="markAllRead"
        >{{ t('app.mark_all_read') }}</button>
      </div>

      <div style="overflow-y:auto;flex:1">
        <div v-if="store.items.length === 0" style="padding:32px 16px;text-align:center;color:#9aa1ab;font-size:13px">
          {{ t('app.no_notifications_yet') }}
        </div>
        <button
          v-for="n in store.items"
          :key="n.id"
          style="width:100%;display:flex;gap:10px;align-items:flex-start;padding:12px 16px;border:none;border-bottom:1px solid #f4f5f6;background:transparent;text-align:left;cursor:pointer;font-family:inherit"
          :style="{ background: n.is_read ? 'transparent' : 'rgba(232,180,8,0.06)' }"
          @click="markRead(n)"
        >
          <div style="width:32px;height:32px;border-radius:10px;background:#f1f2f4;display:flex;align-items:center;justify-content:center;flex-shrink:0">
            <iconify-icon :icon="n.icon" width="16" style="color:#6b7280"></iconify-icon>
          </div>
          <div style="flex:1;min-width:0">
            <div style="font-size:12px;font-weight:700;color:#1b1f24">{{ n.title }}</div>
            <div style="font-size:12px;color:#6b7280;margin-top:2px;line-height:1.4">{{ n.message }}</div>
            <div style="font-size:10px;color:#9aa1ab;margin-top:4px;font-family:'IBM Plex Mono',monospace">{{ relativeTime(n.created_at) }}</div>
          </div>
          <span v-if="!n.is_read" style="width:6px;height:6px;border-radius:50%;background:#d24b3a;flex-shrink:0;margin-top:5px"></span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useNotificationsStore, type AppNotification } from "@/stores/notificationsStore";
import { nuiCallbackAsync } from "@/nui/nuiCallbacks";

const store = useNotificationsStore();
const rootEl = ref<HTMLElement | null>(null);
const { t } = useI18n();

function relativeTime(value: string): string {
  if (!value) return "";
  const d = new Date(value.replace(" ", "T"));
  if (isNaN(d.getTime())) return "";
  const diffMs = Date.now() - d.getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 1) return t('app.time_just_now');
  if (mins < 60) return t('app.time_minutes_ago', { mins });
  const hours = Math.floor(mins / 60);
  if (hours < 24) return t('app.time_hours_ago', { hours });
  const days = Math.floor(hours / 24);
  return t('app.time_days_ago', { days });
}

async function markRead(n: AppNotification) {
  if (n.is_read) return;
  store.markRead(n.id);
  await nuiCallbackAsync("markNotificationRead", { id: n.id });
}

async function markAllRead() {
  store.markAllRead();
  await nuiCallbackAsync("markAllNotificationsRead", {});
}

function handleOutsideClick(event: MouseEvent) {
  if (store.isOpen && rootEl.value && !rootEl.value.contains(event.target as Node)) {
    store.close();
  }
}

onMounted(() => window.addEventListener("click", handleOutsideClick));
onUnmounted(() => window.removeEventListener("click", handleOutsideClick));
</script>
