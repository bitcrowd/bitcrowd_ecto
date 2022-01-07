# BitcrowdEcto

This library contains Bitcrowd's collection of tiny Ecto helpers.

* `BitcrowdEcto.Schema` is our default schema template which configures PK/FKs and timestamp types, among other things.
* `BitcrowdEcto.Repo` contains extensions for Ecto repos, like `fetch/2`.
* `BitcrowdEcto.Changeset` contains mostly validators.
* `BitcrowdEcto.Assertions` has an assortment of useful ExUnit assertions related to Ecto schemas.
