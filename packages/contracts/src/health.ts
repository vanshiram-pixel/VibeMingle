/** Public, non-sensitive health response shared by API and probes. */
export type HealthStatus = "ok" | "degraded";

export interface HealthResponse {
  readonly service: "vibemingle-api";
  readonly status: HealthStatus;
  readonly timestamp: string;
  readonly version: string;
}

export function createHealthResponse(version: string): HealthResponse {
  return {
    service: "vibemingle-api",
    status: "ok",
    timestamp: new Date().toISOString(),
    version,
  };
}