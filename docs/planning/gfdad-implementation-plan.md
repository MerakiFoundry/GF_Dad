# GF Dad — Foundation and Delivery Plan

Status: PROPOSED; not an implementation approval or a claim of independent validation.
Prepared: 2026-10-02.
Review baseline: existing main tree b00f919d3040a3bbab4a6be2de0967897604a469.

This is a documentation-only proposal. It does not change recipes, create infrastructure, change repository visibility, enable spending, or authorize production deployment. An independent AI review is being sought; its actual availability and findings must be reported separately. No outcome is assumed here.

## 1. Purpose and boundaries

GF Dad is a gluten-free family cookbook and working kitchen notebook. The author develops recipes with an assistant, supplies rough feedback and actual photographs, and should not have to format pages or operate a collection of administrative tools. Detailed instructions, failures, practical learning, photographs, audio, and preserved family editions are primary content, not optional extras.

The public site has no social-media buttons, follower/karma system, engagement ranking, or automated claims about the best recipe. Its tone is a quiet cookbook, not a sales landing page. Every public cookbook recipe must meet the project's gluten-free publishing rules. Research references awaiting adaptation are a separate content type, not automatically publishable recipes.

The first release serves one real family workspace. The architecture must support a second isolated workspace from the outset, verified with test data. Private invited collaboration follows. Open registration, a public workspace directory, community-wide search, payments, complex moderation tooling, real-time co-editing, and native app-store distribution are later decisions, not hidden first-release requirements.

The prior experience reported by the owner—another application expanded and needed substantial cleanup—motivates explicit boundaries and change control. This plan does not claim to have audited that prior application's code or know the cause of its rework.

## 2. Product contract

### Ordinary author workflow

1. Discuss a recipe and supply raw notes, voice notes, or photographs.
2. The assistant proposes a structured recipe or cooking note, retaining the original input and marking missing information rather than inventing it.
3. Save a draft automatically only through an authorized, scoped integration. Saving is not public release or confirmation of a cooking result.
4. Produce one preview and a short exception list, not a checklist of cosmetic approvals.
5. The owner or an authorized workspace editor chooses to publish a specific version. Publication may include an explicitly experimental recipe or a failed-test article; it does not certify success.
6. Media and publishing jobs perform mechanical work, report failures, and leave the last working publication intact.

The assistant does not run continuously merely because a conversation exists. Background work must run in implemented application jobs under authorized accounts. Automation setup and account authorization are dependencies, not capabilities assumed to be already connected.

### Reader workflow

A normal search returns one main result per recipe, not every edit. The main page shows the workspace's chosen published edition and its honest maturity label. Recipe, Notebook, and Variations/history are separate views. An incomplete failed attempt may be a notebook article, not a misleading cookable recipe card. Names explain variations; dot-version numbers identify revisions without implying higher quality.

A reader can pin an edition. Starting cooking pins a version for that session; the quantities and audio must not change halfway through because a newer edition was published. A preserved family edition remains addressable independently of the current house recipe.

## 3. Architecture decision

### Recommended initial structure: one application, explicit modules

Use a modular monolith: one application codebase with a public cookbook and authenticated notebook, a managed PostgreSQL database, managed authentication, object storage, and one small background worker/job mechanism. Modules cover identity/workspaces, recipes/tests, media, publishing, and activity/export. Separate modules do not require microservices or separate deployment stacks.

A managed PostgreSQL/Auth/Storage service such as Supabase is the leading backend candidate, not an already purchased service. Avoid self-hosting its complete stack on the smallest VM merely to minimize a server line item. No WordPress, second live CMS, Kubernetes, generic plugin platform, or message broker is required initially. A database-backed jobs/outbox table is sufficient unless the prototype demonstrates otherwise.

Lovable remains a candidate implementation/design tool. It must use the agreed content and permission operations rather than create parallel tables or bypass the publication workflow. Its current framework and deployment constraints require a compatibility test before commitment. Do not build both an Astro site and a Lovable application as two permanent frontends for the same first release.

If Lovable is retained, use its generated app repository as the single application-code repository. The existing GF_Dad repository is imported and preserved; it can later receive generated public recipe exports. This is two repositories with different responsibilities, not two independently editable recipes. A non-Lovable implementation may use one private application repository instead. Resolve this at Gate 0.

### One authoritative store

After a verified migration, the application database is authoritative for working recipes, version snapshots, tests, permissions, and publication selections. GitHub holds code, decision records, schema migrations, and generated content exports. Object storage holds media bytes. A media reference is not a backup of those bytes.

Before migration, the existing repository remains authoritative and unchanged. Import into staging, compare all seven source recipes, obtain a cutover decision, then prohibit automatic two-way editing. Later Git changes to exported content are either rejected as edits to generated files or deliberately imported as a reviewed change; they never silently override the database.

