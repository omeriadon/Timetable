# Timetable Implementation Plan

Status: planning only. No implementation has started.

Primary scope:

- Make the iPhone experience authoritative and complete first.
- Change `pmstt` contracts and persistence where the iPhone work requires it.
- Preserve server authority for school calendar data.
- Defer broad iPadOS, macOS, and Apple Watch parity until the iPhone work is stable.
- Keep the explicitly requested widget and Watch tasks as isolated late phases.
- Do not add optional event start times. Users can place important timing in the title or notes.
- Do not add actual TipKit tips. Configure TipKit only.

Validation boundary:

- Codex does not run builds or tests.
- The user runs all Xcode and server builds.
- Source inspection, formatting, `git diff --check`, migration ordering review, and contract review do not prove runtime behavior.
- Each implementation phase ends at a user-run build or runtime checkpoint before dependent work continues.
- Timetable and `pmstt` changes use separate atomic commits in the existing commit style.
- Existing unrelated changes in `Shared/Defaults.swift` and `Special/Localizable.xcstrings` must remain untouched unless their exact lines become required by this work.

## Confirmed product decisions

- Tags are global and server-managed.
- Users cannot create tags.
- Tag selection has no search field.
- Tag selection is sectioned by tag category.
- Tags use a wrapping flow layout: each chip takes its intrinsic width, fills the current row, then wraps.
- Global tag categories include year groups, subjects, sport, and general.
- Year-group tags are Year 7, Year 8, Year 9, Year 10, Year 11, and Leavers.
- Leavers is the user-facing name for Year 12.
- Administrators create, edit, archive, and reorder tags and tag sections.
- Subject tags are created manually by administrators.
- Every tag has administrator-managed associated names used for normalized import matching.
- An unmatched imported subject does not create a tag and does not change subscriptions.
- Tags on private events are decorative metadata only.
- Private-event tags do not enable filtering or search and never expose the event to another user.
- Private events cannot be assigned a year-group tag.
- School events are visible only when their non-year tags intersect the user’s subscribed tags.
- Multiple non-year tags use OR matching.
- A tagged school event with a year-group restriction additionally requires the user’s year group to match.
- Year-group matching is an AND gate over the ordinary non-year OR rule.
- A school event with no tags is visible to everyone in the school.
- A school event with only year-group tags is visible to users whose year group matches.
- General is subscribed by default but users may unsubscribe from it.
- If an event references a tag that no longer exists, the client and server drop that association safely.
- Normal migrations should preserve valid tag associations.
- Removed tags are archived instead of hard-deleted.
- A calendar import can offer to replace only the user’s existing subject-tag subscriptions with subject tags detected from the import.
- Replacing imported subject-tag subscriptions must preserve year-group, sport, general, and any future non-subject subscriptions.
- Valid account emails end exactly in `@student.education.wa.edu.au`, compared case-insensitively after trimming and normalization.
- Email verification codes are single-use.
- Verification codes expire after ten minutes.
- A replacement code may be requested after two minutes.
- Existing Apple-only accounts are deleted as part of the Apple Sign In removal.
- An Apple-only account is an account without a password credential.
- Accounts with both Apple and password credentials remain and lose only their Apple credential.
- Sync conflicts use the smallest reasonable mutable record as their unit.
- Record-level conflict handling covers every mutable dataset that two devices could edit.
- Device wall-clock time is not authoritative.
- Server-issued revisions and server timestamps resolve conflicts.
- Broadcast title is required.
- Broadcast subtitle and body are optional and may be empty.
- Broadcast records persist the complete message, audience, sender, time, and delivery result.
- Profile images are uploaded to the server.
- Profile-image objects are stored in a private Cloudflare R2 Standard bucket.
- PostgreSQL stores profile-image metadata and R2 object keys, not image bytes.
- pmstt mediates every R2 object operation so application quotas can be enforced.
- Profile storage has a hard application limit of 9,000,000,000 bytes.
- Profile storage has a hard application limit of 900,000 total R2 operations per UTC calendar month.
- Profile images are cropped to a square before upload.
- Profile-image payloads have a one-megabyte maximum.
- Emoji profile content is persisted as Unicode text.
- SwiftEmoji supplies the emoji index and picker UI only.
- Emoji usage, favourites, and recents are not recorded.
- Font weight uses SwiftUI’s discrete system font weights.
- The weight control is a ticked slider.
- Profile colour selection accepts one, two, or three colours.
- Colour selection order is not meaningful.
- The profile colour grid uses a fixed curated palette bundled with the app.
- Badges contain an SF Symbol and optional background and symbol colours.
- Profile badges are modular and represented as an array.
- Badges are overlays and never reduce the base avatar circle.
- Ordinary administrators and permanent owners use different authority badges.
- At most three badges are shown.
- Multiple badges stack leftwards from the bottom-right anchor without moving the anchor farther right.
- The initial reusable profile-picture rollout covers iPhone surfaces where the current user or friends appear.
- Friend removal uses a confirmation dialog.
- Friend reporting uses an alert confirmation.
- Reports do not automatically remove or hide the friend.
- Friend details are presented as a sheet.
- Friend class/detail interactions may use popovers for compact supporting information.
- Shared-class comparisons are case-insensitive and whitespace-normalized.
- A shared class requires identical normalized subject names and identical normalized classrooms.
- A shared subject requires only an identical normalized subject name.
- An identical subject/classroom match appears in both Shared Classes and Shared Subjects.
- Friend email is not shown in friend account details.
- The redundant relationship “Status: Friend” row is removed; live school/activity status remains.
- The main iPhone tab order is Timetable, Friends, Settings.
- Profile editing moves into Settings under Account.
- TipKit display state is local to the installation.
- TipKit does not use iCloud synchronization.
- Debug builds reset the TipKit datastore.
- No tips are authored in this project phase.
- `.timetable` files contain a versioned document and a shared timetable identifier.
- Every calendar-import error resets after four seconds.
- Successful calendar imports remain in their completed state.
- The two permanently privileged accounts cannot lose their elevated authority.
- Their emails are:
  - `omeriadon@outlook.com`
  - `adon.omeri@student.education.wa.edu.au`
- Ordinary administrator access is dynamic and server-owned.
- Removing administrator access does not sign the user out.
- Removed administrators immediately receive `403 Forbidden` from protected administration endpoints.
- The administration tab disappears after the client refreshes authority.
- Administration remains a fourth conditional tab after Settings.
- Watch content background work replaces the existing `containerBackground` composition with the equivalent per-view `background` composition.
- The Watch app icon is not changed by Codex.
- Watch timers must continue updating while their containing tabs are visible.
- Watch Debug settings include a runtime debug-offset text field backed by the shared offset.
- The large summary widget shows at most three friends.
- Friend status in the summary widget is a future stub only; no visible or functional status feature is implemented now.
- Widget Dynamic Type is fixed at `.medium`.
- Friends can be reordered by drag.
- Friend order is server-persisted and determines widget priority.

## Open decisions requiring answers before their dependent phases

- Define the exact symbol and colours for the permanent-owner badge. The ordinary administrator badge remains `shield.fill`.

## Architecture constraints

- Treat `pmstt` as authoritative for:
  - account identity and verification;
  - account authority;
  - global tag definitions;
  - user tag subscriptions;
  - calendar events;
  - timetable revisions;
  - friend ordering;
  - profile appearance and uploaded profile media;
  - broadcast history;
  - shared timetable identifiers.
- Treat the client as an offline cache and editor for client-authored records.
- Never trust device time for conflict resolution.
- Use monotonically increasing revisions or opaque server versions per mutable record.
- Return server time in synchronization responses for diagnostics and relative-clock calculation, but do not use calculated device time as the conflict authority.
- Normalize school email once on the server and enforce the suffix at registration, verification, login, profile changes, and administration account creation.
- Keep authorization separate from authentication:
  - authenticated users remain signed in when a role changes;
  - every privileged endpoint checks current server authority;
  - the client’s role is presentation state, not security.
