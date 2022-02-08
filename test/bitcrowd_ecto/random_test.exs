defmodule BitcrowdEcto.RandomTest do
  use ExUnit.Case, async: true
  import BitcrowdEcto.Random

  describe "uuid/0" do
    test "generates a random UUID" do
      assert uuid() =~ ~r/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
      refute uuid() == uuid()
    end
  end

  describe "url_token/1" do
    test "generates a long random token suitable for inclusion in URLs" do
      token = url_token()
      assert String.length(token) == 44
      assert {:ok, _} = Base.url_decode64(token)
      refute url_token() == url_token()
    end

    test "'bytes' parameter controls the length" do
      assert String.length(url_token(16)) == 24
    end
  end

  describe "unambiguous_human_token/1" do
    test "generates an uppercase human-readable token" do
      assert unambiguous_human_token() =~ ~r/[0123456789CFGHJKLMNPRTVWXYZ]{6}/
    end

    test "'length' parameter controls the length" do
      assert String.length(unambiguous_human_token(12)) == 12
    end
  end
end
