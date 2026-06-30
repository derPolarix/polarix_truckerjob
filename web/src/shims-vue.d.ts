declare module "*.vue" {
  import type { DefineComponent } from "vue";
  const component: DefineComponent<{}, {}, any>;
  export default component;
}

declare namespace JSX {
  interface IntrinsicElements {
    "iconify-icon": {
      icon?: string;
      width?: string | number;
      height?: string | number;
      style?: string;
      class?: string;
    };
  }
}
