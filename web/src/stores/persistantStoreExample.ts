// Dieser Store ist dafür gedacht übergreifende Werte zu verwalten. Für einzelne Pages sollte man zusätzlich eigene Stores erstellen./

//Imports
import { defineStore } from "pinia";
import { nuiCallbackAsync, nuiCallback } from "@/nui/nuiCallbacks";

//Types
type ExampleStateType = {
	IsNuiOpen: boolean;
};
type ExampleGettersType = {
	isNuiOpen: (state: ExampleStateType) => boolean;
};
type ExampleActionsType = {
	setNuiOpen(isOpen: boolean): void;
	closeNui(): Promise<void>;
};

export const useExampleStore = defineStore<
	"example",
	ExampleStateType,
	ExampleGettersType,
	ExampleActionsType
>("example", {
	state: (): ExampleStateType => ({
		IsNuiOpen: true,
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
			await nuiCallbackAsync("closeNui");
		},
	},
});

export type ExampleStore = ReturnType<typeof useExampleStore>;
