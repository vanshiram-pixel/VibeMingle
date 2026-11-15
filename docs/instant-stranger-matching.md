# VibeMingle Stranger Match — Product, UX & Wiring Specification

Status: PRODUCT SPEC LOCKED / implementation pending (unless verified by phase evidence)
Scope: V1 matching + integrated video/chat/translation experience; V2/V3 enhancements below.

## Product contract (do not reinterpret)
- User taps **Start Matching** → server queues and pairs eligible strangers automatically; both clients move to the same call session without a second accept prompt.
- Pairing target: under 1 second when an eligible peer is already waiting (measured target, not a network/pool guarantee).
- **Next Stranger** target: 1–2 seconds when another eligible peer is waiting. Never use a 60–70-second rematch delay.
- If no peer exists, keep searching with clear live status and Cancel/Stop; no fake match and no arbitrary fixed timeout.
- Every fresh pair has a 15-second minimum before Next becomes enabled. This is a skip cooldown, NOT forced participation: End, Report, Block, mute and camera-off remain available immediately.
- V1/V2/V3 are scope tiers. Core UI, contracts and integration must not be discarded or replaced with isolated incomplete demos.

## Matching lifecycle and server rules
State machine: idle → searching → reserved → connecting → active → next/end; terminal outcomes include canceled, expired, failed, blocked and safety-ended.
- Eligibility: authenticated, age gate passed, explicit stranger-match consent, fresh presence heartbeat, not busy/in another session, not suspended/banned, device permission flow handled.
- Server-authoritative atomic reservation/pairing; one active session per user; idempotent retries; no client-supplied arbitrary peer IDs.
- Check blocks in both directions, reports/safety restrictions, recent pair/skip cooldown, duplicate sessions, stale queue entries and fairness.
- Next closes current session correctly for both participants. Other user returns to search only if their intent remains active; otherwise idle. Never ghost sessions or silently opt a user back in.
- Queue/event delivery via authenticated Realtime/WebSocket/server events + heartbeat/TTL. Polling is fallback UI refresh only, not expensive matchmaking SQL every second.
- Match events carry opaque session IDs and authorized participants; client validates state and ignores stale/out-of-order events.
- Rate-limit Start/Next, prevent bots/rapid cycling, log moderation/session metadata without recording call media by default.

## Match card / versioned experience
### V1 — Reliable launch core
- One clear Start Matching action; searching animation/status; matched state; call opens automatically.
- Video-first screen: remote video fills main stage; local camera preview is movable/resizable; controls remain reachable and safe-area aware.
- Compact **live text chat beneath video** (or collapsible bottom sheet on small screens); chat never covers faces/critical call controls. Keyboard opens chat sheet and video adapts without losing call.
- Controls: mic mute, camera on/off, flip camera, speaker, chat toggle, Next (disabled until 15s), End, Report, Block. Safety actions always active.
- 15-second visible countdown/lock explanation; next-match connecting/searching state; clear cancel.
- Basic captions/translation entry point is a UI contract; gracefully show unavailable until translation is enabled—never fake translated output.
### V2 — Smart matching & communication
- Matching preferences/ranking: language, country/region, interests and optional filters; respect consent, fairness and safe defaults.
- Live voice translation: detect each speaker's language, transcribe speech, translate to receiver's chosen language, display aligned subtitles and (where supported) translated audio playback. User controls: enable/disable, target language, original/translated audio, captions, mute translated voice.
- Text chat synchronized with active call; translated text inline or explicit translate action. Preserve original text and label translations.
- AI safety/moderation triage, match quality feedback, analytics and anti-abuse signals with human review.
### V3 — Global/personalized
- Global language/country routing, adaptive match ranking and privacy-safe personalization.
- Scalable multi-region queue/media orchestration, advanced accessibility and localization.
- Creator/social economy integrations only with trust, safety, policy and abuse controls.

## Video + chat + translation layout rules
- Hierarchy: remote video (largest) → local preview (overlay corner, draggable) → call toolbar → expandable chat/translation drawer.
- Portrait phones: video uses upper area; bottom chat drawer peek (latest messages) or expand. Chat input stays below video when space allows; otherwise bottom sheet overlays only lower region and video resizes/crops safely.
- Landscape/tablet/web: video and chat can use side-by-side split; user can switch layout. Handle text alignment, RTL/LTR, long messages, timestamps, subtitle placement, keyboard/insets and accessibility scaling.
- Never place subtitles over eyes/mouth or critical controls; offer subtitle position/background/size. Avoid duplicate original+translation unless selected.
- Chat input/send, scrolling, new-message indicator, delivery errors and call state integrated; drafts survive layout changes.
- Low bandwidth: adaptive video quality, reduce nonessential animation, preserve chat/voice state and show reconnect status.

