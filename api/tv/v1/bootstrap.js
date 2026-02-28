export const config = { runtime: 'edge' };

import {
  TV_MODULE_DEFS,
  TV_PROFILE_CONFIGS,
  TV_SCHEMA_VERSION,
  normalizeProfile,
} from './_shared.js';

function createBootstrapHeaders(request) {
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

function parseRequestedModules(url, profileConfig) {
  const rawModules = url.searchParams.get('modules') || '';
  const candidateModules = rawModules
    .split(',')
    .map((module) => module.trim())
    .filter(Boolean);
  const requested = candidateModules.length > 0 ? candidateModules : profileConfig.modules;

  const normalized = [];
  const seen = new Set();
  for (const key of requested) {
    if (!TV_MODULE_DEFS[key] || seen.has(key)) continue;
    normalized.push(key);
    seen.add(key);
  }

  return normalized.length > 0 ? normalized : profileConfig.modules;
}

export default async function handler(request) {
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: createBootstrapHeaders(request),
    });
  }

  if (request.method !== 'GET') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: createBootstrapHeaders(request),
    });
  }

  const url = new URL(request.url);
  const profile = normalizeProfile(url.searchParams.get('profile'));
  const profileConfig = TV_PROFILE_CONFIGS[profile];
  const requestedModules = parseRequestedModules(url, profileConfig);

  const moduleManifest = {};
  for (const key of requestedModules) {
    moduleManifest[key] = {
      ...TV_MODULE_DEFS[key],
      endpoint: '/api/tv/v1/dashboard',
    };
  }

  const response = {
    schemaVersion: TV_SCHEMA_VERSION,
    profile,
    generatedAt: Date.now(),
    refreshSeconds: 60,
    selectedModules: requestedModules,
    moduleManifest,
    panelOrder: profileConfig.panelOrder,
    mapLayers: profileConfig.mapLayers,
    defaultRegion: profileConfig.defaultRegion,
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: createBootstrapHeaders(request),
  });
}
