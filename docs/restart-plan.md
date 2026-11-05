# MoneyTracker v2 — Restart Plan

A plan for rebuilding MoneyTracker around good system design: a real relational schema,
a layered architecture, and a path to a backend with multi-device sync.

Each phase lists **what you build**, **what you learn**, and **"done when"** so you know when to move on.

---

## 0. Design principles

These rules drive every decision below. When you're unsure, come back to them.

1. **Money is never a floating-point number.** Store integers in the currency's smallest unit (cents).
2. **The database enforces the rules.** Constraints (`NOT NULL`, `CHECK`, `FOREIGN KEY`, `UNIQUE`) catch bugs
   that UI validation misses. The UI validates for friendliness; the DB validates for correctness.
3. **Ask the database, don't loop in Dart.** Filtering, summing, and grouping belong in SQL.
4. **The UI never knows where data comes from.** Widgets talk to state; state talks to repositories;
   repositories talk to SQLite or the server.
5. **Design for sync from day one.** UUID primary keys, `updated_at`, and soft deletes cost nothing now
   and are very painful to retrofit.
6. **Every schema change is a migration.** No "uninstall and reinstall to fix it".

---

## 1. Architecture

```
┌────────────────────────────────────────────────────────────┐
│ UI (widgets)        features/*/ui                          │  ← only renders state, sends user intents
├────────────────────────────────────────────────────────────┤
│ State (Riverpod)    features/*/providers                   │  ← holds screen state (selected month, filters)
├────────────────────────────────────────────────────────────┤
│ Repositories        data/repositories                      │  ← the app's "API": addExpense(), watchMonth()...
├───────────────────────────────┬────────────────────────────┤
│ Local DB (drift / SQLite)     │ Remote (HTTP API)  [later] │
└───────────────────────────────┴────────────────────────────┘
```

**Why this fixes v1's problems:**

| v1 problem | v2 fix |
|---|---|
| Pages call `DatabaseHelper` inside `build()` | UI only reads providers |
| Stats doesn't refresh after adding on Home | Repositories expose drift `watch()` **streams**; every screen updates automatically when a row changes |
| `CurrencyProvider` global mutable singleton | Base currency lives in the `settings` table, exposed through a provider |
| Add form and edit form are 90% duplicated | One `TransactionForm` widget, `initial: Transaction?` (null = add) |
| Date-filter logic copied in two pages | One `DateRange` type + one repository query |

### Tech choices

| Concern | Choice | Why |
|---|---|---|
| Local DB | **drift** + `sqlite3_flutter_libs` | You still write real SQL (in `.drift` files), but get typed results, reactive streams, and a migration + migration-testing toolkit. Bundles a modern SQLite on every platform. |
| State | **Riverpod** | Testable, no `BuildContext` needed, plays well with streams. |
| IDs | **UUIDv7** (`uuid` package) | Globally unique (safe for sync), and time-ordered so they index well. |
| Money | Your own `Money` value class | `Money(amountMinor: 1234, currency: 'HKD')` — no doubles anywhere in the domain. |

### Folder structure (feature-first)

```
lib/
  main.dart                     ← move here from AppPages/ (Flutter's default entry point)
  app/                          router, theme, bottom nav shell
  core/
    money.dart                  Money value type + formatting
    date_range.dart             DateRange (day / month / year), half-open [start, end)
    ids.dart                    UUIDv7 generator
    clock.dart                  injectable "now" (makes time-based code testable)
  data/
    db/
      app_database.dart         drift database class, PRAGMAs, migrations
      schema.drift              CREATE TABLE statements (section 2)
      queries.drift             named SQL queries (section 3)
    repositories/
      transaction_repository.dart
      account_repository.dart
      category_repository.dart
      budget_repository.dart
      fx_repository.dart
    remote/                     [phase 5+] API client
  features/
    entry/                      add / edit transaction (one shared form)
    history/                    list + filters (old "Stats")
    insights/                   charts
    budgets/
    accounts/
    settings/
test/
  data/                         repository + query tests against in-memory SQLite
  migrations/                   schema migration tests
```

---

## 2. Database schema (v1 of the new app)

