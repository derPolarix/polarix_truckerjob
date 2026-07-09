import { defineStore } from "pinia";

export interface AppNotification {
  id: number;
  type: string;
  title: string;
  message: string;
  icon: string;
  is_read: boolean;
  created_at: string;
}

function mapRow(row: any): AppNotification {
  return {
    id: row.id,
    type: row.type ?? "",
    title: row.title ?? "",
    message: row.message ?? "",
    icon: row.icon ?? "tabler:bell",
    is_read: row.is_read === 1 || row.is_read === true,
    created_at: row.created_at ?? "",
  };
}

export const useNotificationsStore = defineStore("notifications", {
  state: () => ({
    items: [] as AppNotification[],
    isOpen: false,
  }),
  getters: {
    unreadCount: (state) => state.items.filter((n) => !n.is_read).length,
  },
  actions: {
    setAll(rows: any[]) {
      this.items = (rows ?? []).map(mapRow);
    },
    push(row: any) {
      this.items.unshift(mapRow(row));
    },
    markRead(id: number) {
      const n = this.items.find((i) => i.id === id);
      if (n) n.is_read = true;
    },
    markAllRead() {
      this.items.forEach((i) => (i.is_read = true));
    },
    toggle() {
      this.isOpen = !this.isOpen;
    },
    close() {
      this.isOpen = false;
    },
  },
});
