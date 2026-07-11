import { fileURLToPath, URL } from "url";

import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue({ template: { compilerOptions: { isCustomElement: (tag) => tag === "iconify-icon" } } })],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  build: {
    outDir: "../html",
  },
  base: "",
  // locales/*.json (SSOT, shared with Lua) lives one level above the vite root — allow reading it.
  server: {
    fs: {
      allow: [".."],
    },
  },
});
