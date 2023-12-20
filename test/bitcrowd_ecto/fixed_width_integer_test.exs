defmodule BitcrowdEcto.FixedWidthIntegerTest do
  use ExUnit.Case, async: true
  import BitcrowdEcto.Assertions
  import Ecto.Changeset

  defmodule TestSchema do
    use Ecto.Schema

    embedded_schema do
      field(:int_4, BitcrowdEcto.FixedWidthInteger, width: 4)
      field(:int_smallint, BitcrowdEcto.FixedWidthInteger, width: :smallint)
      field(:int_bigserial, BitcrowdEcto.FixedWidthInteger, width: :bigserial)
    end
  end

  test "casting an out-of-range value results in a changeset error" do
    for ok <- [-2, 2, 0, -2_147_483_648, 2_147_483_647] do
      cs = cast(%TestSchema{}, %{int_4: ok}, [:int_4])
      assert cs.valid?
    end

    for not_ok <- [-2_147_483_649, 2_147_483_648] do
      cs = cast(%TestSchema{}, %{int_4: not_ok}, [:int_4])
      refute cs.valid?
      assert_error_on(cs, :int_4, :cast)
    end

    for ok <- [-2, 2, 0, -32_768, 32_767] do
      cs = cast(%TestSchema{}, %{int_smallint: ok}, [:int_smallint])
      assert cs.valid?
    end

    for not_ok <- [-32_769, 32_768] do
      cs = cast(%TestSchema{}, %{int_smallint: not_ok}, [:int_smallint])
      refute cs.valid?
      assert_error_on(cs, :int_smallint, :cast)
    end

    for ok <- [1, 9_223_372_036_854_775_807] do
      cs = cast(%TestSchema{}, %{int_bigserial: ok}, [:int_bigserial])
      assert cs.valid?
    end

    for not_ok <- [-1, 0, 9_223_372_036_854_775_808] do
      cs = cast(%TestSchema{}, %{int_bigserial: not_ok}, [:int_bigserial])
      refute cs.valid?
      assert_error_on(cs, :int_bigserial, :cast)
    end
  end
end
