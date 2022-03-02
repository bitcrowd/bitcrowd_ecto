defmodule BitcrowdEcto.Migration do
  @moduledoc """
  Utilities for migrations.
  """

  @moduledoc since: "0.7.0"

  use Ecto.Migration

  @doc """
  This function grants data manipulation privileges to configured dmlroles for a given schema.

  See `grant_privileges_on_schema/3` for details and options.

  ## Usage

  The easiest way of using this is to issue the command after every `CREATE SCHEMA` call:

      def change do
        execute("CREATE SCHEMA foo;", "DROP SCHEMA foo;")

        if direction() == :up do
          BitcrowdEcto.Migration.grant_dml_privileges_on_schema("foo")
        end
      end

  ## Configuration

  In order to not repeat your roles in every schema-creating migration, roles are configured for
  the `:carbonite` OTP app and are read at runtime.

      config :carbonite, dmlroles: ["mydmlrole"]

  This can also be used to disarm this function in development, by passing an empty list.
  """
  @doc since: "0.7.0"
  @spec grant_dml_privileges_on_schema(binary(), keyword()) :: :ok
  def grant_dml_privileges_on_schema(schema, opts \\ []) do
    for dmlrole <- dmlroles() do
      grant_dml_privileges_on_schema(schema, dmlrole, opts)
    end

    :ok
  end

  @grants [
    "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES",
    "GRANT ALL ON ALL FUNCTIONS",
    "GRANT ALL ON ALL SEQUENCES"
  ]

  @default_grants [
    "GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES",
    "GRANT ALL ON FUNCTIONS",
    "GRANT ALL ON SEQUENCES"
  ]

  @doc """
  This function grants data manipulation privileges for a given schema to a given role.

  Use this when you have a setup where your "runtime" user is deprived of all DDL privileges
  (i.e., it can't create or modify tables, etc.), but your migration user is allowed to do so.

  In particular, the following GRANTS are executed:

      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES
      GRANT ALL ON ALL FUNCTIONS
      GRANT ALL ON ALL SEQUENCES

  ## Usage

  The easiest way of using this is to issue the command after every `CREATE SCHEMA` call:

      def change do
        execute("CREATE SCHEMA foo;", "DROP SCHEMA foo;")

        if direction() == :up do
          BitcrowdEcto.Migration.grant_dml_privileges_on_schema("foo", "mydmlrole")
        end
      end

  ## Options

  * `default`  boolean indicating whether the privileges should automatically be granted for
               future objects, defaults to true
  """
  @doc since: "0.7.0"
  @spec grant_dml_privileges_on_schema(binary(), binary(), keyword()) :: :ok
  def grant_dml_privileges_on_schema(schema, role, opts) do
    execute("GRANT USAGE ON SCHEMA #{schema} TO #{role};")

    for grant <- @grants do
      execute("#{grant} IN SCHEMA #{schema} TO #{role};")
    end

    if Keyword.get(opts, :default, true) do
      for grant <- @default_grants do
        execute("ALTER DEFAULT PRIVILEGES IN SCHEMA #{schema} #{grant} TO #{role};")
      end
    end

    :ok
  end

  defp dmlroles do
    Application.get_env(:bitcrowd_ecto, :dmlroles, [])
  end
end
