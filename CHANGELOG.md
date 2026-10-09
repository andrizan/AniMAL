## [2.9.0] - 2026-10-09

### Bug Fixes

- Chunk genre lookups and batch list writes
- Fetch complete user lists instead of the first 100 entries
- Stop caching a one-item list for never-fetched statuses
- Stop leaking unhandled errors from in-flight cleanup
- Keep the stored week in sync with list edits
- Keep scroll position when an edit reloads a page

### Chores

- Bump version to 2.8.0+11 [skip ci]

### Documentation

- Document list edit and reload rules

### Features

- Refresh anilist airing schedule on list refresh
- Refresh anilist airing schedule on list pull-to-refresh

### Performance

- Run airing and user list refresh in parallel
- Apply list mutations in a single sql transaction
- Log request and response bodies lazily
- Drop unused description from the schedule query
- Batch airing schedule writes
- Fetch schedule pages in parallel waves
- Share list refresh and run pull-to-refresh in parallel
- Open the database and init notifications in parallel
- Bundle Inter and drop the inert Noto Sans JP fallback
## [2.8.0] - 2026-10-06

### Bug Fixes

- Show full week schedule including aired episodes

### Chores

- Bump version to 2.7.2+10 [skip ci]

### Documentation

- Describe cache-first fetching without background refresh

### Other

- Merge branch 'main' of https://github.com/andrizan/AniMAL
## [2.7.2] - 2026-10-06

### Bug Fixes

- Fetch only on explicit refresh, sqlite first

### Chores

- Bump version to 2.7.1+9 [skip ci]

### Documentation

- Require conventional commit messages

### Other

- Minimize AniList API fetches with SQLite-first caching
## [2.7.1] - 2026-10-05

### Chores

- Bump version to 2.7.0+8 [skip ci]

### Other

- Align analyze flags between quality and release workflows
- Fix AniList rate limit from repeated fetching on home and airing pages
## [2.7.0] - 2026-10-05

### Bug Fixes

- Update Flutter version to 3.47.6 in release workflow

### Chores

- Bump version to 2.6.5+7 [skip ci]
- Update Flutter version to 3.47.6 in quality workflow

### Other

- Add refresh button to airing page and prevent empty schedule overwrite
- Update dependencies and improve list, image, and countdown performance
- Remove deprecated MaterialUiCompatibilityBridge from app builder
- Add refresh button to home tab toolbar
- Include NSFW entries in MAL API requests
- Add git-cliff release notes and changelog to release workflow
- Fix analyzer infos in local cache tests
- Format lib with dart format
## [2.6.5] - 2026-09-02

### Bug Fixes

- Merge partial API responses into SQLite instead of replacing
- Serve stored data after invalidation and propagate background refreshes
- Raise compileSdk to 37 for flutter_secure_storage 11.x

### Chores

- Bump version to 2.6.4+6 [skip ci]
- Upgrade freezed to 4.0.1
- Move ignore comment above the deprecation diagnostic
## [2.6.4] - 2026-08-30

### Bug Fixes

- Make countdown mandatory for airing anime and translate comments to English

### Chores

- Bump version to 2.6.3+5 [skip ci]
## [2.6.3] - 2026-08-30

### Bug Fixes

- Resolve malId for badge via title fallback
- Restore airing data for other days and seasonal current
- Ensure no page is empty

### Chores

- Bump version to 2.6.2+4 [skip ci]
## [2.6.2] - 2026-08-30

### Bug Fixes

- Keep airing badges visible after refresh
- Persist characters and staff correctly
- Make user list and user info SWR with stale fallback
- Prune merged entries and fix schedule window
- Use UTC consistently for airing times
- Use UTC for initial tab to match UTC schedule window
- Persist accurate nextAiring for synthetic
- Handle hiatus correctly and add character cache test

### Chores

- Bump version to 2.6.1+3 [skip ci]
- Extend airing_schedule prune to 14d for synthetic window

### Documentation

- Update cache table to reflect SWR and 14d retention

### Features

- Live refresh airing countdown every minute

### Performance

- Batch getAnimeList in parallel with Future.wait
- Make airing providers autoDispose and clock efficient
## [2.6.1] - 2026-08-30

### Bug Fixes

- Show countdown to next episode and fix home sorting

### Chores

- Bump version to 2.6.0+2 [skip ci]

### Documentation

- Clarify physical sqlite retention vs cache TTL
## [2.6.0] - 2026-08-28

### Bug Fixes

- Force logout when MAL refresh token is rejected
- Prevent infinite loading on home
- Stabilize sqlite cache and fix home list refresh
- Update analysis options to exclude generated files from analysis
- Enhance build conditions and maintain quality checks

### CI

- Restructure release workflow into quality + build + release jobs
- Make build job independent of quality check failures
- Bind build job to build-config environment for signing secrets

### Chores

- Remove outdated AUDIT.md file

### Documentation

- Rewrite README with proper project documentation

### Features

- Add API Status section with health tracker
- Migrate all in-memory caches to persistent SQLite

### Other

- Upgrade to Flutter 3.47 and adopt standalone material_ui package
- Format with dart format
## [2.5.6] - 2026-07-03

