# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.Changeset do
  @moduledoc """
  Extensions for Ecto changesets.
  """

  @moduledoc since: "0.1.0"

  import Ecto.Changeset

  @doc """
  Validates that a field has changed in a defined way.

  ## Examples

      validate_transition(changeset, field, [{"foo", "bar"}, {"foo", "yolo"}]

  This marks the changeset invalid unless the value of `:field` is currently `"foo"` and is
  changed to `"bar"` or `"yolo"`. If the field is not changed, a `{state, state}` transition
  has to be present in the list of transitions.
  """
  @doc since: "0.1.0"
  @spec validate_transition(Ecto.Changeset.t(), atom, [{any, any}]) :: Ecto.Changeset.t()
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
        field: field,
        from: inspect(from),
        to: inspect(to),
        validation: :transition
      )
    end
  end

  @doc """
  Validates that a field that has been changed.
  """
  @doc since: "0.1.0"
  @spec validate_changed(Ecto.Changeset.t(), atom) :: Ecto.Changeset.t()
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
  @spec validate_immutable(Ecto.Changeset.t(), atom) :: Ecto.Changeset.t()
  def validate_immutable(changeset, field) do
    if is_nil(Map.fetch!(changeset.data, field)) || !Map.has_key?(changeset.changes, field) do
      changeset
    else
      add_error(changeset, field, "cannot be changed", validation: :immutable)
    end
  end

  @valid_email_re ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-z0-9-]+(\.[a-z0-9-]+)*$/i

  @doc """
  Validates that an email has valid format.

  * Ignores nil values.

  ## Compliance

  For a good list of valid/invalid emails, see https://gist.github.com/cjaoude/fd9910626629b53c4d25

  The regex used in this validator doesn't understand half of the inputs, but we don't really care
  for now. Validating super strange emails is not a sport we want to compete in.
  """
  @doc since: "0.1.0"
  @spec validate_email(Ecto.Changeset.t(), atom, [{:max_length, non_neg_integer}]) ::
          Ecto.Changeset.t()
  def validate_email(changeset, field, opts \\ []) do
    max_length = Keyword.get(opts, :max_length, 320)

    changeset
    |> validate_format(field, @valid_email_re)
    |> validate_length(field, max: max_length)
  end

  @doc """
  Validates a field url to be qualified url
  """
  @doc since: "0.1.0"
  @spec validate_url(Ecto.Changeset.t(), atom) :: Ecto.Changeset.t()
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
end