## Voice translation pipeline (wired contract)
1. Capture speaker audio locally with explicit microphone permission and user consent.
2. Send securely to approved speech service (or supported on-device path); provider keys never in client.
3. Speech-to-text + language detection → receiver-language translation → subtitle event with speaker/session/sequence/timestamp.
4. Optional translated speech synthesis/audio channel, controlled by receiver; original audio remains selectable fallback.
5. Handle latency, partial/final transcripts, duplicate/out-of-order chunks, reconnect, quota/errors, unsupported language and privacy deletion.
6. Translation is opt-in, visibly indicated, disableable per call; disclose processing/retention before enabling. Never claim translation works until credentials, server pipeline and E2E tests are complete.

## Security / privacy / safety gates
- Age gate, consent and privacy settings before queue entry; no minors in adult stranger-video flows.
- End/report/block override 15-second lock. Block/report immediately prevents future chat/call/match both ways and creates authorized moderation record.
- No personal phone/email/address exposure. Authenticated signaling and short-lived TURN credentials; secure transport and RLS.
- Camera/mic indicators, permission denial fallback, clear stop/search cancellation, reconnect handling, abuse limits and audit trail.
- Store necessary match/session metadata only; never record audio/video by default. Translation retention/deletion disclosed/configurable.

## Events and API contract (implementation checklist)
Client intents: match.start, match.cancel, match.next, call.end, safety.report, safety.block, translation.setPreferences, chat.send.
Server events: match.queued, match.reserved, match.connected, match.ended, match.searching, match.error; call signaling; chat message events; translation.transcript.partial/final and translation.error.
Every event includes session/match ID, authorization, sequence/version and timestamp; retries idempotent.
Match service hands the same authorized session to call lifecycle; video UI, chat and translation share session identity—not independent parallel sessions.
Admin-configurable 15s floor may be increased only after product/safety review; immediate safety exits cannot be disabled.

## Acceptance / test matrix
- Queue with waiting peer: pairing event p95 ≤1s target; Next with waiting peer ≤1–2s target.
- Empty queue: persistent search + cancel, no false success.
- Two devices: auto call handoff, audio/video, chat beneath video, keyboard/insets, translation subtitles and controls.
- Race tests: simultaneous Start/Next, repeated taps, stale presence, disconnect/reconnect, same-pair exclusion, blocked/reported users, cancel while reserved, one side ends.
- Safety: End/Report/Block during 15s; timer never traps user; block prevents future matching/chat/call.
- Translation: Hindi↔English and supported languages, partial/final ordering, latency/error/quota, opt-out, original audio fallback, privacy.
- Verify Flutter widget/integration tests, SQL/RLS tests, two-account/device staging and performance measurements before VERIFIED.

## Delivery dependencies
Auth + age/consent + profile + presence + block/report → atomic queue/match RPC → authenticated signaling + WebRTC/TURN → integrated video/chat UI → translation backend/provider → admin/moderation → QA/staging. A spec, UI mock, migration or scaffold alone is not completion.


## Match-to-friend transition (locked)
For Add Friend/Follow/Post-Match and private-call eligibility after a match, follow [STRANGER_MATCH_FRIEND_FLOW.md](STRANGER_MATCH_FRIEND_FLOW.md): request → recipient Accept → friendship; Follow independent; same conversation reused; private call requires a new request and receiver Accept; no former-match direct call/rejoin; Block overrides all paths. Specification only; implementation/runtime verification pending.


## V4 alignment — Manual Search & unified engine
V4 confirms three entry modes over one server-authoritative matching engine: Instant Random, Next/Random Switch, and Manual Stranger Search (adult age range, gender preference, language and supported filters). Manual filters must be honored; no silent broadening/fallback. All modes share block/eligibility/queue/session rules. See [V4_FINAL_HARD_LOCKS.md](./V4_FINAL_HARD_LOCKS.md).
