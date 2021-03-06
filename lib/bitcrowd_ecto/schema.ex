# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.Schema do
  @moduledoc """
  An opinionated set of defaults for Ecto schemas.

  * Uses `Ecto.Schema` and imports `Ecto.Changeset` and `BitcrowdEcto.Changeset`
  * Configures an autogenerated PK of type `binary_id`
  * Configures FKs to be of type `binary_id`
  * Sets timestamp type to `utc_datetime_usec`
  * Defines a type `t` as a struct of the schema module.
  * Defines an `id` type

  ## Usage

      defmodule MyApp.MySchema do
        use BitcrowdEcto.Schema
      end

  Or if you table lives in a different Postgres schema:

      defmodule MyApp.MySchema do
        use BitcrowdEcto.Schema, prefix: "foo"
      end
  """

  @moduledoc since: "0.1.0"

  defmacro __using__(opts) do
    schema_prefix =
      if prefix = Keyword.get(opts, :prefix) do
        quote do
          @schema_prefix unquote(prefix)
        end
      end

    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import BitcrowdEcto.Changeset

      unquote(schema_prefix)

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]

      @type t :: %__MODULE__{}
      @type id :: binary
    end
  end

  @doc """
  Safely converts a string into an enum member atom. Returns nil if conversion is not posssible.

  ## Example

      iex> to_enum_member(TestEnumSchema, :some_enum, "foo")
      :foo
  """
  @doc since: "0.9.0"
  @spec to_enum_member(schema :: module, field :: atom, value :: any) :: term | nil
  def to_enum_member(schema, field, value) when is_atom(value) do
    to_enum_member(schema, field, to_string(value))
  end

  def to_enum_member(schema, field, value) do
    schema
    |> Ecto.Enum.mappings(field)
    |> Enum.find_value(fn {member, member_mapping} ->
      if value == member_mapping, do: member
    end)
  end

  @doc """
  Safely converts a string into an enum member atom. Raises if conversion is not possible.
  """
  @doc since: "0.9.0"
  @spec to_enum_member!(schema :: module, field :: atom, value :: any) :: term | no_return
  def to_enum_member!(schema, field, value) do
    to_enum_member(schema, field, value) ||
      raise ArgumentError, """
      #{inspect(value)} is not a member of enum #{inspect(field)} of schema #{inspect(schema)}!
      """
  end
end
