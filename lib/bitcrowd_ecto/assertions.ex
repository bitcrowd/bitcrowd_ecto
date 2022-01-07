# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.Assertions do
  @moduledoc """
  Useful little test assertions related to `t:Ecto.Changeset.t/0`.

  ## Example

  Import this in your `ExUnit.CaseTemplate`:

      defmodule MyApp.TestCase do
        use ExUnit.CaseTemplate

        using do
          quote do
            import Ecto
            import Ecto.Changeset
            import Ecto.Query
            import BitcrowdEcto.Assertions
          end
        end
      end
  """

  @moduledoc since: "0.1.0"

  import ExUnit.Assertions

  @doc """
  A better error helper that transforms the errors on a given field into a list of
  `[<message>, <value of the :validation metadata field>]`.

  If multiple validations failed, the list will contain more elements! That simple.

  ## Metadata

  By default, `flat_errors_on/2` extracts metadata from the `:validation` and `:constraint` keys,
  as those are were Ecto stores its metadata. Custom metadata at different keys can be extracted
  using the `:metadata` option.
  """
  @doc since: "0.1.0"
  @spec flat_errors_on(Ecto.Changeset.t(), atom) :: [String.t() | atom]
  @spec flat_errors_on(Ecto.Changeset.t(), atom, [{:metadata, atom}]) :: [String.t() | atom]
  def flat_errors_on(changeset, field, opts \\ []) do
    metadata =
      opts
      |> Keyword.get(:metadata, [:constraint, :validation])
      |> List.wrap()

    changeset.errors
    |> Keyword.get_values(field)
    |> Enum.flat_map(fn {msg, opts} ->
      interpolated =
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)

      metadata =
        metadata
        |> Enum.map(&Keyword.get(opts, &1))
        |> Enum.reject(&is_nil/1)

      [interpolated | metadata]
    end)
  end

  @doc """
  Asserts that a changeset contains a given error on a given field.

  Returns the changeset for chainability.
  """
  @doc since: "0.1.0"
  @spec assert_error_on(Ecto.Changeset.t(), atom, atom | [atom]) :: Ecto.Changeset.t() | no_return
  @spec assert_error_on(Ecto.Changeset.t(), atom, atom | [atom], [{:metadata, atom}]) ::
          Ecto.Changeset.t() | no_return
  def assert_error_on(changeset, field, error, opts \\ [])

  def assert_error_on(changeset, _field, [], _opts), do: changeset

  def assert_error_on(changeset, field, [error | rest], opts) do
    changeset
    |> assert_error_on(field, error, opts)
    |> assert_error_on(field, rest, opts)
  end

  def assert_error_on(changeset, field, error, opts) do
    assert error in flat_errors_on(changeset, field, opts)

    changeset
  end

  for validation <- [:required, :format, :number, :inclusion, :acceptance] do
    @doc """
    Asserts that a changeset contains a failed "#{validation}" validation on a given field.

    Returns the changeset for chainability.
    """
    @doc since: "0.1.0"
    @spec unquote(:"assert_#{validation}_error_on")(Ecto.Changeset.t(), atom) ::
            Ecto.Changeset.t() | no_return
    def unquote(:"assert_#{validation}_error_on")(changeset, field) do
      assert_error_on(changeset, field, unquote(validation))
    end
  end

  for constraint <- [:unique, :foreign, :no_assoc] do
    @doc """
    Asserts that a changeset contains a failed "#{constraint}" constraint validation on a given field.

    Returns the changeset for chainability.
    """
    @doc since: "0.1.0"
    @spec unquote(:"assert_#{constraint}_constraint_error_on")(Ecto.Changeset.t(), atom) ::
            Ecto.Changeset.t() | no_return
    def unquote(:"assert_#{constraint}_constraint_error_on")(changeset, field) do
      assert_error_on(changeset, field, unquote(constraint))
    end
  end

  @doc """
  Asserts that a changeset does not contain an error on a given field.

  Returns the changeset for chainability.
  """
  @doc since: "0.1.0"
  @spec refute_errors_on(Ecto.Changeset.t(), atom) :: Ecto.Changeset.t() | no_return
  def refute_errors_on(changeset, field) do
    assert flat_errors_on(changeset, field) == []

    changeset
  end

  @doc """
  Asserts that a changeset contains a change of a given field.

  Returns the changeset for chainability.
  """
  @doc since: "0.1.0"
  @spec assert_changes(Ecto.Changeset.t(), atom) :: Ecto.Changeset.t() | no_return
  def assert_changes(changeset, field) do
    assert Map.has_key?(changeset.changes, field)

    changeset
  end

  @doc """
  Asserts that a changeset contains a change of a given field to a given value.

  Returns the changeset for chainability.
  """
  @doc since: "0.1.0"
  @spec assert_changes(Ecto.Changeset.t(), atom, any) :: Ecto.Changeset.t() | no_return
  def assert_changes(changeset, field, value) do
    assert Map.get(changeset.changes, field) == value

    changeset
  end

  @doc """
  Refutes that a changeset accepts changes to a given field.

  Returns the changeset for chainability.
  """
  @doc since: "0.1.0"
  @spec refute_changes(Ecto.Changeset.t(), atom) :: Ecto.Changeset.t() | no_return
  def refute_changes(changeset, field) do
    refute Map.has_key?(changeset.changes, field)

    changeset
  end

  @doc """
  Asserts that a given function changes the integer fetched by another function by a delta.

  ## Example

      assert_difference fn -> Repo.count(Foo) end, 1 fn ->
        %Foo{} |> Repo.insert()
      end
  """
  @doc since: "0.1.0"
  @spec assert_difference((() -> float | integer), float | integer, (() -> any)) ::
          Ecto.Changeset.t() | no_return
  @spec assert_difference((() -> float | integer), float | integer, (() -> any), [
          {:message, String.t()}
        ]) :: Ecto.Changeset.t() | no_return
  def assert_difference(what, by, how, opts \\ []) do
    msg = Keyword.get(opts, :message, "#{inspect(what)} hasn't changed by #{by}")

    value_before = what.()
    rv = how.()
    value_after = what.()

    assert value_before == value_after - by,
           """
           #{msg}

           value before: #{inspect(value_before)}
           value after: #{inspect(value_after)}
           """

    rv
  end

  @doc """
  Assert that a given function doesn't change the value fetched by another function.

  ## Example

      refute_difference fn -> Repo.count(Foo) end, fn ->
        Repo.insert(%Foo{})
      end
  """
  @doc since: "0.1.0"
  @spec refute_difference((() -> any), (() -> any)) :: Ecto.Changeset.t() | no_return
  @spec refute_difference((() -> any), (() -> any), [{:message, String.t()}]) ::
          Ecto.Changeset.t() | no_return
  def refute_difference(what, how, opts \\ []) do
    msg = Keyword.get(opts, :message, "#{inspect(what)} has changed")

    value_before = what.()
    rv = how.()
    value_after = what.()

    assert value_before == value_after,
           """
           #{msg}

           value before: #{inspect(value_before)}
           value after: #{inspect(value_after)}
           """

    rv
  end

  @doc """
  Assert that a given function changes the count of a given database table.

  ## Example

      assert_count_difference Repo, Foo, 1, fn ->
        Repo.insert(%Foo{})
      end
  """
  @doc since: "0.1.0"
  @spec assert_count_difference(Ecto.Repo.t(), module, integer, (() -> any)) ::
          Ecto.Changeset.t() | no_return
  def assert_count_difference(repo, schema, by, how) do
    assert_difference(fn -> repo.count(schema) end, by, how,
      message: "#{inspect(schema)} hasn't changed by #{by}"
    )
  end

  @doc """
  Assert multiple database table count changes.

  See `assert_count_difference/4` for details.

  ## Example

      assert_count_differences([{MyApp.Foo, 1}, {MyApp.Bar, -1}], fn ->
        %MyApp.Foo{} |> MyApp.Repo.insert()
        %MyApp.Bar{id: 1} |> MyApp.Repo.delete()
      end
  """
  @doc since: "0.1.0"
  @spec assert_count_differences(Ecto.Repo.t(), [{module, integer}], (() -> any)) ::
          Ecto.Changeset.t() | no_return
  def assert_count_differences(_repo, [], how), do: how.()

  def assert_count_differences(repo, [{schema, by} | rest], how) do
    assert_count_difference(repo, schema, by, fn ->
      assert_count_differences(repo, rest, how)
    end)
  end

  @doc """
  Asserts that an Ecto struct has a preloaded nested struct at a given path.
  """
  @doc since: "0.1.0"
  @spec assert_preloaded(schema :: Ecto.Schema.t(), fields :: atom | [atom]) ::
          boolean | no_return
  def assert_preloaded(record, [x]), do: assert_preloaded(record, x)
  def assert_preloaded(record, [x | xs]), do: assert_preloaded(Map.get(record, x), xs)

  def assert_preloaded(record, x) when is_atom(x) do
    refute not_loaded_ecto_association?(Map.get(record, x)),
           """
           record of type #{inspect(Map.get(record, :__struct__))} has not loaded association at :#{x}

           record: #{inspect(record)}
           """
  end

  @doc """
  Refutes that an Ecto struct has a preloaded nested struct at a given path.
  """
  @doc since: "0.1.0"
  @spec refute_preloaded(schema :: Ecto.Schema.t(), fields :: atom | [atom]) ::
          boolean | no_return
  def refute_preloaded(record, [x]), do: refute_preloaded(record, x)
  def refute_preloaded(record, [x | xs]), do: refute_preloaded(Map.get(record, x), xs)

  def refute_preloaded(record, x) when is_atom(x) do
    assert not_loaded_ecto_association?(Map.get(record, x)),
           """
           record of type #{inspect(Map.get(record, :__struct__))} has preloaded association at :#{x}

           record: #{inspect(record)}
           """
  end

  defp not_loaded_ecto_association?(%Ecto.Association.NotLoaded{}), do: true
  defp not_loaded_ecto_association?(_), do: false
end
