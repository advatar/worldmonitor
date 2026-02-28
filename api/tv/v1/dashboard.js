export const config = { runtime: 'edge' };

import { createServerContext, normalizeProfile, TV_MODULE_DEFS, TV_PROFILE_CONFIGS, TV_SCHEMA_VERSION } from './_shared.js';
import { infrastructureHandler } from '../../../server/worldmonitor/infrastructure/v1/handler';
import { economicHandler } from '../../../server/worldmonitor/economic/v1/handler';
import { seismologyHandler } from '../../../server/worldmonitor/seismology/v1/handler';
import { cyberHandler } from '../../../server/worldmonitor/cyber/v1/handler';
import { maritimeHandler } from '../../../server/worldmonitor/maritime/v1/handler';
import { intelligenceHandler } from '../../../server/worldmonitor/intelligence/v1/handler';

function parseModules(url, profileConfig) {
  const rawModules = url.searchParams.get('modules') || '';
  const explicit = rawModules
    .split(',')
    .map((key) => key.trim())
    .filter(Boolean);
  const list = explicit.length > 0 ? explicit : profileConfig.modules;

  const values = [];
  const seen = new Set();
  for (const key of list) {
    if (!TV_MODULE_DEFS[key] || seen.has(key)) continue;
    values.push(key);
    seen.add(key);
  }
  return values.length > 0 ? values : profileConfig.modules;
}

function parsePositiveInt(value, fallback, min, max) {
  const parsed = Number.parseInt(value ?? '', 10);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.max(min, Math.min(max, parsed));
}

function mapServiceStatus(value) {
  if (!value) return 'SERVICE_OPERATIONAL_STATUS_UNSPECIFIED';
  const raw = value.trim().toUpperCase();
  if (raw.startsWith('SERVICE_OPERATIONAL_STATUS_')) return raw;
  if (raw === 'OPERATIONAL') return 'SERVICE_OPERATIONAL_STATUS_OPERATIONAL';
  if (raw === 'DEGRADED') return 'SERVICE_OPERATIONAL_STATUS_DEGRADED';
  if (raw === 'PARTIAL_OUTAGE' || raw === 'PARTIAL') return 'SERVICE_OPERATIONAL_STATUS_PARTIAL_OUTAGE';
  if (raw === 'MAJOR_OUTAGE' || raw === 'MAJOR' || raw === 'OUTAGE') return 'SERVICE_OPERATIONAL_STATUS_MAJOR_OUTAGE';
  if (raw === 'MAINTENANCE' || raw === 'MAINT') return 'SERVICE_OPERATIONAL_STATUS_MAINTENANCE';
  return 'SERVICE_OPERATIONAL_STATUS_UNSPECIFIED';
}

function mapCyberType(value) {
  if (!value) return 'CYBER_THREAT_TYPE_UNSPECIFIED';
  const normalized = value.toLowerCase();
  const aliases = {
    c2_server: 'CYBER_THREAT_TYPE_C2_SERVER',
    malware_host: 'CYBER_THREAT_TYPE_MALWARE_HOST',
    phishing: 'CYBER_THREAT_TYPE_PHISHING',
    malicious_url: 'CYBER_THREAT_TYPE_MALICIOUS_URL',
    'c2-server': 'CYBER_THREAT_TYPE_C2_SERVER',
    'malware-host': 'CYBER_THREAT_TYPE_MALWARE_HOST',
  };
  if (aliases[normalized]) return aliases[normalized];
  if (normalized.startsWith('CYBER_THREAT_TYPE_'.toLowerCase())) {
    return value.toUpperCase();
  }
  return 'CYBER_THREAT_TYPE_UNSPECIFIED';
}

function mapThreatSource(value) {
  if (!value) return 'CYBER_THREAT_SOURCE_UNSPECIFIED';
  const normalized = value.toLowerCase();
  const aliases = {
    feodo: 'CYBER_THREAT_SOURCE_FEODO',
    urlhaus: 'CYBER_THREAT_SOURCE_URLHAUS',
    c2intel: 'CYBER_THREAT_SOURCE_C2INTEL',
    'c2-intel': 'CYBER_THREAT_SOURCE_C2INTEL',
    c2_intel: 'CYBER_THREAT_SOURCE_C2INTEL',
    otx: 'CYBER_THREAT_SOURCE_OTX',
    abuseipdb: 'CYBER_THREAT_SOURCE_ABUSEIPDB',
  };
  if (aliases[normalized]) return aliases[normalized];
  if (normalized.startsWith('CYBER_THREAT_SOURCE_'.toLowerCase())) {
    return value.toUpperCase();
  }
  return 'CYBER_THREAT_SOURCE_UNSPECIFIED';
}

function mapThreatSeverity(value) {
  if (!value) return 'CRITICALITY_LEVEL_UNSPECIFIED';
  const normalized = value.toLowerCase();
  const aliases = {
    low: 'CRITICALITY_LEVEL_LOW',
    medium: 'CRITICALITY_LEVEL_MEDIUM',
    high: 'CRITICALITY_LEVEL_HIGH',
    critical: 'CRITICALITY_LEVEL_CRITICAL',
    unspecified: 'CRITICALITY_LEVEL_UNSPECIFIED',
  };
  if (aliases[normalized]) return aliases[normalized];
  if (normalized.startsWith('CRITICALITY_LEVEL_'.toLowerCase())) return value.toUpperCase();
  return 'CRITICALITY_LEVEL_UNSPECIFIED';
}