Public GF_Dad exports contain only explicitly published fields and approved derivatives. Private workspace data, originals, tokens, raw personal notes, and access records are never exported to a public repository. Complete private archival exports go to private storage. Repository visibility changes require a separate decision.

## 4. Minimum durable data model

These are domain entities, not a requirement for one table per paragraph or per feature.

| Entity | Invariant |
|---|---|
| User and external identity | Stable internal user ID, independent of Google/Apple/email provider identity. |
| Workspace and membership | Every private object has a workspace owner; a user can belong to multiple workspaces. Start with owner, editor, reader roles. |
| Recipe | Stable recipe identity, workspace, slug, current working head; no hardcoded assumption that all recipes belong to GF Dad. |
| Recipe version | Immutable named snapshot of content; parent version; display label stored as text, not a numeric decimal; author and source provenance. Autosave drafts need not create a public version on every keystroke. |
| Cooking attempt | Exact version used; actual changes, goals, observations, unknowns, and attachments. Multiple attempts can use the same version. Corrections retain attribution. |
| Publication/edition | Explicit immutable content version and approved asset set, selected by an authorized person; current public pointer and preserved named editions are distinct. |
| Media asset | Private/public treatment, original/derivative distinction, content hash, version or attempt relation, caption and provenance. |
| Job and activity record | Scope, target version, actor, retry status, correlation/idempotency key. Activity is not a public social feed. |

A named alternative is a separate recipe/variation with optional derived-from-version lineage, not an automatic merge of successful changes. Do not grant access to private source content through a lineage link. Cross-workspace copying is deferred until permission and attribution rules exist.

### Recipe content contract

Use a versioned structured document for metadata, ingredient groups, ordered method stages, equipment/settings, quantities, timing, sensory checkpoints, troubleshooting, references, and explanatory prose. Preserve rich narrative where structure adds no value. Use a schema_version for migrations; do not create an unvalidated bag of arbitrary JSON.

Grams are the base where known; store verified cup equivalents rather than invent generic conversions. Preserve ranges, optional quantities, counts of eggs, and unknowns. Method completeness includes prep, baking, resting, cooling, and serving—not just the existing heading called Method. Automated scaling and nutrition estimates are not first-release requirements.

Separate three things: recipe maturity, reported result of an attempt, and public visibility. CONFIRMED is attributed human judgment, not independent certification or an AI-generated conclusion. Last edited is not last cooked. Preserve original source text for migration comparison and raw feedback for provenance.

## 5. Permissions and collaboration

Every read, write, search, export, notification, and asset access must be constrained by membership and publication visibility. UI hiding is not authorization. Validate that recipe, version, attempt, and asset identifiers all belong to the expected workspace, using database constraints where practical.

Use server-side authorization plus database row-level security where applicable. Test the actual role used by browser, API, worker, and export code; service-role clients can bypass RLS. Never give the assistant a database administrator key. Workers use constrained operations and validate job scope rather than trusting arbitrary submitted IDs.

Private object-storage paths are not privacy by themselves. Use access policies and short-lived authorized access. Private notes must not leak through generated exports, HTML, search indexes, media URLs, job logs, notifications, or error payloads. A signed link is a bearer credential; do not promise instantaneous revocation of an already issued link. Public copies and downloads cannot be retroactively made secret.

Start with adult invited accounts; do not build public child registration. Establish a recovery/second-owner process and revoke invitations and access correctly. Provider sign-in is not proof of a real cooking test. Invitations, upload limits, rate limits, and reporting are separate controls.

Use optimistic concurrency: a save names its expected draft revision; a stale edit is rejected with the user's work retained. No silent last-write-wins and no real-time collaborative editor in release one. Editors may propose changes and record outcomes; publication permissions are local to the workspace. Other workspaces do not require the GF Dad owner to judge their recipe choices.

## 6. Publication and automation contract

All human/editor/assistant content changes pass through the same authenticated commands, for example SaveDraft(expectedRevision), RecordAttempt(versionId), AttachAsset(targetId), and PublishVersion(versionId, expectedPublicationRevision). Command names describe a contract, not an assertion these endpoints already exist.

For a publish request, record the authorized request and queued work in one database transaction using an outbox pattern. Workers process at least once, with bounded retries and deduplication. Idempotency keys include workspace, immutable content version/hash, operation, relevant media, and generation configuration.

Build a publication manifest pinned to one exact version and approved assets. A later worker may not overwrite a newer publication: finalization checks the expected publication revision and still-current requested target. Revalidate authority/withdrawal at the final publication operation. Switch the published pointer only after required output checks pass. Do not rebuild the whole app for each content edit; serve/invalidate the approved publication from the data layer. Code deployments remain a separate operation.

