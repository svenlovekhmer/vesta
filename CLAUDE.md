# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development
bin/dev                    # Start development server
bin/rails c                # Rails console

# Database
bin/rails db:migrate       # Run pending migrations
bin/rails db:seed          # Load seed data (demo user: sven@vesta.com / password123)
bin/rails db:reset         # Drop, recreate, migrate, seed

# Tests & CI
bin/rails test             # Run all tests (controller + system + model)
bin/rails test test/controllers/dashboard_controller_test.rb
bin/rails test test/controllers/mission_controller_test.rb
bin/rails test test/system/dashboard_test.rb
bin/rails test test/models/mission_test.rb:42   # Single test at line
bin/ci                     # Full CI: rubocop + bundler-audit + brakeman + importmap audit + tests + seeds
bin/rubocop                # Ruby linting (Rails Omakase config)
bin/brakeman               # Security static analysis
```

## Architecture

Vesta is a project management and client portal system for service providers (interior designers, architects, etc.). Providers manage missions (projects) for clients, tracking progress through customizable step templates. Includes AI-powered Gmail sync to automatically extract decision logs from client emails.

**Tech stack:** Rails 8.1.3, Ruby 3.3.5, PostgreSQL, Bootstrap 5.3, Hotwire (Turbo + Stimulus), Importmap (no Node.js build step), Solid Suite (Cache/Queue/Cable replacing Redis), Active Storage (file uploads), OpenAI/Azure GPT-4o-mini via GitHub Models API.

### Domain model

```
User (Devise + Google OAuth2) → Profile (first_name, last_name, profession, logo [Active Storage])
User → Clients → Missions
User → StepTemplates → StepTemplateItems
User → GmailConnection (access/refresh tokens for Gmail API)

Mission → belongs_to Client, MissionStatus, StepTemplate (optional)
Mission → Steps (ordered) → Documents (file [Active Storage], optional step)
Mission → DecisionLogs (PAV: points à valider)
Mission → MissionStepBlockers (link between Steps and DecisionLogs)

Step → belongs_to StepStatus
Step → MissionStepBlockers → DecisionLogs
Document → DecisionLogDocuments → DecisionLogs (join table)
```

`MissionStatus` and `StepStatus` are lookup-table models (not enums), seeded with French values:
- MissionStatus: *En attente / En cours / En révision / Terminée*
- StepStatus: *À faire / En cours / Validée / Bloquée*

### Key patterns

- **Portal token**: `Mission#portal_token` enables unauthenticated client access without user accounts.
- **File handling**: Documents and profile logos use Active Storage (not `file_url` strings). `has_one_attached :file` on Document, `has_one_attached :logo` on Profile.
- **Authentication**: Devise with `database_authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable` + Google OAuth2 via OmniAuth.
- **Multi-DB (production)**: Separate PostgreSQL databases for primary, cache, queue, and cable — all configured via `DATABASE_URL`.
- **Progress calculation**: percentage of steps whose `step_status.title == "Validée"` over total steps. Computed in views, not stored.
- **Status slugs**: always use `.parameterize` to generate CSS class suffixes from French status titles — never manual gsub. `"Terminée".parameterize` → `"terminee"`, `"En révision".parameterize` → `"en-revision"`.
- **Auto status sync**: `Mission#auto_update_status!` updates mission status automatically when a step is marked Validée (via `StepsController#update`).
- **Turbo Streams**: most CRUD actions on documents, decision_logs, steps, and mission_step_blockers respond with `.turbo_stream.erb` templates for in-place DOM updates without page reload.
- **Gmail AI sync**: `GmailSyncJob` fetches emails, calls `GmailAnalysisService` (streaming Azure GPT-4o-mini), creates/updates `DecisionLog` records with `source: "gmail_ai"`, and broadcasts Turbo Stream updates back to the UI.
- **Environment variables**: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` (OAuth2), `GITHUB_TOKEN` (Azure Models API key for GPT-4o-mini) — stored in `.env` via dotenv-rails.

### Routes

```ruby
devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
root to: "pages#home"                       # redirects authenticated users to /dashboard
get  "/dashboard" => "dashboard#index"

resources :missions, only: [:index, :new, :create, :show, :update, :destroy] do
  get  :confirm_destroy, on: :member
  post :sync_all,        on: :collection    # triggers GmailSyncJob
  resources :documents,  only: [:create]
