# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.SchemaTest do
  use ExUnit.Case, async: true
  import BitcrowdEcto.Schema

  defmodule TestEnumSchema do
    use Ecto.Schema

    schema "test_schema" do
      field(:some_enum, Ecto.Enum, values: [:foo, :bar])
      field(:some_other_field, :integer)
    end
  end

  doctest BitcrowdEcto.Schema

  describe "to_enum_member/3" do
    test "returns the atom representation if string value is a member of the enum" do
      assert to_enum_member(TestEnumSchema, :some_enum, "foo") == :foo
      assert to_enum_member(TestEnumSchema, :some_enum, "bar") == :bar
    end

    test "accepts atoms as well" do
      assert to_enum_member(TestEnumSchema, :some_enum, :foo) == :foo
    end

    test "returns nil if value is not a member of the enum" do
      assert to_enum_member(TestEnumSchema, :some_enum, "baz") == nil
      assert to_enum_member(TestEnumSchema, :some_enum, :baz) == nil
    end

    test "raises an exception if field is not an Ecto.Enum" do
      assert_raise ArgumentError, ~r/is not an Ecto.Enum field/, fn ->
        to_enum_member(TestEnumSchema, :some_other_field, "baz")
      end
    end
  end

  describe "to_enum_member!/3" do
    test "returns the atom representation if string value is a member of the enum" do
      assert to_enum_member!(TestEnumSchema, :some_enum, "foo") == :foo
      assert to_enum_member!(TestEnumSchema, :some_enum, "bar") == :bar
    end

    test "accepts atoms as well" do
      assert to_enum_member!(TestEnumSchema, :some_enum, :foo) == :foo
    end

    test "raises an exception if value is not a member of the enum" do
      assert_raise ArgumentError, ~r/is not a member/, fn ->
        to_enum_member!(TestEnumSchema, :some_enum, "baz")
      end

      assert_raise ArgumentError, ~r/is not a member/, fn ->
        to_enum_member!(TestEnumSchema, :some_enum, :baz)
      end
    end

    test "raises an exception if field is not an Ecto.Enum" do
      assert_raise ArgumentError, ~r/is not an Ecto.Enum field/, fn ->
        to_enum_member!(TestEnumSchema, :some_other_field, "baz")
      end
    end
  end
end
