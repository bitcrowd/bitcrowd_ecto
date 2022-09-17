# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestCldr do
  @moduledoc false

  use Cldr, locales: ["en"], providers: [Cldr.Number], generate_docs: false
end
