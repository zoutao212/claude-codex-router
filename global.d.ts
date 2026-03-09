// Global type definitions for @musistudio/llms
declare module '@musistudio/llms' {
  // Main exports
  export class Server {
    constructor(options?: any);
    register(plugin: any, options?: any): Promise<void>;
    addHook(hookName: string, hookFunction: any): void;
    registerNamespace(name: string, options?: any): Promise<void>;
    start(): Promise<void>;
    app: any;
    configService: any;
    providerService: any;
    transformerService: any;
    tokenizerService: any;
  }

  export const sessionUsageCache: any;
  export const router: any;
  export const calculateTokenCount: any;
  export const searchProjectBySession: any;

  // Services
  export class ConfigService {
    constructor(options?: any);
  }

  export class ProviderService {
    constructor(configService: any, transformerService: any, logger: any);
  }

  export class TransformerService {
    constructor(configService: any, logger: any);
    registerTransformer(name: string, transformer: any): void;
    getTransformer(name: string): any;
  }

  export class TokenizerService {
    constructor(configService: any, logger: any);
    initialize(): Promise<void>;
  }

  // Plugins
  export const pluginManager: any;
  export const tokenSpeedPlugin: any;
  export const getTokenSpeedStats: any;
  export const getGlobalTokenSpeedStats: any;

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
  export class SSEParserTransform {
    constructor(options?: any);
  }

  export class SSESerializerTransform {
    constructor(options?: any);
  }

  export const rewriteStream: any;
}
