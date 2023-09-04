# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestRepo.Migrations.CreateSerialPrimaryKeyTestSchema do
  use Ecto.Migration

  def change do
    create table(:serial_primary_key_test_schema) do
    end
  end
end
