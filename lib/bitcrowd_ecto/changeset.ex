# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.Changeset do
  @moduledoc """
  Extensions for Ecto changesets.
  """

  @moduledoc since: "0.1.0"

  import Ecto.Changeset
  alias Ecto.Changeset

  @doc """
  Validates that a field has changed in a defined way.

  ## Examples

      validate_transition(changeset, field, [{"foo", "bar"}, {"foo", "yolo"}])

  This marks the changeset invalid unless the value of `:field` is currently `"foo"` and is
  changed to `"bar"` or `"yolo"`. If the field is not changed, a `{state, state}` transition
  has to be present in the list of transitions.
  """
  @doc since: "0.1.0"
  @spec validate_transition(Changeset.t(), atom, [{any, any}]) :: Changeset.t()
  def validate_transition(changeset, field, transitions) do
    from = Map.fetch!(changeset.data, field)
    to = Map.get(changeset.changes, field, from)

    if {from, to} in transitions do
      changeset
    else
      add_error(
        changeset,
        field,
        "%{field} cannot transition from %{from} to %{to}",
        from: from,
        to: to,
        validation: :transition
      )
    end
  end

  @doc """
  Validates that a field that has been changed.
  """
  @doc since: "0.1.0"
  @spec validate_changed(Changeset.t(), atom) :: Changeset.t()
  def validate_changed(changeset, field) do
    if Map.has_key?(changeset.changes, field) do
      changeset
    else
      add_error(changeset, field, "did not change", validation: :changed)
    end
  end

  @doc """
  Validates that a field is not changed from its current value, unless the current value is nil.
  """
  @doc since: "0.1.0"
  @spec validate_immutable(Changeset.t(), atom) :: Changeset.t()
  def validate_immutable(changeset, field) do
    if is_nil(Map.fetch!(changeset.data, field)) || !Map.has_key?(changeset.changes, field) do
      changeset
    else
      add_error(changeset, field, "cannot be changed", validation: :immutable)
    end
  end

  @valid_email_re ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-z0-9-]+(\.[a-z0-9-]+)*$/i
  @valid_email_re_only_web ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-z0-9-]+(\.[a-z0-9-]+)+$/i

  @type validate_email_option :: {:max_length, non_neg_integer} | {:only_web, boolean}

  @doc """
  Validates that an email has valid format.

  * Ignores nil values.

  ## Compliance

  For a good list of valid/invalid emails, see https://gist.github.com/cjaoude/fd9910626629b53c4d25

  The regex used in this validator doesn't understand half of the inputs, but we don't really care
  for now. Validating super strange emails is not a sport we want to compete in.

  ## Options

  * `:max_length` - restricts the maximum length of the input, defaults to 320
  * `:only_web` - requires a dot in the domain part, e.g. `domain.tld`, defaults to true
  """
  @doc since: "0.1.0"
  @spec validate_email(Changeset.t(), atom, [validate_email_option]) :: Changeset.t()
  def validate_email(changeset, field, opts \\ []) do
    max_length = Keyword.get(opts, :max_length, 320)

    re =
      if Keyword.get(opts, :only_web, true) do
        @valid_email_re_only_web
      else
        @valid_email_re
      end

    changeset
    |> validate_format(field, re)
    |> validate_length(field, max: max_length)
  end

  @doc """
  Validates a field url to be qualified url
  """
  @doc since: "0.1.0"
  @spec validate_url(Changeset.t(), atom) :: Changeset.t()
  def validate_url(changeset, field) do
    get_field(changeset, field) |> do_validate_url(changeset, field)
  end

  defp do_validate_url(nil, changeset, _field), do: changeset

  defp do_validate_url(url, changeset, field) do
    uri = URI.parse(url)

    if !is_nil(uri.scheme) && uri.host =~ "." do
      changeset
    else
      add_error(changeset, field, "is not a valid url", validation: :format)
    end
  end

  @doc """
  Validates a field timestamp to be in the past, if present
  """
  @doc since: "0.6.0"
  @spec validate_past_datetime(Changeset.t(), atom, DateTime.t()) :: Changeset.t()
  def validate_past_datetime(changeset, field, now \\ DateTime.utc_now()) do
    datetime = get_change(changeset, field)

    if datetime && DateTime.compare(now, datetime) == :lt do
      add_error(changeset, field, "must be in the past", validation: :date_in_past)
    else
      changeset
    end
  end

  @doc """
  Validates a field timestamp to be in the future, if present
  """
  @doc since: "0.6.0"
  @spec validate_future_datetime(Changeset.t(), atom, DateTime.t()) :: Changeset.t()
  def validate_future_datetime(changeset, field, now \\ DateTime.utc_now()) do
    datetime = get_change(changeset, field)

    if datetime && DateTime.compare(now, datetime) != :lt do
      add_error(changeset, field, "must be in the future", validation: :date_in_future)
    else
      changeset
    end
  end

  @doc """
  Validates a field timestamp to be after the given one
  """
  @doc since: "0.6.0"
  @spec validate_datetime_after(Changeset.t(), atom, DateTime.t(), [{:formatter, fun}]) ::
          Changeset.t()
  def validate_datetime_after(changeset, field, reference_datetime, opts \\ []) do
    formatter = Keyword.get(opts, :formatter, &DateTime.to_string/1)
    datetime = get_change(changeset, field)

    if datetime && DateTime.compare(reference_datetime, datetime) != :lt do
      reference = formatter.(reference_datetime)

      add_error(
        changeset,
        field,
        "must be after %{reference}",
        reference: reference,
        validation: :datetime_after
      )
    else
      changeset
    end
  end

  @doc """
  Validates two date fields to be a date range, so if both are set the first field has to be
  before the second field. The error is placed on the later field.

  ## Examples

      validate_date_order(changeset, :from, :to)
      validate_date_order(changeset, :from, :to, [valid_orders: :lt])
      validate_date_order(changeset, :from, :to, [formatter: &Date.day_of_week/1])
  """
  @doc since: "0.6.0"
  @spec validate_date_order(Changeset.t(), atom, atom, [
          {:formatter, fun},
          {:valid_orders, list(atom)}
        ]) ::
          Changeset.t()
  def validate_date_order(changeset, from_field, until_field, opts \\ []) do
    formatter = Keyword.get(opts, :formatter, &Date.to_string/1)
    valid_orders = Keyword.get(opts, :valid_orders, [:lt, :eq])

    validate_order(
      changeset,
      from_field,
      until_field,
      :date_order,
      compare_fun: &Date.compare/2,
      valid_orders: valid_orders,
      formatter: formatter
    )
  end

  @doc """
  Validates two datetime fields to be a time range, so if both are set the first has to be before
  the second field. The error is placed on the later field.

  ## Examples

      validate_datetime_order(changeset, :from, :to)
      validate_datetime_order(changeset, :from, :to, [valid_orders: :lt])
      validate_datetime_order(changeset, :from, :to, [formatter: &DateTime.to_time/1])
  """
  @doc since: "0.6.0"
  @spec validate_datetime_order(Changeset.t(), atom, atom, [
          {:formatter, fun},
          {:valid_orders, list(atom)}
        ]) ::
          Changeset.t()
  def validate_datetime_order(changeset, from_field, until_field, opts \\ []) do
    formatter = Keyword.get(opts, :formatter, &DateTime.to_string/1)
    valid_orders = Keyword.get(opts, :valid_orders, [:lt, :eq])

    validate_order(
      changeset,
      from_field,
      until_field,
      :datetime_order,
      compare_fun: &DateTime.compare/2,
      valid_orders: valid_orders,
      formatter: formatter
    )
  end

  @doc """
  Validates two fields to be a range, so if both are set the first has to be before
  the second field. The error is placed on the second field.

  ## Examples

      validate_order(changeset, :from, :to, :to_is_after_from)
      validate_order(changeset, :from, :to, :to_is_after_from, [compare_fun: fn a, b -> String.length(a) > String.length(b) end])
      validate_order(changeset, :from, :to, :to_is_after_from, [formatter: &String.length/1])
  """
  @doc since: "0.6.0"
  @spec validate_order(Changeset.t(), atom, atom, atom, [
          {:formatter, fun},
          {:compare_fun, fun},
          {:valid_orders, list(atom)}
        ]) ::
          Changeset.t()
  def validate_order(changeset, from_field, until_field, validation_key, opts \\ []) do
    formatter = Keyword.get(opts, :formatter, &Kernel.to_string/1)
    compare_fun = Keyword.get(opts, :compare_fun, &Kernel.</2)
    valid_orders = Keyword.get(opts, :valid_orders, [true])
    from = get_field(changeset, from_field)
    until = get_field(changeset, until_field)

    if from && until && !(compare_fun.(from, until) in List.wrap(valid_orders)) do
      stringified_value = formatter.(from)

      message = "must be after '%{stringified_value}'"

      add_error(changeset, until_field, message,
        validation: validation_key,
        stringified_value: stringified_value
      )
    else
      changeset
    end
  end

  @hex_color_regex ~r/^#[0-9A-Fa-f]{6}$/

  @doc """
  Validates a changeset field with hexadecimal color format
  """
  @doc since: "0.11.0"
  @spec validate_hex_color(Changeset.t(), atom) :: Changeset.t()
  def validate_hex_color(changeset, hex_color_field) do
    validate_format(changeset, hex_color_field, @hex_color_regex)
  end

  @doc """
  Validates a date field in the changeset is after the given reference date.
  """
  @doc since: "0.11.0"
  @spec validate_date_after(Changeset.t(), atom, Date.t(), [{:formatter, fun}]) ::
          Changeset.t()
  def validate_date_after(changeset, date_field, ref_date, opts \\ []) do
    date = get_field(changeset, date_field)

    if date do
      if Date.compare(date, ref_date) in [:eq, :gt] do
        changeset
      else
        formatter = Keyword.get(opts, :formatter, &Date.to_string/1)
        reference = formatter.(ref_date)

        add_error(changeset, date_field, "must be after or equal to #{reference}",
          validation: :date_after
        )
      end
    else
      changeset
    end
  end

  if Code.ensure_loaded?(Money) do
    @type validate_money_option ::
            {:equal_to, Money.t()}
            | {:more_than, Money.t()}
            | {:less_than, Money.t()}
            | {:more_than_or_equal_to, Money.t()}
            | {:less_than_or_equal_to, Money.t()}
            | {:currency, atom}

    @money_validations [
      :equal_to,
      :more_than,
      :less_than,
      :more_than_or_equal_to,
      :less_than_or_equal_to,
      :currency
    ]

    @doc """
    Validates a `t:Money.t` value according to the given options.

    ## Examples

        validate_money(changeset, :amount, less_than: Money.new("100.00", :USD))
        validate_money(changeset, :amount, greater_than_or_equal_to: Money.new("100.00", :USD))
        validate_money(changeset, :amount, currency: :USD)
    """
    @doc since: "0.13.0"
    @spec validate_money(Changeset.t(), atom(), [validate_money_option]) ::
            Changeset.t() | no_return()
    def validate_money(changeset, field, opts) do
      validate_change(changeset, field, fn _, %Money{} = value ->
        opts
        |> Keyword.take(@money_validations)
        |> Enum.flat_map(&do_validate_money(field, value, &1))
      end)
    end

    defp do_validate_money(field, value, {:equal_to, target}) do
      if Money.compare(value, target) != :eq do
        [
          {field,
           {"must be equal to %{money}", [money: target, validation: :money, kind: :equal_to]}}
        ]
      else
        []
      end
    end

    defp do_validate_money(field, value, {:less_than, target}) do
      if Money.compare(value, target) in [:eq, :gt] do
        [
          {field,
           {"must be less than %{money}", [money: target, validation: :money, kind: :less_than]}}
        ]
      else
        []
      end
    end

    defp do_validate_money(field, value, {:more_than, target}) do
      if Money.compare(value, target) in [:eq, :lt] do
        [
          {field,
           {"must be more than %{money}", [money: target, validation: :money, kind: :more_than]}}
        ]
      else
        []
      end
    end

    defp do_validate_money(field, value, {:less_than_or_equal_to, target}) do
      if Money.compare(value, target) == :gt do
        [
          {field,
           {"must be less than or equal to %{money}",
            [money: target, validation: :money, kind: :less_than_or_equal_to]}}
        ]
      else
        []
      end
    end

    defp do_validate_money(field, value, {:more_than_or_equal_to, target}) do
      if Money.compare(value, target) == :lt do
        [
          {field,
           {"must be more than or equal to %{money}",
            [money: target, validation: :money, kind: :more_than_or_equal_to]}}
        ]
      else
        []
      end
    end

    defp do_validate_money(field, value, {:currency, target}) do
      if value.currency != target do
        [
          {field,
           {"currency must be %{currency}",
            [currency: target, validation: :money, kind: :currency]}}
        ]
      else
        []
      end
    end
  end
end
