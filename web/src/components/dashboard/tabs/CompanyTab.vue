<template>
  <div style="display:flex;flex-direction:column;gap:16px">

    <!-- ===== NO COMPANY VIEW ===== -->
    <template v-if="!store.config.companyName">

      <!-- Incoming invitations -->
      <div v-if="store.config.incomingInvites.length > 0" style="background:#fff;border:1px solid #dfe2e6;border-radius:16px;overflow:hidden">
        <div style="padding:16px 20px;border-bottom:1px solid #eef0f2;display:flex;align-items:center;gap:9px">
          <iconify-icon icon="tabler:mail" width="18" style="color:var(--accent)"></iconify-icon>
          <span style="font-size:15px;font-weight:700;color:#1b1f24">{{ t('company.incoming_invitations') }}</span>
          <span style="margin-left:auto;font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ t('company.pending_count', { count: store.config.incomingInvites.length }) }}</span>
        </div>
        <div
          v-for="inv in store.config.incomingInvites"
          :key="inv.companyId"
          style="display:flex;align-items:center;gap:14px;padding:14px 20px;border-bottom:1px solid #f1f2f4"
        >
          <div style="width:44px;height:44px;border-radius:11px;background:#22262d;display:flex;align-items:center;justify-content:center;flex-shrink:0">
            <span style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;color:var(--accent)">{{ inv.companyTag }}</span>
          </div>
          <div style="flex:1;min-width:0">
            <div style="font-size:14px;font-weight:700;color:#1b1f24">{{ inv.companyName }}</div>
            <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;margin-top:2px">{{ t('company.invited_by', { name: inv.invitedBy, sent: inv.sent }) }}</div>
          </div>
          <button
            style="width:34px;height:34px;border-radius:9px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#d24b3a"
            @click="respondToInvite(inv.companyId, false)"
          ><iconify-icon icon="tabler:x" width="16"></iconify-icon></button>
          <button
            style="width:34px;height:34px;border-radius:9px;border:none;background:rgba(47,158,99,0.12);display:flex;align-items:center;justify-content:center;cursor:pointer;color:#2f9e63"
            @click="respondToInvite(inv.companyId, true)"
          ><iconify-icon icon="tabler:check" width="16"></iconify-icon></button>
        </div>
      </div>

      <!-- Create company card (empty state + expandable form) -->
      <div style="background:#fff;border:1px solid #dfe2e6;border-radius:16px;padding:44px 24px;display:flex;flex-direction:column;align-items:center;text-align:center">

        <!-- Loading spinner -->
        <template v-if="isRefetching">
          <div class="spin" style="width:44px;height:44px;border-radius:50%;border:3px solid #eef0f2;border-top-color:var(--accent)"></div>
          <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-top:18px">{{ t('company.setting_up') }}</div>
        </template>

        <!-- Empty state (default) -->
        <template v-else-if="!showCreate">
          <div style="width:72px;height:72px;border-radius:18px;background:rgba(232,180,8,0.12);display:flex;align-items:center;justify-content:center">
            <iconify-icon icon="tabler:building-warehouse" width="38" style="color:var(--accent)"></iconify-icon>
          </div>
          <div style="font-size:22px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24;margin-top:20px">{{ t('company.not_part_of_fleet') }}</div>
          <div style="font-size:13px;color:#9aa1ab;margin-top:8px;max-width:360px;line-height:1.6">{{ t('company.found_or_join_hint') }}</div>
          <button class="accent-btn" style="margin-top:22px;padding:12px 26px;font-size:13px;gap:8px" @click="showCreate = true">
            <iconify-icon icon="tabler:plus" width="16"></iconify-icon>
            {{ t('company.found_a_company') }}
          </button>
        </template>

        <!-- Create form -->
        <template v-else>
          <div style="width:100%;max-width:460px;text-align:left">
            <div style="font-size:18px;font-weight:800;color:#1b1f24;margin-bottom:20px;text-align:center">{{ t('company.found_a_company') }}</div>
            <div style="display:flex;flex-direction:column;gap:14px">
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">{{ t('company.company_name_label') }}</div>
                <input v-model="createName" :placeholder="t('company.company_name_placeholder')" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit" />
              </div>
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">{{ t('company.tag_label') }} <span style="color:#cfd3d8;font-style:normal">{{ t('company.max_8_chars') }}</span></div>
                <input v-model="createTag" placeholder="APEX" maxlength="8" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit;text-transform:uppercase" />
              </div>
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">{{ t('company.description_label') }} <span style="color:#cfd3d8;font-style:normal">{{ t('company.optional') }}</span></div>
                <textarea v-model="createDesc" :placeholder="t('company.description_placeholder')" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;resize:none;height:68px;font-family:inherit"></textarea>
              </div>
              <div style="display:flex;align-items:center;justify-content:space-between;padding:12px 14px;border-radius:10px;background:#f6f7f8;border:1px solid #eef0f2;cursor:pointer" @click="createOpenRec = !createOpenRec">
                <div>
                  <div style="font-size:13px;font-weight:600;color:#1b1f24">{{ t('company.open_recruitment') }}</div>
                  <div style="font-size:11px;color:#9aa1ab;margin-top:2px">{{ t('company.allow_join_requests') }}</div>
                </div>
                <div :style="{ background: createOpenRec ? 'var(--accent)' : '#cfd3d8' }" style="width:40px;height:22px;border-radius:12px;position:relative;flex-shrink:0;transition:background 0.2s">
                  <div :style="{ right: createOpenRec ? '3px' : 'auto', left: createOpenRec ? 'auto' : '3px' }" style="position:absolute;top:2px;width:18px;height:18px;border-radius:50%;background:#fff;transition:left 0.2s,right 0.2s"></div>
                </div>
              </div>
            </div>
            <div style="display:flex;gap:10px;margin-top:18px;justify-content:center">
              <button
                class="accent-btn"
                style="padding:12px 24px;font-size:13px"
                :style="{ opacity: (!createName.trim() || !createTag.trim()) ? '0.5' : '1' }"
                :disabled="!createName.trim() || !createTag.trim()"
                @click="createCompanyAction"
              >
                {{ t('company.create_company') }}
              </button>
              <button style="background:#fff;color:#6b7280;border:1px solid #e4e6e9;border-radius:11px;padding:12px 22px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="showCreate = false">{{ t('app.cancel') }}</button>
            </div>
          </div>
        </template>

      </div>

      <!-- Open recruitment list -->
      <div v-if="store.config.openCompanies.length > 0" style="background:#fff;border:1px solid #dfe2e6;border-radius:16px;overflow:hidden">
        <div style="padding:16px 20px;border-bottom:1px solid #eef0f2;display:flex;align-items:center;gap:9px">
          <iconify-icon icon="tabler:users-plus" width="18" style="color:var(--accent)"></iconify-icon>
          <span style="font-size:15px;font-weight:700;color:#1b1f24">{{ t('company.open_recruitment') }}</span>
          <span style="margin-left:auto;font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ store.config.openCompanies.length }} {{ store.config.openCompanies.length !== 1 ? t('company.fleet_plural') : t('company.fleet_singular') }}</span>
        </div>
        <div
          v-for="c in store.config.openCompanies"
          :key="c.id"
          style="display:flex;align-items:center;gap:14px;padding:14px 20px;border-bottom:1px solid #f1f2f4"
        >
          <div style="width:50px;height:50px;border-radius:12px;background:#22262d;display:flex;align-items:center;justify-content:center;flex-shrink:0">
            <span style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;color:var(--accent)">{{ c.tag }}</span>
          </div>
          <div style="flex:1;min-width:0">
            <div style="font-size:14px;font-weight:700;color:#1b1f24">{{ c.name }}</div>
            <div style="font-size:12px;color:#9aa1ab;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ c.description || t('company.no_description') }}</div>
          </div>
          <div style="display:flex;align-items:center;gap:18px;flex-shrink:0;font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:medal" width="13"></iconify-icon>{{ t('app.level_short', { lvl: c.level }) }}</span>
            <span v-if="c.minLevel > 1" style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:shield-lock" width="13"></iconify-icon>{{ t('company.min_level_prefix', { level: c.minLevel }) }}</span>
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:users" width="13"></iconify-icon>{{ c.members }}</span>
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:packages" width="13"></iconify-icon>{{ c.deliveries }}</span>
            <span style="display:inline-flex;align-items:center;gap:5px" :style="{ color: c.taxRate > 0 ? '#d24b3a' : '#9aa1ab' }"><iconify-icon icon="tabler:receipt-tax" width="13"></iconify-icon>{{ t('company.tax_suffix', { rate: c.taxRate }) }}</span>
          </div>
          <button
            class="accent-btn"
            style="padding:9px 16px;font-size:12px;gap:6px;flex-shrink:0"
            :style="{ opacity: joinedId === c.id ? '0.6' : '1' }"
            :disabled="joinedId === c.id"
            @click="requestJoinAction(c)"
          >
            <iconify-icon :icon="joinedId === c.id ? 'tabler:check' : 'tabler:door-enter'" width="14"></iconify-icon>
            {{ joinedId === c.id ? t('company.joined') : t('company.request_to_join') }}
          </button>
        </div>
      </div>

    </template>

    <!-- ===== IN COMPANY VIEW ===== -->
    <template v-else>

      <!-- Company header -->
      <div style="background:#fff;border:1px solid #dfe2e6;border-radius:16px;padding:20px 22px;display:flex;align-items:center;gap:18px">
        <div style="width:62px;height:62px;border-radius:15px;background:#22262d;display:flex;align-items:center;justify-content:center;flex-shrink:0">
          <iconify-icon icon="tabler:building-warehouse" width="32" :style="{ color: store.config.accentColor }"></iconify-icon>
        </div>
        <div style="flex:1;min-width:0">
          <div style="display:flex;align-items:center;gap:11px">
            <span style="font-size:21px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">{{ store.config.companyName }}</span>
            <span style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;padding:3px 9px;border-radius:7px;background:rgba(232,180,8,0.16);color:#caa006;text-transform:uppercase">{{ store.config.companyTag }}</span>
          </div>
          <div style="font-size:13px;color:#6b7280;margin-top:5px">{{ store.config.companyDescription }}</div>
          <div style="display:flex;align-items:center;gap:16px;margin-top:9px;font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:users" width="13"></iconify-icon>{{ t('company.members_suffix', { count: store.config.companyMembers }) }}</span>
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:calendar" width="13"></iconify-icon>{{ t('company.founded_prefix', { date: store.config.companyFoundedDate }) }}</span>
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:medal" width="13"></iconify-icon>{{ t('app.level_short', { lvl: store.config.companyLevel }) }}</span>
          </div>
        </div>
      </div>

      <!-- Sub-tab bar -->
      <div style="display:flex;gap:4px;border-bottom:1px solid #dfe2e6;padding:0 2px">
        <button
          v-for="ct in ctabDefs"
          :key="ct.key"
          style="position:relative;display:inline-flex;align-items:center;gap:7px;background:transparent;border:none;cursor:pointer;font-family:inherit;font-size:13px;padding:12px 14px"
          :style="{ color: store.ctab === ct.key ? '#1b1f24' : '#6b7280', fontWeight: store.ctab === ct.key ? '600' : '500' }"
          @click="store.setCtab(ct.key as any)"
        >
          <iconify-icon :icon="ct.icon" width="16" :style="{ color: store.ctab === ct.key ? accentDark : '#9aa1ab' }"></iconify-icon>
          {{ ct.label }}
          <span style="position:absolute;left:8px;right:8px;bottom:-1px;height:2.5px;border-radius:2px;background:var(--accent)" :style="{ opacity: store.ctab === ct.key ? '1' : '0' }"></span>
        </button>
      </div>

      <!-- Overview -->
      <template v-if="store.ctab === 'overview'">
        <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:14px">
          <div v-for="cs in companyStats" :key="cs.label" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="width:40px;height:40px;border-radius:11px;display:flex;align-items:center;justify-content:center" :style="{ background: cs.bg }">
              <iconify-icon :icon="cs.icon" width="21" :style="{ color: cs.color }"></iconify-icon>
            </div>
            <div style="font-size:24px;font-weight:800;letter-spacing:-0.02em;color:#1b1f24;margin-top:15px">{{ cs.value }}</div>
            <div style="font-size:13px;font-weight:600;color:#3c424b;margin-top:2px">{{ cs.label }}</div>
            <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;margin-top:6px">{{ t(cs.sub) }}</div>
          </div>
        </div>
        <div style="display:grid;grid-template-columns:1.45fr 1fr;gap:14px;align-items:start">
          <!-- Activity -->
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">
              <div style="font-size:15px;font-weight:700;color:#1b1f24;display:inline-flex;align-items:center;gap:8px">
                <iconify-icon icon="tabler:activity" width="18" style="color:var(--accent)"></iconify-icon>{{ t('company.live_activity') }}
              </div>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ t('ui.company.events') }}</span>
            </div>
            <template v-if="store.config.activity.length > 0">
              <div v-for="a in store.config.activity" :key="a.when + a.who" style="display:flex;align-items:center;gap:12px;padding:10px 2px;border-bottom:1px solid #eef0f2">
                <div style="width:32px;height:32px;border-radius:9px;background:#f3f4f6;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-weight:700;font-size:13px;color:#6b7280">{{ a.who[0] }}</div>
                <div style="flex:1;min-width:0;font-size:13px;color:#3c424b"><span style="font-weight:700;color:#1b1f24">{{ a.who }}</span> {{ a.what }}</div>
                <div style="display:flex;align-items:center;gap:8px;flex-shrink:0">
                  <iconify-icon :icon="a.icon" width="16" :style="{ color: a.color }"></iconify-icon>
                  <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ a.when }}</span>
                </div>
              </div>
            </template>
            <div v-else style="padding:28px 0;text-align:center;font-size:13px;color:#9aa1ab">{{ t('company.no_activity_yet') }}</div>
          </div>
          <!-- Progression -->
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-bottom:14px">{{ t('company.company_progression') }}</div>
            <div style="display:flex;align-items:center;justify-content:space-between">
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.06em;text-transform:uppercase;color:#9aa1ab">{{ t('company.company_level_label') }}</span>
              <span style="font-size:18px;font-weight:800;color:var(--accent)">{{ t('app.level_short', { lvl: store.config.companyLevel }) }}</span>
            </div>
            <div style="margin-top:8px;height:7px;border-radius:4px;background:#eef0f2;overflow:hidden">
              <div style="height:100%;background:var(--accent)" :style="{ width: companyXpPct + '%' }"></div>
            </div>
            <div style="display:flex;justify-content:space-between;margin-top:5px;font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab">
              <span>{{ store.config.companyXp.toLocaleString() }} XP</span>
              <span>{{ store.config.companyXpMax.toLocaleString() }} XP</span>
            </div>
            <div style="margin-top:16px;padding-top:16px;border-top:1px solid #eef0f2">
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab">{{ t('company.founded_heading') }}</div>
              <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-top:3px">{{ store.config.companyFoundedDate }}</div>
            </div>
            <div style="margin-top:14px">
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab">{{ t('company.about_heading') }}</div>
              <div style="font-size:13px;color:#3c424b;margin-top:4px;line-height:1.5">{{ store.config.companyDescription || '—' }}</div>
            </div>
            <div style="margin-top:16px;padding-top:14px;border-top:1px solid #eef0f2;display:flex;align-items:center;justify-content:space-between">
              <span style="font-size:12px;color:#6b7280">{{ t('company.server_ranking') }}</span>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:13px;font-weight:600;color:#1b1f24">{{ store.config.companyServerRank }}</span>
            </div>
          </div>
        </div>
      </template>

      <!-- Members -->
      <template v-if="store.ctab === 'members'">
        <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden">
          <div style="display:grid;grid-template-columns:2fr 1fr 1fr 1fr 0.8fr;gap:12px;padding:13px 20px;background:#f6f7f8;border-bottom:1px solid #eef0f2;font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab">
            <span>{{ t('company.col_member') }}</span><span>{{ t('company.col_role') }}</span><span>{{ t('company.col_deliveries') }}</span><span>{{ t('company.col_earned') }}</span><span>{{ t('company.col_status') }}</span>
          </div>
          <div
            v-for="m in store.config.members"
            :key="m.name"
            style="display:grid;grid-template-columns:2fr 1fr 1fr 1fr 0.8fr;gap:12px;padding:14px 20px;border-bottom:1px solid #f1f2f4;align-items:center"
            :style="{ background: m.you ? 'rgba(232,180,8,0.06)' : '#ffffff' }"
          >
            <div style="display:flex;align-items:center;gap:12px;min-width:0">
              <div style="width:36px;height:36px;border-radius:10px;background:#f1f2f4;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:14px;color:#6b7280;flex-shrink:0">{{ m.name[0] }}</div>
              <div style="min-width:0">
                <div style="font-size:14px;font-weight:600;color:#1b1f24;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ m.name }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab">{{ t('app.level_short', { lvl: m.lvl }) }}</div>
              </div>
            </div>
            <div style="font-size:13px;font-weight:600" :style="{ color: roleColor(m.role) }">{{ m.role }}</div>
            <div style="font-size:13px;color:#3c424b">{{ m.deliveries }}</div>
            <div style="font-size:13px;font-weight:600;color:#1b1f24">{{ m.earned }}</div>
            <div style="display:inline-flex;align-items:center;gap:7px;font-size:12px;color:#6b7280">
              <span style="width:8px;height:8px;border-radius:50%" :style="{ background: statusColor(m.status) }"></span>{{ m.status }}
            </div>
          </div>
        </div>
      </template>

      <!-- Invitations -->
      <template v-if="store.ctab === 'invitations'">
        <div style="display:grid;grid-template-columns:1fr 1.4fr;gap:14px;align-items:start">
          <div v-if="canInvite" style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="display:flex;align-items:center;justify-content:space-between">
              <div>
                <div style="font-size:15px;font-weight:700;color:#1b1f24">{{ t('company.invite_a_driver') }}</div>
                <div style="font-size:13px;color:#9aa1ab;margin-top:4px">{{ t('company.no_username_hint') }}</div>
              </div>
              <button
                style="width:34px;height:34px;border-radius:9px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#6b7280;flex-shrink:0"
                :style="{ opacity: nearbyLoading ? '0.5' : '1' }"
                :disabled="nearbyLoading"
                @click="refreshNearby"
              ><iconify-icon icon="tabler:refresh" width="16"></iconify-icon></button>
            </div>
            <div style="margin-top:14px;display:flex;flex-direction:column;gap:8px">
              <div
                v-for="r in nearbyRecruits"
                :key="r.identifier"
                style="display:flex;align-items:center;gap:10px;padding:9px 10px;border-radius:10px;background:#f6f7f8;border:1px solid #eef0f2"
              >
                <div style="width:30px;height:30px;border-radius:8px;background:#f1f2f4;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:12px;color:#6b7280;flex-shrink:0">{{ r.name[0] }}</div>
                <div style="flex:1;min-width:0">
                  <div style="font-size:13px;font-weight:600;color:#1b1f24;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ r.name }}</div>
                  <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab">{{ t('app.level_short', { lvl: r.lvl }) }}</div>
                </div>
                <button class="accent-btn" style="padding:7px 12px;font-size:12px;flex-shrink:0" @click="sendInvite(r.identifier)">{{ t('app.invite') }}</button>
              </div>
              <div v-if="!nearbyLoading && nearbyRecruits.length === 0" style="padding:16px 0;text-align:center;font-size:13px;color:#9aa1ab">{{ t('company.no_nearby_drivers') }}</div>
            </div>
          </div>
          <div v-else style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px;display:flex;align-items:center;justify-content:center;text-align:center;color:#9aa1ab;font-size:13px">
            {{ t('company.only_owners_managers_invite') }}
          </div>
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px">
              <div style="font-size:15px;font-weight:700;color:#1b1f24">{{ t('company.pending_invitations') }}</div>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ t('company.sent_count', { count: store.config.invitations.length }) }}</span>
            </div>
            <div v-for="v in store.config.invitations" :key="v.identifier" style="display:flex;align-items:center;gap:12px;padding:12px 2px;border-bottom:1px solid #eef0f2">
              <div style="width:36px;height:36px;border-radius:10px;background:#f1f2f4;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:14px;color:#6b7280;flex-shrink:0">{{ v.name[0] }}</div>
              <div style="flex:1;min-width:0">
                <div style="font-size:14px;font-weight:600;color:#1b1f24">{{ v.name }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab;margin-top:2px">{{ t('app.level_short', { lvl: v.lvl }) }} · {{ t('company.sent_suffix', { sent: v.sent }) }}</div>
              </div>
              <button
                v-if="canInvite"
                style="width:34px;height:34px;border-radius:9px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#d24b3a"
                @click="cancelInvite(v.identifier)"
              ><iconify-icon icon="tabler:x" width="16"></iconify-icon></button>
            </div>
            <div v-if="store.config.invitations.length === 0" style="padding:20px 0;text-align:center;font-size:13px;color:#9aa1ab">{{ t('company.no_pending_invitations') }}</div>
          </div>
        </div>
      </template>

      <!-- Statistics -->
      <template v-if="store.ctab === 'statistics'">
        <div style="display:grid;grid-template-columns:1.5fr 1fr;gap:14px;align-items:start">
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:18px">
              <div style="font-size:15px;font-weight:700;color:#1b1f24">{{ t('company.deliveries_this_week') }}</div>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ t('company.total_suffix', { count: store.config.companyDeliveries }) }}</span>
            </div>
            <template v-if="store.config.statChart.length > 0">
              <div style="display:flex;align-items:flex-end;gap:14px;height:180px;padding:0 4px">
                <div v-for="(b, i) in store.config.statChart" :key="b.d" style="flex:1;display:flex;flex-direction:column;align-items:center;gap:8px;height:100%;justify-content:flex-end">
                  <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;font-weight:600;color:#3c424b">{{ b.v }}</div>
                  <div style="width:100%;border-radius:7px 7px 0 0" :style="{ background: i === 4 ? store.config.accentColor : '#cfd3d8', height: barHeight(b.v) }"></div>
                  <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.04em;text-transform:uppercase;color:#9aa1ab">{{ b.d }}</div>
                </div>
              </div>
            </template>
            <div v-else style="height:180px;display:flex;align-items:center;justify-content:center;flex-direction:column;gap:8px">
              <iconify-icon icon="tabler:chart-bar-off" width="32" style="color:#cfd3d8"></iconify-icon>
              <div style="font-size:13px;color:#9aa1ab">{{ t('company.no_weekly_data') }}</div>
            </div>
          </div>
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-bottom:14px">{{ t('company.top_haulers') }}</div>
            <template v-if="store.config.topHaulers.length > 0">
              <div v-for="h in store.config.topHaulers" :key="h.name" style="margin-bottom:14px">
                <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px">
                  <span style="font-size:13px;font-weight:600;color:#1b1f24">{{ h.name }}</span>
                  <span style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#6b7280">{{ h.val }}</span>
                </div>
                <div style="height:7px;border-radius:4px;background:#eef0f2;overflow:hidden">
                  <div style="height:100%;background:var(--accent)" :style="{ width: h.bar }"></div>
                </div>
              </div>
            </template>
            <div v-else style="padding:28px 0;text-align:center;font-size:13px;color:#9aa1ab">{{ t('company.no_deliveries_recorded') }}</div>
          </div>
        </div>
      </template>

      <!-- Bank -->
      <template v-if="store.ctab === 'bank'">
        <div style="display:flex;flex-direction:column;gap:14px">
          <div style="background:#22262d;border-radius:16px;padding:22px 24px;display:flex;align-items:center;justify-content:space-between;position:relative;overflow:hidden">
            <div style="position:absolute;left:0;top:0;bottom:0;width:4px;background:repeating-linear-gradient(45deg,var(--accent) 0 9px,#1b1f24 9px 18px)"></div>
            <div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.12em;text-transform:uppercase;color:#9aa1ab">{{ t('company.treasury') }}</div>
              <div style="font-size:32px;font-weight:800;letter-spacing:-0.02em;color:#fff;margin-top:6px">{{ store.config.companyTreasury }}</div>
            </div>
            <div style="display:flex;gap:10px;align-items:center">
              <input v-model.number="bankAmount" type="number" min="1" :placeholder="t('company.amount_placeholder')" class="no-spinner" style="width:120px;padding:11px 14px;border-radius:10px;border:1px solid #3a414b;background:#2e333b;color:#fff;font-size:13px;outline:none;font-family:inherit" />
              <button class="accent-btn" style="padding:12px 20px;font-size:13px;gap:7px" @click="deposit"><iconify-icon icon="tabler:arrow-down" width="16"></iconify-icon>{{ t('company.deposit') }}</button>
              <button style="background:#2e333b;color:#fff;border:1px solid #3a414b;border-radius:11px;padding:12px 20px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer;display:inline-flex;align-items:center;gap:7px" @click="withdraw"><iconify-icon icon="tabler:arrow-up" width="16"></iconify-icon>{{ t('company.withdraw') }}</button>
            </div>
          </div>
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-bottom:6px">{{ t('company.recent_transactions') }}</div>
            <div v-for="tx in store.config.transactions" :key="tx.label" style="display:flex;align-items:center;gap:12px;padding:12px 2px;border-bottom:1px solid #eef0f2">
              <div style="width:34px;height:34px;border-radius:9px;display:flex;align-items:center;justify-content:center;flex-shrink:0" :style="{ background: tx.pos ? 'rgba(47,158,99,0.12)' : 'rgba(210,75,58,0.10)' }">
                <iconify-icon :icon="tx.icon" width="17" :style="{ color: tx.pos ? '#2f9e63' : '#d24b3a' }"></iconify-icon>
              </div>
              <div style="flex:1;min-width:0">
                <div style="font-size:13px;font-weight:600;color:#1b1f24">{{ tx.label }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;margin-top:2px">{{ tx.when }}</div>
              </div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:14px;font-weight:600" :style="{ color: tx.pos ? '#2f9e63' : '#d24b3a' }">{{ tx.amt }}</div>
            </div>
            <div v-if="store.config.transactions.length === 0" style="padding:20px 0;text-align:center;font-size:13px;color:#9aa1ab">{{ t('company.no_transactions_yet') }}</div>
          </div>
        </div>
      </template>

      <!-- Settings -->
      <template v-if="store.ctab === 'settings'">
        <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:22px 24px;max-width:640px">
          <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-bottom:18px">{{ t('company.company_settings') }}</div>
          <div style="display:flex;flex-direction:column;gap:16px">
            <div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">{{ t('company.company_name_label') }}</div>
              <input v-model="settingsName" :readonly="!isOwner" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit" />
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px">
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">{{ t('company.tag_label') }}</div>
                <input v-model="settingsTag" maxlength="8" :readonly="!isOwner" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit" />
              </div>
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">{{ t('company.min_level_to_join') }}</div>
                <input
                  v-model.number="settingsMinLevel"
                  type="number" min="1" max="11" step="1" class="no-spinner"
                  :readonly="!isOwner"
                  style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit"
                  @change="settingsMinLevel = Math.max(1, Math.min(11, Math.round(settingsMinLevel || 1)))"
                />
              </div>
            </div>
            <div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">{{ t('company.description_label') }}</div>
              <textarea v-model="settingsDesc" :readonly="!isOwner" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;resize:none;height:72px;font-family:inherit"></textarea>
            </div>
            <div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">{{ t('company.company_tax_label') }} <span style="color:#cfd3d8;font-style:normal">{{ t('company.tax_hint') }}</span></div>
              <template v-if="isOwner">
                <input
                  v-model.number="settingsTaxRate"
                  type="number" min="0" max="25" step="1" class="no-spinner"
                  style="width:140px;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit"
                  @change="settingsTaxRate = Math.max(0, Math.min(25, Math.round(settingsTaxRate || 0)))"
                />
              </template>
              <template v-else>
                <div style="font-size:14px;font-weight:700;color:#1b1f24">{{ store.config.companyTaxRate }}%</div>
              </template>
            </div>
            <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 16px;border-radius:11px;background:#f6f7f8;border:1px solid #eef0f2" :style="{ cursor: isOwner ? 'pointer' : 'default' }" @click="isOwner && (settingsOpenRec = !settingsOpenRec)">
              <div>
                <div style="font-size:13px;font-weight:600;color:#1b1f24">{{ t('company.open_recruitment') }}</div>
                <div style="font-size:12px;color:#9aa1ab;margin-top:2px">{{ t('company.allow_join_requests_settings') }}</div>
              </div>
              <div :style="{ background: settingsOpenRec ? 'var(--accent)' : '#cfd3d8', cursor: isOwner ? 'pointer' : 'default' }" style="width:42px;height:24px;border-radius:14px;position:relative;flex-shrink:0;transition:background 0.2s">
                <div :style="{ right: settingsOpenRec ? '3px' : 'auto', left: settingsOpenRec ? 'auto' : '3px' }" style="position:absolute;top:3px;width:18px;height:18px;border-radius:50%;background:#fff;transition:left 0.2s,right 0.2s"></div>
              </div>
            </div>
            <div v-if="isOwner" style="display:flex;gap:10px;margin-top:4px">
              <button class="accent-btn" style="padding:12px 22px;font-size:13px" @click="saveSettings">{{ t('company.save_changes') }}</button>
              <button style="background:#fff;color:#6b7280;border:1px solid #e4e6e9;border-radius:11px;padding:12px 22px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="resetSettings">{{ t('app.cancel') }}</button>
            </div>
          </div>
        </div>

        <!-- Danger zone -->
        <div style="background:#fff;border:1px solid #f3d9d5;border-radius:15px;padding:22px 24px;max-width:640px;margin-top:14px">
          <div style="font-size:15px;font-weight:700;color:#d24b3a;margin-bottom:6px">{{ t('company.danger_zone') }}</div>
          <template v-if="store.config.companyMyRole === 'owner'">
            <div style="font-size:13px;color:#6b7280;margin-bottom:14px">{{ t('company.disband_warning') }}</div>
            <button style="background:#fff;color:#d24b3a;border:1px solid #eecfc9;border-radius:11px;padding:11px 20px;font-family:inherit;font-weight:700;font-size:13px;cursor:pointer" @click="confirmMode = 'disband'">{{ t('company.disband_company') }}</button>
          </template>
          <template v-else>
            <div style="font-size:13px;color:#6b7280;margin-bottom:14px">{{ t('company.leave_warning') }}</div>
            <button style="background:#fff;color:#d24b3a;border:1px solid #eecfc9;border-radius:11px;padding:11px 20px;font-family:inherit;font-weight:700;font-size:13px;cursor:pointer" @click="confirmMode = 'leave'">{{ t('company.leave_company') }}</button>
          </template>
        </div>
      </template>

    </template>

    <!-- Danger zone confirm modal -->
    <div
      v-if="confirmMode"
      style="position:fixed;inset:0;background:rgba(15,17,21,0.55);display:flex;align-items:center;justify-content:center;z-index:50"
      @click.self="confirmMode = null"
    >
      <div style="background:#fff;border-radius:16px;padding:26px 28px;max-width:420px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,0.25)">
        <div style="width:52px;height:52px;border-radius:14px;background:rgba(210,75,58,0.12);display:flex;align-items:center;justify-content:center;margin-bottom:16px">
          <iconify-icon icon="tabler:alert-triangle" width="26" style="color:#d24b3a"></iconify-icon>
        </div>
        <div style="font-size:17px;font-weight:800;color:#1b1f24">{{ confirmMode === 'disband' ? t('company.confirm_disband_title') : t('company.confirm_leave_title') }}</div>
        <div style="font-size:13px;color:#6b7280;margin-top:8px;line-height:1.6">
          {{ confirmMode === 'disband'
            ? t('company.confirm_disband_body', { name: store.config.companyName })
            : t('company.confirm_leave_body', { name: store.config.companyName }) }}
        </div>
        <div style="display:flex;gap:10px;margin-top:20px">
          <button style="flex:1;background:#d24b3a;color:#fff;border:none;border-radius:11px;padding:12px;font-family:inherit;font-weight:700;font-size:13px;cursor:pointer" @click="confirmDanger">
            {{ confirmMode === 'disband' ? t('company.disband_company') : t('company.leave_company') }}
          </button>
          <button style="flex:1;background:#fff;color:#6b7280;border:1px solid #e4e6e9;border-radius:11px;padding:12px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="confirmMode = null">{{ t('app.cancel') }}</button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import { useDashboardStore } from "@/stores/dashboardStore";
import type { OpenCompanyEntry, NearbyRecruit } from "@/stores/dashboardStore";
import { nuiCallback } from "@/nui/nuiCallbacks";

const store = useDashboardStore();
const { t } = useI18n();
const accentDark = "#b58a05";
const isOwner = computed(() => store.config.companyMyRole === 'owner');
const canInvite = computed(() => store.config.companyMyRole === 'owner' || store.config.companyMyRole === 'manager');

// --- No-company state ---
const showCreate    = ref(false);
const isRefetching  = ref(false);
const createName    = ref('');
const createTag     = ref('');
const createDesc    = ref('');
const createOpenRec = ref(false);
const joinedId      = ref<number | null>(null);

async function createCompanyAction() {
  if (!createName.value.trim() || !createTag.value.trim()) return;
  const res = await nuiCallback<{ ok: boolean }>('createCompany', {
    name:            createName.value.trim(),
    tag:             createTag.value.trim().toUpperCase(),
    description:     createDesc.value.trim(),
    openRecruitment: createOpenRec.value,
  });
  if (res?.ok) {
    showCreate.value   = false;
    isRefetching.value = true;
    await nuiCallback('refetchDashboard');
    isRefetching.value = false;
  }
}

async function requestJoinAction(company: OpenCompanyEntry) {
  if (joinedId.value === company.id) return;
  const res = await nuiCallback<{ ok: boolean }>('requestJoin', { companyId: company.id });
  if (res?.ok) {
    joinedId.value     = company.id;
    isRefetching.value = true;
    await nuiCallback('refetchDashboard');
    isRefetching.value = false;
  }
}

// --- Invite (no username system — pick from nearby online drivers) ---
const nearbyRecruits = ref<NearbyRecruit[]>([]);
const nearbyLoading   = ref(false);

async function refreshNearby() {
  nearbyLoading.value = true;
  const res = await nuiCallback<{ ok: boolean; list: NearbyRecruit[] }>('getNearbyRecruits');
  nearbyRecruits.value = res?.list ?? [];
  nearbyLoading.value = false;
}

async function sendInvite(identifier: string) {
  const res = await nuiCallback<{ ok: boolean }>('inviteMember', { identifier });
  if (res?.ok) {
    nearbyRecruits.value = nearbyRecruits.value.filter(r => r.identifier !== identifier);
    await nuiCallback('refetchDashboard');
  }
}

async function cancelInvite(identifier: string) {
  const res = await nuiCallback<{ ok: boolean }>('cancelInvite', { identifier });
  if (res?.ok) await nuiCallback('refetchDashboard');
}

async function respondToInvite(companyId: number, accept: boolean) {
  const res = await nuiCallback<{ ok: boolean }>('respondInvite', { companyId, accept });
  if (res?.ok) {
    isRefetching.value = true;
    await nuiCallback('refetchDashboard');
    isRefetching.value = false;
  }
}

watch(() => store.ctab, (v) => {
  if (v === 'invitations' && canInvite.value) refreshNearby();
});

// --- Bank ---
const bankAmount = ref<number | null>(null);

async function deposit() {
  if (!bankAmount.value || bankAmount.value <= 0) return;
  const res = await nuiCallback<{ ok: boolean }>('depositBank', { amount: bankAmount.value });
  bankAmount.value = null;
  if (res?.ok) await nuiCallback('refetchDashboard');
}

async function withdraw() {
  if (!bankAmount.value || bankAmount.value <= 0) return;
  const res = await nuiCallback<{ ok: boolean }>('withdrawBank', { amount: bankAmount.value });
  bankAmount.value = null;
  if (res?.ok) await nuiCallback('refetchDashboard');
}

// --- Settings ---
const settingsName    = ref(store.config.companyName);
const settingsTag     = ref(store.config.companyTag);
const settingsDesc    = ref(store.config.companyDescription);
const settingsOpenRec = ref(store.config.companyOpenRecruitment);
const settingsTaxRate = ref(store.config.companyTaxRate);
const settingsMinLevel = ref(store.config.companyMinLevelToJoin);

watch(() => store.config.companyName,            v => { settingsName.value     = v; });
watch(() => store.config.companyTag,             v => { settingsTag.value      = v; });
watch(() => store.config.companyDescription,     v => { settingsDesc.value     = v; });
watch(() => store.config.companyOpenRecruitment, v => { settingsOpenRec.value  = v; });
watch(() => store.config.companyTaxRate,         v => { settingsTaxRate.value  = v; });
watch(() => store.config.companyMinLevelToJoin,  v => { settingsMinLevel.value = v; });

async function saveSettings() {
  const res = await nuiCallback<{ ok: boolean }>('saveCompanySettings', {
    name:            settingsName.value,
    tag:             settingsTag.value,
    description:     settingsDesc.value,
    openRecruitment: settingsOpenRec.value,
    taxRate:         Math.max(0, Math.min(25, Math.round(settingsTaxRate.value || 0))),
    minLevel:        Math.max(1, Math.min(11, Math.round(settingsMinLevel.value || 1))),
  });
  if (res?.ok) {
    isRefetching.value = true;
    await nuiCallback('refetchDashboard');
    isRefetching.value = false;
  }
}

function resetSettings() {
  settingsName.value     = store.config.companyName;
  settingsTag.value      = store.config.companyTag;
  settingsDesc.value     = store.config.companyDescription;
  settingsOpenRec.value  = store.config.companyOpenRecruitment;
  settingsTaxRate.value  = store.config.companyTaxRate;
  settingsMinLevel.value = store.config.companyMinLevelToJoin;
}

// --- Danger zone ---
const confirmMode = ref<'disband' | 'leave' | null>(null);

async function confirmDanger() {
  const mode = confirmMode.value;
  confirmMode.value = null;
  if (mode === 'disband') {
    await nuiCallback('disbandCompany');
  } else if (mode === 'leave') {
    await nuiCallback('leaveCompany');
  }
  isRefetching.value = true;
  await nuiCallback('refetchDashboard');
  isRefetching.value = false;
}

const ctabDefs = computed(() => [
  { key: "overview",    label: t('company.tab_overview'),    icon: "tabler:layout-grid" },
  { key: "members",     label: t('company.tab_members'),     icon: "tabler:users" },
  { key: "invitations", label: t('company.tab_invitations'), icon: "tabler:mail" },
  { key: "statistics",  label: t('company.tab_statistics'),  icon: "tabler:chart-bar" },
  { key: "bank",        label: t('company.tab_bank'),        icon: "tabler:building-bank" },
  { key: "settings",    label: t('company.tab_settings'),    icon: "tabler:settings" },
]);

const companyStats = computed(() => [
  { icon: "tabler:cash-banknote",   value: store.config.companyEarnings,   label: t('company.company_earnings_label'), sub: "ui.company.earnings",   color: "#b58a05", bg: "rgba(232,180,8,0.16)" },
  { icon: "tabler:packages",        value: store.config.companyDeliveries, label: t('company.total_deliveries_label'), sub: "ui.company.deliveries", color: "#2f9e63", bg: "rgba(47,158,99,0.14)" },
  { icon: "tabler:route",           value: store.config.companyDistance,   label: t('company.distance_hauled_label'), sub: "ui.company.km",         color: "#3b82f6", bg: "rgba(59,130,246,0.14)" },
  { icon: "tabler:trophy",          value: store.config.companyServerRank, label: t('company.server_rank_label'),     sub: "company.global_fleet_standing", color: "#8b5cf6", bg: "rgba(139,92,246,0.14)" },
]);

const companyXpPct = computed(() =>
  store.config.companyXpMax > 0
    ? Math.round((store.config.companyXp / store.config.companyXpMax) * 100)
    : 0
);

function roleColor(role: string) {
  const map: Record<string, string> = { Owner: "#b58a05", Manager: "#3b82f6", Driver: "#3c424b", Recruit: "#9aa1ab" };
  return map[role] ?? "#3c424b";
}

function statusColor(status: string) {
  if (status === "online") return "#2f9e63";
  if (status === "idle")   return "#E8B408";
  return "#aab0b8";
}

const maxChart = computed(() => {
  const vals = store.config.statChart.map(b => b.v);
  return vals.length > 0 ? Math.max(...vals) : 1;
});

function barHeight(v: number) {
  return Math.max(Math.round((v / maxChart.value) * 100), 1) + "%";
}
</script>

<style scoped>
@keyframes spin { to { transform: rotate(360deg); } }
.spin { animation: spin 0.75s linear infinite; }

.no-spinner::-webkit-outer-spin-button,
.no-spinner::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
.no-spinner {
  appearance: textfield;
  -moz-appearance: textfield;
}
</style>
