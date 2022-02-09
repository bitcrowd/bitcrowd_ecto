defmodule BitcrowdEcto.Random do
  @moduledoc """
  Various random value generators.
  """

  @moduledoc since: "0.6.0"

  @doc """
  Generates a UUID V4.
  """
  @doc since: "0.6.0"
  @spec uuid() :: String.t()
  defdelegate uuid, to: Ecto.UUID, as: :generate

  @doc """
  Generates a random token suitable for inclusion in URLs.
  """
  @doc since: "0.6.0"
  @spec url_token() :: String.t()
  @spec url_token(bytes :: non_neg_integer) :: String.t()
  def url_token(bytes \\ 16) do
    bytes
    |> random_bytes()
    |> Base.url_encode64(padding: true)
  end

  @german_passport_id_alphabet String.codepoints("0123456789CFGHJKLMNPRTVWXYZ")

  @doc """
  Generates a random token from an alphabet designed to have no ambiguities.
  """
  @doc since: "0.6.0"
  @spec unambiguous_human_token() :: String.t()
  @spec unambiguous_human_token(length :: non_neg_integer) :: String.t()
  def unambiguous_human_token(length \\ 6) do
    for _ <- 1..length do
      Enum.random(@german_passport_id_alphabet)
    end
    |> Enum.join()
  end

  defp random_bytes(n) do
    :crypto.strong_rand_bytes(n)
  end
end