- Store image metadata in the database and image bytes in an explicitly chosen server storage layer.
- Do not put one-megabyte avatar blobs into generic profile appearance JSON.
- Keep avatar appearance backwards-decodable while old clients may still send the current `ProfileAppearance` shape.
- Keep modal state and `.sheet`, `.alert`, `.confirmationDialog`, and `.popover` modifiers on the root host view.
- Use one `@Namespace` per host and unique source identifiers for matched sheet transitions.
- Use `.appNavigationTitle`, never `.navigationTitle`, in changed iPhone SwiftUI views.
- Apply `.scrollEdgeEffect()` with default values to the changed Friends and profile/settings scrolling surfaces.
- Use labels with SF Symbols for normal buttons.
- Use role-only cancel buttons.
- Use `role: .confirm` and `.buttonStyle(.glassProminent)` for confirmation buttons.
- Use a `.fraction(0.5 ... 0.7)` detent for short forms and short lists.
- Keep code split into readable types and files.
- Do not condense declarations or statements onto single lines.
- Constrain profile-avatar geometry relative to the component’s proposed square size.
- Do not use fixed point offsets for badge placement inside the reusable avatar.
- Disable Dynamic Type only where explicitly requested, including the large summary widget.

## Phase 0: Baseline and implementation bookkeeping

- [ ] Re-read both worktrees before implementation.
- [ ] Record all unrelated modified, staged, and untracked files in Timetable.
- [ ] Record all unrelated modified, staged, and untracked files in `pmstt`.
- [ ] Confirm the live Timetable branch and `pmstt` branch.
- [ ] Confirm the active Xcode project tabs.
- [ ] Confirm filesystem-synchronized groups before proposing any manual `.pbxproj` edits.
- [ ] If a package must be added through Xcode project settings, stop for the user to add it through the Xcode UI.
- [ ] Create a phase checklist from this document.
- [ ] Keep each commit limited to one behavior or one contract/migration unit.
- [ ] Inspect staged file names after every hook before committing.

## Phase 1: Shared naming and server contract design

- [x] Choose the permanent privileged-role product name.
  - Recommended internal name: `systemOwner`.
  - Recommended UI name: `Owner Administrator`.
  - Do not use database role names as user-facing copy without review.
- [x] Define `AccountAuthority` as a closed server contract.
  - `user`
  - `administrator`
  - `systemOwner`
- [ ] Define `ProfileBadge`.
  - stable identifier;
  - SF Symbol name;
  - optional background RGBA colour;
  - optional symbol RGBA colour;
  - priority/order;
  - accessibility label.
- [x] Define tag category identifiers.
  - `yearGroup`
  - `subject`
  - `sport`
  - `general`
- [x] Define `EventTag`.
  - stable UUID;
  - stable slug;
  - display name;
  - category;
  - associated names used for matching;
  - optional symbol;
  - optional colour;
  - sort order;
  - active/archived state;
  - created and updated timestamps;
  - server revision.
- [ ] Define a normalization function for subject and classroom comparisons.
  - trim;
  - collapse internal whitespace;
  - case-fold using a stable locale;
  - preserve the original display value.
- [ ] Define a versioned `.timetable` document.
  - format version;
  - shared identifier;
  - optional locator kind only if UUID and alias need disambiguation;
  - no embedded timetable content.
- [ ] Define `SyncEnvelope`.
  - server time;
  - request identifier;
  - client installation identifier;
  - individual record mutations;
  - per-record base revision;
  - per-record server result;
  - tombstones;
  - conflicts;
  - next server cursor if needed.
- [ ] Define conflict outcomes.
  - accepted client mutation;
  - server record already newer;
  - deleted on server;
  - invalid reference dropped;
  - authorization rejected;
  - validation rejected.
- [ ] Define client behavior for every conflict outcome before adding UI.

## Phase 2: `pmstt` database foundations

### 2.1 Account authority

- [x] Add an account-authority field or role relationship to `User`.
- [x] Backfill the two permanent accounts as `systemOwner`.
- [x] Backfill current configured administrators as `administrator` where appropriate.
- [x] Ensure the two permanent email identities resolve to `systemOwner` even if a bad database value exists.
- [x] Prevent changing or deleting the authority of a `systemOwner`.
- [x] Prevent ordinary administrators from changing authority.
- [x] Permit only `systemOwner` accounts to grant and revoke `administrator`.
- [x] Add authority to authenticated profile/bootstrap responses.
- [x] Remove calendar-event management capability as a proxy for global administration authority.
- [x] Keep calendar-event management as a capability derived from the authority contract.

### 2.2 Email verification

- [ ] Add an email-verification challenge model.
- [ ] Store a hashed code, never the plaintext code.
- [ ] Store normalized email.
- [ ] Store creation, expiry, resend-available, used, and attempt timestamps.
- [ ] Add a bounded failed-attempt counter.
- [ ] Add rate limits per normalized email, installation, and source IP.
- [ ] Invalidate older live codes when a replacement code is issued.
- [ ] Mark a code used atomically with account creation or email verification.
- [ ] Clean expired challenges without affecting accounts.
- [ ] Configure the existing Resend integration for verification messages.
- [ ] Keep API keys exclusively in deployed environment configuration.
- [ ] Add mail content for the six-digit code and ten-minute expiry.

### 2.3 Apple-account removal

- [ ] Identify Apple-only accounts as accounts with no password hash.
- [ ] Preserve accounts that have both a password hash and Apple subject.
- [ ] Add a migration or explicit maintenance command that deletes Apple-only accounts and their dependent data.
- [ ] Rely on database cascade behavior only after auditing every relationship.
- [ ] Explicitly cover:
  - sessions and refresh tokens;
  - devices and APNs tokens;
  - Live Activity records;
  - friendships and requests;
  - received timetable imports;
  - authored timetables;
  - owner timetable;
  - calendar events;
  - reports;
  - passes and registrations;
  - aliases;
  - profile media.
- [ ] Remove Apple identity fields after the deletion migration is safely ordered.
- [ ] Clear Apple identity fields from preserved password accounts before removing the columns.
- [ ] Remove Apple-auth server routes.
- [ ] Remove Apple server-notification routes.
- [ ] Remove Apple JWT configuration that is no longer used.
- [ ] Remove Apple account-state DTOs and admin JSON fields.
- [ ] Keep migration ordering reversible at the schema level where practical; account deletion itself is intentionally destructive.

### 2.4 Global tags and subscriptions

- [x] Add an administrator-managed tag-section table.
- [x] Add the global tag table.
- [x] Add associated tag names as a normalized child table or validated array field.
- [x] Add an account-to-tag subscription join table.
- [x] Add a calendar-event-to-tag join table.
- [ ] Add uniqueness constraints for normalized active tag names within categories.
- [x] Add stable ordering within each category.
- [x] Add foreign-key behavior for archived or deleted tags.
- [ ] Prefer archive plus association cleanup over hard delete.
- [x] Seed Year 7, Year 8, Year 9, Year 10, Year 11, and Leavers.
- [x] Seed a General tag and subscribe new users to it by default.
- [x] Keep Sport and General data-driven rather than branching on their names.
- [x] Require administrators to create subject tags manually.
- [ ] Normalize and uniquely constrain associated names used for import matching.
- [ ] Prevent ambiguous associated names from belonging to more than one active subject tag.
- [ ] Ensure stale tag IDs in client payloads are ignored and reported as dropped.
- [x] Add tag revisions or updated timestamps for incremental synchronization.

### 2.5 Broadcast history

- [x] Add `BroadcastNotificationRecord`.
- [ ] Persist:
  - title;
  - optional subtitle;
  - optional body;
  - sender account ID;
  - sender email snapshot;
  - sender authority snapshot;
  - requested audience;
  - creation timestamp;
  - eligible-device count;
  - delivered count;
  - invalidated-token count;
  - failed count;
  - terminal delivery state;
  - structured failure summary.
