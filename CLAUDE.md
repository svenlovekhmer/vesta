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
bin/rails test             # Run all tests (controller + system)
bin/rails test test/controllers/dashboard_controller_test.rb
bin/rails test test/system/dashboard_test.rb
bin/rails test test/models/mission_test.rb:42   # Single test at line
bin/ci                     # Full CI: rubocop + bundler-audit + brakeman + importmap audit + tests + seeds
bin/rubocop                # Ruby linting (Rails Omakase config)
bin/brakeman               # Security static analysis
```

## Architecture

Vesta is a project management and client portal system for service providers (interior designers, architects, etc.). Providers manage missions (projects) for clients, tracking progress through customizable step templates. Clients get a branded portal via `portal_token` for unauthenticated access.

**Tech stack:** Rails 8.1.3, Ruby 3.3.5, PostgreSQL, Bootstrap 5.3, Hotwire (Turbo + Stimulus), Importmap (no Node.js build step), Solid Suite (Cache/Queue/Cable replacing Redis).

### Domain model

```
User (Devise) → Profile (first_name, last_name, profession, logo_url)
User → Clients → Missions
User → StepTemplates → StepTemplateItems

Mission → belongs_to Client, MissionStatus, StepTemplate
Mission → Steps → Documents (file_url string, not Active Storage)
Mission → DecisionLogs

Step → belongs_to StepStatus
```

`MissionStatus` and `StepStatus` are lookup-table models (not enums), seeded with French values:
- MissionStatus: *En attente / En cours / En révision / Terminée*
- StepStatus: *À faire / En cours / Validée / Bloquée*

### Key patterns

- **Portal token**: `Mission#portal_token` enables unauthenticated client access without user accounts.
- **File handling**: Documents use `file_url` string + `file_type`; Active Storage is not configured.
- **Authentication**: Devise with `database_authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable`.
- **Multi-DB (production)**: Separate PostgreSQL databases for primary, cache, queue, and cable — all configured via `DATABASE_URL`.
- **Progress calculation**: percentage of steps whose `step_status.title == "Validée"` over total steps. Computed in views, not stored.
- **Status slugs**: always use `.parameterize` to generate CSS class suffixes from French status titles — never manual gsub. `"Terminée".parameterize` → `"terminee"`, `"En révision".parameterize` → `"en-revision"`.

### Routes

```ruby
devise_for :users
root to: "dashboard#index"
resources :missions, only: [:index]
get "up" => "rails/health#show"
```

### Current features

**Dashboard** (`/`) — requires authentication (`before_action :authenticate_user!`)
- Stats row: active mission count, blocked steps count, missions awaiting client, client count
- Mission table: client avatar (initials), progress bar, status badge
- Client-side tab filter (Toutes / En cours / Terminées) via Stimulus `mission-filter` controller
- Sidebar with VESTA logo, nav links, user profile (name + profession from `Profile`)

### Styling

Stylesheets under `app/assets/stylesheets/`:
- `config/` — `_colors.scss` (`$red`, `$blue`, `$yellow`, `$orange`, `$green`, `$gray`, `$light-gray`), `_fonts.scss`, `_bootstrap_variables.scss`
- `components/` — `_sidebar.scss` (`.app-layout`, `.app-sidebar`, `.app-main`), `_navbar.scss`, `_avatar.scss`, `_alert.scss`
- `pages/` — `_dashboard.scss` (stat cards, mission table, progress bars, status badges), `_home.scss`

**Bootstrap CSS variable pattern for progress bars:** set `--bs-progress-bar-bg: #{$scss-variable}` on modifier classes (e.g. `.missions-progress__bar--full`), not `background-color`. The `.missions-progress` container must be `display: inline-flex` (not `inline-block`) — Bootstrap's `.progress-bar` child gets its height from the flex context; `inline-block` collapses it to `0px`.

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
- `create_mission_for(user, title:, status_title:, created_at:)` — builds a complete mission (status, template, client, mission) for a given user
- `teardown` prints `✓ PASS` / `✗ FAIL` + test name after every test
- `ActionDispatch::IntegrationTest.include Devise::Test::IntegrationHelpers` — enables `sign_in` in controller tests

**`test/application_system_test_case.rb`**:
- Driver: `selenium, using: :headless_chrome, screen_size: [1400, 900]`
- `login_as(user)` — navigates to the Devise login form and submits it

**Test files:**
- `test/controllers/dashboard_controller_test.rb` — 9 integration tests: auth redirect, data isolation per user, stats counts, ordering, response body content
- `test/system/dashboard_test.rb` — 11 system tests: page content, sidebar, Stimulus tab filter (JS), progress bar display
