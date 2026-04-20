/**
 * A simple semaphore for limiting concurrent access per provider.
 * When maxConcurrency is 1, requests are strictly serialized (FIFO queue).
 */
export class ProviderSemaphore {
  private queues: Map<string, Array<{ acquire: () => void }>> = new Map();
  private activeCount: Map<string, number> = new Map();
  private limits: Map<string, number> = new Map();
  private logger?: any;

  constructor(logger?: any) {
    this.logger = logger;
  }

  /**
   * Set the concurrency limit for a provider.
   * A value of 0 or undefined means unlimited.
   */
  setLimit(providerName: string, maxConcurrency: number | undefined): void {
    if (maxConcurrency && maxConcurrency > 0) {
      this.limits.set(providerName, maxConcurrency);
    } else {
      this.limits.delete(providerName);
    }
  }

  /**
   * Remove a provider's limit and reject all queued waiters.
   */
  removeLimit(providerName: string): void {
    this.limits.delete(providerName);
    const queue = this.queues.get(providerName);
    if (queue) {
      // Clear the queue — pending requests will proceed immediately
      // since the limit is removed
      queue.forEach((waiter) => waiter.acquire());
      this.queues.delete(providerName);
    }
  }

  /**
   * Acquire a slot for the given provider. Returns a release function.
   * If the provider has reached its concurrency limit, this will wait
   * until a slot becomes available.
   */
  async acquire(providerName: string): Promise<() => void> {
    const limit = this.limits.get(providerName);
    // No limit configured — unlimited concurrency
    if (!limit) {
      return () => {};
    }

    const current = this.activeCount.get(providerName) || 0;

    // If under limit, proceed immediately
    if (current < limit) {
      this.activeCount.set(providerName, current + 1);
      return this.createRelease(providerName);
    }

    // Over limit — queue up
    this.logger?.info?.(
      `Provider '${providerName}' concurrency limit reached (${limit}), queuing request...`
    );

    return new Promise<() => void>((resolve) => {
      const queue = this.queues.get(providerName) || [];
      queue.push({
        acquire: () => {
          const count = (this.activeCount.get(providerName) || 0) + 1;
          this.activeCount.set(providerName, count);
          resolve(this.createRelease(providerName));
        },
      });
      this.queues.set(providerName, queue);
    });
  }

  /**
   * Get current stats for a provider.
   */
  getStats(providerName: string): { active: number; queued: number; limit: number | undefined } {
    return {
      active: this.activeCount.get(providerName) || 0,
      queued: this.queues.get(providerName)?.length || 0,
      limit: this.limits.get(providerName),
    };
  }

  private createRelease(providerName: string): () => void {
    let released = false;
    return () => {
      if (released) return;
      released = true;

      const current = this.activeCount.get(providerName) || 1;
      const newCount = current - 1;
      this.activeCount.set(providerName, Math.max(0, newCount));

      // If there are queued requests, let the next one through
      const queue = this.queues.get(providerName);
      if (queue && queue.length > 0) {
        const next = queue.shift()!;
        if (queue.length === 0) {
          this.queues.delete(providerName);
        }
        // Process next in queue asynchronously to avoid stack overflow
        setImmediate(() => next.acquire());
      }
    };
  }
}
