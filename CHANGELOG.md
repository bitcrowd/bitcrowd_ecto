<!-- SPDX-License-Identifier: Apache-2.0 -->

### Added

* Give `Repo.fetch_by/2`, `Repo.count/1`, and `Assertions.assert_count_difference/4` an optional  `opts` parameter that is forwarded to the underlying Ecto function. Useful to pass query options like `:prefix`.

## [0.14.0] - 2023-01-03

### Added

* Changed `Repo.fetch/2` and `Repo.fetch/3` to work with primary key with name other than `id`.

## [0.13.2] - 2022-12-19

* Add `error_tag` option to `BitcrowdEcto.Repo.fetch_by/3` and friends to allow overriding the queryable in the error result.

## [0.13.1] - 2022-09-21

### Fixed

* Fix dependency specifications by restoring the `:only` options and explicitly listing conflicting packages. See https://github.com/kipcole9/money/issues/142 for explanation.

## [0.13.0] - 2022-09-14

NOTE: 0.13.0 needed to be retired due to a corrupt dependency tree listing all dev/test dependencies as prod dependencies.

* Add `BitcrowdEcto.Changeset.validate_money/3` for validating `Money` values from `ex_money`, which is introduced as an optional dependency.

## [0.12.0] - 2022-06-21

### Added

* Add `BitcrowdEcto.DateTime.beginning_of_month/1`.
* Add `BitcrowdEcto.DateTime.beginning_of_last_month/1`.
* Add `BitcrowdEcto.DateTime.beginning_of_next_month/1`.
* Add `BitcrowdEcto.DateTime.beginning_of_yesterday/1`.
* Add `BitcrowdEcto.DateTime.beginning_of_tomorrow/1`.

## [0.11.0] - 2022-06-09

* Add `BitcrowdEcto.Changeset.validate_date_after/3` Validates a date field in the changeset is after the given reference date.
* Add `BitcrowdEcto.Changeset.validate_hex_color/2` validates a changeset field has hexadecimal color format.
* Add `BitcrowdEcto.Assertions.assert_changeset_valid/1`.
* Add `BitcrowdEcto.Assertions.refute_changeset_valid/1`.


## [0.10.0] - 2022-04-28

### Added

* New `BitcrowdEcto.Assertions.assert_*_constraint_on/2` matchers assert on constraints on changesets without going to the database.
* Add `BitcrowdEcto.DateTime.shift/2` and `BitcrowdEcto.DateTime.beginning_of_day/1`.

### Changed

* BREAKING: Stopped `inspect`ing the `from`/`to` fields in `validate_transition/3` error details. Previously atom columns (e.g. from `Ecto.Enum`) would result in `[from: ":foo", to: ":bar"]` error details, now these atoms are inserted unchanged as `[from: :foo, to: :bar]`
* BREAKING: Removed `:field` from `validate_transition/3` error details as it is redundant with the error field.
* Deprecated `BitcrowdEcto.Assertions.assert_foreign_constraint_error_on/2` in favour of new `assert_foreign_key_constraint_error_on/2`. Constraint assert functions are all called after the `Ecto.Changeset.*_constraint` functions now, not after internal error type names.

## [0.9.0] - 2022-03-25

### Added

* Add `BitcrowdEcto.Assertions.assert_change_to_almost_now/2` to assert that the value of a datetime field changed to the present time.

* Add `BitcrowdEcto.Schema.to_enum_member/3` and `BitcrowdEcto.Schema.to_enum_member!/3`, functions that safely convert a string to the member of an enum based on reflection on the given schema.

### Changed

* BREAKING: Add `:only_web` option to `BitcrowdEcto.Changeset.validate_email/3` that enforces a dot in the host part of the email address (e.g. `foo@example.net` is valid, `foo@example` is not). Defaults to **true**.

## [0.8.0] - 2022-03-03

### Changed

* BREAKING: Drop the `BitcrowdEcto.Migration.grant_dml_privileges_on_schema/2` variant that reads from a configuration variable. However, the keyword list on `grant_dml_privileges_on_schema/3` has become optional, so effectively there is a different `/2` now.

## [0.7.0] - 2022-03-02

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
