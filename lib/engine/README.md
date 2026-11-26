# Engine (reserved)

This folder is reserved for the lead engine, delivered in prompts **D1 to D6**.

Nothing here yet, by design: A1 and the following foundation/data prompts must not
contain scraping, extraction, validation or ranking logic. When the engine lands it
will own:

- source adapters (Maps listing, website crawl, social search)
- contact extraction (phones, emails, websites, social links, WhatsApp evidence)
- validation (phone format/type, email syntax + MX + role/disposable, website
  reachability, duplicate fingerprints)
- filtering, sorting, deduplication and confidence scoring

The UI contract the engine must satisfy is Section 7 of `Client Hunt Mockups/README.md`.