- [ ] Decide whether individual device delivery outcomes need a child table.
- [x] Save the record before delivery begins.
- [x] Update aggregate outcomes after best-effort delivery finishes.
- [x] Retain a failed record if delivery throws before fan-out completes.
- [x] Never require subtitle or body.
- [x] Reject a whitespace-only title.

### 2.6 Profile media and badges

- [ ] Use a private Cloudflare R2 Standard bucket for profile-photo objects.
- [ ] Keep R2 credentials in deployed environment configuration only.
- [ ] Store only object keys and image metadata in PostgreSQL.
- [ ] Use revisioned object keys such as `avatars/<userID>/<revision>.jpg`.
- [ ] Keep the bucket private.
- [ ] Do not enable the public `r2.dev` URL or a public custom domain.
- [ ] Mediate uploads, downloads, HEAD checks, and deletions through pmstt.
- [ ] Do not use reusable direct-to-R2 presigned URLs because they bypass exact operation accounting.
- [ ] Let pmstt authenticate the caller before every profile-image operation.
- [ ] Add profile-media metadata.
- [ ] Associate at most one active profile photo with a user.
- [ ] Store content type, byte size, dimensions, checksum, revision, and update time.
- [ ] Enforce square dimensions or server-crop defensively.
- [ ] Enforce the one-megabyte limit server-side.
- [ ] Accept only explicitly supported raster formats.
- [ ] Strip unneeded metadata.
- [ ] Prevent SVG or arbitrary file uploads.
- [ ] Define authenticated upload, fetch, and delete routes.
- [ ] Delete superseded R2 objects only after the new database reference commits successfully.
- [ ] Add orphan-object cleanup for abandoned uploads and failed database transactions.
- [ ] Provide cache validation using revision, ETag, or content hash.
- [ ] Let pmstt answer a matching conditional request with `304 Not Modified` from database metadata without reading R2.
- [ ] Add profile badges to friend/profile DTOs.
- [ ] Derive authority badges on the server rather than accepting them from profile edits.
- [ ] Keep future manually assigned badges possible without changing avatar rendering.

### 2.7 R2 quota enforcement

- [ ] Add one database row representing the global profile-storage quota state.
- [ ] Track every known R2 object, including active, superseded, temporary, and orphaned objects.
- [ ] Track the exact stored-byte total from known object metadata.
- [ ] Use 9,000,000,000 bytes as the hard stored-object ceiling.
- [ ] Reserve the incoming object’s bytes atomically before uploading.
- [ ] Reject an upload when the reservation would exceed the hard byte ceiling.
- [ ] Keep the old image’s bytes counted until its R2 deletion succeeds.
- [ ] Release an upload reservation only when it is proven that no R2 object was created.
- [ ] Add a monthly operation-counter row keyed by UTC year and month.
- [ ] Count all application-mediated R2 calls against one conservative operation budget.
- [ ] Count PUT, GET, HEAD, DELETE, LIST, and cleanup operations.
- [ ] Reserve an operation atomically before sending the R2 request.
- [ ] Do not decrement the counter after an attempted R2 request because a failed request may still be billable.
- [ ] Enforce a hard maximum of 900,000 reserved operations per UTC calendar month.
- [ ] Stop profile-image mutations before the hard limit to preserve a read reserve.
- [ ] Use 850,000 operations as the write cutoff.
- [ ] Permit cached/conditional reads that do not contact R2 after the write cutoff.
- [ ] Permit R2 reads until the 900,000 hard limit.
- [ ] Reject storage exhaustion with HTTP `507 Insufficient Storage` and structured code `profileStorageCapacityReached`.
- [ ] Reject mutation-budget exhaustion with HTTP `429 Too Many Requests` and structured code `profileStorageWriteBudgetReached`.
- [ ] Reject hard operation-budget exhaustion with HTTP `429 Too Many Requests` and structured code `profileStorageOperationBudgetReached`.
- [ ] Include a `Retry-After` value ending at the next UTC calendar month for monthly operation-budget errors.
- [ ] Preserve existing cached profile pictures when an R2 quota error occurs.
- [ ] Never change the authoritative profile-photo revision when upload or finalization fails.
- [ ] Add administrator-visible current byte usage, monthly operation usage, limits, and remaining allowance.
- [ ] Add warning logs at 80%, 90%, and 95% of each quota.
- [ ] Query Cloudflare R2 GraphQL analytics periodically for reconciliation.
- [ ] Treat Cloudflare analytics as delayed audit data, not the synchronous enforcement source.
- [ ] Reconcile tracked object bytes against R2 metrics and controlled bucket listings.
- [ ] Disable new writes and surface an administration warning if reconciliation reports usage above local accounting.

### 2.8 Friend order

- [x] Add a per-user friend-priority/order field on the friendship relationship.
- [x] Model order independently for each side of a friendship.
- [x] Backfill a deterministic initial order using accepted time and stable ID.
- [x] Add an atomic reorder endpoint.
- [x] Validate that submitted IDs are exactly the caller’s current friends.
- [x] Normalize sparse or duplicated order values on the server.
- [x] Return friends in persisted user order.

### 2.9 Record-level sync metadata

- [ ] Inventory every client-authored mutable record.
- [ ] Give each in-scope record:
  - stable record ID;
  - server revision;
  - server updated timestamp;
  - optional deletion tombstone.
- [ ] Avoid using a single owner-timetable revision for unrelated settings and events.
- [ ] Add migrations for records that currently have only whole-blob storage.
- [ ] Keep server-owned school calendar and administration data download-only.
- [ ] Define retention for tombstones so offline clients can observe deletions.

## Phase 3: `pmstt` endpoint and middleware changes

### 3.1 Authentication endpoints

- [ ] Replace direct registration with a verification-first flow.
- [ ] Add request-code endpoint.
- [ ] Normalize and validate the school email before sending.
- [ ] Return resend availability and challenge expiry.
- [ ] Add verify-code-and-register endpoint.
- [ ] Atomically consume the code.
- [ ] Keep password validation and hashing.
- [ ] Derive the default display name from the normalized email local part.
- [ ] Split the local part using the required `firstname.lastname` format.
- [ ] Strip trailing digits from the last-name component.
- [ ] Capitalize the first and last names for display.
- [ ] Reject registration addresses that do not provide the required first-name and last-name components.
- [ ] Reject non-school emails at every account mutation boundary.
- [ ] Keep login failure responses non-enumerating where appropriate.
- [ ] Remove client and server Apple login endpoints.
- [ ] Invalidate sessions for accounts deleted by the Apple-only cleanup.

### 3.2 Administration authority

- [ ] Replace environment-email-list middleware with current database authority checks.
- [ ] Resolve the user from the active session on every admin request.
- [ ] Return `403` when authority has been revoked.
- [ ] Add system-owner-only endpoints to grant and revoke administrator authority.
- [ ] Reject role changes for either permanent owner.
- [ ] Include authority and badges in administration account data.
- [ ] Add an administration dashboard response that distinguishes `administrator` and `systemOwner`.

### 3.3 Tag endpoints

- [x] Add authenticated tag catalogue endpoint.
- [x] Add current-user tag-subscription endpoint.
- [x] Add atomic replacement of subject-only subscriptions.
- [x] Preserve all non-subject subscriptions during subject replacement.
- [x] Add administration tag-section create/update/archive/order endpoints.
- [x] Add administration tag create/update/archive/order endpoints.
- [x] Validate associated names and reject ambiguous active subject aliases.
- [x] Add tag IDs to school/global calendar event requests and responses.
- [x] Add non-year tag IDs to private-event requests and responses as decorative metadata.
- [x] Reject year-group tag IDs on private events.
- [x] Filter user-visible school events using the non-year OR rule.
- [x] Apply year-group tags as a separate required match when an event has a year restriction.
- [x] Return untagged school events to every authenticated school account.
- [x] Return year-only school events to accounts matching one of the event’s year-group tags.
- [x] Let users unsubscribe from General even though new accounts receive it by default.
- [x] Keep administrator event-management visibility independent of subscriber filtering.
- [ ] Include dropped/archived association information in mutation responses where useful.

