# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestSchema do
  @moduledoc false

  use BitcrowdEcto.Schema

  schema "test_schema" do
    field(:some_string, :string)
    field(:some_integer, :integer)
    field(:some_boolean, :boolean)

    belongs_to(:parent, __MODULE__)
    has_many(:children, __MODULE__, foreign_key: :parent_id)
  end
end
