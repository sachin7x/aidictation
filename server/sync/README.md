# Sync protocol

Sync is revision-based and conflict-aware.

Mutable entities carry id, version, updatedAt, and deviceId. The server assigns a monotonically increasing revision to changes. Clients send their last acknowledged cursor and receive changes after that cursor.

Conflict rule:
1. reject stale writes when the entity version is older than the server version;
2. return the authoritative entity and version;
3. client merges and retries explicitly;
4. represent deletes as durable tombstones where required.

Initial scope: dictionary entries, snippets, styles, and device configuration. Audio and raw transcripts are not sync payloads by default.
