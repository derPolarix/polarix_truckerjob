import { createApp } from "vue";
import { createPinia } from "pinia";

import "./style.css";

import App from "./App.vue";
import router from "./router";
import { i18n } from "./i18n";
import { usePersistantStore } from "@/stores/persistantStore";

const app = createApp(App);
const pinia = createPinia();

export const isDev = import.meta.env.DEV;

// Make router + store accessible via the component instance proxy (e.g. getCurrentInstance()?.proxy?.$router)
app.config.globalProperties.$router = router;
app.config.globalProperties.$persistantStore = usePersistantStore(pinia);

app.use(pinia);
app.use(router);
app.use(i18n);

app.mount("#app");
