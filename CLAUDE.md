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
bin/rails db:reset         # Drop, recreate, migrate

# Tests & CI
bin/rails test             # Run all tests
bin/ci                     # Full CI: rubocop + bundler-audit + brakeman + importmap audit + tests + seeds
bin/rubocop                # Ruby linting (Rails Omakase config)
bin/brakeman               # Security static analysis

# Single test
bin/rails test test/models/mission_test.rb
bin/rails test test/models/mission_test.rb:42
```

## Architecture

Vesta is a project management and client portal system for service providers (interior designers, architects, etc.). Suppliers manage missions (projects) for clients, tracking progress through customizable step templates, and share branded client portals for unauthenticated client access via `portal_token`.

**Tech stack:** Rails 8.1.3, Ruby 3.3.5, PostgreSQL, Bootstrap 5, Hotwire (Turbo + Stimulus), Importmap (no Node.js build step), Solid Suite (Cache/Queue/Cable replacing Redis).

### Domain model

```
User (Devise) → Profile (name, profession, logo_url)
User → Clients → Missions
User → StepTemplates → StepTemplateItems

Mission → belongs_to Client, MissionStatus, StepTemplate
Mission → Steps → Documents (file_url string, not Active Storage)
Mission → DecisionLogs (AI-generated summaries)

Step → belongs_to StepStatus
```

`MissionStatus` and `StepStatus` are lookup-table models (not enums), seeded with French values: *En attente / En cours / En révision / Terminée* and *À faire / En cours / Validée / Bloquée*.

### Key patterns

- **Portal token**: `Mission#portal_token` enables unauthenticated client access without user accounts.
- **File handling**: Documents use `file_url` string + `file_type`; Active Storage is not yet configured.
- **Authentication**: Devise with `database_authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable` (no confirmable/lockable yet).
- **Multi-DB (production)**: Separate PostgreSQL databases for primary, cache, queue, and cable — all configured via `DATABASE_URL`.

### Current routes

```ruby
devise_for :users
root to: "home#index"
get "up" => "rails/health#show"
```

Missions, Clients, StepTemplates, Steps, Documents, and portal access routes are not yet implemented.

### Styling

Stylesheets are organized under `app/assets/stylesheets/`:
- `config/` — Bootstrap overrides, fonts, colors
- `components/` — Reusable UI components (navbar, avatar, alerts, forms)
- `pages/` — Page-specific styles

### Testing

Uses Rails default TestUnit (no RSpec). Fixtures are disabled in generators. System tests exist but are commented out in the CI script.