Audio is linked to script hash, content version, voice/configuration, and base serving size. Never pair old spoken quantities with new written quantities. Default policy: updated text may publish without optional audio while new audio is pending; the old track is disabled for that edition. The prior edition remains intact. A text-only spelling correction need not incur a full narration job when the narration script is unchanged.

Process actual supplied photographs into responsive derivatives, preserve originals privately, strip location metadata from public derivatives, and retain version/attempt associations. Generated concept art is labeled as illustration, never evidence of an actual batch. Do not alter crumb, doneness, shape, or failure evidence during enhancement. Audio transcripts and accessible player controls are required; stepwise playback and offline downloads can be phased.

Notification delivery consumes activity records later. Begin with an in-app recent-updates list and essential operational failure reporting. No engagement messages. Email digests and push require an explicit feature gate, opt-in settings, deduplication, and authorization checks at send time. Revoked users must not receive subsequent private updates.

If generation, export, or deployment fails, retain the last good publication, retry only bounded work, and surface an actionable failure. Set usage/upload limits and generation budgets before enabling paid automation. A rollback to content must restore a coherent version and media manifest, not merely an earlier frontend build.

## 7. Mobile and platform independence

Website first; responsive cookbook and notebook share the content/authorization contract. Progressive enhancement must leave the detailed recipe readable and printable. No social-media UI. Quiet hero, recipe-first navigation, usable typography, keyboard access, and phone/iPad checks are part of acceptance.

Capacitor/PWA is the initial mobile path to evaluate, not a guaranteed automatic export. Current Lovable server-rendered output cannot simply be assumed to become an offline client bundle. Test packaged assets versus hosted functions, sign-in redirects and deep links, audio controls/background behavior, and one photo upload. Server-only logic stays on a server. Record the result and limits; choose a different implementation before feature expansion if this fails.

The later app's useful native scope is version-pinned offline reading/audio and batch capture, not an empty wrapper. Offline editing/synchronization is deferred and must specify conflict handling. App-store approval is not promised. User-generated-content distribution also requires a moderation/reporting plan when appropriate.

## 8. Preservation, privacy, and recovery

Archive readable Markdown/HTML (and optionally generated print/PDF editions), structured JSON, provenance, original images/audio, generated audio/transcripts, and an integrity manifest. Do not make the application or assistant subscription the only way to read the collection. Original human voice and generated narration are separately labeled assets.

Back up database and media independently to access-controlled storage; test recovery into a clean environment. The family archive needs a named second administrator, domain/account recovery information kept securely, and export instructions. Recovery secrets never belong in public Git. An archive should be useful even if no external community develops.

Before the family launch, confirm media consent, what is public, basic retention/deletion handling, contributor attribution, and provider privacy/training settings. Invitations and independent workspaces are not a substitute for platform abuse handling. Open public workspaces require a separate operational owner, terms/permissions for content reuse, and reporting/abuse procedures.

## 9. Phased delivery and exit gates

### Gate 0 — Resolve the expensive choices before feature coding

Deliver a one-page product contract, chosen app repo/runtime/deployment route, database authority and cutover ADR, schema/permissions outline, a three-recipe fixture set (complete, in-testing, incomplete), and a mobile/auth smoke test. Compare an existing recipe manager only against the distinctive requirements; do not build a second full prototype.

Price the whole operating stack: app/runtime, database/auth, storage/egress, backup, email, narration/AI, domain, and later app-store costs. Distinguish development subscriptions from runtime costs. Record included limits, idle/suspension risks, restore options, and one capped pilot budget; do not order services without owner approval. A $5 static server quote is not the budget for the full application.

Exit: a written proposed architecture, known framework/export/mobile constraints, an independently reviewed plan if an authorized reviewer is available, and explicit unresolved decisions. A missing third-party review is reported as missing, never treated as approval.

### Gate 1 — Prove one end-to-end family workflow

Build one real workspace and a second isolated test workspace; import the three fixtures; implement draft/save, immutable version, cooking note, scoped photograph, and public-edition selection. Deliver one full recipe page preserving all instructions, one audio/transcript, and a portable export. Connect the assistant through the same commands or document the exact missing integration; no fictitious automatic writes.

Exercise two sessions, a stale edit, a repeated job, a revoked user, wrong-workspace identifiers, and a changed quantity. Reader sees one recipe, author sees history. End-to-end workflow is the first usable product, not a disposable mock backend.

Exit: owner can supply rough input and a photograph, review a concise exception summary, and publish a coherent recipe without re-entering it in another CMS. Automated negative-access, concurrency, version/audio, and duplicate-job tests pass.