### Bug Fixes

- Preserve scroll position on detail page after mutations and on home page when returning from detail
- Add removal animation to AnimeCard when changing list status
- Crash from ref after Navigator.pop, enable card dismiss animation
- Update package versions and sha256 checksums in pubspec.lock

### Other

- Remove broken dismiss animation, restore original _save flow
## [2.5.5] - 2026-07-02

### Bug Fixes

- Episode counter in detail page for anime with unknown total
## [2.5.4] - 2026-06-25

### Bug Fixes

- Allow editing episode count for anime with unknown total episodes
## [2.5.3] - 2026-06-25

### Bug Fixes

- Completed auto-sets episodes, status propagates to calendar/airing/search
- Tapping an airing notification opens the anime detail page
- Push notification

### Features

- Enhance OAuth flow and state management
- Implement basic authentication header for API requests and remove unused crypto dependency
## [2.5.2] - 2026-06-24

### Bug Fixes

- Add SnackBar feedback, remove button in modal, and list sync from detail page
## [2.5.1] - 2026-06-24

### Bug Fixes

- Target user list invalidation and capture MyListStatus from update
## [2.5.0] - 2026-06-23

### Bug Fixes

- Use studio logo image, follow staff page SliverAppBar pattern
- Propagate my_list_status to all pages (search, seasonal, ranking, airing)
- Stabilize animeListProvider key, fix import ordering, remove dead code, add color rule
- Import ordering, replace Logger() with appLogger, remove duplicate provider
- AiringRepository now uses AnimeRepository for shared cache, update audit
- Lift auth providers to core, lift airingByMalIdProvider to shared, 34/37 audit fixed
- Use StatefulShellRoute for home tab composition, 35/37 audit fixed
- Remove @freezed from ApiException, extract GitHub check to core utility, 37/37 audit done
- Resolve AUDIT.md findings (8 HIGH, 9 MEDIUM, 7 LOW)
- Resolve audit findings (4 HIGH, 4 MEDIUM) and update AUDIT.md
- Resolve remaining audit findings (MEDIUM/LOW) and track AUDIT.md
- Resolve remaining LOW audit items (L7, L10, L11, L12)

### CI

- Optimize release APK build with Gradle/pub caches

### Code Refactoring

- Rename files per AGENTS.md naming conventions, move providers to correct layer
- Extract AniList models, unify InfoChip widget, fix TextEditingController leak, create layer dirs
- Lift AiringEntry to shared, fix route error feedback, update audit

### Features

- Add airing dates, season, episode duration, and studios to anime detail page
- Switch studios to AniList API, add studio detail page with tappable cards
- Studio page with full MAL data via AnimeCard, fix AniList query errors
- Add list status badge to AnimeCard, use AnimeCard on staff/character pages

### Other

- Fix remaining import ordering, move AuthToken to shared, finalize AUDIT.md — 0 violations
- Remove unused extensions, models, and widget files to clean up the codebase
## [2.0.0] - 2026-06-23

### Chores

- Update app_links and flutter_dotenv dependencies to latest versions
- Bump version to 2.0.0

### Code Refactoring

- Remove dead code, fix hardcoded values, move providers to correct dirs, lift shared providers
- Remove ProfileRepositoryImpl implementation

### Features

- Make alternative titles selectable/copyable
- Add share button to anime detail, remove desktop support
- Add anime airing notification system

### Other

- Phase 1
- Phase 2
- Phase 3
- Phase 4
- Dart format lib/ + update AGENTS.md rate-limit & formatting rules

### Performance

- Add in-memory caching + search debounce to minimize API rate limits
## [1.2.0] - 2026-06-23

### Features

- GitHub link, check for update, dynamic version from pubspec
## [1.1.1] - 2026-06-23

### Bug Fixes

- Make VA/staff names selectable in profile pages
## [1.1.0] - 2026-06-23

### Features

- Persist sort prefs, add airing filter, make text selectable
- Default dark theme, remove system option, use switch toggle
## [1.0.0] - 2026-06-22

### Bug Fixes

- Correct directory name in clone instructions
- Update clone instructions with correct repository URL and directory name
- Handle 404 & show media type
- Update package and bundle identifiers to use com.andrizan.animal
- Use unified AnimeCard on search page
- Improve AniList error logging
- Use date-range queries for AniList schedule and pass Japanese title to cards
- Add INTERNET permission
- Import java.util.Properties in build.gradle.kts

### CI

- Add GitHub Actions workflow to build APK on release tag
- Create .env from GitHub Secrets during build
- Add contents:write permission for release creation
- Rename release APK to animal-{version}.apk
- Add release signing with keystore

### Chores

- Fix flutter analyze issues (81 -> 3)
- Cleanup unused schedule files and dependencies
- Add environment configuration for build job

### Features

- Update anime cards & airing
- Next episode countdown
- External links section
- Next episode badge
- Sort by airing time
- Theme settings (system/light/dark)
- Custom app icon & name AniMAL
- Persist theme setting

### Other

- Initial commit
- Initial commit

### Performance

- Merge AniList calls
- Reduce API calls & add autoDispose
