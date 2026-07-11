import { createI18n } from "vue-i18n";

// SSOT: same locales/*.json files the Lua side reads via shared/locale.lua.
// Keys are semantic (e.g. "notify.vehicle_bought"), values are the display text per language.
import de from "../../locales/de.json";
import en from "../../locales/en.json";

export const i18n = createI18n({
  legacy: false,
  locale: "de",
  fallbackLocale: "en",
  messages: { de, en },
});
