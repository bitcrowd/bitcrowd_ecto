# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.RepoTest do
  use BitcrowdEcto.TestCase, async: true
  require Ecto.Query

  defp insert_test_schema(_) do
    %{resource: insert(:test_schema)}
  end

  describe "count/1" do
    setup [:insert_test_schema]

    test "it gives the count of the given queryable" do
      assert TestRepo.count(TestSchema) == 1
      assert TestRepo.count(from(x in TestSchema, where: is_nil(x.id))) == 0
    end
  end

  describe "fetch/2" do
    setup [:insert_test_schema]

    test "fetches a record by id and wraps it into an ok tuple", %{resource: resource} do
      assert TestRepo.fetch(TestSchema, resource.id) == {:ok, resource}
    end
  end

  describe "fetch/2 when the resource does not exist" do
    test "returns a tagged not found error" do
      assert TestRepo.fetch(TestSchema, Ecto.UUID.generate()) ==
               {:error, {:not_found, TestSchema}}
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
end
