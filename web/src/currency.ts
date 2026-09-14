import { reactive } from "vue";

// SSOT: Config.Currency, pushed in on every Lua->NUI message next to the language.
// Every money value in the UI goes through money() so the symbol and its position
// are decided in exactly one place - same contract as shared/currency.lua.
export type CurrencyConfig = {
  symbol: string;
  position: "prefix" | "suffix";
};

const currency = reactive<CurrencyConfig>({
  symbol: "$",
  position: "prefix",
});

export function setCurrency(config: Partial<CurrencyConfig> | undefined): void {
  if (!config) return;
  if (config.symbol) currency.symbol = config.symbol;
  if (config.position === "prefix" || config.position === "suffix") currency.position = config.position;
}

export function currencySymbol(): string {
  return currency.symbol;
}

export function money(amount: number | null | undefined): string {
  const grouped = Math.trunc(amount ?? 0).toLocaleString("en-US");
  // suffix currencies are conventionally written with a space, prefix ones without
  return currency.position === "suffix" ? `${grouped} ${currency.symbol}` : `${currency.symbol}${grouped}`;
}