### 3.4 Profile endpoints

- [ ] Replace opaque appearance-data-only handling with an explicit versioned appearance DTO.
- [ ] Retain legacy decode support during migration.
- [ ] Add an authenticated pmstt upload endpoint that validates, reserves quota, and writes to R2.
- [ ] Add an authenticated pmstt image endpoint that supports ETag and conditional requests.
- [ ] Add an authenticated pmstt deletion endpoint that updates the profile and then removes superseded R2 data.
- [ ] Return structured capacity and operation-budget errors from all profile-image endpoints.
- [ ] Add photo URL/revision and badges to friend and self-profile responses.
- [ ] Do not include friend email in normal friend responses.
- [ ] Keep email in authenticated self-account responses and privileged administration responses.
- [ ] Ensure profile-update requests cannot set badges or authority.

### 3.5 Friend endpoints

- [x] Return persisted friend order.
- [x] Add reorder endpoint.
- [ ] Keep report behavior unchanged apart from confirmation UI.
- [ ] Compute or return enough timetable data for exact shared-class/shared-subject comparison.
- [ ] Avoid server claims that depend on unnormalized subject or classroom values.

### 3.6 Broadcast endpoints

- [x] Decode optional subtitle and body.
- [x] Trim title and reject it when empty.
- [x] Create the persistent broadcast record before APNs fan-out.
- [x] Snapshot the sender email and authority.
- [x] Update the record with aggregate outcomes.
- [x] Return the record ID with delivery counts.
- [x] Add history and detail endpoints for administration.
- [x] Restrict history to current administrators.

### 3.7 Sync endpoint

- [ ] Add a batched record-level synchronization endpoint.
- [ ] Apply each record mutation independently where safe.
- [ ] Use a transaction per coupled record set, not one transaction for the entire account.
- [ ] Compare client base revision with current server revision.
- [ ] Never compare client wall-clock dates to choose a winner.
- [ ] Return current server records for conflicts.
- [ ] Return server time once per response.
- [ ] Return dropped tag references explicitly.
- [ ] Return server-side tombstones.
- [ ] Make retries idempotent using mutation IDs.
- [ ] Prevent replay of already accepted mutations.
- [ ] Log conflict decisions with record type and IDs but no sensitive payloads.

## Phase 4: `pmstt` logging timestamps

- [x] Inspect the active LoggingSystem bootstrap and deployed log handler.
- [x] Configure one consistent timestamp prefix at the log-handler formatter layer.
- [x] Use ISO 8601 with timezone or an explicitly agreed local timezone.
- [ ] Include milliseconds if concurrent request ordering requires them.
- [x] Avoid manually prepending timestamps in every `logger` call.
- [x] Preserve log level, label, metadata, source, and message.
- [ ] Confirm PM2 does not add a second conflicting timestamp.
- [ ] Document the deployed format.
- [ ] User runtime check:
  - startup message;
  - ordinary request log;
  - warning;
  - structured error;
  - APNs fan-out log.

## Phase 5: Shared client contracts and local cache

- [x] Add `AccountAuthority`.
- [ ] Add explicit profile appearance DTOs.
- [ ] Add `ProfileContentKind`.
  - photo;
  - monogram;
  - emoji.
- [ ] Add discrete `ProfileFontDesign`.
- [ ] Add discrete `ProfileFontWeight`.
- [ ] Add one-to-three background colours.
- [ ] Add photo revision/URL metadata.
- [ ] Add `[ProfileBadge]`.
- [ ] Decode legacy symbol-based appearances into the closest emoji/monogram default without crashing.
- [ ] Add global tag models and category ordering.
- [ ] Add current-user tag subscriptions.
- [ ] Add tagged event models.
- [ ] Add friend order.
- [ ] Add per-record sync metadata.
- [ ] Add pending mutation storage.
- [ ] Add tombstone storage where offline deletion is supported.
- [ ] Add TipKit configuration marker only if needed outside TipKit’s own datastore.
- [ ] Version every changed Defaults payload that needs backwards decoding.
- [ ] Preserve generated `Encodable` behavior by isolating legacy decode-only keys.

## Phase 6: Email-only authentication and onboarding

### 6.1 Authentication UI

- [ ] Remove Sign in with Apple UI and authorization handlers.
- [ ] Remove Apple-specific loading and error states.
- [ ] Restrict email input to the school suffix.
- [ ] Normalize pasted uppercase or whitespace-padded emails.
- [ ] Preserve a clear registration/sign-in distinction.
- [ ] Add verification-code request state.
- [ ] Add six-digit code entry.
- [ ] Show ten-minute expiry.
- [ ] Disable resend until the two-minute cooldown elapses.
- [ ] Permit requesting a replacement code after cooldown.
- [ ] Invalidate the previous local challenge state when replacement succeeds.
- [ ] Handle already-used, expired, invalid, and rate-limited codes distinctly.
- [ ] Use system-symbol button labels.
- [ ] Use `.glassProminent` and confirm role for the final verification action.
- [ ] Keep modal modifiers on the authentication root.

### 6.2 Name and year group

- [ ] Treat the verified school email as the required account identifier.
- [ ] Derive the initial display name from `firstname.lastname`.
- [ ] Strip trailing digits from the last name.
- [ ] Capitalize the derived first and last names.
- [x] Add year-group selection during onboarding.
- [x] Show Year 7, Year 8, Year 9, Year 10, Year 11, and Leavers.
- [x] Use global year-group tags from the server rather than hardcoded presentation-only values.
- [x] Persist the selected year-group subscription through the tag-subscription endpoint.
- [x] Make the onboarding page unable to advance until a valid year group is saved.
- [x] Restore the saved year group if onboarding is reopened.

### 6.3 Successful sign-in regression

- [ ] Trace every write to onboarding page ID and completion state.
- [ ] Reproduce the source sequence that sets the page back to `1`.
- [ ] Separate authentication bootstrap progress from onboarding page navigation.
- [ ] Prevent `SessionStore.apply(..., bootstrap: true)` completion from resetting an already-valid page.
- [ ] Preserve the current page when account bootstrap publishes Defaults changes.
- [ ] Reset onboarding only through explicit onboarding versioning or account deletion/sign-out rules.

## Phase 7: Tag catalogue, subscriptions, and event editing on iPhone

### 7.1 Reusable wrapping tag selector

- [x] Create a reusable flow-layout container using SwiftUI Layout.
- [x] Measure each tag chip intrinsically.
- [x] Fill available width and wrap without square-grid assumptions.
- [x] Group tags into ordered sections.
- [x] Show selected state clearly without relying on colour alone.
- [x] Support single and multiple selection configurations.
- [x] Add accessibility labels, selected traits, and section context.
- [x] Do not add search.
- [x] Do not introduce explicit fixed chip widths.
- [x] Use reasonable section spacing while preserving readable code.

### 7.2 Account subscriptions

- [x] Add a Settings destination for subscribed tags if required by the final navigation decision.
- [x] Show year groups, subjects, sport, and general in sections.
- [x] Allow multiple non-year subscriptions.
- [ ] Require exactly one year-group subscription during onboarding.
- [x] Permit changing the account year group later through the approved Settings location.
- [ ] Subscribe new accounts to General by default.
- [x] Allow users to remove General.
- [x] Save changes atomically.
- [x] Roll back local selection if the server rejects the update.
- [x] Drop archived/missing tags from the cache.
- [x] Surface save failures through the existing status-badge system.

### 7.3 Event editor

- [x] Add tags to school/global event DTOs and administration event editing.
- [x] Add decorative non-year tag selection to private event editing.
- [x] Exclude the year-group section from private-event tag selection.
- [x] Do not add filtering or search based on private-event tags.
- [x] Never publish private events through a tag association.
- [ ] Keep school/global event authority read-only for ordinary users.
- [ ] Preserve existing matched transitions.
- [ ] Keep short tag selection sheets within the requested fractional detent range where content permits.
- [ ] Do not add optional start time.
- [ ] Preserve title, notes, and symbol behavior unless superseded by the emoji/profile work.