Written as SQLite DDL so you can read it as plain SQL. With drift, this goes almost verbatim into `schema.drift`.

### Conventions used everywhere

| Column | Type | Meaning |
|---|---|---|
| `id` | `TEXT` | UUIDv7 string |
| `created_at`, `updated_at` | `INTEGER` | Unix epoch **milliseconds, UTC** — an *instant* |
| `deleted_at` | `INTEGER NULL` | Soft delete. `NULL` = alive. Sync needs to know "this was deleted". |
| `occurred_on` | `TEXT` `'YYYY-MM-DD'` | A *calendar date* in the user's local time — "I bought lunch on March 3" is not an instant. ISO format sorts correctly as text. |
| `*_minor` | `INTEGER` | Money in smallest units. 12.34 HKD → `1234`; 500 JPY → `500` |

> ⚠️ SQLite does **not** enforce foreign keys unless you run `PRAGMA foreign_keys = ON;` on every connection.
> Put it in drift's `beforeOpen` callback.

### Reference data

```sql
-- How many decimal places each currency has. JPY = 0, HKD/USD/EUR/AUD = 2.
CREATE TABLE currencies (
  code      TEXT PRIMARY KEY,                 -- ISO 4217: 'HKD'
  exponent  INTEGER NOT NULL CHECK (exponent BETWEEN 0 AND 4),
  symbol    TEXT NOT NULL
);

-- Simple key/value store for app preferences: base_currency, first_day_of_week, ...
CREATE TABLE settings (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL
);
```

### Accounts and categories (now real tables, not in-memory lists)

```sql
CREATE TABLE accounts (
  id                     TEXT PRIMARY KEY,
  name                   TEXT NOT NULL,
  kind                   TEXT NOT NULL CHECK (kind IN ('cash','bank','credit_card','e_wallet','other')),
  currency               TEXT NOT NULL REFERENCES currencies(code),
  opening_balance_minor  INTEGER NOT NULL DEFAULT 0,
  archived               INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0,1)),
  sort_order             INTEGER NOT NULL DEFAULT 0,
  created_at             INTEGER NOT NULL,
  updated_at             INTEGER NOT NULL,
  deleted_at             INTEGER
);

CREATE TABLE categories (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  kind        TEXT NOT NULL CHECK (kind IN ('expense','income')),
  parent_id   TEXT REFERENCES categories(id),       -- optional sub-categories: Food > Coffee
  icon        TEXT,
  color       INTEGER,                              -- ARGB int, stable color per category
  archived    INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0,1)),
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  deleted_at  INTEGER
);

-- No two live categories with the same name (case-insensitive) — but a deleted
-- "Food" must not block creating a new "Food". That's what the partial index does.
CREATE UNIQUE INDEX ux_categories_name
  ON categories(kind, name COLLATE NOCASE)
  WHERE deleted_at IS NULL;
```

**Why this matters:** renaming "Food" → "Groceries" is now one `UPDATE` on one row, and all history follows,
because transactions store `category_id`, not the name.

### Transactions

