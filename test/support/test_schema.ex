# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestSchema do
  @moduledoc false

  use BitcrowdEcto.Schema

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

    belongs_to(:parent, __MODULE__)
    has_many(:children, __MODULE__, foreign_key: :parent_id)
  end
end
