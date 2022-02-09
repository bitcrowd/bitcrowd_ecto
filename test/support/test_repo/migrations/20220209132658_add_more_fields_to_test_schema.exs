defmodule BitcrowdEcto.TestRepo.Migrations.AddMoreFieldsToTestSchema do
  use Ecto.Migration

  def change do
    alter table(:test_schema) do
      add(:datetime, :utc_datetime_usec, null: true)
      add(:from, :date, null: true)
      add(:until, :date, null: true)
      add(:from_dt, :utc_datetime_usec, null: true)
      add(:until_dt, :utc_datetime_usec, null: true)
      add(:from_number, :integer, null: true)
      add(:to_number, :integer, null: true)
    end
  end
end
