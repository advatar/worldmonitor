export const config = { runtime: 'edge' };

import {
  TV_SCHEMA_VERSION,
  TV_PROFILE_CONFIGS,
  TV_MODULE_DEFS,
} from './_shared.js';

function getHeaders(request) {
  const headers = {
    'Content-Type': 'application/json',
    'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=1800',
  };
  return {
    ...headers,
    ...createManifestCorsHeaders(request),
  };
}

function createManifestCorsHeaders(request) {
  const origin = request.headers.get('origin') || '';
  const allowedOrigin = [
    /^https:\/\/(.*\.)?worldmonitor\.app$/,
    /^https:\/\/worldmonitor-[a-z0-9-]+-elie-[a-z0-9]+\.vercel\.app$/,
    /^https:\/\/worldmonitor-[a-z0-9-]+\.vercel\.app$/,
    /^https?:\/\/localhost(:\d+)?$/,
    /^https?:\/\/127\.0\.0\.1(:\d+)?$/,
  ].some((regex) => regex.test(origin)) ? origin : 'https://worldmonitor.app';

  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-WorldMonitor-Key',
    Vary: 'Origin',
  };
}

export default async function handler(request) {
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: getHeaders(request),
    });
  }

  if (request.method !== 'GET') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: getHeaders(request),
    });
  }

  const allProfiles = Object.values(TV_PROFILE_CONFIGS);
  const allProfileIds = allProfiles.map((profile) => profile.id);
  const response = {
    schemaVersion: TV_SCHEMA_VERSION,
    generatedAt: new Date().toISOString(),
    endpoints: {
      bootstrap: '/api/tv/v1/bootstrap',
      dashboard: '/api/tv/v1/dashboard',
    },
    moduleDefs: TV_MODULE_DEFS,
    profiles: {
      ids: allProfileIds,
      details: TV_PROFILE_CONFIGS,
    },
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: getHeaders(request),
  });
}
