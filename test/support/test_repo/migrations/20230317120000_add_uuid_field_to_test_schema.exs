# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestRepo.Migrations.AddUuidFieldToTestSchema do
  use Ecto.Migration

  def change do
    alter table(:test_schema) do
      add(:some_uuid, :binary_id, null: true)
    end

    alter table(:test_schema, prefix: "foo") do
      add(:some_uuid, :binary_id, null: true)
    end
  end
end
