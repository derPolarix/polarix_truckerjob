<template>
  <div ref="rootEl" style="position:relative">
    <button
      style="width:36px;height:36px;border-radius:10px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#6b7280;position:relative"
      @click="onToggle"
    >
      <iconify-icon icon="tabler:users" width="18"></iconify-icon>
      <span
        v-if="badgeCount > 0"
        style="position:absolute;top:-4px;right:-4px;min-width:16px;height:16px;padding:0 4px;border-radius:999px;background:#d24b3a;color:#fff;font-size:10px;font-weight:700;line-height:16px;text-align:center;font-family:'IBM Plex Mono',monospace"
      >{{ badgeCount > 9 ? '9+' : badgeCount }}</span>
    </button>

    <div
      v-if="store.isOpen"
      style="position:absolute;top:44px;right:0;width:320px;max-height:460px;display:flex;flex-direction:column;background:#fff;border-radius:14px;border:1px solid #e4e6e9;box-shadow:0 20px 60px rgba(0,0,0,0.18);z-index:1000;font-family:'Archivo',system-ui,sans-serif"
    >
      <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 16px;border-bottom:1px solid #eef0f2;flex-shrink:0">
        <span style="font-size:14px;font-weight:700;color:#1b1f24">Convoy</span>
        <span v-if="store.party" style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ store.party.members.length }}/{{ store.party.maxSize }}</span>
      </div>

      <div style="overflow-y:auto;flex:1;padding:12px 14px;display:flex;flex-direction:column;gap:10px">

        <!-- Incoming invite -->
        <div v-if="store.pendingInvite" style="padding:12px;border-radius:12px;background:rgba(232,180,8,0.08);border:1px solid rgba(232,180,8,0.25)">
          <div style="font-size:13px;color:#1b1f24"><span style="font-weight:700">{{ store.pendingInvite.fromName }}</span> invited you to their convoy.</div>
          <div style="display:flex;gap:8px;margin-top:10px">
            <button class="accent-btn" style="flex:1;padding:8px;font-size:12px;justify-content:center" @click="respond(true)">Accept</button>
            <button style="flex:1;background:#fff;color:#6b7280;border:1px solid #e4e6e9;border-radius:9px;padding:8px;font-family:inherit;font-weight:600;font-size:12px;cursor:pointer" @click="respond(false)">Decline</button>
          </div>
        </div>

        <!-- In a convoy -->
        <template v-if="store.party">
          <div v-if="store.rewardMultiplier" style="display:flex;align-items:center;gap:8px;padding:9px 11px;border-radius:10px;background:rgba(47,158,99,0.08);border:1px solid rgba(47,158,99,0.2);font-size:12px;color:#2f9e63">
            <iconify-icon icon="tabler:bolt" width="15"></iconify-icon>
            Convoy Bonus: +{{ Math.round((store.rewardMultiplier.cash - 1) * 100) }}% Cash, +{{ Math.round((store.rewardMultiplier.xp - 1) * 100) }}% XP
          </div>

          <div v-if="store.missionProgress" style="padding:10px 11px;border-radius:10px;background:#f6f7f8;border:1px solid #eef0f2">
            <div style="display:flex;align-items:center;justify-content:space-between;font-family:'IBM Plex Mono',monospace;font-size:11px;color:#6b7280">
              <span>Pool-Fortschritt</span>
              <span>{{ store.missionProgress.totalPallets }} insgesamt</span>
            </div>
            <div style="height:6px;border-radius:4px;background:#e4e6e9;margin-top:7px;overflow:hidden">
              <div style="height:100%;background:#2f9e63;border-radius:4px" :style="{ width: progressPct(store.missionProgress) + '%' }"></div>
            </div>
            <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;margin-top:5px">{{ store.missionProgress.claimedTotal }} eingeladen · {{ store.missionProgress.deliveredTotal }} geliefert</div>
          </div>

          <div style="display:flex;flex-direction:column;gap:6px">
            <div
              v-for="m in store.party.members"
              :key="m.identifier"
              style="display:flex;align-items:center;gap:10px;padding:9px 10px;border-radius:10px;background:#f6f7f8;border:1px solid #eef0f2"
            >
              <div style="width:30px;height:30px;border-radius:8px;background:#f1f2f4;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:12px;color:#6b7280;flex-shrink:0">{{ m.name[0] }}</div>
              <div style="flex:1;min-width:0">
                <div style="font-size:13px;font-weight:600;color:#1b1f24;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;display:flex;align-items:center;gap:5px">
                  {{ m.name }}
                  <iconify-icon v-if="m.isLeader" icon="tabler:crown" width="13" style="color:#caa006"></iconify-icon>
                </div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab;display:inline-flex;align-items:center;gap:5px">
                  <span style="width:6px;height:6px;border-radius:50%" :style="{ background: m.online ? '#2f9e63' : '#aab0b8' }"></span>{{ m.online ? 'online' : 'offline' }}
                </div>
              </div>
              <template v-if="isLeader && !isSelf(m)">
                <button
                  v-if="m.online"
                  title="Make leader"
                  style="width:28px;height:28px;border-radius:8px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#b58a05;flex-shrink:0"
                  @click="makeLeader(m.identifier)"
                ><iconify-icon icon="tabler:crown" width="14"></iconify-icon></button>
                <button
                  title="Kick"
                  style="width:28px;height:28px;border-radius:8px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#d24b3a;flex-shrink:0"
                  @click="kick(m.identifier)"
                ><iconify-icon icon="tabler:user-x" width="14"></iconify-icon></button>
              </template>
            </div>
          </div>

          <button
            style="background:#fff;color:#d24b3a;border:1px solid #eecfc9;border-radius:10px;padding:9px;font-family:inherit;font-weight:700;font-size:12px;cursor:pointer"
            @click="isLeader ? disband() : leave()"
          >{{ isLeader ? 'Disband convoy' : 'Leave convoy' }}</button>
        </template>

        <!-- Not in a convoy -->
        <template v-else-if="!store.pendingInvite">
          <div style="text-align:center;padding:14px 4px;color:#9aa1ab;font-size:13px">You're not in a convoy.</div>

          <div style="display:flex;align-items:center;justify-content:space-between">
            <span style="font-size:12px;font-weight:600;color:#1b1f24">Invite a company member</span>
            <button
              style="width:26px;height:26px;border-radius:7px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#6b7280"
              :style="{ opacity: candidatesLoading ? '0.5' : '1' }"
              :disabled="candidatesLoading"
              @click="refreshCandidates"
            ><iconify-icon icon="tabler:refresh" width="14"></iconify-icon></button>
          </div>
          <div
            v-for="c in candidates"
            :key="c.identifier"
            style="display:flex;align-items:center;gap:10px;padding:9px 10px;border-radius:10px;background:#f6f7f8;border:1px solid #eef0f2"
          >
            <div style="width:28px;height:28px;border-radius:8px;background:#f1f2f4;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:12px;color:#6b7280;flex-shrink:0">{{ c.name[0] }}</div>
            <div style="flex:1;min-width:0">
              <div style="font-size:13px;font-weight:600;color:#1b1f24;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ c.name }}</div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab">Lvl {{ c.lvl }}</div>
            </div>
            <button class="accent-btn" style="padding:6px 11px;font-size:11px;flex-shrink:0" @click="invite(c.identifier)">Invite</button>
          </div>
          <div v-if="!candidatesLoading && candidatesFetched && candidates.length === 0" style="padding:10px 0;text-align:center;font-size:12px;color:#9aa1ab">No online company members without a convoy.</div>
        </template>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from "vue";
