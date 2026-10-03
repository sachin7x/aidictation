# Authentication boundary

The native clients already use Supabase Auth and persist sessions locally. The platform API should preserve that identity model rather than introduce a second account system.

Rules:
- clients authenticate with Supabase Auth;
- APIs validate bearer access tokens server-side;
- service-role credentials never reach clients;
- device sessions are application metadata, not replacement credentials;
- entitlement decisions are server-side;
- provider configuration is not a client-trusted claim.

The existing native implementation has explicit callback/session validation and durable credential storage. The web implementation should converge on the same identity source.
