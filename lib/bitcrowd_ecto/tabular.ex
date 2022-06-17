defmodule BitcrowdEcto.Tabular do
  @moduledoc """
  Functions for arranging a list of maps or structs in a tabular, CSV-like way.
  """

  @moduledoc since: "0.12.0"

  @type column :: atom | binary | {binary, atom} | {binary, binary} | {binary, function}
  @type option :: {:headers, boolean}
  @type stream :: Enumerable.t()

  @doc ~S"""
  Converts an enumerable into a list of tabular data according to the given column definitions.

  ## Column definitions

  Columns have to be defined by given field accessors and optional header names.

      # Simple Access-based fetching of an atom key, the header will stringified.
      :id

      # Using a different header.
      {"ID", :id}

      # Using a customer access function.
      &"#{&1.first_name} #{&1.last_name}"

  ## Options

  - `headers` - defines whether the data should be prepended with a header line (default: true)

  ## Examples

      iex> users = [%{id: 1, name: "Jane"}, %{id: 2, name: "John"}]
      ...> all(users, [:id, :name])
      [["id", "name"], [1, "Jane"], [2, "John"]]

      iex> users = [%{id: 1, name: "Jane"}, %{id: 2, name: "John"}]
      ...> all(users, [:id, :name], headers: false)
      [[1, "Jane"], [2, "John"]]

      iex> all([%{id: 1}, %{id: 2}], [{"Identifier", :id}])
      [["Identifier"], [1], [2]]

      iex> all([%{id: 1}, %{id: 2}], [{"id", fn %{id: id} -> id * 2 end}])
      [["id"], [2], [4]]
  """
  @doc since: "0.12.0"
  @spec all(Enumerable.t(), [column]) :: list
  @spec all(Enumerable.t(), [column], [option]) :: list
  def all(data, columns, opts \\ []) do
    data
    |> stream(columns, opts)
    |> Enum.into([])
  end

  @doc ~S"""
  Converts an enumerable into a stream of tabular data.

  See `BitcrowdEcto.Tabular.all/3`.

  ## Examples

      iex> exploding_getter =
      ...>   fn %{id: id} ->
      ...>     if id == 2, do: raise("boom"), else: id
      ...>   end
      ...>
      ...> stream([%{id: 1}, %{id: 2}], [{"id", exploding_getter}])
      ...> |> Stream.take(2)
      ...> |> Enum.into([])
      [["id"], [1]]
  """
  @doc since: "0.12.0"
  @spec stream(Enumerable.t(), [column]) :: stream
  @spec stream(Enumerable.t(), [column], [option]) :: stream
  def stream(data, columns, opts \\ []) do
    mapper = fn entry ->
      Enum.map(columns, fn
        {_, fun} when is_function(fun, 1) ->
          fun.(entry)

        {_, key} when is_atom(key) or is_binary(key) ->
          Map.fetch!(entry, key)

        key when is_atom(key) or is_binary(key) ->
          Map.fetch!(entry, key)
      end)
    end

    body = Stream.map(data, mapper)

    if Keyword.get(opts, :headers, true) do
      headers =
        Enum.map(columns, fn
          {header, _} when is_binary(header) -> header
          key when is_atom(key) or is_binary(key) -> to_string(key)
        end)

      Stream.concat([headers], body)
    else
      body
    end
  end
end
