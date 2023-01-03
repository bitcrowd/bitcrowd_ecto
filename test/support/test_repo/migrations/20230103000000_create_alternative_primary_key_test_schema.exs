# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestRepo.Migrations.CreateAlternativePrimaryKeyTestSchema do
  use Ecto.Migration

  def change do
    create table(:alternative_primary_key_test_schema, primary_key: false) do
      add(:name, :string, primary_key: true, null: false)
    end
  end
end