## Phase 8: Calendar import behavior

### 8.1 Import performance and sampling

- [ ] Inventory every deliberate sleep/delay in the import state machine.
- [ ] Remove or shorten presentation-only delays while retaining visible state transitions.
- [ ] Never delay actual calendar parsing or persistence merely for animation.
- [ ] Change sample extraction from Monday-only to every weekday in every sampled week.
- [ ] Deduplicate equivalent detected subjects.
- [ ] Normalize subject names before tag matching.
- [ ] Preserve original display names in imported timetable subjects.

### 8.2 Subject-tag replacement prompt

- [ ] Fetch the latest tag catalogue before finalizing import.
- [ ] Match imported subjects to normalized global subject tags.
- [ ] Build the proposed subject-tag set.
- [ ] If the user already has subject subscriptions and the proposed set differs, show an explicit override prompt.
- [ ] Explain that only subject tags change.
- [ ] Preserve year-group, sport, general, and future non-subject subscriptions.
- [ ] Permit keeping the current subject tags.
- [ ] Permit replacing them with imported subject tags.
- [ ] Do not fail the timetable import merely because tag matching or subscription saving fails.
- [ ] Surface partial success accurately.

### 8.3 Error reset

- [ ] Centralize import error-state reset scheduling.
- [ ] Reset every error after four seconds.
- [ ] Cancel an old reset task when a new attempt begins.
- [ ] Guard against an old task resetting a newer state.
- [ ] Reset calendar-onboarding error presentation after four seconds.
- [ ] Keep successful import state stable.
- [ ] Do not reset successful completion after four seconds.

## Phase 9: Record-level synchronization

### 9.1 Client mutation tracking

- [ ] Replace broad “last sync” meaning with per-record server revision state.
- [ ] Generate stable mutation IDs.
- [ ] Persist pending mutations before sending.
- [ ] Include base server revision with every mutation.
- [ ] Retry pending mutations idempotently.
- [ ] Clear a mutation only after an accepted or definitively rejected server result.
- [ ] Keep a human-readable aggregate last-successful-sync time for Settings.

### 9.2 Merge behavior

- [ ] Accept server response revisions as authoritative.
- [ ] Replace local records when the server revision is newer.
- [ ] Apply accepted local mutations using returned server records.
- [ ] Remove records represented by server tombstones.
- [ ] Drop missing tag associations without failing unrelated mutations.
- [ ] Keep conflicts isolated to individual records.
- [ ] Do not let one calendar event conflict block timetable or settings sync.
- [ ] Recompute widgets, Spotlight, notifications, and Watch handoff only for affected datasets.

### 9.3 Existing owner timetable migration

- [ ] Map the current whole-timetable revision contract into the new envelope.
- [ ] Decide whether each `Subject` is a record or the owner timetable remains one record.
- [ ] If subjects become individual records, define stable subject IDs independent of editable names.
- [ ] Preserve server searchability as its own mutable record.
- [ ] Preserve current authoritative server behavior for non-empty server owner data.
- [ ] Keep older endpoint compatibility until the client cutover is complete.

## Phase 10: Reusable profile-picture system

### 10.1 Data model

- [ ] Replace `usesMonogram` and `symbol` branching with an explicit content kind.
- [ ] Support photo, monogram, and emoji.
- [ ] Keep one-to-three background colours for monogram and emoji modes.
- [ ] Hide background controls in photo mode.
- [ ] Hide monogram and emoji overlays in photo mode.
- [ ] Store Unicode emoji directly.
- [ ] Store font design and weight only where text rendering uses them.
- [ ] Store badges outside user-editable appearance data.

### 10.2 Reusable renderer

- [ ] Create one public iPhone profile-picture component.
- [ ] Accept a concrete square size proposed by the caller.
- [ ] Derive every internal dimension from component width/height.
- [ ] Keep the main circle at the full requested size regardless of badges.
- [ ] Render badges with `overlay`.
- [ ] Position badges relative to the avatar bounds.
- [ ] Use z-index for badge layering.
- [ ] Let badge visuals extend outside the circle without changing external measurement.
- [ ] Clip only the avatar content, not the badge overlay.
- [ ] Render authority and future badges from the array.
- [ ] Add stable placeholders for missing or loading photos.
- [ ] Cache server images by revision.
- [ ] Add accessibility text that describes the person and relevant badge meaning.

### 10.3 ColourfulX rendering

- [ ] Replace the current small-avatar gradient fallback with the shared ColorfulX-backed background where appropriate.
- [ ] Adjust ColorfulX render parameters so the gradient variation remains visible at small avatar sizes.
- [ ] Prefer render configuration, coordinate mapping, or container sizing over literal `.scaleEffect`.
- [ ] Keep frame rate and render scale bounded.
- [ ] Avoid one animated ColorfulX timeline per off-screen friend row if a static rendered representation is sufficient.
- [ ] Reuse a cached/static representation for scrolling lists if live animation harms performance.

## Phase 11: Profile editor in Settings

### 11.1 Navigation and initial state

- [ ] Remove the profile editor entry from Friends.
- [ ] Add Profile under Settings > Account.
- [ ] Present it using the host Settings namespace and a unique matched transition source.
- [ ] Use `.appNavigationTitle`.
- [ ] Apply `.scrollEdgeEffect()`.
- [ ] Load the saved appearance before presenting editable controls where possible.
- [ ] Initialize local editor state from the cached authoritative profile in `init` or a dedicated model.
- [ ] Eliminate the visible default-icon-to-owned-icon animation.

### 11.2 Mode selector

- [ ] Reuse the Timetable tab’s custom segmented picker.
- [ ] Make the left segment a menu-style selector for Photo, Monogram, and Emoji.
- [ ] Add reasonable SF Symbols to every option.
- [ ] Show the background segment only for Monogram and Emoji.
- [ ] Animate its blur and opacity when Photo is selected.
- [ ] Animate the remaining foreground selector into the center when it is the only segment.
- [ ] Restore the two-segment layout when a compatible foreground is selected.
- [ ] Avoid SwiftUI’s default segmented picker where the mock-ups show the custom control.

### 11.3 Photo selection and crop

- [ ] Use PhotosPicker for image selection.
- [ ] Decode the selected transferable off the main UI path.
- [ ] Present a square crop editor.
- [ ] Support drag to reposition.
- [ ] Support pinch to zoom.
- [ ] Prevent empty space inside the final square crop.
- [ ] Render the final square using `ImageRenderer` or an appropriate image pipeline.
- [ ] Downsample before upload.
- [ ] Encode to a supported format below one megabyte.
- [ ] Show the actual circular mask preview while cropping.
- [ ] Preserve the previous profile image until the new upload succeeds.
- [ ] Allow removal or replacement of the current photo.
- [ ] Handle Photos permission and decode failures without corrupting appearance state.

### 11.4 Emoji picker

- [ ] Add SwiftEmoji through Xcode package settings.
- [ ] Remove the old iPhone profile dependency on SFSymbolsPicker.
- [ ] Load sectioned emoji data through `EmojiIndexProvider`.
- [ ] Use SwiftEmoji’s grid.
- [ ] Add emoji search.
- [ ] Use relevance or alphabetical search, not usage ranking.
- [ ] Disable `EmojiUsageTracker`.
- [ ] Do not call `recordUse`.
- [ ] Do not request or display favourites.
- [ ] Persist only `emoji.character`.
- [ ] Keep the picker’s modal attached to the profile-editor root.

### 11.5 Monogram editing

- [ ] Place the transparent TextField directly inside the monogram preview/pop control.
- [ ] Preserve the visual typography while editing.
- [ ] Enforce the agreed character limit.
- [ ] Normalize casing without moving cursor state unnecessarily.
- [ ] Keep the field accessible and focusable.
- [ ] Avoid a separate rounded-border TextField below the preview.

