import { defineStore } from "pinia";

export type GameHudPhase = "pickup" | "delivering" | null;

export interface GameHudPayload {
  visible: boolean;
  phase?: GameHudPhase;
  cargo?: string;
  city?: string;
  distanceKm?: number;
  speedKmh?: number;
  damage?: number;
  palletsLoaded?: number;
  palletsRequired?: number;
  inForklift?: boolean;
  forkliftCarrying?: boolean;
}

type GameHudState = {
  visible: boolean;
  phase: GameHudPhase;
  cargo: string;
  city: string;
  distanceKm: number;
  speedKmh: number;
  damage: number;
  palletsLoaded: number;
  palletsRequired: number;
  inForklift: boolean;
  forkliftCarrying: boolean;
};

export const useGameHudStore = defineStore("gameHud", {
  state: (): GameHudState => ({
    visible: false,
    phase: null,
    cargo: "",
    city: "",
    distanceKm: 0,
    speedKmh: 0,
    damage: 0,
    palletsLoaded: 0,
    palletsRequired: 0,
    inForklift: false,
    forkliftCarrying: false,
  }),
  actions: {
    update(payload: GameHudPayload) {
      if (!payload.visible) {
        this.visible = false;
        return;
      }
      this.visible = true;
      this.phase = payload.phase ?? null;
      this.cargo = payload.cargo ?? "";
      this.city = payload.city ?? "";
      this.distanceKm = payload.distanceKm ?? 0;
      this.speedKmh = payload.speedKmh ?? 0;
      this.damage = payload.damage ?? 0;
      this.palletsLoaded = payload.palletsLoaded ?? 0;
      this.palletsRequired = payload.palletsRequired ?? 0;
      this.inForklift = payload.inForklift ?? false;
      this.forkliftCarrying = payload.forkliftCarrying ?? false;
    },
  },
});
