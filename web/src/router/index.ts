import { createRouter, createWebHistory } from "vue-router";

//Hier müssen die verschiedenen Vue Seiten importiert werden die der Router nutzen soll
import Defaultpage from "../views/DefaultPage.vue";
import TemplatePage from "../views/TemplatePage.vue";
import Dashboard from "../views/Dashboard.vue";

//Hier werden neue Seiten definiert die der Router nutzen kann
//Um neue Routen anzulegen einfach ein neues Objekt in das routes Array hinzufügen
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/defaultpage", //Die URL die im Browser aufgerufen wird
      name: "defaultpage", //Der Name der Route (wird z.B. in der Sidebar genutzt um die Route zu referenzieren)
      component: Defaultpage, //Das Vue Komponent das gerendert wird
      meta: { navLabel: "Startseite / Defaultpage" }, //Metadaten die der Route hinzugefügt werden können (z.B. für die Sidebar Navigation das Label)
    },
    {
      path: "/template",
      name: "template",
      component: TemplatePage,
      meta: { navLabel: "Vorlage / TemplatePage" },
    },
    {
      path: "/dashboard",
      name: "dashboard",
      component: Dashboard,
      meta: { navLabel: "Dashboard" },
    },
    {
      path: "/",
      redirect: "/dashboard",
    },
  ],
});

export default router;
