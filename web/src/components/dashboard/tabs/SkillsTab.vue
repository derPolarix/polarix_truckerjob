<template>
  <div style="display:flex;flex-direction:column;gap:18px">
    <div style="display:flex;align-items:flex-end;justify-content:space-between;gap:16px">
      <div>
        <div style="font-size:20px;font-weight:800;letter-spacing:-0.01em;color:#1b1f24">Skill tree</div>
        <div style="font-family:'IBM Plex Mono',monospace;font-size:11px;color:#9aa1ab;margin-top:4px">Hover a node for details · earn points by hauling</div>
      </div>
      <div style="display:flex;align-items:center;gap:18px">
        <div style="display:inline-flex;align-items:center;gap:7px;font-size:12px;color:#6b7280">
          <span style="width:13px;height:13px;border-radius:50%;background:var(--accent)"></span>Acquired
        </div>
        <div style="display:inline-flex;align-items:center;gap:7px;font-size:12px;color:#6b7280">
          <span style="width:13px;height:13px;border-radius:50%;background:#fff;border:2px solid var(--accent)"></span>Available
        </div>
        <div style="display:inline-flex;align-items:center;gap:7px;font-size:12px;color:#6b7280">
          <span style="width:13px;height:13px;border-radius:50%;background:#e9ebee;border:1px solid #d2d6db"></span>Locked
        </div>
        <div style="display:inline-flex;align-items:center;gap:7px;padding:7px 13px;border-radius:20px;background:#22262d;color:#fff;font-size:12px;font-weight:600">
          <iconify-icon icon="tabler:bolt" width="15" :style="{ color: store.config.accentColor }"></iconify-icon>
          {{ store.config.skillPoints }} points
        </div>
      </div>
    </div>

    <div v-for="branch in store.config.branches" :key="branch.name" style="background:#fff;border:1px solid #dfe2e6;border-radius:16px;padding:22px 26px">
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:8px">
        <div style="width:30px;height:30px;border-radius:9px;background:#f1f2f4;display:flex;align-items:center;justify-content:center">
          <iconify-icon :icon="branch.icon" width="17" style="color:#3c424b"></iconify-icon>
        </div>
        <span style="font-size:14px;font-weight:700;color:#1b1f24">{{ branch.name }}</span>
      </div>
      <div style="display:flex;align-items:center;padding:14px 0 6px">
        <div v-for="(skill, i) in branch.skills" :key="skill.id" style="display:flex;align-items:center;flex:0 0 auto">
          <div
            style="position:relative;display:flex;flex-direction:column;align-items:center;width:96px"
            @mouseenter="store.setHoverSkill(skill.id)"
            @mouseleave="store.setHoverSkill(null)"
          >
            <div
              style="width:50px;height:50px;border-radius:14px;display:flex;align-items:center;justify-content:center;border-width:2px;border-style:solid;cursor:pointer"
              :style="nodeStyle(skill.state)"
            >
              <iconify-icon :icon="nodeIcon(skill.state)" width="22" :style="{ color: nodeIconColor(skill.state) }"></iconify-icon>
            </div>
            <div style="font-size:11px;font-weight:600;color:#3c424b;margin-top:8px;text-align:center;line-height:1.2">{{ skill.name }}</div>

            <!-- Tooltip -->
            <div
              v-if="store.hoverSkill === skill.id"
              style="position:absolute;bottom:64px;left:50%;transform:translateX(-50%);width:208px;background:#22262d;color:#fff;border-radius:12px;padding:13px 15px;box-shadow:0 14px 34px rgba(0,0,0,0.3);z-index:20;pointer-events:none"
            >
              <div style="display:flex;align-items:center;justify-content:space-between;gap:8px">
                <span style="font-size:13px;font-weight:700">{{ skill.name }}</span>
                <span style="font-family:'IBM Plex Mono',monospace;font-size:8px;letter-spacing:0.08em;padding:2px 6px;border-radius:5px" :style="tagStyle(skill.state)">{{ skill.state.toUpperCase() }}</span>
              </div>
              <div style="font-size:12px;color:#aeb4bd;margin-top:7px;line-height:1.45">{{ skill.desc }}</div>
              <div style="position:absolute;top:100%;left:50%;transform:translateX(-50%);width:0;height:0;border-left:7px solid transparent;border-right:7px solid transparent;border-top:7px solid #22262d"></div>
            </div>
          </div>

          <!-- Connector line -->
          <div
            v-if="i < branch.skills.length - 1"
            style="width:44px;height:3px;border-radius:2px;margin:0 2px;align-self:flex-start;margin-top:24px"
            :style="{ background: lineColor(branch.skills, i) }"
          ></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useDashboardStore } from "@/stores/dashboardStore";
import type { SkillNode } from "@/stores/dashboardStore";

const store = useDashboardStore();

function nodeStyle(state: SkillNode["state"]): Record<string, string> {
  const acc = store.config.accentColor;
  if (state === "acquired") return { background: acc, borderColor: acc };
  if (state === "available") return { background: "#ffffff", borderColor: acc };
  return { background: "#e9ebee", borderColor: "#cdd2d8" };
}

function nodeIcon(state: SkillNode["state"]) {
  if (state === "acquired") return "tabler:check";
  if (state === "available") return "tabler:plus";
  return "tabler:lock";
}

function nodeIconColor(state: SkillNode["state"]) {
  const acc = store.config.accentColor;
  if (state === "acquired") return "#22262d";
  if (state === "available") return acc;
  return "#aab0b8";
}

function tagStyle(state: SkillNode["state"]): Record<string, string> {
  if (state === "acquired") return { background: "rgba(47,158,99,0.22)", color: "#7ee2a8" };
  if (state === "available") return { background: "rgba(232,180,8,0.22)", color: "#f0c93f" };
  return { background: "rgba(255,255,255,0.1)", color: "#aeb4bd" };
}

function lineColor(skills: SkillNode[], i: number): string {
  const acc = store.config.accentColor;
  return skills[i + 1]?.state === "acquired" ? acc : "#cdd2d8";
}
</script>
