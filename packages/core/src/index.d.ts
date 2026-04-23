// Type declarations for @musistudio/llms

// Listener types
export type ListenerProtocol = "openai" | "anthropic" | "all";

export interface ListenerConfig {
  name: string;
  port: number;
  host?: string;
  protocol: ListenerProtocol;
  apiKey?: string;
}

// Main Server class
export declare class Server {
  constructor(options?: any);
  register(plugin: any, options?: any): Promise<void>;
  addHook(hookName: string, hookFunction: any): void;
  registerNamespace(name: string, options?: any): Promise<void>;
  start(): Promise<void>;
  startListeners(): Promise<void>;
  stopListeners(): Promise<void>;
  app: any;
  configService: ConfigService;
  providerService: ProviderService;
  transformerService: TransformerService;
  tokenizerService: TokenizerService;
}

// Default export
declare const _default: typeof Server;
export default _default;

// Cache and utilities
export declare const sessionUsageCache: any;
export declare const router: any;
export declare const calculateTokenCount: any;
export declare const searchProjectBySession: any;

// Type exports
export type RouterScenarioType = any;
export type RouterFallbackConfig = any;

// Services
export declare class ConfigService {
  constructor(options?: any);
}

export declare class ProviderService {
  constructor(configService: ConfigService, transformerService: TransformerService, logger: any);
}

export declare class TransformerService {
  constructor(configService: ConfigService, logger: any);
  registerTransformer(name: string, transformer: any): void;
  getTransformer(name: string): any;
}

export declare class TokenizerService {
  constructor(configService: ConfigService, logger: any, options?: any);
  initialize(): Promise<void>;
  getTokenizer(config?: any): Promise<any>;
  getTokenizerConfigForModel(providerName: string, modelName: string): any;
  countTokens(request: any, config?: any): Promise<any>;
}

// Plugins
export declare const pluginManager: any;
export declare const tokenSpeedPlugin: any;
export declare const getTokenSpeedStats: any;
export declare const getGlobalTokenSpeedStats: any;

export interface CCRPlugin {
  name: string;
  enabled?: boolean;
  options?: Record<string, any>;
}

export interface CCRPluginOptions {
  enabled?: boolean;
  outputHandlers?: any[];
}

export interface PluginMetadata {
  name: string;
  version: string;
  description?: string;
}

// SSE utilities
export declare class SSEParserTransform {
  constructor(options?: any);
}

export declare class SSESerializerTransform {
  constructor(options?: any);
}

export declare const rewriteStream: any;