end

resources :clients do                        # full CRUD
  post :sync_emails, on: :member            # triggers GmailSyncJob for one client
end

resource  :profile, only: [:edit, :update]  # singular; handles logo upload/purge

resources :steps,              only: [:update]
resources :documents,          only: [:destroy]
resources :mission_step_blockers, only: [:create, :destroy]

resources :decision_logs, only: [:create, :update, :destroy] do
  get   :new_modal,     on: :collection
  get   :resolve_modal, on: :member
  patch :resolve,       on: :member
end

get "up" => "rails/health#show"
```

### Current features

**Dashboard** (`/dashboard`) — requires authentication
- Stats row: active mission count, blocked steps count, missions awaiting client, client count
- Pending decision logs grouped by mission (PAV section)
- Mission table: client avatar (initials), progress bar, status badge
- Client-side tab filter (Toutes / En cours / Terminées) via Stimulus `mission-filter` controller
- Sidebar with VESTA logo, nav links, user profile (name + profession from `Profile`)

**Missions** (`/missions`) — requires authentication
- `index` — lists all missions for `current_user` with progress bars and status badges
- `new` — form with inline step builder (add/remove steps before creation)
- `create` — saves mission, auto-assigns `MissionStatus "En attente"`, redirects to `show`
- `show` — tabbed view: Steps timeline / Documents / Decision Logs (PAV + decided sections)
- `update` — inline edits (title, etc.) via Stimulus `inline-edit` controller
- `destroy` — with confirmation page (`confirm_destroy`)
- `sync_all` — POST: enqueues `GmailSyncJob` for all missions; responds with Turbo Stream updating gmail panel

**Steps** (`/steps/:id`)
- `update` — toggles step status; when set to "Validée", auto-advances next step to "En cours" and calls `mission.auto_update_status!`; responds with `update.turbo_stream.erb`

**Decision Logs / PAV** (`/decision_logs`) — points à valider
- `new_modal` — renders Turbo Frame modal for creating a decision log (linked to mission, optionally to a step)
- `create` — creates log; responds with `create.turbo_stream.erb` or `create_blocker.turbo_stream.erb`
- `update` — inline edits on decision log fields
- `destroy` — removes log; Turbo Stream removes DOM element
- `resolve_modal` — renders modal to mark a log as decided (with resolved_at date)
- `resolve` — PATCH: marks log resolved; Turbo Stream moves it from PAV to decided section
- `DecisionLog` enum `owner_type`: `client / provider / third_party`
- `DecisionLog` attribute `source`: `"gmail_ai"` for AI-generated logs, nil for manual

**Mission Step Blockers** — links between Steps and DecisionLogs
- `create` — find_or_create_by linking a decision log to a step; Turbo Stream updates the step's blocker zone
- `destroy` — removes the link; Turbo Stream removes the pill component
- `MissionStepBlocker` enum `blocking_status`: `blocking / warning / resolved`; stores snapshot titles

**Documents** — per mission, optionally per step
- `create` — file upload via Active Storage; optionally associates with a step; Turbo Stream inserts new document card
- `destroy` — removes file and record; Turbo Stream removes card

**Clients** (`/clients`) — full CRUD
- `index` — grid of client cards
- `show` — client detail with missions list
- `new` / `edit` / `update` / `destroy` (with `confirm_destroy`)
- `sync_emails` — POST: enqueues `GmailSyncJob` for specific client; requires active `GmailConnection`
- Validations: email (unique per user, format), phone (regex), first/last name

**Profile** (`/profile`) — singular resource
- `edit` / `update` — first_name, last_name, profession, logo (Active Storage); logo purge via checkbox

**Gmail AI Integration**
- Google OAuth2 (`users/omniauth_callbacks#google_oauth2`) creates/updates `GmailConnection` with access/refresh tokens
- `GmailSyncJob` (Solid Queue): fetches 10 most recent emails to/from client, calls `GmailAnalysisService`, creates/updates `DecisionLog` records, broadcasts Turbo Streams to update `gmail_panel`, `pav_section`, `decided_section`, `pav_sync_label` DOM regions
- `GmailAnalysisService`: `stream_synthesis(messages)` yields tokens for real-time UI; `analyze_decisions(messages)` returns `{ "decided" => [...], "pending" => [...] }`; French prompts; Faraday with SSE streaming
- `GmailConnection#fresh_access_token!` auto-refreshes expired tokens via Faraday POST to `GOOGLE_TOKEN_URL`