### 11.6 Font popover

- [ ] Attach a font popover to its root profile-editor host.
- [ ] Show the four existing designs:
  - default;
  - serif;
  - monospaced;
  - rounded.
- [ ] Render each sample using `.font(.system(size:weight:design:))`.
- [ ] Add the ticked weight slider below the four designs.
- [ ] Map ticks to explicit SwiftUI weights.
- [ ] Persist the selected design and weight.
- [ ] Ensure preview and reusable renderer use the same mapping.

### 11.7 Colour grid

- [ ] Replace three ColorPickers.
- [ ] Build one dense palette of approximately fifteen columns by ten rows in portrait width.
- [ ] Use no inter-cell padding.
- [ ] Permit one-to-three selected colours.
- [ ] Show selection without requiring colour order.
- [ ] Reject a fourth selection.
- [ ] Permit deselection only while at least one colour remains.
- [ ] Feed the selected set into ColorfulX.
- [ ] Keep colour identifiers stable across launches.

### 11.8 Save transaction

- [ ] Separate display-name update, appearance update, and photo upload without exposing partial corrupt state.
- [ ] Upload the new photo before switching the authoritative content kind to Photo.
- [ ] Save appearance before deleting an old photo when switching away from Photo.
- [ ] Refresh the authoritative profile response after save.
- [ ] Update local caches once from that response.
- [ ] Refresh Friends and widgets only after authoritative save succeeds.
- [ ] Use a prominent confirm button with system image.

## Phase 12: Friends iPhone redesign

### 12.1 Main Friends list

- [ ] Replace `.navigationTitle("Friends")` with `.appNavigationTitle("Friends")`.
- [ ] Apply `.scrollEdgeEffect()`.
- [ ] Keep refreshable behavior.
- [ ] Remove the Profile toolbar button.
- [ ] Preserve friend-request and add-friend matched transitions.
- [ ] Replace current brown paper with white paper.
- [ ] Clip the paper image using the established Today/Planner card technique.
- [ ] Prevent a resizable paper image from claiming the full screen or row proposal.
- [ ] Use the reusable profile-picture component.
- [ ] Remove the disclosure chevron if sheet presentation no longer implies navigation.
- [ ] Make the entire visible card the only hit target.
- [ ] Present friend details as a matched-transition sheet from the row.
- [ ] Give each friend row a stable unique transition ID.

### 12.2 Friend row content

- [ ] Preserve current-class prominence.
- [ ] Render next class slightly smaller.
- [ ] Apply `.secondary` foreground style to next class.
- [ ] Prefix it with `Next:`.
- [ ] Avoid a double prefix when `FriendScheduleStatus` already returns `Next:`.
- [ ] Keep live school/activity status.
- [ ] Remove redundant relationship labels.
- [ ] Keep the row readable at fixed medium Dynamic Type only if explicitly retained for this surface.

### 12.3 Drag reordering

- [ ] Add an edit/reorder interaction suitable for the existing ScrollView.
- [ ] Use stable friend IDs.
- [ ] Update local order immediately during drag.
- [ ] Save the final order once per completed drag.
- [ ] Roll back or refresh if the server rejects the order.
- [ ] Prevent search results from participating in friend priority order.
- [ ] Propagate the new order to widget snapshots and timelines.
- [ ] Keep the first three friends as summary-widget priority.

### 12.4 Friend detail sheet

- [ ] Move friend detail presentation from `navigationDestination` to `.sheet(item:)`.
- [ ] Attach the sheet to the Friends root.
- [ ] Apply matched zoom transition from the tapped row.
- [ ] Use `.appNavigationTitle`.
- [ ] Apply `.scrollEdgeEffect()`.
- [ ] Keep the General/Week custom segmented control with SF Symbols.
- [ ] Preserve live status.
- [ ] Remove friend email.
- [ ] Put destructive actions in the intended visible bottom controls or action menu according to final visual implementation.
- [ ] Use SF Symbols in Remove and Report buttons.
- [ ] Attach remove confirmation dialog to the detail-sheet root.
- [ ] Attach report alert to the detail-sheet root.
- [ ] Remove the existing Block action and related client state.
- [ ] Keep the approved actions limited to Remove and Report.

### 12.5 Exact shared comparison

- [ ] Compare the signed-in owner timetable to the friend timetable.
- [ ] Normalize subject names case-insensitively.
- [ ] Normalize classroom names case-insensitively.
- [ ] Treat missing classroom as matching only another missing classroom.
- [ ] Build Shared Classes from identical subject and classroom pairs.
- [ ] Build Shared Subjects from identical subject names.
- [ ] Include exact subject/classroom matches in Shared Subjects as well as Shared Classes.
- [ ] Deduplicate repeated weekly occurrences.
- [ ] Preserve stable order based on the owner timetable or normalized name.
- [ ] Render empty states separately for both sections.

### 12.6 Class popovers

- [ ] Make current class, next class, shared class, and shared subject rows interactive where data exists.
- [ ] Attach popovers to the detail-sheet root.
- [ ] Give each popover source a stable item identity.
- [ ] Show the useful subset available for the selected relationship:
  - subject;
  - classroom;
  - teacher;
  - matching days/periods;
  - whether it is an exact shared class or subject-only match.
- [ ] Avoid showing empty labels.
- [ ] Use a compact presentation that adapts to iPhone sheet behavior.

## Phase 13: Settings and main tab structure

- [x] Reorder the primary tabs to Timetable, Friends, Settings.
- [x] Preserve the custom UIKit tab bridge and prominent-action behavior.
- [x] Update `MainTab` mapping.
- [x] Update programmatic tab selection.
- [ ] Update notification-based deep links to Settings and Timetable.
- [x] Keep Administration as the fourth conditional tab after Settings.
- [x] Make admin-tab visibility derive from current server authority, not calendar-event cache capability.
- [x] Remove the admin tab immediately after an authority-refresh response reports no access.
- [x] Keep the account signed in.
- [ ] Add Profile under Settings > Account.
- [ ] Reuse the profile picture in the Settings account row.
- [ ] Show authority badges on the Settings profile picture.

## Phase 14: Administration refresh and account data

### 14.1 Refreshable administration surfaces

- [ ] Add `.refreshable` to Administration dashboard content.
- [ ] Add `.refreshable` to Users.
- [ ] Add `.refreshable` to user detail/account data.
- [ ] Add `.refreshable` to school calendar date ranges.
- [ ] Add `.refreshable` to pupil-free/skipped dates.
- [ ] Add `.refreshable` to school events.
- [ ] Add `.refreshable` to tag management if added.
- [ ] Add `.refreshable` to broadcast history if added.
- [ ] Do not add `.refreshable` to the broadcast composer.
- [ ] Ensure refresh operations replace authoritative snapshots without duplicating rows.
- [ ] Present refresh failures through status badges.

### 14.2 Tag and section management

- [x] Add a Tags destination to Administration.
- [x] Use disclosure groups for tag sections.
- [x] Show each section’s tags inside its disclosure group.
- [x] Support adding, renaming, reordering, and archiving sections.
- [x] Support adding, editing, reordering, and archiving tags.
- [ ] Edit each tag’s display name, category, associated names, symbol, and colour.
- [x] Give associated names a readable token/list editor.
- [x] Normalize aliases before saving.
- [x] Show validation when an alias conflicts with another active subject tag.
- [ ] Keep year-group canonical values protected while permitting approved display metadata changes.
- [ ] Keep destructive archive actions behind confirmation dialogs attached to the administration root.
- [ ] Use matched transitions and unique source IDs for compact tag and section editors.
- [x] Use fractional sheet detents for short tag and section forms.
- [x] Add `.refreshable` to the tag-management list.

### 14.3 Account JSON disclosure hierarchy

