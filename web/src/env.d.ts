/// <reference types="vite/client" />

declare module "*.vue" {
  import type { DefineComponent } from "vue";
  const component: DefineComponent<{}, {}, unknown>;
  export default component;
}

declare global {
  function GetParentResourceName(): string;
}

// Augemente die in allen Vue Komponenten verfügbaren globalen Properties
// Hier werden der Router und der Persistant Store hinzugefügt
// So können diese in jeder Komponente via this.$router bzw. this.$persistantStore genutzt werden

declare module "@vue/runtime-core" {
  interface ComponentCustomProperties {
    $persistantStore: import("./stores/persistantStore").PersistantStore;
    $router: import("vue-router").Router;
  }
}

export {};