### Gate 2 — Family release at the owned domain

Import and reconcile all seven existing recipes without changing untested facts. Add consistent recipe/search/notebook pages, status explanations, print, responsive accessibility, production authorization, independent backups, error reporting, and a restore drill. Keep the publishing surface free of social-media components and promotional filler. Real photos replace design placeholders only when supplied and approved.

Exit: recipe text and media survive an independent restore; no private material appears in public export/search; normal publication needs no manual page design; factual ambiguities and failures remain visible. Recipe code and content operations have separate rollback paths.

### Gate 3 — Small invited collaboration pilot

Enable a real second independent workspace without schema redesign. Invite editors, test local publication decisions, record separate attempts, retain attribution, and add a small activity inbox. Use the pilot to measure whether people actually return and contribute useful notes, not whether they like the idea.

Exit: boundaries remain intact, editing is understandable, operating effort stays acceptable, and collaboration provides observable value. Public onboarding is a separate go/no-go decision.

### Gate 4 — Mobile application and selective expansion

Reuse the contract and validated runtime route. Add pinned offline cookbook/audio, camera capture, appropriate sign-in, privacy, deletion, reporting, and platform requirements. Only then evaluate additional notification delivery, workspace discovery, and cross-workspace adaptations. Each item requires its own scope and evidence; no automatic growth into a social platform.

## 10. Change control to prevent avoidable cleanup

Maintain short ADRs for data authority, privacy/workspace boundaries, version/publication semantics, runtime/mobile choice, and preservation. Every change states the decision it alters. Supersede decisions with reasons rather than leaving contradictory instructions in chat or code.

One feature changes one vertical workflow with tests. Separate schema/auth changes from cosmetic redesign. Apply migrations to staging before production; retain a recovery path. Use small pull requests and review boundaries, not a prompt asking an agent to build every future feature. No speculative repository abstraction or universal workflow engine.

Accept ordinary UI refactoring. Avoid preventable rewrites caused by lost history, duplicated authoritative data, missing ownership, public-by-default assets, provider-bound identities, and server-only behavior assumed to work offline. If open workspaces are abandoned, the family cookbook must still function without their UI or jobs.

## 11. Required acceptance checks

- Another workspace's guessed recipe/version/asset IDs cannot be read, changed, published, searched, exported, or notified to an unauthorized user.
- A revoked member and a stale editor cannot publish a new version. Authorized edits do not silently overwrite a concurrent revision.
- Immutable editions survive later edits; a reader cooking v1.1 retains v1.1 even if v1.2 is published.
- Replaying or completing jobs out of order cannot create duplicate test records, duplicate paid generations, or roll publication back to an older request.
- Text, recipe metadata, print output, and attached audio agree on the selected version and quantities; stale audio is absent, not silently reused.
- All seven imported source recipes retain known instructions, unknowns, status, and provenance; reference material cannot enter the cookbook without gluten-free publication review.
- Private inputs and originals are excluded from public HTML, indexes, Git exports, and notification payloads; credentials are never in frontend code or logs.
- A clean restore recovers actual media bytes and usable recipes without the original application account or this conversation.
- A second real workspace can be enabled by configuration/data and permissions, without replacing the recipe schema or building another application.

## 12. Independent reviewer brief

Review this proposal adversarially as a small-family-project architecture, not as a generic enterprise product. Do not reward complexity or propose extra features merely because possible. Distinguish blockers, manageable risks, and later options. Cite the section and a concrete failure scenario for every finding. State what evidence you lack; do not claim a running system was tested.

Specifically challenge: database-versus-Git authority/cutover; public exports from a public repo; cross-workspace references/media and worker privilege; draft/version/test/publication complexity; race conditions and authority revocation; assistant access; managed backend cost/restore assumptions; Lovable/mobile portability; moderation without a social feed; migration of incomplete recipes; and long-term archival usefulness. Identify at least three things to remove or simplify and tests that would falsify the proposal. Do not implement or merge changes.

## 13. External references

These sources support specific platform facts and design checks; none is an endorsement or independent review of GF Dad.

1. Microsoft, architecture decision records: https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record
2. AWS, tenant isolation versus authorization: https://docs.aws.amazon.com/prescriptive-guidance/latest/saas-multitenant-api-access-authorization/introduction.html
3. Lovable, current framework/mobile/repository limits: https://docs.lovable.dev/introduction/faq
4. Lovable, Git synchronization: https://docs.lovable.dev/integrations/github
5. Supabase, database backups and separate Storage objects: https://supabase.com/docs/guides/platform/backups
6. Capacitor, requirements for integrating a web application: https://capacitorjs.com/docs/getting-started
7. GitHub, requesting Copilot review including REST API support: https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/copilot-code-review
