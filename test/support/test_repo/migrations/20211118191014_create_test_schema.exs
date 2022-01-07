defmodule BitcrowdEcto.TestRepo.Migrations.CreateTestSchema do
  use Ecto.Migration

  def change do
    create table(:test_schema) do
      add(:some_string, :string)
      add(:some_integer, :integer)
      add(:some_boolean, :boolean)

      add(:parent_id, references(:test_schema), null: true)
    end
  end
end
