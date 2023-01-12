# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.RepoTest do
  use BitcrowdEcto.TestCase, async: true
  require Ecto.Query

  defp insert_test_schema(_) do
    %{resource: insert(:test_schema)}
  end

  defp insert_test_schema_with_prefix(_) do
    prefix = :foo
    %{resource: insert(:test_schema, [], prefix: prefix), prefix: prefix}
  end

  describe "count/1" do
    setup [:insert_test_schema]

    test "it gives the count of the given queryable" do
      assert TestRepo.count(TestSchema) == 1
      assert TestRepo.count(from(x in TestSchema, where: is_nil(x.id))) == 0
    end
  end

  describe "count/2" do
    setup [:insert_test_schema_with_prefix]

    test "it gives the count of the given queryable using a prefix option", %{prefix: prefix} do
      assert TestRepo.count(TestSchema) == 0
      assert TestRepo.count(TestSchema, prefix: prefix) == 1
    end
  end

  describe "fetch/2" do
    setup [:insert_test_schema]

    test "fetches a record by primary key and wraps it into an ok tuple", %{resource: resource} do
      assert TestRepo.fetch(TestSchema, resource.id) == {:ok, resource}
    end
  end

  describe "fetch/2 with schemas with non-standard primary key" do
    test "fetches a record by primary key when primary key is not 'id'" do
      %{name: name} = insert(:alternative_primary_key_test_schema)

      assert {:ok, %AlternativePrimaryKeyTestSchema{name: ^name}} =
               TestRepo.fetch(AlternativePrimaryKeyTestSchema, name)
    end

    test "raises when the schema as multiple primary keys" do
      defmodule TwoPrimaryKeyTestSchema do
        @moduledoc false
        use BitcrowdEcto.Schema
        @primary_key false

        schema "two_primary_key_test_schema" do
          field(:a, :string, primary_key: true)
          field(:b, :string, primary_key: true)
        end
      end

      assert_raise ArgumentError, ~r"exactly one primary key", fn ->
        TestRepo.fetch(TwoPrimaryKeyTestSchema, "abc")
      end
    end
  end

  describe "fetch/2 when the resource does not exist" do
    test "returns a tagged not found error" do
      assert TestRepo.fetch(TestSchema, Ecto.UUID.generate()) ==
               {:error, {:not_found, TestSchema}}
    end
  end

  describe "fetch/3" do
    setup [:insert_test_schema_with_prefix]

    test "returns the record using the prefix option", %{resource: resource, prefix: prefix} do
      assert TestRepo.fetch(TestSchema, resource.id) == {:error, {:not_found, TestSchema}}
      assert TestRepo.fetch(TestSchema, resource.id, prefix: prefix) == {:ok, resource}
    end
  end

  describe "fetch_by/3" do
    setup [:insert_test_schema]

    test "fetches a record by clauses and wraps it into an ok tuple", %{resource: resource} do
      assert TestRepo.fetch_by(TestSchema, id: resource.id) == {:ok, resource}
    end

    test "fetches a record from a queryable", %{resource: %{id: id} = resource} do
      query = Ecto.Query.from(x in TestSchema, where: x.id == ^id)
      assert TestRepo.fetch_by(query, []) == {:ok, resource}
    end

    # The actual lock is non-trivial to test, I tried.
    test "can lock for :update", %{resource: %{id: id} = resource} do
      assert TestRepo.fetch_by(TestSchema, [id: id], lock: :update) == {:ok, resource}
    end

    test "can lock for :no_key_update", %{resource: %{id: id} = resource} do
      assert TestRepo.fetch_by(TestSchema, [id: id], lock: :no_key_update) == {:ok, resource}
    end

    test "returns the given error tag instead of the queryable" do
      query = Ecto.Query.from(x in TestSchema, where: x.id == ^Ecto.UUID.generate())
      assert TestRepo.fetch_by(query, []) == {:error, {:not_found, query}}
      assert TestRepo.fetch_by(query, [], error_tag: :foo) == {:error, {:not_found, :foo}}
    end

    test "raises an exception on unknown lock mode", %{resource: %{id: id}} do
      assert_raise RuntimeError, ~r/unknown lock mode/, fn ->
        TestRepo.fetch_by(TestSchema, [id: id], lock: :foo)
      end
    end
  end

  describe "fetch_by/3 when the resource does not exist" do
    test "returns a tagged not found error" do
      assert TestRepo.fetch_by(TestSchema, id: Ecto.UUID.generate()) ==
               {:error, {:not_found, TestSchema}}
    end
  end

  describe "fetch_by/3 accepts ecto options" do
    setup [:insert_test_schema_with_prefix]

    test "fetches a record by clauses and wraps it into an ok tuple", %{
      resource: resource,
      prefix: prefix
    } do
      assert TestRepo.fetch_by(TestSchema, id: resource.id) ==
               {:error, {:not_found, TestSchema}}

      assert TestRepo.fetch_by(TestSchema, [id: resource.id], prefix: prefix) == {:ok, resource}
    end
  end
end
