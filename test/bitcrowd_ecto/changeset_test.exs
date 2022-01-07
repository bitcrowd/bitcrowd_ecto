defmodule BitcrowdEcto.ChangesetTest do
  use BitcrowdEcto.TestCase, async: true
  import BitcrowdEcto.Assertions
  import BitcrowdEcto.Changeset

  describe "validate_transition/3" do
    defp transition_changeset(from, to, transitions) do
      %TestSchema{some_string: from}
      |> change(%{some_string: to})
      |> validate_transition(:some_string, transitions)
    end

    defp transition_error(from, to, transitions) do
      :transition in flat_errors_on(transition_changeset(from, to, transitions), :some_string)
    end

    test "validates that a field changes in a predefined way" do
      assert transition_error("foo", "bar", [])
      assert transition_error("foo", "bar", [{"foo", "yolo"}])
      assert transition_error("foo", "bar", [{"bar", "foo"}])
      refute transition_error("foo", "bar", [{"foo", "bar"}])
      refute transition_error("foo", "bar", [{"foo", "yolo"}, {"foo", "bar"}])
    end

    test "recursive transitions (field not changed) are invalid by default" do
      assert transition_error("foo", "foo", [])
      refute transition_error("foo", "foo", [{"foo", "foo"}])
    end

    test "nil values are normal values and are validated" do
      assert transition_error(nil, nil, [])
      assert transition_error("foo", nil, [])
    end
  end

  describe "validate_changed/2" do
    defp changed_changeset(initial, change) do
      %TestSchema{some_string: initial}
      |> change(%{some_string: change})
      |> validate_changed(:some_string)
    end

    defp changed_error(initial, change) do
      :changed in flat_errors_on(changed_changeset(initial, change), :some_string)
    end

    test "validates that a field has been changed" do
      refute changed_error(nil, "foo")
      assert changed_error("foo", "foo")
      refute changed_error("foo", "bar")
    end
  end

  describe "validate_immutable/2" do
    defp immutable_changeset(initial, change) do
      %TestSchema{some_string: initial}
      |> change(%{some_string: change})
      |> validate_immutable(:some_string)
    end

    defp immutable_error(initial, change) do
      :immutable in flat_errors_on(immutable_changeset(initial, change), :some_string)
    end

    test "validates that a field is not changed from its initial value" do
      refute immutable_error(nil, "foo")
      refute immutable_error("foo", "foo")
      assert immutable_error("foo", "bar")
    end
  end

  describe "validate_email/2" do
    defp email_changeset(value) do
      %TestSchema{}
      |> Ecto.Changeset.cast(%{some_string: value}, [:some_string])
      |> validate_email(:some_string)
    end

    defp valid_email_error(value) do
      :format in flat_errors_on(email_changeset(value), :some_string)
    end

    # Our regex comes from somewhere, as does this list of inputs:
    # https://gist.github.com/cjaoude/fd9910626629b53c4d25

    @valid_emails [
      "email@example.com",
      "firstname.lastname@example.com",
      "email@subdomain.example.com",
      "firstname+lastname@example.com",
      "1234567890@example.com",
      "email@example-one.com",
      "_______@example.com",
      "email@example.name",
      "email@example.museum",
      "email@example.co.jp",
      "firstname-lastname@example.com"
    ]

    # further valid according to gist:
    #  "email"@example.com
    #  email@123.123.123.123
    #  email@[123.123.123.123]
    #  much.”more\ unusual”@example.com
    #  very.unusual.”@”.unusual.com@example.com
    #  very.”(),:;<>[]”.VERY.”very@\\ "very”.unusual@strange.example.com

    @invalid_emails [
      "plainaddress",
      "@%^%#$@#$@#.com",
      "@example.com",
      "Joe Smith <email@example.com>",
      "email.example.com",
      "email@example@example.com",
      "あいうえお@example.com",
      "email@example.com (Joe Smith)",
      "email@example..com"
    ]

    # further invalid according to gist:
    #  email@example
    #  email@-example.com
    #  .email@example.com
    #  email.@example.com
    #  email@example.web
    #  email..email@example.com
    #  email@111.222.333.44444
    #  Abc..123@example.com

    test "validates qualified urls" do
      for email <- @valid_emails do
        refute valid_email_error(email), "email not detected as valid: #{email}"
      end

      for email <- @invalid_emails do
        assert valid_email_error(email), "email not detected as invalid: #{email}"
      end
    end

    test "does not fail on a nil url" do
      refute valid_email_error(nil)
    end
  end

  describe "validate_url/2" do
    defp url_changeset(value) do
      %TestSchema{}
      |> Ecto.Changeset.cast(%{some_string: value}, [:some_string])
      |> validate_url(:some_string)
    end

    defp valid_url_error(value) do
      :format in flat_errors_on(url_changeset(value), :some_string)
    end

    @valid_urls [
      "https://elixir-lang.org/",
      "http://elixir-lang.org/"
    ]

    @invalid_urls [
      "//elixir-lang.org/",
      "foo/bar",
      "foo",
      "www.foo.com"
    ]

    test "validates qualified urls" do
      for url <- @valid_urls do
        refute valid_url_error(url), "url not detected as valid: #{url}"
      end

      for url <- @invalid_urls do
        assert valid_url_error(url), "url not detected as invalid: #{url}"
      end
    end

    test "does not fail on a nil url" do
      refute valid_url_error(nil)
    end
  end
end
