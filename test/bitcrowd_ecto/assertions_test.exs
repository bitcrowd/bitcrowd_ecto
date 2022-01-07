# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.AssertionsTest do
  use BitcrowdEcto.TestCase, async: true
  import BitcrowdEcto.Assertions

  describe "flat_errors_on/2" do
    test "flattens all errors and their validation metadata into a list" do
      cs =
        %TestSchema{}
        |> change(%{})
        |> add_error(:some_string, "is wrong", validation: :wrong)
        |> add_error(:some_string, "is really wrong", validation: :really_wrong)
        |> add_error(:some_integer, "is also wrong", validation: :also_wrong)

      assert flat_errors_on(cs, :some_string) == [
               "is really wrong",
               :really_wrong,
               "is wrong",
               :wrong
             ]

      assert flat_errors_on(cs, :some_integer) == ["is also wrong", :also_wrong]
    end

    test "can fetch metadata by a given key" do
      cs =
        %TestSchema{}
        |> change(%{})
        |> add_error(:some_string, "is wrong", foo: :bar)

      assert :bar in flat_errors_on(cs, :some_string, metadata: :foo)
      assert :bar in flat_errors_on(cs, :some_string, metadata: [:foo])
    end
  end

  describe "assert_error_on/4" do
    test "asserts that a given error is present on a field" do
      cs =
        %TestSchema{}
        |> change(%{})
        |> validate_required(:some_string)

      assert assert_error_on(cs, :some_string, :required)

      assert_raise ExUnit.AssertionError, fn ->
        assert assert_error_on(cs, :some_integer, :length)
      end
    end

    test "can assert on multiple errors" do
      cs =
        %TestSchema{}
        |> change(%{some_string: "foo", some_integer: 1})
        |> validate_length(:some_string, min: 10)
        |> validate_inclusion(:some_string, ["bar"])
        |> validate_inclusion(:some_integer, [5])

      assert assert_error_on(cs, :some_string, [:length, :inclusion])

      assert_raise ExUnit.AssertionError, fn ->
        assert assert_error_on(cs, :some_integer, [:inclusion, :number])
      end
    end
  end

  describe "assert_required_error_on/2" do
    test "asserts on the :required error on a field" do
      cs =
        %TestSchema{}
        |> change(%{})
        |> validate_required(:some_string)

      assert assert_required_error_on(cs, :some_string) == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_required_error_on(cs, :some_integer)
      end
    end
  end

  describe "assert_format_error_on/2" do
    test "asserts on the :format error on a field" do
      cs =
        %TestSchema{}
        |> change(%{some_string: "foo"})
        |> validate_format(:some_string, ~r/bar/)

      assert assert_format_error_on(cs, :some_string) == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_format_error_on(cs, :some_integer)
      end
    end
  end

  describe "assert_number_error_on/2" do
    test "asserts on the :number error on a field" do
      cs =
        %TestSchema{}
        |> change(%{some_integer: 5})
        |> validate_number(:some_integer, greater_than: 5)

      assert assert_number_error_on(cs, :some_integer) == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_number_error_on(cs, :some_string)
      end
    end
  end

  describe "assert_inclusion_error_on/2" do
    test "asserts on the :inclusion error on a field" do
      cs =
        %TestSchema{}
        |> change(%{some_string: "foo"})
        |> validate_inclusion(:some_string, ["bar", "baz"])

      assert assert_inclusion_error_on(cs, :some_string) == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_inclusion_error_on(cs, :some_integer)
      end
    end
  end

  describe "assert_acceptance_error_on/2" do
    test "asserts on the :acceptance error on a field" do
      cs =
        %TestSchema{}
        |> cast(%{"some_boolean" => false}, [:some_boolean])
        |> validate_acceptance(:some_boolean)

      assert assert_acceptance_error_on(cs, :some_boolean) == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_acceptance_error_on(cs, :some_integer)
      end
    end
  end

  # We don't have a constraints on the "test_schema" table, so we add the errors ourselves.

  describe "assert_unique_constraint_error_on/2" do
    test "asserts on the :unique error on a field" do
      cs =
        %TestSchema{}
        |> change(%{})
        |> add_error(:some_string, "has already been taken", constraint: :unique)

      assert assert_unique_constraint_error_on(cs, :some_string) == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_unique_constraint_error_on(cs, :some_integer)
      end
    end
  end

  describe "assert_foreign_constraint_error_on/2" do
    test "asserts on the :foreign error on a field" do
      cs =
        %TestSchema{}
        |> change(%{})
        |> add_error(:some_string, "does not exist", constraint: :foreign)

      assert assert_foreign_constraint_error_on(cs, :some_string) == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_foreign_constraint_error_on(cs, :some_integer)
      end
    end
  end

  describe "assert_no_assoc_constraint_error_on/2" do
    test "asserts on the :no_assoc error on a field" do
      cs =
        %TestSchema{}
        |> change(%{})
        |> add_error(:some_string, "is still associated with this entry", constraint: :no_assoc)

      assert assert_no_assoc_constraint_error_on(cs, :some_string) == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_no_assoc_constraint_error_on(cs, :some_integer)
      end
    end
  end

  describe "refute_errors_on/2" do
    test "asserts that a field does not have errors" do
      cs =
        %TestSchema{}
        |> change(%{})
        |> validate_required(:some_string)

      assert refute_errors_on(cs, :some_integer) == cs

      assert_raise ExUnit.AssertionError, fn ->
        refute_errors_on(cs, :some_string)
      end
    end
  end

  describe "assert_changes/2" do
    test "asserts that a field is changed" do
      cs = change(%TestSchema{}, %{some_string: "foo"})

      assert assert_changes(cs, :some_string) == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_changes(cs, :some_integer)
      end
    end
  end

  describe "assert_changes/3" do
    test "asserts that a field is changed to a specific valud" do
      cs = change(%TestSchema{}, %{some_string: "foo"})

      assert assert_changes(cs, :some_string, "foo") == cs

      assert_raise ExUnit.AssertionError, fn ->
        assert_changes(cs, :some_string, "bar")
      end
    end
  end

  describe "refute_changes/2" do
    test "asserts that a field is not changed" do
      cs = change(%TestSchema{}, %{some_string: "foo"})

      assert refute_changes(cs, :some_integer) == cs

      assert_raise ExUnit.AssertionError, fn ->
        refute_changes(cs, :some_string)
      end
    end
  end

  describe "assert_difference/4" do
    setup do
      %{agent: start_supervised!({Agent, fn -> 0 end})}
    end

    test "asserts that a given function changes the integer fetched by another function by a delta",
         %{agent: agent} do
      assert_difference(
        fn -> Agent.get(agent, & &1) end,
        1,
        fn -> Agent.update(agent, fn x -> x + 1 end) end
      )

      assert_raise ExUnit.AssertionError, ~r/hasn't changed by 2/, fn ->
        assert_difference(
          fn -> Agent.get(agent, & &1) end,
          2,
          fn -> Agent.update(agent, fn x -> x + 1 end) end
        )
      end
    end

    test "accepts a message option to configure the error message", %{agent: agent} do
      assert_raise ExUnit.AssertionError, ~r/boom/, fn ->
        assert_difference(
          fn -> Agent.get(agent, & &1) end,
          2,
          fn -> Agent.update(agent, fn x -> x + 1 end) end,
          message: "boom"
        )
      end
    end
  end

  describe "refute_difference/4" do
    setup do
      %{agent: start_supervised!({Agent, fn -> 0 end})}
    end

    test "asserts that a given function does not change the integer fetched by another function",
         %{agent: agent} do
      refute_difference(
        fn -> Agent.get(agent, & &1) end,
        fn -> nil end
      )

      assert_raise ExUnit.AssertionError, ~r/has changed/, fn ->
        refute_difference(
          fn -> Agent.get(agent, & &1) end,
          fn -> Agent.update(agent, fn x -> x + 1 end) end
        )
      end
    end

    test "accepts a message option to configure the error message", %{agent: agent} do
      assert_raise ExUnit.AssertionError, ~r/boom/, fn ->
        refute_difference(
          fn -> Agent.get(agent, & &1) end,
          fn -> Agent.update(agent, fn x -> x + 1 end) end,
          message: "boom"
        )
      end
    end
  end

  describe "assert_count_difference/4" do
    test "asserts that a given function changes the count of a given database table" do
      assert_count_difference(TestRepo, TestSchema, 1, fn ->
        insert(:test_schema)
      end)

      assert_raise ExUnit.AssertionError, ~r/TestSchema hasn't changed by 3/, fn ->
        assert_count_difference(TestRepo, TestSchema, 3, fn ->
          insert(:test_schema)
          insert(:test_schema)
        end)
      end
    end
  end

  describe "assert_count_differences/4" do
    test "asserts that a given function changes the count of multiple database tables" do
      assert_count_differences(TestRepo, [{TestSchema, 1}], fn ->
        insert(:test_schema)
      end)

      assert_raise ExUnit.AssertionError, ~r/TestSchema hasn't changed by 3/, fn ->
        assert_count_differences(TestRepo, [{TestSchema, 3}], fn ->
          insert(:test_schema)
          insert(:test_schema)
        end)
      end
    end
  end

  describe "assert_preloaded/2" do
    setup do
      %{test_schema: insert(:test_schema)}
    end

    test "asserts that an Ecto struct has a preloaded nested struct at a given path", %{
      test_schema: %{id: id}
    } do
      {:ok, test_schema} = TestRepo.fetch(TestSchema, id, preload: :children)
      assert_preloaded(test_schema, [:children])
      assert_preloaded(test_schema, :children)

      assert_raise ExUnit.AssertionError, ~r/TestSchema has not loaded association/, fn ->
        {:ok, test_schema} = TestRepo.fetch(TestSchema, id)
        assert_preloaded(test_schema, [:children])
      end
    end
  end

  describe "refute_preloaded/2" do
    setup do
      %{test_schema: insert(:test_schema)}
    end

    test "asserts that an Ecto struct does not have a preloaded nested struct at a given path", %{
      test_schema: %{id: id}
    } do
      {:ok, test_schema} = TestRepo.fetch(TestSchema, id)
      refute_preloaded(test_schema, [:children])
      refute_preloaded(test_schema, :children)

      assert_raise ExUnit.AssertionError, ~r/TestSchema has preloaded association/, fn ->
        {:ok, test_schema} = TestRepo.fetch(TestSchema, id, preload: :children)
        refute_preloaded(test_schema, [:children])
      end
    end
  end
end
