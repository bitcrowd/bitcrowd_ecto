# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestRepo.Migrations.AddMoneyToTestSchema do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE public.money_with_currency AS (amount integer, currency varchar(3))",
      "DROP TYPE public.money_with_currency"
    )

    alter table(:test_schema) do
      add(:money, :money_with_currency, null: true)
    end
  end
end