- [ ] Preserve complete sanitized account JSON.
- [ ] Preserve recursive direct/base64 JSON decoding.
- [ ] Parse the top-level JSON object.
- [ ] Render each top-level item as a DisclosureGroup.
- [ ] For object and array children, render second-level items as DisclosureGroups.
- [ ] Below the second level, render readable raw/pretty JSON text.
- [ ] Keep text selectable and monospaced.
- [ ] Keep deterministic sorted keys.
- [ ] Avoid hiding scalar top-level values.
- [ ] Bound large raw sections without truncating stored data.
- [ ] Exclude password hashes, verification-code hashes, APNs credentials, and other authentication secrets.

### 14.4 Administrator management

- [ ] Show current authority in user rows and detail.
- [ ] Show administrator badge overlays using the reusable profile picture.
- [ ] Show permanent-owner badge according to the final distinction.
- [ ] Only system owners see grant/revoke controls.
- [ ] Confirm grant and revoke operations.
- [ ] Prevent revoking either permanent owner.
- [ ] Refresh target account and current dashboard after a role change.
- [ ] If the current account somehow loses ordinary admin authority, handle the next `403` by removing the admin tab.
- [ ] Record authority changes in an audit record with actor, target, old role, new role, and timestamp.

## Phase 15: Broadcast composer and history

- [ ] Keep title required and visibly marked.
- [ ] Permit empty subtitle.
- [ ] Permit empty body.
- [ ] Disable Send only when trimmed title is empty or a request is active.
- [ ] Preserve best-effort APNs delivery.
- [ ] Show eligible, delivered, invalidated, and failed counts.
- [x] Add broadcast history to Administration separately from the composer.
- [x] Show sender email snapshot and send time.
- [x] Show full title, subtitle, and body without inventing placeholder content.
- [x] Show aggregate delivery result.
- [x] Add detail disclosure for structured failures if persisted.
- [ ] Do not add pull-to-refresh to the composer.
- [x] Add pull-to-refresh to history.

## Phase 16: TipKit setup only

- [ ] Add `TipKit` import and one-time application configuration.
- [ ] Configure local-only datastore behavior.
- [ ] Disable CloudKit/iCloud synchronization.
- [ ] In Debug builds, reset the TipKit datastore before configuration.
- [ ] In Release builds, retain display state for the installation.
- [ ] Do not define or show any `Tip` types.
- [ ] Keep reset behavior out of production.
- [ ] Confirm reinstall naturally resets installation-local state.

## Phase 17: Versioned `.timetable` format

- [ ] Add the versioned share-document model.
- [ ] Encode only the shared identifier and format version.
- [ ] Use a stable content type declaration.
- [ ] Update file export.
- [ ] Update file import.
- [ ] Validate supported version before fetching.
- [ ] Resolve identifier through the authenticated shared-timetable fetch path.
- [ ] Handle deleted, private, malformed, unsupported-version, and not-found documents.
- [ ] Preserve Universal Link and Messages `/share/<locator>` behavior.
- [ ] Do not embed current subject data in new exports.
- [ ] Do not add a legacy decoder because no prior `.timetable` file format exists.
- [ ] Refresh the received timetable cache after a successful fetch/import.

## Phase 18: Large summary widget

- [ ] Add a new large-only widget configuration.
- [ ] Prevent small and medium families from selecting it.
- [ ] Fix Dynamic Type to `.medium`.
- [ ] Build timeline entry data in the provider.
- [ ] Include:
  - current owner subject/state;
  - up to three ordered friends;
  - each friend’s current subject/state;
  - upcoming calendar events;
  - profile-picture data or cached image representation.
- [ ] Reserve a clean model/UI extension point for future friend statuses.
- [ ] Do not render a status placeholder or add a user-status endpoint in this phase.
- [ ] Ensure all content fits without runtime truncation in the large family.
- [ ] Prioritize the first three persisted friend-order entries.
- [ ] Add `Next:` to the existing Friends widget where requested.
- [ ] Avoid network requests from the widget view.
- [ ] Cache profile photos in the shared App Group at an appropriate downsampled size.
- [ ] Trigger timeline reload after:
  - friend reorder;
  - profile update;
  - friend profile refresh;
  - timetable sync;
  - calendar event sync.
- [ ] Use current timeline entries so countdowns and class state do not begin stale.
- [ ] Constrain text widths and monospaced timers where required.

## Phase 19: Explicit Watch-only cleanup

- [ ] Replace shared Watch `containerBackground` use with equivalent per-view `background`.
- [ ] Keep each Watch view’s existing visual background.
- [ ] Trace the current `Timer.publish` ownership in `WatchTimetablesTabView`.
- [ ] Confirm timer cancellation, tab identity, and background transitions when switching tabs.
- [ ] Move periodic time ownership into each visible timer-dependent tab where necessary.
- [ ] Prefer `TimelineView(.periodic(...))` for view-driven school-state refresh when it remains active inside the tab container.
- [ ] Ensure Current, Friends, and any other time-derived tab recompute school state after period boundaries.
- [ ] Ensure `Text(timerInterval:)` receives valid moving intervals and is not recreated from a permanently stale `now`.
- [ ] Keep update cadence proportional to the UI:
  - one second for visible countdowns;
  - slower periodic updates for labels that do not show seconds.
- [ ] Add a Debug-only `debugOffset` numeric TextField to Watch Settings.
- [ ] Bind the field to the shared `Defaults[.debugOffset]` value.
- [ ] Recompute visible timer tabs immediately when the offset changes.
- [ ] Keep the field human-readable and consistent with the iPhone Debug setting.
- [ ] Do not change the Watch app icon.
- [ ] Do not redesign Watch navigation or profile pictures in this phase.
- [ ] Do not expand the reusable avatar to Watch yet.

## Phase 20: Platform audit after iPhone completion

- [ ] Audit Codable compatibility on iPadOS, macOS, Watch, widgets, Messages, App Intents, and Live Activities.
- [ ] Keep new profile DTOs decodable even where the UI is not yet updated.
- [ ] Ensure unsupported profile photo surfaces fall back safely.
- [ ] Ensure authority changes do not expose an admin destination on unsupported platforms.
- [ ] Ensure tag filtering does not remove server-authoritative calendar data accidentally.
- [ ] Ensure record-level sync changes do not break Watch bootstrap.
- [ ] Schedule separate parity work rather than widening iPhone commits.

## User-run verification matrix

### Cloudflare R2 provisioning

- [ ] Activate R2 in the Cloudflare dashboard.
- [ ] Create a private Standard bucket named `timetable-profile-images` or another approved lowercase name.
- [ ] Leave location on Automatic unless the pmstt server’s region makes an explicit location hint preferable.
- [ ] Leave public development URL access disabled.
- [ ] Do not attach a public custom domain.
- [ ] Create an Account API token with Object Read & Write permission.
- [ ] Scope the token to the single profile-image bucket.
- [ ] Record the Access Key ID and Secret Access Key at creation time.
- [ ] Record the Cloudflare Account ID.
- [ ] Put all credentials in the deployed PM2/process environment, never the repository.
- [ ] Configure:
  - `R2_ACCOUNT_ID`;
  - `R2_ACCESS_KEY_ID`;
  - `R2_SECRET_ACCESS_KEY`;
  - `R2_BUCKET`;
  - `R2_ENDPOINT`.
- [ ] Set `R2_STORAGE_LIMIT_BYTES=9000000000`.
- [ ] Set `R2_MONTHLY_OPERATION_LIMIT=900000`.
- [ ] Set `R2_MONTHLY_WRITE_CUTOFF=850000`.
- [ ] Restart pmstt with its updated production environment only after implementation.
- [ ] Confirm upload, conditional read, replacement, and deletion through pmstt.
- [ ] Confirm the bucket remains inaccessible without valid credentials.
- [ ] Confirm the administration quota display matches server accounting.
- [ ] Compare server accounting with the Cloudflare R2 dashboard and GraphQL metrics.

### Server migration and authentication

