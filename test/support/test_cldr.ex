defmodule BitcrowdEcto.TestCldr do
  @moduledoc false

  use Cldr, locales: ["en"], providers: [Cldr.Number]
end
