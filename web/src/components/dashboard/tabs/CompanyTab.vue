<template>
  <div style="display:flex;flex-direction:column;gap:16px">

    <!-- ===== NO COMPANY VIEW ===== -->
    <template v-if="!store.config.companyName">

      <!-- Create company card (empty state + expandable form) -->
      <div style="background:#fff;border:1px solid #dfe2e6;border-radius:16px;padding:44px 24px;display:flex;flex-direction:column;align-items:center;text-align:center">

        <!-- Loading spinner -->
        <template v-if="isRefetching">
          <div class="spin" style="width:44px;height:44px;border-radius:50%;border:3px solid #eef0f2;border-top-color:var(--accent)"></div>
          <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-top:18px">Setting up your company…</div>
        </template>

        <!-- Empty state (default) -->
        <template v-else-if="!showCreate">
          <div style="width:72px;height:72px;border-radius:18px;background:rgba(232,180,8,0.12);display:flex;align-items:center;justify-content:center">
            <iconify-icon icon="tabler:building-warehouse" width="38" style="color:var(--accent)"></iconify-icon>
          </div>
          <div style="font-size:22px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24;margin-top:20px">Not part of a fleet yet</div>
          <div style="font-size:13px;color:#9aa1ab;margin-top:8px;max-width:360px;line-height:1.6">Found your own company or request to join an open fleet below.</div>
          <button class="accent-btn" style="margin-top:22px;padding:12px 26px;font-size:13px;gap:8px" @click="showCreate = true">
            <iconify-icon icon="tabler:plus" width="16"></iconify-icon>
            Found a Company
          </button>
        </template>

        <!-- Create form -->
        <template v-else>
          <div style="width:100%;max-width:460px;text-align:left">
            <div style="font-size:18px;font-weight:800;color:#1b1f24;margin-bottom:20px;text-align:center">Found a Company</div>
            <div style="display:flex;flex-direction:column;gap:14px">
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">Company name</div>
                <input v-model="createName" placeholder="e.g. Apex Logistics" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit" />
              </div>
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">Tag <span style="color:#cfd3d8;font-style:normal">(max 8 chars)</span></div>
                <input v-model="createTag" placeholder="APEX" maxlength="8" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit;text-transform:uppercase" />
              </div>
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">Description <span style="color:#cfd3d8;font-style:normal">(optional)</span></div>
                <textarea v-model="createDesc" placeholder="What your fleet stands for..." style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;resize:none;height:68px;font-family:inherit"></textarea>
              </div>
              <div style="display:flex;align-items:center;justify-content:space-between;padding:12px 14px;border-radius:10px;background:#f6f7f8;border:1px solid #eef0f2;cursor:pointer" @click="createOpenRec = !createOpenRec">
                <div>
                  <div style="font-size:13px;font-weight:600;color:#1b1f24">Open recruitment</div>
                  <div style="font-size:11px;color:#9aa1ab;margin-top:2px">Allow drivers to request joining.</div>
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
                Create Company
              </button>
              <button style="background:#fff;color:#6b7280;border:1px solid #e4e6e9;border-radius:11px;padding:12px 22px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="showCreate = false">Cancel</button>
            </div>
          </div>
        </template>

      </div>

      <!-- Open recruitment list -->
      <div v-if="store.config.openCompanies.length > 0" style="background:#fff;border:1px solid #dfe2e6;border-radius:16px;overflow:hidden">
        <div style="padding:16px 20px;border-bottom:1px solid #eef0f2;display:flex;align-items:center;gap:9px">
          <iconify-icon icon="tabler:users-plus" width="18" style="color:var(--accent)"></iconify-icon>
          <span style="font-size:15px;font-weight:700;color:#1b1f24">Open recruitment</span>
          <span style="margin-left:auto;font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ store.config.openCompanies.length }} fleet{{ store.config.openCompanies.length !== 1 ? 's' : '' }}</span>
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
            <div style="font-size:12px;color:#9aa1ab;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{{ c.description || 'No description.' }}</div>
          </div>
          <div style="display:flex;align-items:center;gap:18px;flex-shrink:0;font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:medal" width="13"></iconify-icon>Lvl {{ c.level }}</span>
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:users" width="13"></iconify-icon>{{ c.members }}</span>
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:packages" width="13"></iconify-icon>{{ c.deliveries }}</span>
          </div>
          <button
            class="accent-btn"
            style="padding:9px 16px;font-size:12px;gap:6px;flex-shrink:0"
            :style="{ opacity: joinedId === c.id ? '0.6' : '1' }"
            :disabled="joinedId === c.id"
            @click="requestJoinAction(c)"
          >
            <iconify-icon :icon="joinedId === c.id ? 'tabler:check' : 'tabler:door-enter'" width="14"></iconify-icon>
            {{ joinedId === c.id ? 'Joined' : 'Request to join' }}
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
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:users" width="13"></iconify-icon>{{ store.config.companyMembers }} members</span>
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:calendar" width="13"></iconify-icon>Founded {{ store.config.companyFoundedDate }}</span>
            <span style="display:inline-flex;align-items:center;gap:5px"><iconify-icon icon="tabler:medal" width="13"></iconify-icon>Lvl {{ store.config.companyLevel }}</span>
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
            <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;margin-top:6px">{{ cs.sub }}</div>
          </div>
        </div>
        <div style="display:grid;grid-template-columns:1.45fr 1fr;gap:14px;align-items:start">
          <!-- Activity -->
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">
              <div style="font-size:15px;font-weight:700;color:#1b1f24;display:inline-flex;align-items:center;gap:8px">
                <iconify-icon icon="tabler:activity" width="18" style="color:var(--accent)"></iconify-icon>Live activity
              </div>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">ui.company.events</span>
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
            <div v-else style="padding:28px 0;text-align:center;font-size:13px;color:#9aa1ab">No activity recorded yet.</div>
          </div>
          <!-- Progression -->
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-bottom:14px">Company progression</div>
            <div style="display:flex;align-items:center;justify-content:space-between">
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.06em;text-transform:uppercase;color:#9aa1ab">Company level</span>
              <span style="font-size:18px;font-weight:800;color:var(--accent)">Lvl {{ store.config.companyLevel }}</span>
            </div>
            <div style="margin-top:8px;height:7px;border-radius:4px;background:#eef0f2;overflow:hidden">
              <div style="height:100%;background:var(--accent)" :style="{ width: companyXpPct + '%' }"></div>
            </div>
            <div style="display:flex;justify-content:space-between;margin-top:5px;font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab">
              <span>{{ store.config.companyXp.toLocaleString() }} XP</span>
              <span>{{ store.config.companyXpMax.toLocaleString() }} XP</span>
            </div>
            <div style="margin-top:16px;padding-top:16px;border-top:1px solid #eef0f2">
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab">Founded</div>
              <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-top:3px">{{ store.config.companyFoundedDate }}</div>
            </div>
            <div style="margin-top:14px">
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab">About</div>
              <div style="font-size:13px;color:#3c424b;margin-top:4px;line-height:1.5">{{ store.config.companyDescription || '—' }}</div>
            </div>
            <div style="margin-top:16px;padding-top:14px;border-top:1px solid #eef0f2;display:flex;align-items:center;justify-content:space-between">
              <span style="font-size:12px;color:#6b7280">Server ranking</span>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:13px;font-weight:600;color:#1b1f24">{{ store.config.companyServerRank }}</span>
            </div>
          </div>
        </div>
      </template>

      <!-- Members -->
      <template v-if="store.ctab === 'members'">
        <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;overflow:hidden">
          <div style="display:grid;grid-template-columns:2fr 1fr 1fr 1fr 0.8fr;gap:12px;padding:13px 20px;background:#f6f7f8;border-bottom:1px solid #eef0f2;font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab">
            <span>Member</span><span>Role</span><span>Deliveries</span><span>Earned</span><span>Status</span>
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
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab">Lvl {{ m.lvl }}</div>
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
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="font-size:15px;font-weight:700;color:#1b1f24">Invite a driver</div>
            <div style="font-size:13px;color:#9aa1ab;margin-top:4px">Send a recruitment offer by username.</div>
            <div style="display:flex;align-items:center;gap:10px;margin-top:16px;padding:11px 14px;border-radius:11px;background:#f1f2f4;border:1px solid #e4e6e9">
              <iconify-icon icon="tabler:at" width="17" style="color:#9aa1ab"></iconify-icon>
              <input v-model="inviteUsername" placeholder="username" style="flex:1;border:none;background:transparent;outline:none;font-size:13px;color:#1b1f24;font-family:inherit" />
            </div>
            <button class="accent-btn" style="margin-top:12px;width:100%;padding:12px;font-size:13px;justify-content:center" @click="sendInvite">Send invitation</button>
          </div>
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px">
              <div style="font-size:15px;font-weight:700;color:#1b1f24">Pending invitations</div>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ store.config.invitations.length }} sent</span>
            </div>
            <div v-for="v in store.config.invitations" :key="v.name" style="display:flex;align-items:center;gap:12px;padding:12px 2px;border-bottom:1px solid #eef0f2">
              <div style="width:36px;height:36px;border-radius:10px;background:#f1f2f4;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:14px;color:#6b7280;flex-shrink:0">{{ v.name[0] }}</div>
              <div style="flex:1;min-width:0">
                <div style="font-size:14px;font-weight:600;color:#1b1f24">{{ v.name }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;color:#9aa1ab;margin-top:2px">Lvl {{ v.lvl }} · sent {{ v.sent }}</div>
              </div>
              <button style="width:34px;height:34px;border-radius:9px;border:1px solid #e4e6e9;background:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer;color:#d24b3a"><iconify-icon icon="tabler:x" width="16"></iconify-icon></button>
              <button style="width:34px;height:34px;border-radius:9px;border:none;background:rgba(47,158,99,0.12);display:flex;align-items:center;justify-content:center;cursor:pointer;color:#2f9e63"><iconify-icon icon="tabler:check" width="16"></iconify-icon></button>
            </div>
            <div v-if="store.config.invitations.length === 0" style="padding:20px 0;text-align:center;font-size:13px;color:#9aa1ab">No pending invitations.</div>
          </div>
        </div>
      </template>

      <!-- Statistics -->
      <template v-if="store.ctab === 'statistics'">
        <div style="display:grid;grid-template-columns:1.5fr 1fr;gap:14px;align-items:start">
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:18px">
              <div style="font-size:15px;font-weight:700;color:#1b1f24">Deliveries this week</div>
              <span style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab">{{ store.config.companyDeliveries }} total</span>
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
              <div style="font-size:13px;color:#9aa1ab">No weekly data yet.</div>
            </div>
          </div>
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-bottom:14px">Top haulers</div>
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
            <div v-else style="padding:28px 0;text-align:center;font-size:13px;color:#9aa1ab">No deliveries recorded yet.</div>
          </div>
        </div>
      </template>

      <!-- Bank -->
      <template v-if="store.ctab === 'bank'">
        <div style="display:flex;flex-direction:column;gap:14px">
          <div style="background:#22262d;border-radius:16px;padding:22px 24px;display:flex;align-items:center;justify-content:space-between;position:relative;overflow:hidden">
            <div style="position:absolute;left:0;top:0;bottom:0;width:4px;background:repeating-linear-gradient(45deg,var(--accent) 0 9px,#1b1f24 9px 18px)"></div>
            <div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;letter-spacing:0.12em;text-transform:uppercase;color:#9aa1ab">Company treasury</div>
              <div style="font-size:32px;font-weight:800;letter-spacing:-0.02em;color:#fff;margin-top:6px">{{ store.config.companyTreasury }}</div>
            </div>
            <div style="display:flex;gap:10px;align-items:center">
              <input v-model.number="bankAmount" type="number" min="1" placeholder="Amount" style="width:120px;padding:11px 14px;border-radius:10px;border:1px solid #3a414b;background:#2e333b;color:#fff;font-size:13px;outline:none;font-family:inherit" />
              <button class="accent-btn" style="padding:12px 20px;font-size:13px;gap:7px" @click="deposit"><iconify-icon icon="tabler:arrow-down" width="16"></iconify-icon>Deposit</button>
              <button style="background:#2e333b;color:#fff;border:1px solid #3a414b;border-radius:11px;padding:12px 20px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer;display:inline-flex;align-items:center;gap:7px" @click="withdraw"><iconify-icon icon="tabler:arrow-up" width="16"></iconify-icon>Withdraw</button>
            </div>
          </div>
          <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:18px">
            <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-bottom:6px">Recent transactions</div>
            <div v-for="t in store.config.transactions" :key="t.label" style="display:flex;align-items:center;gap:12px;padding:12px 2px;border-bottom:1px solid #eef0f2">
              <div style="width:34px;height:34px;border-radius:9px;display:flex;align-items:center;justify-content:center;flex-shrink:0" :style="{ background: t.pos ? 'rgba(47,158,99,0.12)' : 'rgba(210,75,58,0.10)' }">
                <iconify-icon :icon="t.icon" width="17" :style="{ color: t.pos ? '#2f9e63' : '#d24b3a' }"></iconify-icon>
              </div>
              <div style="flex:1;min-width:0">
                <div style="font-size:13px;font-weight:600;color:#1b1f24">{{ t.label }}</div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:10px;color:#9aa1ab;margin-top:2px">{{ t.when }}</div>
              </div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:14px;font-weight:600" :style="{ color: t.pos ? '#2f9e63' : '#d24b3a' }">{{ t.amt }}</div>
            </div>
            <div v-if="store.config.transactions.length === 0" style="padding:20px 0;text-align:center;font-size:13px;color:#9aa1ab">No transactions yet.</div>
          </div>
        </div>
      </template>

      <!-- Settings -->
      <template v-if="store.ctab === 'settings'">
        <div style="background:#fff;border:1px solid #dfe2e6;border-radius:15px;padding:22px 24px;max-width:640px">
          <div style="font-size:15px;font-weight:700;color:#1b1f24;margin-bottom:18px">Company settings</div>
          <div style="display:flex;flex-direction:column;gap:16px">
            <div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">Company name</div>
              <input v-model="settingsName" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit" />
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px">
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">Tag</div>
                <input v-model="settingsTag" maxlength="8" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit" />
              </div>
              <div>
                <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">Min. level to join</div>
                <input value="Lvl 2" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;font-family:inherit" />
              </div>
            </div>
            <div>
              <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#9aa1ab;margin-bottom:7px">Description</div>
              <textarea v-model="settingsDesc" style="width:100%;padding:11px 14px;border-radius:10px;border:1px solid #e4e6e9;background:#f6f7f8;font-size:13px;color:#1b1f24;outline:none;resize:none;height:72px;font-family:inherit"></textarea>
            </div>
            <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 16px;border-radius:11px;background:#f6f7f8;border:1px solid #eef0f2;cursor:pointer" @click="settingsOpenRec = !settingsOpenRec">
              <div>
                <div style="font-size:13px;font-weight:600;color:#1b1f24">Open recruitment</div>
                <div style="font-size:12px;color:#9aa1ab;margin-top:2px">Let drivers request to join.</div>
              </div>
              <div :style="{ background: settingsOpenRec ? 'var(--accent)' : '#cfd3d8' }" style="width:42px;height:24px;border-radius:14px;position:relative;flex-shrink:0;cursor:pointer;transition:background 0.2s">
                <div :style="{ right: settingsOpenRec ? '3px' : 'auto', left: settingsOpenRec ? 'auto' : '3px' }" style="position:absolute;top:3px;width:18px;height:18px;border-radius:50%;background:#fff;transition:left 0.2s,right 0.2s"></div>
              </div>
            </div>
            <div style="display:flex;gap:10px;margin-top:4px">
              <button class="accent-btn" style="padding:12px 22px;font-size:13px" @click="saveSettings">Save changes</button>
              <button style="background:#fff;color:#6b7280;border:1px solid #e4e6e9;border-radius:11px;padding:12px 22px;font-family:inherit;font-weight:600;font-size:13px;cursor:pointer" @click="resetSettings">Cancel</button>
            </div>
          </div>
        </div>
      </template>

    </template>

  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useDashboardStore } from "@/stores/dashboardStore";
