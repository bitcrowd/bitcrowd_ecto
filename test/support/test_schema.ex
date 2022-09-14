# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestSchema do
  @moduledoc false

  use BitcrowdEcto.Schema
  import Ecto.Changeset

  @attrs [
    :some_string,
    :some_integer,
    :some_boolean,
    :datetime,
    :from,
    :until,
    :from_dt,
    :until_dt,
    :from_number,
    :to_number,
    :money
  ]

  schema "test_schema" do
    field(:some_string, :string)
    field(:some_integer, :integer)
    field(:some_boolean, :boolean)
    field(:datetime, :utc_datetime_usec)
    field(:from, :date)
    field(:until, :date)
    field(:from_dt, :utc_datetime_usec)
    field(:until_dt, :utc_datetime_usec)
    field(:from_number, :integer)
    field(:to_number, :integer)
    field(:money, Money.Ecto.Composite.Type, default_currency: :EUR)

    belongs_to(:parent, __MODULE__)
    has_many(:children, __MODULE__, foreign_key: :parent_id)
  end

  def changeset(params \\ %{}), do: cast(%__MODULE__{}, params, @attrs)
end
