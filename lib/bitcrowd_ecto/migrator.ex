defmodule BitcrowdEcto.Migrator do
  @moduledoc """
  Release migration logic for repositories.

  Can deal with normal repositories & multi-tenant repositories.

  ## Usage

  In the simplest case, add the Migrator to your repository:

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres

        use BitcrowdEcto.Migrator
      end

  and call the migrator from your release:

      bin/my_app eval 'MyApp.Repo.up()'

  ### Multi-Tenant repositories

  For multi-tenant repositories, you need to provide a list of tenants (= PG schemas) by
  overriding the `known_prefixes/0` function on your repository:

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Postgres

        use BitcrowdEcto.Migrator

        def known_prefixes do
          ["tenant_a", "tenant_b"]
        end
      end

  This will make the migrator apply migrations from the `priv/repo/tenant_migrations` directory
  onto schemas `tenant_a` and `tenant_b`. The schemas will be created if necessary.

  ### Mix tasks for development

  In normal development without multi-tenancy, the usual Ecto mix tasks will work just fine.

  When using tenant schemas, the normal Ecto mix tasks will only apply the "global" (i.e.
  non-prefixed migrations) from `priv/repo/migrations`, which is not enough. You can define
  your own Mix tasks calling the `up/0` and `down/1` functions on your repository:

      defmodule Mix.Tasks.MyApp.Migrate do
        use Mix.Task

        @shortdoc "Migrates our repository"
        @moduledoc "Migrates the repository including the tenant schemas"

        @impl true
        def run(args) do
          Mix.Task.run("app.config", args)

          MyApp.Repo.up()
        end
      end
  """

  require Logger
  alias Ecto.Adapters.SQL
  alias Ecto.Migrator

  defmacro __using__(_) do
    quote do
      @doc """
      Returns the list of prefixes used on this repository.
      """
      @spec known_prefixes :: [String.t()]
      def known_prefixes, do: []

      @doc """
      Migrates both the "main" (i.e. non-tenant) schemas/tables and the tenant schemas to their
      latest version.
      """
      @spec up() :: :ok
      def up do
        BitcrowdEcto.Migrator.up(__MODULE__)
      end

      @doc """
      Rolls back both the main schemas/tables and the tenant schemas to a given version.
      """
      @spec down(to :: non_neg_integer()) :: :ok
      def down(to) when is_integer(to) do
        BitcrowdEcto.Migrator.down(__MODULE__, to)
      end

      defoverridable known_prefixes: 0
    end
  end

  @doc false
  @spec up(repo :: module()) :: :ok
  def up(repo) do
    boot(repo)

    retry_when_no_connection(fn ->
      {:ok, _, _} =
        Migrator.with_repo(repo, fn repo ->
          Migrator.run(repo, :up, all: true)

          for tenant <- repo.known_prefixes() do
            ensure_schema!(repo, tenant)
            Migrator.run(repo, tenant_migrations_path(repo), :up, all: true, prefix: tenant)
          end
        end)
    end)

    :ok
  end

  @doc false
  @spec down(repo :: module(), to :: non_neg_integer()) :: :ok
  def down(repo, to) when is_integer(to) do
    boot(repo)

    {:ok, _, _} =
      Migrator.with_repo(repo, fn repo ->
        for tenant <- repo.known_prefixes() do
          Migrator.run(repo, tenant_migrations_path(repo), :down, prefix: tenant, to: to)
        end

        Migrator.run(repo, :down, to: to)
      end)

    :ok
  end

  defp boot(repo) do
    :ok =
      repo.config()
      |> Keyword.fetch!(:otp_app)
      |> Application.ensure_loaded()
  end

  defp retry_when_no_connection(n \\ 5, callback)
  defp retry_when_no_connection(1, callback), do: callback.()

  defp retry_when_no_connection(n, callback) do
    callback.()
  rescue
    DBConnection.ConnectionError ->
      Logger.info("Caught DBConnection.ConnectionError, retrying in 5s...")
      :timer.sleep(5000)
      retry_when_no_connection(n - 1, callback)
  end

  defp tenant_migrations_path(repo) do
    repo
    |> Migrator.migrations_path()
    |> Path.join("../tenant_migrations")
    |> Path.expand()
  end

  @exists_query """
  SELECT 1 FROM information_schema.schemata WHERE schema_name = $1;
  """

  defp ensure_schema!(repo, tenant) do
    unless match?(%{rows: [[1]]}, SQL.query!(repo, @exists_query, [tenant])) do
      SQL.query!(repo, ~s(CREATE SCHEMA "#{tenant}"), [])
    end
  end
end