```sql
CREATE TABLE transactions (
  id                 TEXT PRIMARY KEY,
  type               TEXT NOT NULL CHECK (type IN ('expense','income','transfer')),
  occurred_on        TEXT NOT NULL CHECK (occurred_on GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),

  account_id         TEXT NOT NULL REFERENCES accounts(id),
  category_id        TEXT REFERENCES categories(id),       -- NULL for transfers

  amount_minor       INTEGER NOT NULL CHECK (amount_minor > 0),   -- always positive; `type` gives direction
  currency           TEXT NOT NULL REFERENCES currencies(code),

  -- Snapshot of the value in the user's base currency AT THE TIME OF THE TRANSACTION.
  -- This is what fixes "last year's yen dinner changes value every day".
  fx_rate_to_base    REAL NOT NULL,                         -- a multiplier, not money, so REAL is OK
  base_amount_minor  INTEGER NOT NULL,

  -- Transfers only: money arriving in the other account (may be a different currency)
  to_account_id      TEXT REFERENCES accounts(id),
  to_amount_minor    INTEGER,

  note               TEXT NOT NULL DEFAULT '',
  is_starred         INTEGER NOT NULL DEFAULT 0 CHECK (is_starred IN (0,1)),
  importance         INTEGER NOT NULL DEFAULT 3 CHECK (importance BETWEEN 1 AND 5),
  recurring_rule_id  TEXT REFERENCES recurring_rules(id),

  created_at         INTEGER NOT NULL,
  updated_at         INTEGER NOT NULL,
  deleted_at         INTEGER,

  -- Shape rules: the DB refuses a transfer without a destination, or an expense with one.
  CHECK (
    (type = 'transfer'
       AND to_account_id IS NOT NULL
       AND to_amount_minor IS NOT NULL AND to_amount_minor > 0
       AND to_account_id <> account_id
       AND category_id IS NULL)
    OR
    (type IN ('expense','income')
       AND to_account_id IS NULL
       AND to_amount_minor IS NULL
       AND category_id IS NOT NULL)
  )
);

-- Indexes match the questions the app asks most often.
CREATE INDEX ix_tx_date          ON transactions(occurred_on)              WHERE deleted_at IS NULL;
CREATE INDEX ix_tx_account_date  ON transactions(account_id, occurred_on)  WHERE deleted_at IS NULL;
CREATE INDEX ix_tx_category_date ON transactions(category_id, occurred_on) WHERE deleted_at IS NULL;

-- Makes recurring-transaction generation idempotent (see phase 4).
CREATE UNIQUE INDEX ux_tx_recurring_occurrence
  ON transactions(recurring_rule_id, occurred_on)
  WHERE recurring_rule_id IS NOT NULL;
```

### Tags (many-to-many — your first join table)

```sql
CREATE TABLE tags (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  deleted_at  INTEGER
);
CREATE UNIQUE INDEX ux_tags_name ON tags(name COLLATE NOCASE) WHERE deleted_at IS NULL;

CREATE TABLE transaction_tags (
  transaction_id  TEXT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  tag_id          TEXT NOT NULL REFERENCES tags(id)         ON DELETE CASCADE,
  PRIMARY KEY (transaction_id, tag_id)
);
```

A transaction can have many tags (`#trip-japan`, `#work`), and a tag spans many transactions —
something a single `category` column can't express.

### Budgets, recurring rules, exchange rates

```sql
CREATE TABLE budgets (
  id            TEXT PRIMARY KEY,
  category_id   TEXT REFERENCES categories(id),      -- NULL = overall monthly budget
  period        TEXT NOT NULL CHECK (period IN ('month','week','year')),
  amount_minor  INTEGER NOT NULL CHECK (amount_minor > 0),   -- in base currency
  starts_on     TEXT NOT NULL,
  ends_on       TEXT,                                 -- NULL = ongoing
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL,
  deleted_at    INTEGER
);

CREATE TABLE recurring_rules (
  id            TEXT PRIMARY KEY,
  -- template for the generated transaction
  type          TEXT NOT NULL CHECK (type IN ('expense','income')),
  account_id    TEXT NOT NULL REFERENCES accounts(id),
  category_id   TEXT NOT NULL REFERENCES categories(id),
  amount_minor  INTEGER NOT NULL CHECK (amount_minor > 0),
  currency      TEXT NOT NULL REFERENCES currencies(code),
  note          TEXT NOT NULL DEFAULT '',
  -- schedule
  frequency     TEXT NOT NULL CHECK (frequency IN ('daily','weekly','monthly','yearly')),
  interval      INTEGER NOT NULL DEFAULT 1 CHECK (interval >= 1),   -- every N units
  starts_on     TEXT NOT NULL,
  ends_on       TEXT,
  next_due_on   TEXT NOT NULL,                        -- cursor: first date NOT yet generated
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL,
  deleted_at    INTEGER
);

-- Cached daily rates. One row per (date, quote currency), relative to a fixed pivot (USD).
CREATE TABLE exchange_rates (
  rate_date   TEXT NOT NULL,
  quote       TEXT NOT NULL REFERENCES currencies(code),
  per_usd     REAL NOT NULL CHECK (per_usd > 0),       -- 1 USD = per_usd units of `quote`
  fetched_at  INTEGER NOT NULL,
  PRIMARY KEY (rate_date, quote)
);
```

### Entity-relationship overview

