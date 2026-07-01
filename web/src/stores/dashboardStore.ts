import { defineStore } from "pinia";

export type TabKey = "dashboard" | "orders" | "vehicles" | "skills" | "company" | string;
export type CompanyTabKey = "overview" | "members" | "invitations" | "statistics" | "bank" | "settings";

export interface Order {
  id: string;
  name: string;
  cargo: string;
  weight: string;
  distance: string;
  reward: string;
  xp: string;
  time: string;
  perKm: string;
  lvlReq: string;
  pickup: string;
  pickupCity: string;
  pickupKm: string;
  driveKm: string;
  driveTime: string;
  dropoff: string;
  dropoffCity: string;
  dropoffKm: string;
  comment: string;
  tag: string;
  tagColor: string;
  tagBg: string;
  icon: string;
}

export interface VehicleOwned {
  name: string;
  cls: string;
  slot: string;
  speed: string;
  cap: string;
  fuel: string;
  equipped: boolean;
}

export interface VehicleShop {
  name: string;
  cls: string;
  slot: string;
  speed: string;
  cap: string;
  fuel: string;
  price: string;
  locked: boolean;
  lvl: string;
}

export interface SkillNode {
  id: string;
  name: string;
  desc: string;
  cost: number;
  requires: string | null;
  state: "acquired" | "available" | "locked";
}

export interface SkillBranch {
  name: string;
  icon: string;
  skills: SkillNode[];
}

export interface Member {
  name: string;
  role: string;
  deliveries: number;
  earned: string;
  status: "online" | "idle" | "offline";
  lvl: number;
  you?: boolean;
}

export interface Transaction {
  label: string;
  amt: string;
  when: string;
  pos: boolean;
  icon: string;
}

export interface Invitation {
  name: string;
  lvl: number;
  sent: string;
}

export interface DashboardConfig {
  brandName: string;
  driverName: string;
  accentColor: string;
  driverLevel: number;
  driverXp: number;
  driverXpMax: number;
  skillPoints: number;
  balance: number;
  openOrders: number;
  completedOrders: number;
  successRate: string;
  earnings: string;
  orders: Order[];
  vehiclesOwned: VehicleOwned[];
  vehiclesShop: VehicleShop[];
  branches: SkillBranch[];
  recentRuns: { route: string; code: string; reward: string; tag: string; icon: string; failed: boolean }[];
  companyName: string;
  companyDescription: string;
  companyTag: string;
  companyLevel: number;
  companyXp: number;
  companyXpMax: number;
  companyFoundedDate: string;
  companyMembers: number;
  companyServerRank: string;
  companyEarnings: string;
  companyDeliveries: string;
  companyDistance: string;
  companyTreasury: string;
  companyOpenRecruitment: boolean;
  members: Member[];
  invitations: Invitation[];
  transactions: Transaction[];
  activity: { who: string; what: string; when: string; icon: string; color: string }[];
  statChart: { d: string; v: number }[];
  topHaulers: { name: string; val: string; bar: string }[];
}