import { usePartyStore, type PartyMember, type PartyMissionProgress, type PartyOnlineCandidate } from "@/stores/partyStore";
import { useDashboardStore } from "@/stores/dashboardStore";
import { nuiCallback, nuiCallbackAsync } from "@/nui/nuiCallbacks";

const store = usePartyStore();
const dashboardStore = useDashboardStore();
const rootEl = ref<HTMLElement | null>(null);

const candidates = ref<PartyOnlineCandidate[]>([]);
const candidatesLoading = ref(false);
const candidatesFetched = ref(false);

const isLeader = computed(() => !!store.party && store.party.members.some(m => m.isLeader && isSelf(m)));
const badgeCount = computed(() => (store.pendingInvite ? 1 : 0));

function isSelf(m: PartyMember): boolean {
  return m.name === dashboardStore.config.driverName;
}

function progressPct(progress: PartyMissionProgress): number {
  if (progress.totalPallets <= 0) return 0;
  return Math.min(100, Math.round((progress.deliveredTotal / progress.totalPallets) * 100));
}

async function onToggle() {
  store.toggle();
  if (store.isOpen) {
    const res = await nuiCallback<{ ok: boolean; state: any }>('getPartyState');
    if (res?.ok) store.setState(res.state ?? null);
    if (!store.party && !store.pendingInvite) refreshCandidates();
  }
}

async function refreshCandidates() {
  candidatesLoading.value = true;
  const res = await nuiCallback<{ ok: boolean; list: PartyOnlineCandidate[] }>('getCompanyOnlineMembers');
  candidates.value = res?.list ?? [];
  candidatesLoading.value = false;
  candidatesFetched.value = true;
}

async function invite(identifier: string) {
  const res = await nuiCallbackAsync<{ ok: boolean }>('invitePartyMember', { identifier }).catch(() => null);
  if (res?.ok) candidates.value = candidates.value.filter(c => c.identifier !== identifier);
}

async function respond(accept: boolean) {
  const partyId = store.pendingInvite?.partyId;
  if (partyId === undefined) return;
  store.setPendingInvite(null);
  await nuiCallbackAsync('respondPartyInvite', { partyId, accept }).catch(() => null);
  if (accept) {
    const res = await nuiCallback<{ ok: boolean; state: any }>('getPartyState');
    if (res?.ok) store.setState(res.state ?? null);
  }
}

async function makeLeader(identifier: string) {
  await nuiCallbackAsync('transferPartyLeader', { identifier }).catch(() => null);
}

async function kick(identifier: string) {
  await nuiCallbackAsync('kickPartyMember', { identifier }).catch(() => null);
}

async function leave() {
  await nuiCallbackAsync('leaveParty').catch(() => null);
}

async function disband() {
  await nuiCallbackAsync('disbandParty').catch(() => null);
}

function handleOutsideClick(event: MouseEvent) {
  if (store.isOpen && rootEl.value && !rootEl.value.contains(event.target as Node)) {
    store.close();
  }
}

onMounted(() => window.addEventListener("click", handleOutsideClick));
onUnmounted(() => window.removeEventListener("click", handleOutsideClick));
</script>
