<!-- SPDX-License-Identifier: Apache-2.0 -->

## Unreleased

### Changed

* BREAKING: Drop the `BitcrowdEcto.Migration.grant_dml_privileges_on_schema/2` variant that reads from a configuration variable. However, the keyword list on `grant_dml_privileges_on_schema/3` has become optional, so effectively there is a different `/2` now.

## [0.7.0] - 2022-03-2

### Added

* Add `BitcrowdEcto.Migration` for migration utilities, first util is `grant_dml_privileges_on_schema/2` that `GRANT`s certain privileges to a Postgres role.

## [0.6.0] - 2022-02-10

### Added

* Add `BitcrowdEcto.Random` containing various random token generators.
* Add `validate_past_datetime/3`, `validate_future_datetime/3`, `validate_datetime_after/4`, `validate_date_order/4`, `validate_datetime_order/4` and `validate_order/5` to `BitcrowdEcto.Changeset`.

## [0.5.0] - 2022-02-04

### Added

* Add `Migrator.ensure_up!/0` to check whether all migrations are up.

## [0.4.0] - 2022-01-28

### Added

* Add `handle_migrator_exception/2` callback to `Migrator` to allow exception reporting.

## [0.3.1] - 2022-01-17

### Added

* Add missing `assert_sorted_equal/3`.

## [0.3.0] - 2022-01-17

### Added

* Add `assert_almost_now/1`, `assert_almost_coincide/3` and `assert_sorted_equal/2` to `BitcrowdEcto.Assertions`.

## [0.2.0] - 2022-01-17

### Added

* Add `BitcrowdEcto.DateTime.in_seconds/1`.

## [0.1.0] - 2022-01-07

Initial release to the public 🎉
