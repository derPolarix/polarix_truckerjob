// Global store for cross-page state; create dedicated stores for individual pages.
import { defineStore } from "pinia";
import { nuiCallbackAsync } from "@/nui/nuiCallbacks";

export type HeldAction = {
	name: string;
	hint?: string;
	primaryKey: string;
	primaryAction: string;
} | null;

type PersistantState = {
	IsNuiOpen: boolean;
  MessageData: string | null;
	heldAction: HeldAction;
	isHoldingAction: boolean;
};
type PersistantGetters = {
	isNuiOpen: (state: PersistantState) => boolean;
};
type PersistantActions = {
	setNuiOpen(isOpen: boolean): void;
	closeNui(): Promise<void>;
	setHeldAction(action: HeldAction): void;
	clearHeldAction(): void;
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
			heldAction: null,
			isHoldingAction: false,
		}),
		getters: {
			isNuiOpen: (state) => state.IsNuiOpen,
		},
		actions: {
			setNuiOpen(isOpen: boolean) {
				this.IsNuiOpen = isOpen;
			},
			setHeldAction(action: HeldAction) {
				this.heldAction = action;
				this.isHoldingAction = action !== null;
			},
			clearHeldAction() {
				this.heldAction = null;
				this.isHoldingAction = false;
			},
			async closeNui() {
				this.IsNuiOpen = false;
				await nuiCallbackAsync("closeNui", {message: this.MessageData});
			},
		},
	},
);

export type PersistantStore = ReturnType<typeof usePersistantStore>;
