# SPDX-License-Identifier: Apache-2.0

BitcrowdEcto.TestRepo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(BitcrowdEcto.TestRepo, :manual)

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