import type { OpenCompanyEntry } from "@/stores/dashboardStore";
import { nuiCallback } from "@/nui/nuiCallbacks";

const store = useDashboardStore();
const accentDark = "#b58a05";

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

// --- Invite ---
const inviteUsername = ref('');

async function sendInvite() {
  if (!inviteUsername.value.trim()) return;
  await nuiCallback('inviteMember', { name: inviteUsername.value.trim() });
  inviteUsername.value = '';
}

// --- Bank ---
const bankAmount = ref<number | null>(null);

async function deposit() {
  if (!bankAmount.value || bankAmount.value <= 0) return;
  await nuiCallback('depositBank', { amount: bankAmount.value });
  bankAmount.value = null;
}

async function withdraw() {
  if (!bankAmount.value || bankAmount.value <= 0) return;
  await nuiCallback('withdrawBank', { amount: bankAmount.value });
  bankAmount.value = null;
}

// --- Settings ---
const settingsName    = ref(store.config.companyName);
const settingsTag     = ref(store.config.companyTag);
const settingsDesc    = ref(store.config.companyDescription);
const settingsOpenRec = ref(store.config.companyOpenRecruitment);

watch(() => store.config.companyName,            v => { settingsName.value    = v; });
watch(() => store.config.companyTag,             v => { settingsTag.value     = v; });
watch(() => store.config.companyDescription,     v => { settingsDesc.value    = v; });
watch(() => store.config.companyOpenRecruitment, v => { settingsOpenRec.value = v; });

