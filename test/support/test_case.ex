# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias BitcrowdEcto.TestRepo
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import BitcrowdEcto.Factory
      import BitcrowdEcto.TestCase

      alias BitcrowdEcto.{
        AlternativePrimaryKeyTestSchema,
        TestRepo,
        TestSchema,
        TestSchemaWithPrefix
      }
    end
  end

  setup tags do
    :ok = Sandbox.checkout(TestRepo)

    unless tags[:async] do
      Sandbox.mode(TestRepo, {:shared, self()})
    end

    :ok
  end
end
