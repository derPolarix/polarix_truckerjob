/// <reference types="vite/client" />

declare module "*.vue" {
  import type { DefineComponent } from "vue";
  const component: DefineComponent<{}, {}, unknown>;
  export default component;
}

declare global {
  function GetParentResourceName(): string;
}

// Adds router and persistant store to $router / $persistantStore on every component instance
declare module "@vue/runtime-core" {
  interface ComponentCustomProperties {
    $persistantStore: import("./stores/persistantStore").PersistantStore;
    $router: import("vue-router").Router;
  }
}

export {};