import { Transformer, TransformerContext } from "@/types/transformer";
import { LLMProvider, UnifiedChatRequest } from "@/types/llm";

export class OpenAITransformer implements Transformer {
  name = "OpenAI";
  endPoint = "/v1/chat/completions";
  logger?: any;

  async transformRequestIn(
    request: UnifiedChatRequest,
    provider: LLMProvider
  ): Promise<{ body: UnifiedChatRequest; config: { url: URL; headers: Record<string, string> } }> {
    return {
      body: request,
      config: {
        url: this.buildChatCompletionsUrl(provider.baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'text/event-stream, application/json, */*',
        },
      },
    };
  }

  async auth(request: any, provider: LLMProvider): Promise<any> {
    return {
      body: request,
      config: {
        url: this.buildChatCompletionsUrl(provider.baseUrl),
        headers: {
          'Authorization': `Bearer ${provider.apiKey}`,
          'Content-Type': 'application/json; charset=utf-8',
        },
      },
    };
  }

  private buildChatCompletionsUrl(baseUrl: string): URL {
    const url = new URL(baseUrl);
    const normalizedPath = url.pathname.replace(/\/+$/, "");

    if (normalizedPath.endsWith("/chat/completions")) {
      return url;
    }

    if (!normalizedPath || normalizedPath === "/") {
      url.pathname = "/v1/chat/completions";
      return url;
    }

    if (normalizedPath.endsWith("/v1")) {
      url.pathname = `${normalizedPath}/chat/completions`;
      return url;
    }

    url.pathname = `${normalizedPath}/chat/completions`;
    return url;
  }
}