```
currencies ◄──── accounts ◄──────────── transactions ────► categories ◄── budgets
    ▲                ▲   (account_id,        │  │              ▲  (parent_id → self)
    │                │    to_account_id)     │  └──► recurring_rules
    └── exchange_rates                       │
                                    transaction_tags ───► tags
```

### Design decisions worth understanding (not just copying)

1. **Store balances or compute them?** v2 **computes** account balances from transactions (section 3).
   Stored balances are faster but can drift out of sync with the rows that produced them. This is the
   general *derived data* trade-off: only cache once a measured query is actually slow.
2. **Single-row transfers vs. double-entry.** Here a transfer is one row with `account_id` → `to_account_id`.
   Real accounting systems use *double-entry*: every transaction is ≥2 `entries` that sum to zero.
   That's more flexible (splits, fees) but more complex. Single-row is the right start; read about
   double-entry as a stretch topic.
3. **Why snapshot `base_amount_minor`?** Historical totals must not move when today's rate moves.
   Trade-off: if the user changes their base currency, you must **recompute** every row's
   `fx_rate_to_base` and `base_amount_minor` from `exchange_rates` — which is why you keep that table too.
4. **Why `deleted_at` instead of `DELETE`?** If phone A deletes a row and phone B hasn't synced yet,
   B needs a record that says "this was deleted", otherwise B will re-upload it. Deleted rows are
   filtered out with `WHERE deleted_at IS NULL` (the partial indexes above make that cheap) and
   permanently purged later, once every device has synced.

---

## 3. Key queries

All date filters use **half-open ranges** `[start, end)`: "March" = `occurred_on >= '2026-03-01' AND occurred_on < '2026-04-01'`.
No off-by-one errors and no "last day of the month" math.

```sql
-- Pie chart: spending by category in a date range
SELECT c.id, c.name, c.color, SUM(t.base_amount_minor) AS total_minor
FROM transactions t
JOIN categories c ON c.id = t.category_id
WHERE t.type = 'expense'
  AND t.deleted_at IS NULL
  AND t.occurred_on >= :start AND t.occurred_on < :end
GROUP BY c.id
ORDER BY total_minor DESC;

-- Monthly trend: income vs. expense per month for a year
SELECT substr(occurred_on, 1, 7) AS month,
       SUM(CASE WHEN type = 'income'  THEN base_amount_minor ELSE 0 END) AS income_minor,
       SUM(CASE WHEN type = 'expense' THEN base_amount_minor ELSE 0 END) AS expense_minor
FROM transactions
WHERE deleted_at IS NULL AND type <> 'transfer'
  AND occurred_on >= :yearStart AND occurred_on < :nextYearStart
GROUP BY month
ORDER BY month;
```

**Account balances using a VIEW.** A view is a saved query you can select from like a table:

```sql
-- Every money movement, signed from the account's point of view
CREATE VIEW account_movements AS
  SELECT account_id, occurred_on,
         CASE WHEN type = 'income' THEN amount_minor ELSE -amount_minor END AS delta_minor
  FROM transactions WHERE deleted_at IS NULL
  UNION ALL
  SELECT to_account_id, occurred_on, to_amount_minor
  FROM transactions WHERE type = 'transfer' AND deleted_at IS NULL;

SELECT a.id, a.name, a.currency,
       a.opening_balance_minor + COALESCE(SUM(m.delta_minor), 0) AS balance_minor
FROM accounts a
LEFT JOIN account_movements m ON m.account_id = a.id
WHERE a.deleted_at IS NULL
GROUP BY a.id;
```

**Budget progress:**

```sql
SELECT b.id, b.category_id, b.amount_minor AS budget_minor,
       COALESCE(SUM(t.base_amount_minor), 0) AS spent_minor
FROM budgets b
LEFT JOIN transactions t
  ON t.type = 'expense'
 AND t.deleted_at IS NULL
 AND (b.category_id IS NULL OR t.category_id = b.category_id)
 AND t.occurred_on >= :periodStart AND t.occurred_on < :periodEnd
WHERE b.deleted_at IS NULL AND b.period = 'month'
GROUP BY b.id;
```

