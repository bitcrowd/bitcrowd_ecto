<!-- SPDX-License-Identifier: Apache-2.0 -->

# BitcrowdEcto

<!-- MDOC -->

This library contains Bitcrowd's collection of tiny Ecto helpers.

* `BitcrowdEcto.Schema` is our default schema template which configures PK/FKs and timestamp types, among other things.
* `BitcrowdEcto.Repo` contains extensions for Ecto repos, like `fetch/2`.
* `BitcrowdEcto.Migrator` contains a tool for migrating from within releases.
* `BitcrowdEcto.Changeset` contains mostly validators.
* `BitcrowdEcto.DateTime` contains date/time helpers.
* `BitcrowdEcto.Assertions` has an assortment of useful ExUnit assertions related to Ecto schemas.
* `BitcrowdEcto.Random` contains functions that generate random tokens.

<!-- MDOC -->