### Stimulus controllers

| Controller | Purpose |
|---|---|
| `mission-filter` | Tab filter on missions list (Toutes / En cours / Terminées) |
| `mission-tabs` | Tab switcher on mission show (Steps / Documents / Logs) |
| `mission-accordion` | Expandable mission items in PAV section |
| `inline-edit` | Click-to-edit text fields with pencil icon |
| `row-link` | Clickable table rows that navigate to show page |
| `clients-filter` | Client list search/filter |
| `modal` | Generic modal open/close |
| `step-selector` | Step dropdown in decision log form |
| `step-link` | Drag-drop linking decision logs to steps |
| `steps` | Step status toggle |
| `blocker-inline` | Inline toggle for step blocker visibility |
| `blocker-modal` | Modal for creating step blockers from a step |
| `doc-blocker-modal` | Modal for document-linked blocker creation |
| `document-upload` | File drop zone with preview |
| `logo-upload` | Profile logo upload with preview |
| `gmail-sync` | Gmail sync button + polling for sync status |
| `pav-sync` | PAV sync label lifecycle (fresh / loading / error) |
| `resolve-modal` | Resolve decision log modal with date picker |

### Styling

Stylesheets under `app/assets/stylesheets/`:
- `config/` — `_colors.scss` (`$red`, `$blue`, `$yellow`, `$orange`, `$green`, `$gray`, `$light-gray`), `_fonts.scss`, `_bootstrap_variables.scss`
- `components/` — `_sidebar.scss`, `_navbar.scss`, `_avatar.scss`, `_alert.scss`, `_buttons.scss`, `_card.scss`, `_form.scss`, `_steps.scss`, `_logs.scss`, `_inline_edit.scss`, `_gmail_sync.scss`, `_breadcrumb.scss`, `_title.scss`
- `pages/` — `_dashboard.scss`, `_missions.scss`, `_clients.scss`, `_profile.scss`, `_auth.scss`, `_home.scss`

**Bootstrap CSS variable pattern for progress bars:** set `--bs-progress-bar-bg: #{$scss-variable}` on modifier classes, not `background-color`. The `.missions-progress` container must be `display: inline-flex` (not `inline-block`) — Bootstrap's `.progress-bar` child gets its height from the flex context.

**Status color classes:** generated via `.parameterize` on status titles — e.g. `.status--en-cours`, `.status--terminee`. Provider and client colors differentiated via `.provider` / `.client` modifier classes.

### Seeds

`bin/rails db:seed` creates:
- 1 user: `sven@vesta.com / password123`
- 1 profile: Sven Dupont, Architecte d'intérieur
- 1 step template with 7 items
- 4 clients: Marie Laurent, Thomas Moreau, Isabelle Petit, Nicolas Bernard
- 4 missions (one per status: En cours / En attente / En révision / Terminée) with steps and decision logs

### Testing

Uses Rails Minitest (no RSpec). Gems: `capybara`, `selenium-webdriver`, `rails-controller-testing`.

**`test/test_helper.rb`** shared setup:
- `create_mission_for(user, title:, status_title:, created_at:)` — builds a complete mission for a given user
- `teardown` prints `✓ PASS` / `✗ FAIL` + test name after every test
- `ActionDispatch::IntegrationTest.include Devise::Test::IntegrationHelpers` — enables `sign_in` in controller tests

**`test/application_system_test_case.rb`**:
- Driver: `selenium, using: :headless_chrome, screen_size: [1400, 900]`
- `login_as(user)` — navigates to the Devise login form and submits it

**Test files:**
- `test/controllers/dashboard_controller_test.rb` — 9 tests: auth redirect, data isolation, stats counts, ordering, response body
- `test/controllers/mission_controller_test.rb` — 16 tests: auth, CRUD, status assignment, validation
- `test/controllers/clients_controller_test.rb` — client CRUD tests
- `test/controllers/profiles_controller_test.rb` — profile edit/update
- `test/system/dashboard_test.rb` — 11 system tests: page content, sidebar, Stimulus tab filter, progress bars
- `test/models/` — model tests for Mission, Step, Client, User, Profile, Document, DecisionLog, StepTemplate, GmailConnection, and lookup tables
