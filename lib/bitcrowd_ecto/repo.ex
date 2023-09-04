# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.Repo do
  @moduledoc """
  Extensions for Ecto repos.

  ## Usage

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres

        use BitcrowdEcto.Repo
      end
  """

  @moduledoc since: "0.1.0"

  import Ecto.Query, only: [lock: 2, preload: 2, where: 3]
  alias Ecto.Adapters.SQL

  @type lock_mode :: :no_key_update | :update

  @type fetch_option ::
          {:lock, lock_mode | false}
          | {:preload, atom | list}
          | {:error_tag, any}
          | {:raise_cast_error, boolean()}
          | ecto_option

  @type fetch_result :: {:ok, Ecto.Schema.t()} | {:error, {:not_found, Ecto.Queryable.t() | any}}

  @ecto_options [:prefix, :timeout, :log, :telemetry_event, :telemetry_options]

  @type ecto_option ::
          {:prefix, binary}
          | {:timeout, integer | :infinity}
          | {:log, Logger.level() | false}
          | {:telemetry_event, any}
          | {:telemetry_options, any}

  @doc """
  Fetches a record by primary key or returns a "tagged" error tuple.

  See `c:fetch_by/3`.
  """
  @doc since: "0.1.0"
  @callback fetch(schema :: module, id :: any) :: fetch_result()

  @doc """
  Fetches a record by given clauses or returns a "tagged" error tuple.

  See `c:fetch_by/3` for options.
  """
  @doc since: "0.1.0"
  @callback fetch(schema :: module, id :: any, [fetch_option()]) :: fetch_result()

  @doc """
  Fetches a record by given clauses or returns a "tagged" error tuple.

  See `c:fetch_by/3` for options.
  """
  @doc since: "0.1.0"
  @callback fetch_by(queryable :: Ecto.Queryable.t(), clauses :: map | keyword) :: fetch_result()

  @doc """
  Fetches a record by given clauses or returns a "tagged" error tuple.

  - On success, the record is wrapped in a `:ok` tuple.
  - On error, a "tagged" error tuple is returned that contains the *original* queryable or module
    as the tag, e.g. `{:error, {:not_found, Account}}` for a `fetch_by(Account, id: 1)` call.

  Passing invalid values that would normally result in an `Ecto.Query.CastError` will result in
  a `:not_found` error tuple as well.

  This function can also apply row locks.

  ## Options

  * `lock`               any of `[:no_key_update, :update]` (defaults to `false`)
  * `preload`            allows to preload associations
  * `error_tag`          allows to specify a custom "tag" value (instead of the queryable)
  * `raise_cast_error`   raise `CastError` instead of converting to `:not_found` (defaults to `false`)

  ## Ecto options

  * `prefix`             See https://hexdocs.pm/ecto/Ecto.Repo.html#c:one/2-options
  * `timeout`            See [Ecto's Shared Options](https://hexdocs.pm/ecto/Ecto.Repo.html#module-shared-options)
  * `log`                See [Ecto's Shared Options](https://hexdocs.pm/ecto/Ecto.Repo.html#module-shared-options)
  * `telemetry_event`    See [Ecto's Shared Options](https://hexdocs.pm/ecto/Ecto.Repo.html#module-shared-options)
  * `telemetry_options`  See [Ecto's Shared Options](https://hexdocs.pm/ecto/Ecto.Repo.html#module-shared-options)
  """
  @doc since: "0.1.0"
  @callback fetch_by(queryable :: Ecto.Queryable.t(), clauses :: map | keyword, [fetch_option()]) ::
              fetch_result()

  @doc """
  Allows to conveniently count a queryable.

  See `c:count/2` for options.
  """
  @doc since: "0.1.0"
  @callback count(queryable :: Ecto.Queryable.t()) :: non_neg_integer

  @doc """
  Allows to conveniently count a queryable.

  ## Ecto options

  * `prefix`             See https://hexdocs.pm/ecto/Ecto.Repo.html#c:one/2-options
  * `timeout`            See [Ecto's Shared Options](https://hexdocs.pm/ecto/Ecto.Repo.html#module-shared-options)
  * `log`                See [Ecto's Shared Options](https://hexdocs.pm/ecto/Ecto.Repo.html#module-shared-options)
  * `telemetry_event`    See [Ecto's Shared Options](https://hexdocs.pm/ecto/Ecto.Repo.html#module-shared-options)
  * `telemetry_options`  See [Ecto's Shared Options](https://hexdocs.pm/ecto/Ecto.Repo.html#module-shared-options)
  """
  @doc since: "0.15.0"
  @callback count(queryable :: Ecto.Queryable.t(), [ecto_option()]) :: non_neg_integer

  @doc """
  Acquires an advisory lock for a named resource.

  Advisory locks are helpful when you don't have a specific row to lock, but also don't want
  to lock an entire table.

  See https://www.postgresql.org/docs/9.4/explicit-locking.html#ADVISORY-LOCKS

  ## Example

      MyApp.Repo.transaction(fn ->
        MyApp.Repo.advisory_lock(:foo)
        # Advisory lock is held until end of transaction
      end)

  ## A note on the advisory lock key

  `pg_advisory_xact_lock()` has two versions: One which you pass a 64-bit signed integer as
  the lock key, and one which you pass two 32-bit integers as the keys (e.g., one
  "application" key and one specific lock key), in which case PostgreSQL concatenates them
  into a 64-bit value. In any case you need to pass integers.

  We decided that we wanted to have atom or string keys for better readability.  Hence, in=
  order to make PostgreSQL happy, we hash these strings into 64 bits signed ints.

  64 bits make a pretty big number already, so it is quite unlikely that two of our keys (or
  keys of other libraries that use advisory locks, e.g. Oban) collide. But for an extra false
  sense of safety we use a crypto hash algorithm to ensure that keys spread out over the
  domain uniformly. Luckily, taking a prefix of a cryptographic hash does not break its
  uniformity.
  """
  @doc since: "0.1.0"
  @callback advisory_xact_lock(atom | binary) :: :ok

  defmacro __using__(_) do
    quote do
      alias BitcrowdEcto.Repo, as: BER

      @behaviour BER

      @impl BER
      def fetch(module, id, opts \\ []) when is_atom(module) do
        BER.fetch(__MODULE__, module, id, opts)
      end

      @impl BER
      def fetch_by(queryable, clauses, opts \\ []) do
        BER.fetch_by(__MODULE__, queryable, clauses, opts)
      end

      @impl BER
      def count(queryable, opts \\ []) do
        BER.count(__MODULE__, queryable, opts)
      end

      @impl BER
      def advisory_xact_lock(name) do
        BER.advisory_xact_lock(__MODULE__, name)
      end
    end
  end

  @doc false
  @spec fetch(module, module, any, keyword) :: fetch_result
  def fetch(repo, module, id, opts) when is_atom(module) do
    case module.__schema__(:primary_key) do
      [pk] ->
        repo.fetch_by(module, [{pk, id}], opts)

      pks ->
        raise ArgumentError,
              "BitcrowdEcto.Repo.fetch/4 requires the schema #{inspect(module)} " <>
                "to have exactly one primary key, got: #{inspect(pks)}"
    end
  end

  @doc false
  @spec fetch_by(module, Ecto.Queryable.t(), map | keyword, keyword) :: fetch_result
  def fetch_by(repo, queryable, clauses, opts \\ []) do
    query =
      queryable
      |> where([], ^Enum.to_list(clauses))
      |> maybe_apply_lock(opts)
      |> maybe_preload(opts)

    result =
      maybe_rescue_cast_error(opts, fn ->
        repo.one(query, Keyword.take(opts, @ecto_options))
      end)

    case result do
      nil -> {:error, {:not_found, Keyword.get(opts, :error_tag, queryable)}}
      value -> {:ok, value}
    end
  end

  defp maybe_apply_lock(queryable, opts) do
    case Keyword.get(opts, :lock, false) do
      :no_key_update ->
        lock(queryable, "FOR NO KEY UPDATE")

      :update ->
        lock(queryable, "FOR UPDATE")

      disabled when disabled in [nil, false] ->
        queryable

      other ->
        raise("unknown lock mode #{inspect(other)}")
    end
  end

  defp maybe_preload(queryable, opts) do
    if preload = Keyword.get(opts, :preload) do
      preload(queryable, ^preload)
    else
      queryable
    end
  end

  defp maybe_rescue_cast_error(opts, callback) do
    if Keyword.get(opts, :raise_cast_error, false) do
      callback.()
    else
      try do
        callback.()
      rescue
        Ecto.Query.CastError -> nil
      end
    end
  end

  @doc false
  @spec count(module, Ecto.Queryable.t(), keyword) :: non_neg_integer
  def count(repo, queryable, opts) do
    repo.aggregate(queryable, :count, opts)
  end

  @doc false
  def advisory_xact_lock(repo, name) do
    <<advisory_lock_key::signed-integer-64, _rest::binary>> = :crypto.hash(:sha, name)
    SQL.query!(repo, "SELECT pg_advisory_xact_lock($1);", [advisory_lock_key])
    :ok
  end
end
