export function parseCorsOrigins(raw?: string): true | string[] {
  if (!raw || raw.trim().length === 0 || raw.trim() === '*') {
    return true;
  }

  return raw
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
}

export function isCorsOriginAllowed(
  allowed: true | string[],
  origin?: string | null,
): boolean {
  if (allowed === true) {
    return true;
  }

  if (origin == null || origin.length === 0) {
    return false;
  }

  return allowed.includes(origin);
}

export function resolveWsCorsOrigins(): true | string[] {
  return parseCorsOrigins(
    process.env.WS_CORS_ORIGINS ?? process.env.CORS_ORIGINS,
  );
}