- [ ] Back up the database before the destructive Apple-only account cleanup.
- [ ] Apply migrations in a non-production copy first.
- [ ] Confirm only Apple-only accounts are removed.
- [ ] Confirm both permanent owners survive and retain authority.
- [ ] Confirm ordinary administrator grant and revoke behavior.
- [ ] Confirm revoked administrators receive `403` without session invalidation.
- [ ] Confirm non-school registration is rejected.
- [ ] Confirm uppercase valid school email normalizes correctly.
- [ ] Confirm code expiry at ten minutes.
- [ ] Confirm resend is blocked before two minutes and allowed afterward.
- [ ] Confirm an old code stops working after resend.
- [ ] Confirm a used code cannot be replayed.

### Tags and calendar import

- [ ] Confirm tag sections and wrapping layout at narrow iPhone width.
- [ ] Confirm no tag search field exists.
- [ ] Confirm missing/archived tags are dropped safely.
- [ ] Confirm year-group subscription survives subject-tag replacement.
- [ ] Confirm sport/general subscriptions survive subject-tag replacement.
- [ ] Confirm Keep Current Subject Tags.
- [ ] Confirm Replace Subject Tags.
- [ ] Confirm every weekday in every sampled week contributes to import analysis.
- [ ] Confirm every import error resets after four seconds.
- [ ] Confirm successful import does not reset.

### Sync

- [ ] Edit different records on two devices and sync in both orders.
- [ ] Change one device’s wall clock before editing and syncing.
- [ ] Confirm server revision, not clock time, wins.
- [ ] Confirm one record conflict does not block unrelated records.
- [ ] Confirm deletion tombstones reach an offline-returning device.
- [ ] Confirm repeated mutation requests are idempotent.
- [ ] Confirm Settings displays the aggregate last successful sync time.

### Profile editor

- [ ] Confirm the editor opens with the saved profile immediately.
- [ ] Confirm no default-icon transition is visible.
- [ ] Confirm Photo mode hides background controls.
- [ ] Confirm mode-control centering animation.
- [ ] Confirm square crop at minimum and maximum zoom.
- [ ] Confirm upload remains below one megabyte.
- [ ] Confirm failed upload preserves the old photo.
- [ ] Confirm emoji search works.
- [ ] Confirm favourites and recents remain unused.
- [ ] Confirm monogram editing occurs inside the preview.
- [ ] Confirm all four font designs visibly differ.
- [ ] Confirm every ticked weight maps to the intended system weight.
- [ ] Confirm one, two, and three colours render.
- [ ] Confirm a fourth colour cannot be selected.
- [ ] Confirm badges do not shrink the avatar.
- [ ] Confirm multiple avatar sizes preserve relative badge geometry.

### Friends

- [ ] Confirm tab order is Timetable, Friends, Settings.
- [ ] Confirm Friends uses `.appNavigationTitle`.
- [ ] Confirm white paper clips to each row.
- [ ] Confirm row backgrounds do not claim the full screen.
- [ ] Confirm friend detail opens as a sheet with matched transition.
- [ ] Confirm friend email is absent.
- [ ] Confirm live status remains.
- [ ] Confirm next class is smaller, secondary, and prefixed `Next:`.
- [ ] Confirm exact shared classes require matching subject and classroom.
- [ ] Confirm shared subjects require matching subject only.
- [ ] Confirm case and whitespace differences do not prevent matches.
- [ ] Confirm class popovers show available teacher/classroom/period information.
- [ ] Confirm Remove uses confirmation dialog.
- [ ] Confirm Report uses alert.
- [ ] Confirm modals originate from the correct root.
- [ ] Confirm reporting leaves the friend visible.
- [ ] Reorder friends and confirm the order survives relaunch and another device refresh.

### Administration and broadcasts

- [ ] Pull to refresh every administration list/detail surface.
- [ ] Confirm no pull-to-refresh exists on the broadcast composer.
- [ ] Confirm account JSON top and second levels disclose correctly.
- [ ] Confirm deeper JSON remains selectable raw formatted text.
- [ ] Confirm secrets remain excluded.
- [ ] Send title-only broadcast.
- [ ] Send title and subtitle with empty body.
- [ ] Confirm whitespace-only title is rejected.
- [ ] Confirm broadcast history stores sender and all delivery counts.
- [ ] Confirm logs show one correctly formatted timestamp prefix.

### File sharing, widgets, and Watch

- [ ] Export a versioned `.timetable` file.
- [ ] Confirm the document contains no embedded timetable content.
- [ ] Import it and fetch the shared timetable.
- [ ] Confirm malformed and unsupported versions fail clearly.
- [ ] Confirm the existing Friends widget says `Next:`.
- [ ] Confirm the large summary widget fits owner, three friends, and events.
- [ ] Confirm widget Dynamic Type remains medium.
- [ ] Confirm reordered friends change widget priority.
- [ ] Confirm each Watch view preserves its prior background after modifier replacement.
- [ ] Confirm countdowns continue updating after switching between Watch tabs.
- [ ] Confirm school state changes when a period boundary passes while the tab remains open.
- [ ] Change Watch Debug Offset and confirm visible timer tabs update immediately.

### R2 quota failures

- [ ] Set a temporary low byte limit and confirm an upload receives `507` with `profileStorageCapacityReached`.
- [ ] Set a temporary low write cutoff and confirm profile-image mutation receives `429` with `profileStorageWriteBudgetReached`.
- [ ] Set a temporary low operation limit and confirm R2-backed reads receive `429` with `profileStorageOperationBudgetReached`.
- [ ] Confirm quota failures preserve the existing profile image and revision.
- [ ] Confirm `Retry-After` points to the next UTC month for monthly operation errors.
- [ ] Confirm conditional `304` responses do not consume an R2 operation.

## Planned atomic commit sequence

The exact sequence may split further when source boundaries require it.

### `pmstt`

- [ ] `add account authority`
- [ ] `add email verification challenges`
- [ ] `remove apple authentication`
- [ ] `add global event tags`
- [ ] `add profile media`
- [ ] `enforce profile storage quotas`
- [ ] `add profile badges`
- [ ] `persist friend order`
- [ ] `store broadcast history`
- [ ] `add record sync metadata`
- [ ] `add record sync endpoint`
- [ ] `add timestamps to server logs`

### Timetable

- [ ] `add account authority contracts`
- [ ] `replace apple sign in with email verification`
- [ ] `add year group onboarding`
- [ ] `fix onboarding state after sign in`
- [ ] `reset calendar import errors`
- [ ] `improve calendar import sampling`
- [ ] `add tag subscriptions`
- [ ] `add event tag selection`
- [ ] `sync records by server revision`
- [ ] `add reusable profile pictures`
- [ ] `move profile editor to settings`
- [ ] `add photo profile editor`
- [ ] `replace profile symbols with emoji`
- [ ] `add profile font controls`
- [ ] `add profile colour grid`
- [ ] `redesign friends rows`
- [ ] `show friend details in a sheet`
- [ ] `fix shared class matching`
- [ ] `persist friend priority`
- [ ] `reorder main tabs`
- [ ] `refresh administration views`
- [ ] `improve administration account data`
- [ ] `manage administrators`
- [ ] `show broadcast history`
- [ ] `configure tipkit`
- [ ] `version timetable share files`
- [ ] `add summary widget`
- [ ] `update friends widget next class`
- [ ] `make watch backgrounds view local`
- [ ] `keep watch timers updating`
- [ ] `add watch debug time offset`

## Explicit exclusions

- No optional start-time field for events.
- No event end-time work.
- No actual TipKit tips.
- No iCloud synchronization for TipKit state.
- No user-created tags.
- No tag search field.
- No emoji favourites, recents, or usage ranking.
- No automatic hiding/removal after reporting a friend.
- No email in ordinary friend details.
- No Apple Sign In compatibility after the destructive migration.
- No device-clock-based last-write-wins logic.
- No broad Watch, macOS, or iPadOS profile redesign during the iPhone-first phases.
- No Watch app icon changes.
- No friend-status feature beyond an internal future extension point.
- No legacy `.timetable` decoder because this is the first format.
- No Block action in friend details.
- No builds or tests run by Codex.
