import { createRouter, createWebHistory } from "vue-router";

import Dashboard from "../views/Dashboard.vue";
import AdminMissionEditor from "../views/AdminMissionEditor.vue";

// Add new pages by adding an object to the routes array below.
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/dashboard",
      name: "dashboard",
      component: Dashboard,
      meta: { navLabel: "Dashboard" },
    },
    {
      path: "/admin-missions",
      name: "admin-missions",
      component: AdminMissionEditor,
      meta: { navLabel: "Admin: Missionen" },
    },
    {
      path: "/",
      redirect: "/dashboard",
    },
  ],
});

export default router;
