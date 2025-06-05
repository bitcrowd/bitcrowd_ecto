# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.TestRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :bitcrowd_ecto,
    adapter: Ecto.Adapters.Postgres,
    priv: "test/support/test_repo"

  use BitcrowdEcto.Repo
end

defmodule BitcrowdEcto.TestRepoWithUntaggedNotFoundErrors do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :bitcrowd_ecto,
    adapter: Ecto.Adapters.Postgres,
    priv: "test/support/test_repo"

  use BitcrowdEcto.Repo, tagged_not_found_errors: false
end
