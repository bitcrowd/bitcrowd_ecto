defmodule BitcrowdEcto.DateTime do
  @moduledoc """
  Functions to work with date and time values.
  """
  @moduledoc since: "0.2.0"

  @type unit :: :second | :minute | :hour | :day | :week
  @type period :: {integer(), unit()}

  @doc """
  Converts a `{<value>, <unit>}` tuple into seconds.

  #Examples

      iex> in_seconds({99, :second})
      99

      iex> in_seconds({1, :minute})
      60

      iex> in_seconds({1, :hour})
      3600

      iex> in_seconds({1, :day})
      86400

      iex> in_seconds({1, :week})
      604800
  """
  @doc since: "0.2.0"
  @spec in_seconds(period()) :: integer()
  def in_seconds({seconds, :second}), do: seconds
  def in_seconds({minutes, :minute}), do: 60 * minutes
  def in_seconds({hours, :hour}), do: 3600 * hours
  def in_seconds({days, :day}), do: in_seconds({days * 24, :hour})

  def in_seconds({weeks, :week}),
    do: in_seconds({weeks * 7 * 24, :hour})

  @doc """
  Works similar to `Timex.shift/3`, but way more simple.

  ## Behaviour

  Semantics are like `DateTime.add/3`. TimeZone-awareness when using tzdata.
  DateTime, e.g. "2020-03-29 14:00 Europe/Berlin" - 1 day = "2020-03-28 13:00" as March 29th
  only had 23 hours due to DST.

  ## Examples

      iex> shift(~U[2022-04-07 07:21:22.036Z], 15)
      ~U[2022-04-07 07:21:37.036Z]

      iex> shift(~U[2022-04-07 07:21:22.036Z], -3600)
      ~U[2022-04-07 06:21:22.036Z]

      iex> shift(~U[2022-04-07 07:21:22.036Z], {1, :day})
      ~U[2022-04-08 07:21:22.036Z]

      iex> ~U[2020-03-29 12:00:00.000Z]
      ...> |> DateTime.shift_zone!("Europe/Berlin")
      ...> |> shift({-1, :day})
      ...> |> DateTime.to_iso8601()
      "2020-03-28T13:00:00.000+01:00"
  """
  @doc since: "0.10.0"
  @spec shift(DateTime.t(), integer() | period()) :: DateTime.t()
  def shift(datetime, period) when is_tuple(period), do: shift(datetime, in_seconds(period))
  def shift(datetime, seconds), do: DateTime.add(datetime, seconds)

  @doc """
  Works similar to `Timex.beginning_of_day/3`, but way more simple.

  ## Behaviour

  Nulls the time fields of the `DateTime` and keeps the rest.

  ## Examples

      iex> beginning_of_day(~U[2022-04-07 07:21:22.036Z])
      ~U[2022-04-07 00:00:00.000000Z]
  """
  @doc since: "0.10.0"
  @spec beginning_of_day(DateTime.t()) :: DateTime.t()
  def beginning_of_day(datetime) do
    %{datetime | hour: 0, minute: 0, second: 0, microsecond: {0, 6}}
  end

  @doc """
  Calculates the beginning of yesterday, equalizing day length differences due to DST.

  ## Behaviour

  Subtracts 0.5d from today's midnight and goes back to midnight. Should be relatively safe.

  ## Examples

      iex> beginning_of_yesterday(~U[2022-04-07 07:21:22.036Z])
      ~U[2022-04-06 00:00:00.000000Z]

      iex> ~U[2020-03-29 12:00:00.000Z]
      ...> |> DateTime.shift_zone!("Europe/Berlin")
      ...> |> beginning_of_yesterday()
      ...> |> DateTime.to_iso8601()
      "2020-03-28T00:00:00.000000+01:00"
  """
  @doc since: "0.12.0"
  @spec beginning_of_yesterday(DateTime.t()) :: DateTime.t()
  def beginning_of_yesterday(datetime) do
    datetime
    |> beginning_of_day()
    |> DateTime.add(-43_200)
    |> beginning_of_day()
  end

  @doc """
  Calculates the beginning of tomorrow, equalizing day length differences due to DST.

  ## Behaviour

  Adds 1.5d to today's midnight and goes back to midnight. Should be relatively safe.

  ## Examples

      iex> beginning_of_tomorrow(~U[2022-04-07 07:21:22.036Z])
      ~U[2022-04-08 00:00:00.000000Z]

      iex> ~U[2020-03-29 12:00:00.000Z]
      ...> |> DateTime.shift_zone!("Europe/Berlin")
      ...> |> beginning_of_tomorrow()
      ...> |> DateTime.to_iso8601()
      "2020-03-30T00:00:00.000000+02:00"
  """
  @doc since: "0.12.0"
  @spec beginning_of_tomorrow(DateTime.t()) :: DateTime.t()
  def beginning_of_tomorrow(datetime) do
    datetime
    |> beginning_of_day()
    |> DateTime.add(129_600)
    |> beginning_of_day()
  end

  @doc """
  Works similar to `Timex.beginning_of_day/3`, but way more simple.

  ## Behaviour

  Sets `day` to 1 and nulls the time fields.

  ## Examples

      iex> beginning_of_month(~U[2022-04-07 07:21:22.036Z])
      ~U[2022-04-01 00:00:00.000000Z]
  """
  @doc since: "0.12.0"
  @spec beginning_of_month(DateTime.t()) :: DateTime.t()
  def beginning_of_month(datetime) do
    beginning_of_day(%{datetime | day: 1})
  end

  @doc """
  Calculates the beginning of last month.

  ## Behaviour

  Goes to this month's beginning, subtracts 15 days, and goes back to the month's beginning.

  Should be relatively safe.

  ## Examples

      iex> beginning_of_last_month(~U[2022-04-07 07:21:22.036Z])
      ~U[2022-03-01 00:00:00.000000Z]

      iex> beginning_of_last_month(~U[2022-02-07 07:21:22.036Z])
      ~U[2022-01-01 00:00:00.000000Z]
  """
  @doc since: "0.12.0"
  @spec beginning_of_last_month(DateTime.t()) :: DateTime.t()
  def beginning_of_last_month(datetime) do
    datetime
    |> beginning_of_month()
    |> DateTime.add(-1_296_000)
    |> beginning_of_month()
  end

  @doc """
  Calculates the beginning of next month.

  ## Behaviour

  Goes to this month's beginning, adds 45 days, and goes back to the month's beginning.

  Should be relatively safe.

  ## Examples

      iex> beginning_of_next_month(~U[2022-04-07 07:21:22.036Z])
      ~U[2022-05-01 00:00:00.000000Z]

      iex> beginning_of_next_month(~U[2022-02-07 07:21:22.036Z])
      ~U[2022-03-01 00:00:00.000000Z]
  """
  @doc since: "0.12.0"
  @spec beginning_of_next_month(DateTime.t()) :: DateTime.t()
  def beginning_of_next_month(datetime) do
    datetime
    |> beginning_of_month()
    |> DateTime.add(3_888_000)
    |> beginning_of_month()
  end
end
