export type NuiCallback = <TResponse = unknown>(
  name: string,
  data?: unknown
) => Promise<TResponse | null>;

export type NuiCallbackAsync = <TResponse = unknown>(
  name: string,
  data?: unknown
) => Promise<TResponse>;

export type NuiMessage<TAction extends string = string, TData = unknown> = {
  action: TAction;
  data?: TData;
};

