// Dieser Store ist dafür gedacht übergreifende Werte zu verwalten. Für einzelne Pages sollte man zusätzlich eigene Stores erstellen./

//Imports
import { defineStore } from "pinia";
import { nuiCallbackAsync } from "@/nui/nuiCallbacks";

//Types
type PersistantState = {
	IsNuiOpen: boolean;
  MessageData: string | null;
};
type PersistantGetters = {
	isNuiOpen: (state: PersistantState) => boolean;
};
type PersistantActions = {
	setNuiOpen(isOpen: boolean): void;
	closeNui(): Promise<void>;
};

export const usePersistantStore = defineStore<
	"persistant",
	PersistantState,
	PersistantGetters,
	PersistantActions
>(
	"persistant",
	{
		state: (): PersistantState => ({
			IsNuiOpen: false,
      MessageData: null,
		}),
		getters: {
			isNuiOpen: (state) => state.IsNuiOpen,
		},
		actions: {
			setNuiOpen(isOpen: boolean) {
				this.IsNuiOpen = isOpen;
			},
			async closeNui() {
				this.IsNuiOpen = false;
				await nuiCallbackAsync("closeNui", {message: this.MessageData});
			},
		},
	},
);

export type PersistantStore = ReturnType<typeof usePersistantStore>;
