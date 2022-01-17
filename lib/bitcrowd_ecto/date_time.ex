defmodule BitcrowdEcto.DateTime do
  @moduledoc """
  Functions to work with date and time values.
  """
  @moduledoc since: "0.2.0"

  @type value :: integer()
  @type unit :: :second | :minute | :hour | :day | :week

  @doc """
  Converts a `{<value>, <unit>}` tuple into seconds.

  #Examples

      iex> BitcrowdEcto.DateTime.in_seconds({99, :second})
      99

      iex> BitcrowdEcto.DateTime.in_seconds({1, :minute})
      60

      iex> BitcrowdEcto.DateTime.in_seconds({1, :hour})
      3600

      iex> BitcrowdEcto.DateTime.in_seconds({1, :day})
      86400

      iex> BitcrowdEcto.DateTime.in_seconds({1, :week})
      604800
  """
  @doc since: "0.2.0"
  @spec in_seconds({value(), unit()}) :: value()
  def in_seconds({seconds, :second}), do: seconds
  def in_seconds({minutes, :minute}), do: 60 * minutes
  def in_seconds({hours, :hour}), do: 3600 * hours
  def in_seconds({days, :day}), do: in_seconds({days * 24, :hour})

  def in_seconds({weeks, :week}),
    do: in_seconds({weeks * 7 * 24, :hour})
end
