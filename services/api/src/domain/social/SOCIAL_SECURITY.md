# Social graph security
- Friend request writes must be server authenticated and idempotent; no caller may set sender identity.
- Reject self requests, duplicate pending requests, existing friendship, either-direction block, sanctions and excessive request rate.
- Only receiver may accept/reject; sender may cancel; accepted request creates canonical ordered friendship pair transactionally.
- Friend removal must delete friendship and revoke friend-only presence visibility immediately.
- Presence must be ephemeral/TTL-backed; expose only online/last-seen granularity allowed by subject settings.
- Apply block edges to friend lists, request endpoints, presence, messaging, matching and private calls in both directions.
- RLS policies in migration are intentionally restrictive; API/service layer must project safe results.
- Draft migration; no database execution or tests yet.