async function saveSettings() {
  await nuiCallback('saveCompanySettings', {
    name:            settingsName.value,
    tag:             settingsTag.value,
    description:     settingsDesc.value,
    openRecruitment: settingsOpenRec.value,
  });
}

function resetSettings() {
  settingsName.value    = store.config.companyName;
  settingsTag.value     = store.config.companyTag;
  settingsDesc.value    = store.config.companyDescription;
  settingsOpenRec.value = store.config.companyOpenRecruitment;
}

const ctabDefs = [
  { key: "overview",    label: "Overview",    icon: "tabler:layout-grid" },
  { key: "members",     label: "Members",     icon: "tabler:users" },
  { key: "invitations", label: "Invitations", icon: "tabler:mail" },
  { key: "statistics",  label: "Statistics",  icon: "tabler:chart-bar" },
  { key: "bank",        label: "Bank",        icon: "tabler:building-bank" },
  { key: "settings",    label: "Settings",    icon: "tabler:settings" },
];

const companyStats = computed(() => [
  { icon: "tabler:cash-banknote",   value: store.config.companyEarnings,   label: "Company earnings",  sub: "ui.company.earnings",   color: "#b58a05", bg: "rgba(232,180,8,0.16)" },
  { icon: "tabler:packages",        value: store.config.companyDeliveries, label: "Total deliveries",  sub: "ui.company.deliveries", color: "#2f9e63", bg: "rgba(47,158,99,0.14)" },
  { icon: "tabler:route",           value: store.config.companyDistance,   label: "Distance hauled",   sub: "ui.company.km",         color: "#3b82f6", bg: "rgba(59,130,246,0.14)" },
  { icon: "tabler:trophy",          value: store.config.companyServerRank, label: "Server rank",       sub: "global fleet standing", color: "#8b5cf6", bg: "rgba(139,92,246,0.14)" },
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
</style>
