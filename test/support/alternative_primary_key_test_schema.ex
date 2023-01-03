# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.AlternativePrimaryKeyTestSchema do
  @moduledoc false

  use BitcrowdEcto.Schema

  @primary_key {:name, :string, autogenerate: false}

  schema "alternative_primary_key_test_schema" do
  end
end