**Learning exercise:** run `EXPLAIN QUERY PLAN` on the pie-chart query with and without `ix_tx_date`.
You should see it switch from `SCAN transactions` (reads every row) to `SEARCH transactions USING INDEX`.

---

## 4. Migrations

- `schemaVersion` starts at **1** in v2 and only ever goes up.
- Every bump gets a step in `onUpgrade` (drift's `stepByStep` helper) and a **test** that opens an
  old-version database and checks the upgrade preserves data.
- Use drift's `make-migrations` tooling: it snapshots each schema version as JSON and generates test scaffolding.
- Rule: **never edit a migration that has shipped.** Add a new one.

**Optional exercise — import your v1 data.** Write a one-time importer that reads the old
`money_tracker.db` and:
- converts `amount REAL` → `amount_minor INTEGER` (multiply by `10^exponent`, **round**, don't truncate),
- turns category/account name strings into rows in `categories`/`accounts` and links them by ID,
- maps `isHighlighted` → `is_starred` and `rating` → `importance`.

That's a realistic data-migration task: the kind of job companies do when they redesign a schema.

---

## 5. Multi-currency design

```
            ┌──────────── on app start / daily ─────────────┐
            ▼                                               │
  FxRepository.ensureRates(date)                            │
     1. look in exchange_rates for that date                │
     2. if missing → fetch from API → INSERT                │
     3. if offline → use the most recent date we have       │
            │                                               │
            ▼                                               │
  Saving a transaction:                                     │
     fx_rate_to_base   = per_usd[base] / per_usd[currency]  │
     base_amount_minor = round(amount × rate, adjusting     │
                         for each currency's exponent)      │
```

- The app **never blocks startup** waiting for the network. Rates are a background refresh.
- Conversion lives in **one** pure function in `core/money.dart`, with unit tests (including JPY ↔ HKD,
  where the exponents differ).
- **API key:** in phases 1–4 pass it with `--dart-define=FX_API_KEY=...` (never commit it).
  In phase 5 the **server** fetches rates and the key leaves the app entirely.

---

## 6. Backend (phase 5) and sync (phase 6)

### Why a backend at all

A mobile app must never connect to MySQL/Postgres directly: the credentials would be inside the app
binary for anyone to extract. The shape is always:

```
 Phone (SQLite)  ⇄  HTTPS + auth  ⇄  Your API server  ⇄  Postgres
                                         │
                                  cron: fetch FX rates daily
```

### Server database (Postgres)

Same tables as the app, with three changes:
- Every table gets `user_id UUID NOT NULL` (every row belongs to someone) and every query filters by it.
  Postgres **Row-Level Security** can enforce this at the DB level — worth learning.
- Types upgrade: `UUID`, `DATE`, `TIMESTAMPTZ`, `BIGINT` for money.
- Every syncable row gets `server_version BIGINT`, assigned from one global sequence on each write.

### Sync protocol (offline-first)

The phone is the source of truth for the UI; the server is the source of truth for *agreement* between devices.

```
PUSH  POST /sync/push   { changes: [ {table, id, row, updated_at}, ... ] }
      ← server upserts each row, assigns a new server_version, returns it

PULL  GET  /sync/pull?since=<last_server_version_seen>
      ← every row (from any of the user's devices) with server_version > since
      → client upserts locally, stores the new high-water mark
```

- **Client side:** add a `dirty` flag (or an `outbox` table) via a migration. Each local write marks
  the row dirty; a sync worker pushes dirty rows, then pulls.
- **Why `server_version` instead of `updated_at` for pulling?** Phone clocks are wrong all the time.
  A server-assigned counter has an order you can trust.
- **Conflicts:** start with *last-write-wins per row* — simple and good enough for one person on two
  devices. Then write down where it breaks (e.g. two edits to different fields of the same transaction)
  and look at per-field merging as an upgrade.
- **Deletes** sync as normal updates that set `deleted_at`. Purge tombstones after N days.

### Auth

Email + password or OAuth (Sign in with Apple/Google) → server issues a short-lived **access token**
(JWT) + long-lived **refresh token**. Tokens go in `flutter_secure_storage`, never in SQLite or SharedPreferences.

---

## 7. Roadmap

### Phase 0 — Housekeeping (½ day)
- [x] Remove the hardcoded freecurrencyapi key from source (now read via `--dart-define=FX_API_KEY=...`).
- [ ] Register a new free account for a fresh key. The old key (git history, commit `f5c8bde`) can't be
      revoked because the account is lost; it's free-tier, so the worst case is someone burning its quota.
- [ ] Create a `v2` branch. Keep `fonts/`, `images/`, and the visual style; rewrite `lib/` from scratch.
- [ ] Entry point at `lib/main.dart`, stricter lints (`flutter_lints` + `always_declare_return_types` etc.).
- [ ] Add a `test/` folder and get `flutter test` running in a GitHub Action.

### Phase 1 — Local foundation
Build: drift DB with the section 2 schema (minus budgets/recurring), `Money`, repositories with `watch()`
streams, Riverpod, one shared add/edit form, editable accounts & categories, seeded defaults.
Learn: normalization, constraints, foreign keys, the repository pattern, reactive data flow.
**Done when:** add/edit/delete works; categories and accounts survive a restart; renaming a category
updates its history; repository tests pass against an in-memory DB.

### Phase 2 — Queries & insights
Build: history with filters (date range, account, category, tag, text search), pie chart, monthly trend,
account balances via the view, income vs. expense.
Learn: `GROUP BY`, `JOIN`, views, indexes, `EXPLAIN QUERY PLAN`.
**Done when:** no screen loads all transactions into Dart to filter them; seed 50,000 rows and every screen still feels instant.

### Phase 3 — Multi-currency done right
Build: `currencies` and `exchange_rates`, cached and offline-safe rates, snapshot conversion on save,
"change base currency" with a full recompute run inside one DB transaction.
Learn: caching, idempotent fetches, DB transactions (all-or-nothing writes), precision and rounding.
**Done when:** airplane-mode launch works; changing base currency recomputes correctly; conversion has unit tests.

### Phase 4 — Budgets & recurring transactions
Build: budgets with progress bars; recurring rules (rent, subscriptions) generated on app open.
Learn: scheduling and **idempotency** — the generator runs `INSERT OR IGNORE` for each due date
up to today, then advances `next_due_on`, all in one DB transaction. Running it twice must never duplicate
a row (the unique index `ux_tx_recurring_occurrence` guarantees it).
**Done when:** killing the app mid-generation and reopening produces exactly the right rows.

### Phase 5 — Backend & auth
Build: API server + Postgres, signup/login, FX fetching moved server-side, deployed with Docker.
Learn: API design, auth tokens, server-side migrations, environments (dev/prod), secrets management.
**Done when:** the app can log in and the API key no longer exists anywhere in the app.

### Phase 6 — Sync
Build: push/pull sync, dirty tracking, conflict handling, background sync.
Learn: offline-first design, logical clocks vs. wall clocks, eventual consistency.
**Done when:** two simulators edit offline, reconnect, and converge to the same data.

### Phase 7 — Stretch features (pick by interest)
- **Receipts:** photo → object storage (S3/R2) with an `attachments` table; OCR to prefill the form.
- **Shared / split expenses:** groups, members, "who owes whom". Multi-tenant data and permissions.
- **QnA tab with an LLM:** "how much did I spend on food in March?" Turn questions into queries
  safely: a read-only connection, a whitelisted set of views, always scoped to the current user.
- **Double-entry ledger:** migrate transactions → entries. A hard but excellent migration exercise.

---

## 8. Open decisions (my recommendation first)

| Decision | Recommendation | Alternative |
|---|---|---|
| Restart in place or new repo? | New `v2` branch, same repo — your history shows growth | New repo |
| Local DB library | drift (real SQL + migrations) | Raw sqflite (more manual, more control) |
| Server DB | **Postgres** — stronger constraints, native UUID/partial indexes, RLS, most common in modern stacks | MySQL — fine, but no advantage for this project |
| Server language | **Python + FastAPI** — a second language widens your skills; huge docs; Alembic migrations mirror drift's | Dart (Dart Frog) to share models with the app |
| Hosted backend instead? | Build your own first — that's where the learning is | Supabase (Postgres + auth done for you) once you understand what it replaces |