const defaultConfig: DashboardConfig = {
  brandName: "Polarix",
  driverName: "Max Mustermann",
  accentColor: "#E8B408",
  driverLevel: 2,
  driverXp: 240,
  driverXpMax: 750,
  skillPoints: 15,
  balance: 45750,
  openOrders: 5,
  completedOrders: 3,
  successRate: "75%",
  earnings: "$45,750",
  orders: [
    { id: "al", name: "Alcohols", cargo: "Fragile", weight: "4.3 t", distance: "6.0 km", reward: "$43,500", xp: "+4", time: "2h 45m", perKm: "$7,250 / km", lvlReq: "Lvl 1", pickup: "Paleto Bay Main Street", pickupCity: "Paleto Bay", pickupKm: "8.0 km", driveKm: "6.0 km", driveTime: "2h 45m", dropoff: "Mirror Park Boulevard", dropoffCity: "Los Santos", dropoffKm: "6.0 km", comment: "Handle with care! Fragile goods inside.", tag: "FRAGILE", tagColor: "#b58a05", tagBg: "rgba(232,180,8,0.16)", icon: "tabler:bottle" },
    { id: "el", name: "Electronics", cargo: "High value", weight: "2.1 t", distance: "14.2 km", reward: "$68,900", xp: "+7", time: "1h 20m", perKm: "$4,852 / km", lvlReq: "Lvl 3", pickup: "LS International Airport", pickupCity: "Los Santos", pickupKm: "2.0 km", driveKm: "14.2 km", driveTime: "1h 20m", dropoff: "Sandy Shores Depot", dropoffCity: "Sandy Shores", dropoffKm: "14.2 km", comment: "Insured cargo. Avoid rough terrain.", tag: "VALUABLE", tagColor: "#3b82f6", tagBg: "rgba(59,130,246,0.14)", icon: "tabler:device-laptop" },
    { id: "fu", name: "Fuel Drums", cargo: "Hazardous", weight: "9.8 t", distance: "22.0 km", reward: "$91,200", xp: "+11", time: "3h 10m", perKm: "$4,145 / km", lvlReq: "Lvl 5", pickup: "Elysian Oil Refinery", pickupCity: "Los Santos", pickupKm: "5.0 km", driveKm: "22.0 km", driveTime: "3h 10m", dropoff: "Grapeseed Fuel Yard", dropoffCity: "Grapeseed", dropoffKm: "22.0 km", comment: "HAZMAT certification required. No smoking.", tag: "HAZMAT", tagColor: "#d24b3a", tagBg: "rgba(210,75,58,0.13)", icon: "tabler:flame" },
    { id: "li", name: "Livestock", cargo: "Perishable", weight: "6.4 t", distance: "18.5 km", reward: "$52,300", xp: "+6", time: "2h 05m", perKm: "$2,827 / km", lvlReq: "Lvl 2", pickup: "Grapeseed Farm", pickupCity: "Grapeseed", pickupKm: "3.0 km", driveKm: "18.5 km", driveTime: "2h 05m", dropoff: "Los Santos Meat Co.", dropoffCity: "Los Santos", dropoffKm: "18.5 km", comment: "Live cargo. Keep your speed steady.", tag: "LIVE", tagColor: "#2f9e63", tagBg: "rgba(47,158,99,0.14)", icon: "tabler:cow" },
    { id: "co", name: "Construction Steel", cargo: "Heavy", weight: "14.2 t", distance: "9.0 km", reward: "$38,750", xp: "+5", time: "1h 50m", perKm: "$4,305 / km", lvlReq: "Lvl 4", pickup: "Murrieta Heights Yard", pickupCity: "Los Santos", pickupKm: "4.0 km", driveKm: "9.0 km", driveTime: "1h 50m", dropoff: "Vinewood Build Site", dropoffCity: "Vinewood", dropoffKm: "9.0 km", comment: "Overweight load. Use main highways.", tag: "HEAVY", tagColor: "#8b5cf6", tagBg: "rgba(139,92,246,0.14)", icon: "tabler:building-factory-2" },
  ],
  vehiclesOwned: [
    { name: "Polarix Hauler T-200", cls: "Light Duty", slot: "veh-owned-1", speed: "140", cap: "8 t", fuel: "320 L", equipped: true },
    { name: "Mack Titan XR", cls: "Heavy Duty", slot: "veh-owned-2", speed: "110", cap: "24 t", fuel: "600 L", equipped: false },
  ],
  vehiclesShop: [
    { name: "Volvo FH16 Globetrotter", cls: "Heavy Duty", slot: "veh-shop-1", speed: "125", cap: "30 t", fuel: "700 L", price: "$680,000", locked: false, lvl: "" },
    { name: "Kenworth W900", cls: "Long-haul", slot: "veh-shop-2", speed: "135", cap: "26 t", fuel: "750 L", price: "$540,000", locked: false, lvl: "" },
    { name: "Scania R730 V8", cls: "Premium", slot: "veh-shop-3", speed: "150", cap: "28 t", fuel: "800 L", price: "$1,250,000", locked: true, lvl: "Lvl 10" },
    { name: "Freightliner Cascadia", cls: "Long-haul", slot: "veh-shop-4", speed: "130", cap: "27 t", fuel: "720 L", price: "$610,000", locked: false, lvl: "" },
  ],
  branches: [],
  recentRuns: [
    { route: "Los Santos Port → Sandy Shores", code: "#OR-2024-001231", reward: "$12,500", tag: "FULL HAUL", icon: "tabler:building-warehouse", failed: false },
    { route: "Downtown → Mirror Park", code: "#OR-2024-001212", reward: "$8,750", tag: "HALF LOAD", icon: "tabler:road", failed: false },
    { route: "Paleto Bay → LS International", code: "#OR-2024-001188", reward: "$24,500", tag: "VEHICLE", icon: "tabler:car", failed: false },
    { route: "Industrial District → Grapeseed", code: "#OR-2024-001120", reward: "$0", tag: "FAILED", icon: "tabler:alert-triangle", failed: true },
  ],
  companyName: "Polarix Freight Co.",
  companyDescription: "Reliable cross-country hauls. We move it, you trust it.",
  companyTag: "PLRX",
  companyLevel: 12,
  companyXp: 8400,
  companyXpMax: 12000,
  companyFoundedDate: "Aug 14, 2024",
  companyMembers: 6,
  companyServerRank: "#4 / 87",
  companyEarnings: "$18,450,000",
  companyDeliveries: "1,284",
  companyDistance: "84,320 km",
  companyTreasury: "$18,450,000",
  companyOpenRecruitment: false,
  members: [
    { name: "IronMike", role: "Owner", deliveries: 412, earned: "$5.2M", status: "online", lvl: 24 },
    { name: "HaulerJane", role: "Manager", deliveries: 308, earned: "$3.8M", status: "online", lvl: 19 },
    { name: "TruckerBob", role: "Driver", deliveries: 266, earned: "$2.9M", status: "online", lvl: 17 },
    { name: "DieselDon", role: "Driver", deliveries: 154, earned: "$1.6M", status: "idle", lvl: 17 },
    { name: "Max Mustermann", role: "Driver", deliveries: 3, earned: "$45.7K", status: "online", lvl: 2, you: true },
    { name: "RookieRiley", role: "Recruit", deliveries: 0, earned: "$0", status: "offline", lvl: 1 },
  ],
  invitations: [
    { name: "SpeedyGonzales", lvl: 14, sent: "2d ago" },
    { name: "BigRigBenny", lvl: 21, sent: "5d ago" },
    { name: "CargoQueen", lvl: 9, sent: "1w ago" },
  ],
  transactions: [
    { label: "Delivery payout – TruckerBob", amt: "+$13,500", when: "2m ago", pos: true, icon: "tabler:arrow-down-left" },
    { label: "Fuel reimbursement – HaulerJane", amt: "-$2,100", when: "1h ago", pos: false, icon: "tabler:arrow-up-right" },
    { label: "Delivery payout – HaulerJane", amt: "+$24,200", when: "1h ago", pos: true, icon: "tabler:arrow-down-left" },
    { label: "Vehicle purchase – Mack Titan", amt: "-$420,000", when: "1d ago", pos: false, icon: "tabler:arrow-up-right" },
    { label: "Member dividend payout", amt: "-$60,000", when: "2d ago", pos: false, icon: "tabler:arrow-up-right" },
  ],
  activity: [
    { who: "TruckerBob", what: "completed Sandy Shores delivery for $13,500", when: "2m ago", icon: "tabler:circle-check", color: "#2f9e63" },
    { who: "HaulerJane", what: "completed Paleto Bay run for $24,200", when: "18m ago", icon: "tabler:circle-check", color: "#2f9e63" },
    { who: "HaulerJane", what: "was promoted to Manager", when: "1h ago", icon: "tabler:arrow-up-circle", color: "#b58a05" },
    { who: "DieselDon", what: "reached level 17", when: "3h ago", icon: "tabler:star", color: "#3b82f6" },
    { who: "RookieRiley", what: "joined the company", when: "5h ago", icon: "tabler:user-plus", color: "#8b5cf6" },
  ],
  statChart: [
    { d: "Mon", v: 42 }, { d: "Tue", v: 58 }, { d: "Wed", v: 35 },
    { d: "Thu", v: 71 }, { d: "Fri", v: 88 }, { d: "Sat", v: 64 }, { d: "Sun", v: 29 },
  ],
  topHaulers: [
    { name: "IronMike", val: "412 runs", bar: "100%" },
    { name: "HaulerJane", val: "308 runs", bar: "75%" },
    { name: "TruckerBob", val: "266 runs", bar: "65%" },
    { name: "DieselDon", val: "154 runs", bar: "37%" },
  ],
};

