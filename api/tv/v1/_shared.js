export const TV_SCHEMA_VERSION = '1.0.0';

const PROFILE_DEFAULT = 'full';

export const TV_PROFILE_CONFIGS = {
  full: {
    id: 'full',
    displayName: 'Global Intelligence',
    description: 'Full geopolitical + infrastructure + cyber + market monitoring',
    panelOrder: [
      'live-news',
      'live-webcams',
      'insights',
      'strategic-posture',
      'strategic-risk',
      'cii',
      'macro-signals',
      'economic',
      'trade-policy',
      'supply-chain',
      'security-advisories',
      'security',
      'news',
    ],
    modules: ['riskPulse', 'serviceStatus', 'macroSignals', 'earthquakes', 'cyberThreats', 'navigationWarnings'],
    mapLayers: {
      conflicts: true,
      outages: true,
      cables: true,
      pipelines: false,
      weather: true,
      economic: true,
      military: true,
      ai: false,
      startupHubs: false,
    },
    defaultRegion: 'global',
  },
  tech: {
    id: 'tech',
    displayName: 'Tech',
    description: 'Tech and AI startup intelligence with policy signals',
    panelOrder: [
      'live-news',
      'live-webcams',
      'insights',
      'ai',
      'tech-readiness',
      'tech',
      'macro-signals',
      'security',
      'markets',
      'crypto',
      'news',
    ],
    modules: ['riskPulse', 'macroSignals', 'cyberThreats', 'earthquakes'],
    mapLayers: {
      conflicts: false,
      outages: true,
      cables: true,
      pipelines: false,
      weather: true,
      economic: true,
      military: false,
      ai: true,
      startupHubs: true,
      cloudRegions: true,
    },
    defaultRegion: 'global',
  },
  finance: {
    id: 'finance',
    displayName: 'Finance',
    description: 'Markets, rates, supply chain, and risk infrastructure feed',
    panelOrder: [
      'live-news',
      'markets',
      'market-news',
      'macro-signals',
      'etf-flows',
      'economic',
      'trade-policy',
      'supply-chain',
      'polymarket',
      'stablecoins',
      'insights',
      'news',
    ],
    modules: ['macroSignals', 'riskPulse', 'serviceStatus', 'earthquakes'],
    mapLayers: {
      conflicts: false,
      outages: true,
      cables: true,
      pipelines: true,
      weather: false,
      economic: true,
      military: false,
      commodityMarkets: true,
      stockExchanges: true,
      financialCenters: true,
    },
    defaultRegion: 'global',
  },
  happy: {
    id: 'happy',
    displayName: 'Good News',
    description: 'Human progress and positive-signal feed for TV loops',
    panelOrder: ['positive-feed', 'spotlight', 'breakthroughs', 'progress', 'digest', 'species', 'giving'],
    modules: ['macroSignals', 'riskPulse'],
    mapLayers: {
      positiveEvents: true,
      kindness: true,
      happiness: true,
      speciesRecovery: true,
      renewableInstallations: true,
      weather: false,
      military: false,
      conflicts: false,
    },
    defaultRegion: 'global',
  },
};

export const TV_MODULE_DEFS = {
  riskPulse: {
    key: 'riskPulse',
    name: 'Strategic Risk',
    description: 'Global calculated CII/strategic risk score bundle',
    cacheHint: 'short',
  },
  serviceStatus: {
    key: 'serviceStatus',
    name: 'Service Status',
    description: 'Infrastructure and cloud provider availability snapshot',
    cacheHint: 'medium',
  },
  macroSignals: {
    key: 'macroSignals',
    name: 'Macro Signals',
    description: 'Liquidity, macro regime, and risk-on/off summary',
    cacheHint: 'medium',
  },
  earthquakes: {
    key: 'earthquakes',
    name: 'Earthquakes',
    description: 'Recent M4.5+ global seismic events',
    cacheHint: 'medium',
  },
  cyberThreats: {
    key: 'cyberThreats',
    name: 'Cyber Threats',
    description: 'Open threat intelligence + malicious activity signals',
    cacheHint: 'medium',
  },
  navigationWarnings: {
    key: 'navigationWarnings',
    name: 'Maritime Warnings',
    description: 'NGA maritime safety warnings',
    cacheHint: 'medium',
  },
};

export function normalizeProfile(profile) {
  if (typeof profile !== 'string') return PROFILE_DEFAULT;
  const normalized = profile.toLowerCase().trim();
  return TV_PROFILE_CONFIGS[normalized] ? normalized : PROFILE_DEFAULT;
}

export function buildJsonResponse(request, body, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...extraHeaders,
      ...getCorsHeaders(request),
    },
  });
}

export function createServerContext(request) {
  return {
    request,
    pathParams: {},
    headers: Object.fromEntries(request.headers.entries()),
  };
}

function getCorsHeaders(request) {
  // Lightweight re-implementation to avoid circular imports from this shared file.
  const origin = request.headers.get('origin') || '';
  const patterns = [
    /^https:\/\/(.*\.)?worldmonitor\.app$/,
    /^https:\/\/worldmonitor-[a-z0-9-]+-elie-[a-z0-9]+\.vercel\.app$/,
    /^https?:\/\/localhost(:\d+)?$/,
    /^https?:\/\/127\.0\.0\.1(:\d+)?$/,
    /^https?:\/\/tauri\.localhost(:\d+)?$/,
    /^https?:\/\/[a-z0-9-]+\.tauri\.localhost(:\d+)?$/i,
    /^tauri:\/\/localhost$/,
    /^asset:\/\/localhost$/,
  ];
  const allowOrigin = patterns.some((re) => re.test(origin)) ? origin : 'https://worldmonitor.app';

  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-WorldMonitor-Key',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}
