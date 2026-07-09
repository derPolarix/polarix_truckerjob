import { defineStore } from "pinia";

export interface PartyMember {
  identifier: string;
  name: string;
  isLeader: boolean;
  online: boolean;
}

export interface PartyState {
  partyId: number;
  leaderIdentifier: string;
  members: PartyMember[];
  maxSize: number;
}

export interface PartyInvite {
  partyId: number;
  fromName: string;
}

export interface PartyRewardMultiplier {
  cash: number;
  xp: number;
}

export interface PartyOnlineCandidate {
  identifier: string;
  name: string;
  lvl: number;
}

export interface PartyMissionProgress {
  totalPallets: number;
  claimedTotal: number;
  deliveredTotal: number;
}

export const usePartyStore = defineStore("party", {
  state: () => ({
    party: null as PartyState | null,
    pendingInvite: null as PartyInvite | null,
    rewardMultiplier: null as PartyRewardMultiplier | null,
    missionProgress: null as PartyMissionProgress | null,
    isOpen: false,
  }),
  actions: {
    setState(state: PartyState | null) {
      this.party = state;
    },
    setPendingInvite(invite: PartyInvite | null) {
      this.pendingInvite = invite;
    },
    setMultiplier(mult: PartyRewardMultiplier | null) {
      this.rewardMultiplier = mult ?? null;
    },
    setMissionProgress(progress: PartyMissionProgress | null) {
      this.missionProgress = progress;
    },
    toggle() {
      this.isOpen = !this.isOpen;
    },
    close() {
      this.isOpen = false;
    },
  },
});