export const useDashboardStore = defineStore("dashboard", {
  state: () => ({
    isOpen: false,
    tab: "dashboard" as TabKey,
    orderId: null as string | null,
    ctab: "overview" as CompanyTabKey,
    hoverSkill: null as string | null,
    config: { ...defaultConfig },
  }),
  actions: {
    open(cfg?: Partial<DashboardConfig>) {
      if (cfg) {
        Object.assign(this.config, cfg);
        if (cfg.orders !== undefined) {
          this.config.openOrders = this.config.orders.length;
        }
      }
      this.isOpen = true;
      this.tab = "dashboard";
      this.orderId = null;
      this.ctab = "overview";
    },
    close() {
      this.isOpen = false;
    },
    setTab(t: TabKey) {
      this.tab = t;
      this.orderId = null;
    },
    openOrder(id: string) {
      this.tab = "orders";
      this.orderId = id;
    },
    closeOrder() {
      this.orderId = null;
    },
    setCtab(t: CompanyTabKey) {
      this.ctab = t;
    },
    setHoverSkill(id: string | null) {
      this.hoverSkill = id;
    },
    unlockSkill(skillId: string) {
      for (const branch of this.config.branches) {
        for (let i = 0; i < branch.skills.length; i++) {
          const skill = branch.skills[i];
          if (skill.id === skillId && skill.state === "available") {
            this.config.skillPoints -= skill.cost ?? 1;
            skill.state = "acquired";
            const next = branch.skills[i + 1];
            if (next && next.state === "locked") {
              next.state = "available";
            }
            return;
          }
        }
      }
    },
  },
});
