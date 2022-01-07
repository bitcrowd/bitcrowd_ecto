defmodule BitcrowdEcto.Repo do
  @moduledoc """
  Extensions for Ecto repos.

  ## Usage

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres

        use BitcrowdEcto.Repo
      end
  """

  import Ecto.Query, only: [from: 2, lock: 2, preload: 2, where: 3]
  alias Ecto.Adapters.SQL

  defmacro __using__(_) do
    quote do
      alias BitcrowdEcto.Repo, as: BER

      @doc """
      Fetches a record by ID or returns a "tagged" error tuple.

      See `fetch_by/3` for options.
      """
      @spec fetch(module, binary) :: BER.fetch_result()
      @spec fetch(module, binary, keyword) :: BER.fetch_result()
      def fetch(module, id, opts \\ []) when is_atom(module) and is_binary(id) do
        BER.fetch(__MODULE__, module, id, opts)
      end

      @doc """
      Fetches a record by given clauses or returns the result wrapped in an ok tuple.

      On error, a "tagged" error tuple is returned that contains the *original* queryable or module
      as the tag, e.g. `{:error, {:not_found, Account}}` for a `fetch_by(Account, id: 1)` call.

      This function can also apply row locks.

      ## Options

      * `lock`    any of `[:no_key_update, :update]` (defaults to `false`)
      * `preload` allows to preload associations
      """
      @spec fetch_by(Ecto.Queryable.t(), map | keyword) :: BER.fetch_result()
      @spec fetch_by(Ecto.Queryable.t(), map | keyword, keyword) :: BER.fetch_result()
      def fetch_by(queryable, clauses, opts \\ []) do
        BER.fetch_by(__MODULE__, queryable, clauses, opts)
      end

      @doc """
      Allows to conveniently count a queryable.
      """
      @spec count(Ecto.Queryable.t()) :: non_neg_integer
      def count(queryable) do
        BER.count(__MODULE__, queryable)
      end

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
      @spec advisory_xact_lock(atom | binary) :: :ok
      def advisory_xact_lock(name) do
        BER.advisory_xact_lock(__MODULE__, name)
      end
    end
  end

  @type fetch_result :: {:ok, Ecto.Schema.t()} | {:error, {:not_found, Ecto.Queryable.t()}}
  @type lock_mode :: :no_key_update | :update

  @doc false
  @spec fetch(module, module, binary, keyword) :: fetch_result
  def fetch(repo, module, id, opts) when is_atom(module) and is_binary(id) do
    repo.fetch_by(module, [id: id], opts)
  end

  @doc false
  @spec fetch_by(module, Ecto.Queryable.t(), map | keyword, keyword) :: fetch_result
  def fetch_by(repo, queryable, clauses, opts \\ []) do
    queryable
    |> where([], ^Enum.to_list(clauses))
    |> maybe_apply_lock(opts)
    |> maybe_preload(opts)
    |> repo.one()
    |> ok_tuple_or_not_found_error(queryable)
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

  defp ok_tuple_or_not_found_error(nil, error_tag), do: {:error, {:not_found, error_tag}}
  defp ok_tuple_or_not_found_error(value, _error_tag), do: {:ok, value}

  @doc false
  @spec count(module, Ecto.Queryable.t()) :: non_neg_integer
  def count(repo, queryable) do
    queryable
    |> from(select: count())
    |> repo.one!()
  end

  @doc false
  def advisory_xact_lock(repo, name) do
    <<advisory_lock_key::signed-integer-64, _rest::binary>> = :crypto.hash(:sha, name)
    SQL.query!(repo, "SELECT pg_advisory_xact_lock($1);", [advisory_lock_key])
    :ok
  end
end
