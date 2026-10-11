import { createRemoteJWKSet, jwtVerify } from 'jose';
import { AUTH0_DOMAIN, AUTH0_CLIENT_ID } from '../config.js';
import { clientFor } from '../db.js';

const issuer = `https://${AUTH0_DOMAIN}/`;
// Long cache so a JWKS blip at a cache boundary can't 401 everyone; an unknown kid still forces a refetch.
const jwks = createRemoteJWKSet(new URL(`${issuer}.well-known/jwks.json`), { cacheMaxAge: 12 * 60 * 60 * 1000 });

// jose errors that mean "the caller's token is bad". Anything else (JWKS timeout/fetch failure) is our outage.
const TOKEN_ERRORS = new Set([
  'ERR_JWT_EXPIRED', 'ERR_JWT_CLAIM_VALIDATION_FAILED', 'ERR_JWT_INVALID', 'ERR_JWS_INVALID',
  'ERR_JWS_SIGNATURE_VERIFICATION_FAILED', 'ERR_JWKS_NO_MATCHING_KEY', 'ERR_JWKS_MULTIPLE_MATCHING_KEYS',
  'ERR_JOSE_ALG_NOT_ALLOWED', 'ERR_JOSE_NOT_SUPPORTED',
]);

// Sets req.userId (the Auth0 sub) and req.db (a Supabase client acting as the caller).
export async function auth(req, res, next) {
  const token = req.get('authorization')?.match(/^Bearer (.+)$/)?.[1];
  if (!token) return res.status(401).json({ error: 'Missing bearer token' });
  try {
    const { payload } = await jwtVerify(token, jwks, {
      issuer,
      audience: AUTH0_CLIENT_ID, // the app sends ID tokens
      algorithms: ['RS256'],
      requiredClaims: ['sub'],
    });
    req.userId = payload.sub;
  } catch (err) {
    if (!TOKEN_ERRORS.has(err.code)) throw err;
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  req.db = clientFor(token);
  next();
}
