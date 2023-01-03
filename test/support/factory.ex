# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: BitcrowdEcto.TestRepo

  def test_schema_factory do
    %BitcrowdEcto.TestSchema{
      some_string: "Happy Halloween!",
      some_integer: 2021
    }
  end

  def alternative_primary_key_test_schema_factory do
    %BitcrowdEcto.AlternativePrimaryKeyTestSchema{
      name: sequence("name")
    }
  end
end