const DASHBOARD_CACHE_HINTS = {
  short: 60,
  medium: 150,
  long: 300,
};

const moduleFetchers = {
  async riskPulse(ctx, request) {
    const region = request.searchParams.get('region') || '';
    return intelligenceHandler.getRiskScores(ctx, { region });
  },

  async serviceStatus(ctx, request) {
    const status = mapServiceStatus(request.searchParams.get('service_status') || request.searchParams.get('status'));
    return infrastructureHandler.listServiceStatuses(ctx, { status });
  },

  async macroSignals(ctx) {
    return economicHandler.getMacroSignals(ctx, {});
  },

  async earthquakes(ctx, request) {
    const pageSize = parsePositiveInt(request.searchParams.get('page_size') || request.searchParams.get('pageSize'), 75, 1, 500);
    const minMagnitude = Number(request.searchParams.get('min_magnitude') || request.searchParams.get('minMagnitude')) || 0;
    return seismologyHandler.listEarthquakes(ctx, {
      start: 0,
      end: 0,
      pageSize,
      cursor: '',
      minMagnitude,
    });
  },

  async cyberThreats(ctx, request) {
    const pageSize = parsePositiveInt(request.searchParams.get('page_size') || request.searchParams.get('pageSize'), 100, 1, 1000);
    const type = mapCyberType(request.searchParams.get('type'));
    const source = mapThreatSource(request.searchParams.get('source'));
    const minSeverity = mapThreatSeverity(request.searchParams.get('min_severity') || request.searchParams.get('minSeverity'));

    return cyberHandler.listCyberThreats(ctx, {
      start: 0,
      end: 0,
      pageSize,
      cursor: '',
      type,
      source,
      minSeverity,
    });
  },

  async navigationWarnings(ctx, request) {
    const pageSize = parsePositiveInt(request.searchParams.get('page_size') || request.searchParams.get('pageSize'), 100, 1, 500);
    const area = request.searchParams.get('area') || '';
    return maritimeHandler.listNavigationalWarnings(ctx, { pageSize, cursor: '', area });
  },
};

async function fetchModule(key, context, request) {
  const fetcher = moduleFetchers[key];
  if (!fetcher) {
    return {
      key,
      status: 'unsupported',
      ok: false,
      error: `Module ${key} is not supported.`,
    };
  }

  const start = Date.now();
  try {
    const data = await fetcher(context, request);
    return {
      key,
      status: 'ok',
      ok: true,
      latencyMs: Date.now() - start,
      updatedAt: new Date().toISOString(),
      data,
    };
  } catch (error) {
    return {
      key,
      status: 'error',
      ok: false,
      latencyMs: Date.now() - start,
      updatedAt: new Date().toISOString(),
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

function getRequestHeaders(request) {
  const origin = request.headers.get('origin') || '';
  const allowed = [
    /^https:\/\/(.*\.)?worldmonitor\.app$/,
    /^https:\/\/worldmonitor-[a-z0-9-]+-elie-[a-z0-9]+\.vercel\.app$/,
    /^https:\/\/worldmonitor-[a-z0-9-]+\.vercel\.app$/,
    /^https?:\/\/localhost(:\d+)?$/,
    /^https?:\/\/127\.0\.0\.1(:\d+)?$/,
    /^tauri:\/\/localhost$/,
    /^asset:\/\/localhost$/,
  ].some((pattern) => pattern.test(origin)) ? origin : 'https://worldmonitor.app';

  return {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-WorldMonitor-Key',
    'Cache-Control': 'public, s-maxage=120, stale-while-revalidate=60',
    Vary: 'Origin',
  };
}

function getCacheControl(modules) {
  const cacheSeconds = modules.map((module) => DASHBOARD_CACHE_HINTS[TV_MODULE_DEFS[module]?.cacheHint] || 120);
  const min = Math.min(...cacheSeconds, 120);
  return `public, s-maxage=${min}, stale-while-revalidate=60`;
}

export default async function handler(request) {
  const requestHeaders = getRequestHeaders(request);
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: requestHeaders,
    });
  }
  if (request.method !== 'GET') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: requestHeaders,
    });
  }

  const url = new URL(request.url);
  const profile = normalizeProfile(url.searchParams.get('profile'));
  const profileConfig = TV_PROFILE_CONFIGS[profile];
  const requestedModules = parseModules(url, profileConfig);
  const context = createServerContext(request);

  const results = await Promise.all(
    requestedModules.map((module) => fetchModule(module, context, url)),
  );

  const modules = {};
  for (const result of results) {
    modules[result.key] = {
      status: result.status,
      ok: result.ok,
      data: result.ok ? result.data : undefined,
      error: result.error,
      latencyMs: result.latencyMs,
      updatedAt: result.updatedAt,
    };
  }

  const hasErrors = results.some((item) => !item.ok);
  const status = hasErrors ? 'partial' : 'ok';
  const response = {
    schemaVersion: TV_SCHEMA_VERSION,
    status,
    generatedAt: new Date().toISOString(),
    profile,
    region: profileConfig.defaultRegion,
    modules,
  };

  requestHeaders.set('Cache-Control', getCacheControl(requestedModules));
  return new Response(JSON.stringify(response), {
    status: 200,
    headers: requestHeaders,
  });
}
