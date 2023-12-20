defmodule BitcrowdEcto.FixedWidthInteger do
  @moduledoc """
  An Ecto type that automatically validates that the given integer fits the underlying DB type.

  This turns the ugly Postgrex errors into neat `validation: :cast` changeset errors without
  having to manually `validate_number` all `:integer` fields.

  Named widths are based on Postgres' integer types.

  https://www.postgresql.org/docs/current/datatype-numeric.html
  """

  use Ecto.ParameterizedType

  @postgres_type_ranges %{
    smallint: -32_768..32_767,
    integer: -2_147_483_648..2_147_483_647,
    bigint: -9_223_372_036_854_775_808..9_223_372_036_854_775_807,
    smallserial: 1..32_767,
    serial: 1..2_147_483_647,
    bigserial: 1..9_223_372_036_854_775_807
  }

  @generic_byte_size_ranges %{
    2 => -32_768..32_767,
    4 => -2_147_483_648..2_147_483_647,
    8 => -9_223_372_036_854_775_808..9_223_372_036_854_775_807
  }

  @impl true
  def init(opts) do
    opts
    |> Keyword.get(:width, 4)
    |> width_to_range()
  end

  defp width_to_range(type) when is_atom(type), do: Map.fetch!(@postgres_type_ranges, type)
  defp width_to_range(size) when is_integer(size), do: Map.fetch!(@generic_byte_size_ranges, size)

  @impl true
  def type(_range), do: :integer

  @impl true
  def cast(value, range) do
    if is_integer(value) and value not in range do
      :error
    else
      Ecto.Type.cast(:integer, value)
    end
  end

  @impl true
  def load(value, loader, _range) do
    Ecto.Type.load(:integer, value, loader)
  end

  @impl true
  def dump(value, dumper, _range) do
    Ecto.Type.dump(:integer, value, dumper)
  end

  @impl true
  def equal?(a, b, _range) do
    a == b
  end
end
