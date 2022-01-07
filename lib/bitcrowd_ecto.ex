# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto do
  @readme Path.join([__DIR__, "../README.md"])
  @external_resource @readme

  @moduledoc @readme
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.drop(1)
             |> Enum.take_every(2)
             |> Enum.join("\n")

  @moduledoc since: "0.1.0"
end
