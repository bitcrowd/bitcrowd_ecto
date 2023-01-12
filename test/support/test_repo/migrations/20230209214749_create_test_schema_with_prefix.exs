defmodule BitcrowdEcto.TestRepo.Migrations.CreateTestSchemaWithPrefix do
  use Ecto.Migration

  def change do
    prefix = "foo"
    execute("CREATE SCHEMA IF NOT EXISTS #{prefix};", "DROP SCHEMA IF EXISTS #{prefix};")

    create table(:test_schema, prefix: prefix) do
      add(:some_string, :string)
      add(:some_integer, :integer)
      add(:some_boolean, :boolean)
      add(:datetime, :utc_datetime_usec, null: true)
      add(:from, :date, null: true)
      add(:until, :date, null: true)
      add(:from_dt, :utc_datetime_usec, null: true)
      add(:until_dt, :utc_datetime_usec, null: true)
      add(:from_number, :integer, null: true)
      add(:to_number, :integer, null: true)
      add(:money, :money_with_currency, null: true)

      add(:parent_id, references(:test_schema), null: true)
    end
  end
end
