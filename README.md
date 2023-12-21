<!-- SPDX-License-Identifier: Apache-2.0 -->

# BitcrowdEcto

<!-- MDOC -->

This library contains Bitcrowd's collection of tiny Ecto helpers.

* `BitcrowdEcto.Schema` is our default schema template which configures PK/FKs and timestamp types, among other things.
* `BitcrowdEcto.Repo` contains extensions for Ecto repos, like `fetch/2`.
* `BitcrowdEcto.Migrator` contains a tool for migrating from within releases.
* `BitcrowdEcto.Migration` contains functions used in migrations.
* `BitcrowdEcto.Changeset` contains mostly validators, plus the introspection-based `cast_all/3`.
  - The `validate_money/3` validator is enabled when you add `ex_money` as a dependency to your project. Note that you need to recompile `bitcrowd_ecto` when you add `ex_money` later.
* `BitcrowdEcto.DateTime` contains date/time helpers.
* `BitcrowdEcto.Assertions` has an assortment of useful ExUnit assertions related to Ecto schemas.
* `BitcrowdEcto.Random` contains functions that generate random tokens.

<!-- MDOC -->

## Steps to release

* Replace the version number in `mix.exs`
* Set version number & date in `CHANGELOG.md`
* Commit, push and open a PR for your release
* When the PR is merged:

```
git tag -a 'vX.X.X'
git push --tags
mix hex.publish
```

