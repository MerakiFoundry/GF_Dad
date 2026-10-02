---
applyTo: "docs/planning/*.md"
---

# Review instructions for the GF Dad architecture proposal

This pull request is documentation-only. The owner requested an independent, skeptical review of the concept and delivery plan before implementation. Review the plan itself as an architecture/design change. Do not limit review to Markdown formatting, and do not interpret discussion of future capability as an existing implementation.

Read docs/planning/gfdad-implementation-plan.md and the current recipe template/taxonomy for context. The actual product is a low-administration gluten-free family cookbook, detailed kitchen notebook, versioned real cooking attempts, supplied photographs, and version-matched audio. Future independent workspaces/mobile must not force a predictable rebuild; open community/social features are not first-release requirements.

Prioritize concrete contradictions or missing decisions in: authoritative database versus Git exports and cutover; workspace isolation including media, jobs, search, and export; safe assistant permissions; immutable versions and publication races; private data in a public source repository; ownership/revocation/concurrent edits; incomplete recipe import; audio consistency; full media backup/restore; Lovable server-rendering/mobile portability; operating costs and unnecessary scope.

For each finding, give its severity, document section/line, failure scenario, and smallest reasonable correction. Distinguish blockers from optional enhancements. Do not add enterprise infrastructure by default. Identify overengineered aspects as well as missing safeguards. Do not claim test execution or product demand evidence that you do not have. A review is not approval to implement, purchase services, publish family material, or merge the branch.
