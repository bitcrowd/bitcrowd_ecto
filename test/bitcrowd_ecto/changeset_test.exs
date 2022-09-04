# SPDX-License-Identifier: Apache-2.0

defmodule BitcrowdEcto.ChangesetTest do
  use BitcrowdEcto.TestCase, async: true
  import BitcrowdEcto.Assertions
  import BitcrowdEcto.Changeset

  @one_euro Money.new(:EUR, 1)
  @two_euros Money.new(:EUR, 2)
  @three_euros Money.new(:EUR, 3)

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

    test "includes from/to fields in error details" do
      assert %Ecto.Changeset{errors: [some_string: {_msg, details}]} =
               transition_changeset(:foo, :bar, [])

      assert details[:from] == :foo
      assert details[:to] == :bar
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
    end

    defp valid_email_error(value) do
      cs = value |> email_changeset() |> validate_email(:some_string)

      :format in flat_errors_on(cs, :some_string)
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

    test ":only_web option" do
      cs = email_changeset("foo@example")

      cs = validate_email(cs, :some_string, only_web: false)
      assert cs.valid?

      cs = validate_email(cs, :some_string, only_web: true)
      refute cs.valid?
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

  describe "validate_past_datetime/2" do
    defp past_date_changeset(value) do
      %TestSchema{}
      |> Ecto.Changeset.cast(%{datetime: value}, [:datetime])
      |> validate_past_datetime(:datetime)
    end

    test "now is valid" do
      refute :date_in_past in flat_errors_on(past_date_changeset(DateTime.utc_now()), :datetime)
    end

    test "past dates are valid" do
      refute :date_in_past in flat_errors_on(
               past_date_changeset(DateTime.utc_now() |> DateTime.add(-60, :second)),
               :datetime
             )
    end

    test "future dates are invalid" do
      assert :date_in_past in flat_errors_on(
               past_date_changeset(DateTime.utc_now() |> DateTime.add(5, :second)),
               :datetime
             )
    end

    test "accepts another now parameter" do
      value = DateTime.utc_now() |> DateTime.add(-60, :second)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      cs =
        %TestSchema{}
        |> Ecto.Changeset.cast(%{datetime: value}, [:datetime])
        |> validate_past_datetime(:datetime, now)

      refute :date_in_past in flat_errors_on(cs, :datetime)
    end
  end

  describe "validate_future_datetime/2" do
    defp future_date_changeset(value) do
      %TestSchema{}
      |> Ecto.Changeset.cast(%{datetime: value}, [:datetime])
      |> validate_future_datetime(:datetime)
    end

    test "now is not valid" do
      assert :date_in_future in flat_errors_on(
               future_date_changeset(DateTime.utc_now()),
               :datetime
             )
    end

    test "future dates are valid" do
      refute :date_in_future in flat_errors_on(
               future_date_changeset(DateTime.utc_now() |> DateTime.add(60, :second)),
               :datetime
             )
    end

    test "past dates are invalid" do
      assert :date_in_future in flat_errors_on(
               future_date_changeset(DateTime.utc_now() |> DateTime.add(-5, :second)),
               :datetime
             )
    end

    test "accepts another now parameter" do
      value = DateTime.utc_now() |> DateTime.add(60, :second)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      cs =
        %TestSchema{}
        |> Ecto.Changeset.cast(%{datetime: value}, [:datetime])
        |> validate_future_datetime(:datetime, now)

      refute :date_in_future in flat_errors_on(cs, :datetime)
    end
  end

  describe "validate_datetime_after/3" do
    defp datetime_after_changeset(value, datetime) do
      %TestSchema{}
      |> Ecto.Changeset.cast(%{datetime: value}, [:datetime])
      |> validate_datetime_after(:datetime, datetime)
    end

    test "with a reference date" do
      now = DateTime.utc_now()

      assert flat_errors_on(
               datetime_after_changeset(now, now),
               :datetime
             ) == ["must be after #{DateTime.to_string(now)}", :datetime_after]

      refute :datetime_after in flat_errors_on(
               datetime_after_changeset(now, now |> DateTime.add(-1)),
               :datetime
             )
    end

    test "with a custom formatter" do
      now = DateTime.utc_now()
      formatter = fn datetime -> DateTime.to_date(datetime) end

      cs =
        %TestSchema{}
        |> Ecto.Changeset.cast(%{datetime: now}, [:datetime])
        |> validate_datetime_after(:datetime, now, formatter: formatter)

      assert flat_errors_on(cs, :datetime) == [
               "must be after #{DateTime.to_date(now)}",
               :datetime_after
             ]
    end
  end

  describe "validate_date_order/3" do
    defp date_order_changeset(from, until) do
      %TestSchema{from: from}
      |> Ecto.Changeset.cast(%{until: until}, [:until])
      |> validate_date_order(:from, :until)
    end

    defp date_order_changeset(from, until, opts) do
      %TestSchema{from: from}
      |> Ecto.Changeset.cast(%{until: until}, [:until])
      |> validate_date_order(:from, :until, opts)
    end

    setup do
      %{today: Date.utc_today()}
    end

    test "date range is valid", %{today: today} do
      refute :date_order in flat_errors_on(
               date_order_changeset(today, today |> Date.add(3)),
               :until
             )
    end

    test "both dates on the same day is valid", %{today: today} do
      refute :date_order in flat_errors_on(date_order_changeset(today, today), :until)
    end

    test "both dates on the same day is invalid given only :lt ordering", %{today: today} do
      assert :date_order in flat_errors_on(
               date_order_changeset(today, today, valid_orders: :lt),
               :until
             )
    end

    test "valid if first date is missing", %{today: today} do
      refute :date_order in flat_errors_on(date_order_changeset(nil, today), :until)
    end

    test "valid if second date is missing", %{today: today} do
      refute :date_order in flat_errors_on(date_order_changeset(today, nil), :until)
    end

    test "first date after second date is invalid", %{today: today} do
      assert :date_order in flat_errors_on(
               date_order_changeset(today, today |> Date.add(-1)),
               :until
             )
    end

    test "with a custom formatter", %{today: today} do
      formatter = fn date -> Date.to_iso8601(date, :basic) end
      cs = date_order_changeset(today, today |> Date.add(-1), formatter: formatter)

      assert flat_errors_on(cs, :until) == [
               "must be after '#{Date.to_iso8601(today, :basic)}'",
               :date_order
             ]
    end
  end

  describe "validate_datetime_order/3" do
    defp datetime_order_changeset(from, until) do
      %TestSchema{}
      |> Ecto.Changeset.cast(%{from_dt: from, until_dt: until}, [:from_dt, :until_dt])
      |> validate_datetime_order(:from_dt, :until_dt)
    end

    defp datetime_order_changeset(from, until, opts) do
      %TestSchema{}
      |> Ecto.Changeset.cast(%{from_dt: from, until_dt: until}, [:from_dt, :until_dt])
      |> validate_datetime_order(:from_dt, :until_dt, opts)
    end

    test "date range is valid" do
      refute :datetime_order in flat_errors_on(
               datetime_order_changeset(~U[2020-01-01 00:00:00Z], ~U[2020-01-01 01:00:00Z]),
               :until_dt
             )
    end

    test "valid if first datetime is missing" do
      refute :datetime_order in flat_errors_on(
               datetime_order_changeset(nil, ~U[2020-01-01 00:00:00Z]),
               :until_dt
             )
    end

    test "valid if second date is missing" do
      refute :datetime_order in flat_errors_on(
               datetime_order_changeset(~U[2020-01-01 00:00:00Z], nil),
               :until_dt
             )
    end

    test "invalid if first datetime is after second datetime" do
      assert :datetime_order in flat_errors_on(
               datetime_order_changeset(~U[2020-01-01 01:00:00Z], ~U[2020-01-01 00:00:00Z]),
               :until_dt
             )
    end

    test "valid for identical datetimes (by default)" do
      refute :datetime_order in flat_errors_on(
               datetime_order_changeset(~U[2020-01-01 00:00:00Z], ~U[2020-01-01 00:00:00Z]),
               :until_dt
             )
    end

    test "invalid for identical datetimes given only the :lt ordering" do
      assert :datetime_order in flat_errors_on(
               datetime_order_changeset(~U[2020-01-01 00:00:00Z], ~U[2020-01-01 00:00:00Z],
                 valid_orders: :lt
               ),
               :until_dt
             )
    end

    test "with a custom formatter" do
      from = ~U[2020-01-01 01:00:00Z]
      until = ~U[2020-01-01 00:00:00Z]

      cs = datetime_order_changeset(from, until, formatter: &DateTime.to_date/1)

      assert flat_errors_on(cs, :until_dt) == [
               "must be after '#{DateTime.to_date(from)}'",
               :datetime_order
             ]
    end
  end

  describe "validate_order/5" do
    defp number_order_changeset(from_number, to_number) do
      %TestSchema{}
      |> Ecto.Changeset.cast(%{from_number: from_number, to_number: to_number}, [
        :from_number,
        :to_number
      ])
      |> validate_order(:from_number, :to_number, :numbers_order_consistency)
    end

    test "does not add any error when the numbers order is valid" do
      refute :numbers_order_consistency in flat_errors_on(
               number_order_changeset(0, 1),
               :to_number
             )
    end

    test "adds an error to the :to_number field in the changeset when the order is invalid" do
      assert flat_errors_on(
               number_order_changeset(10, 9),
               :to_number
             ) == ["must be after '10'", :numbers_order_consistency]
    end
  end

  describe "validate_hex_color/2" do
    test "validate representative hexadecimal colors" do
      valid_cs = fn cs, expected -> assert cs.valid? == expected end

      test_cases = [
        %{pattern: "#aaaaaa", valid: true},
        %{pattern: "#AAAAAA", valid: true},
        %{pattern: "#123456", valid: true},
        %{pattern: "#zzzzzz", valid: false},
        %{pattern: "aaaaaa", valid: false},
        %{pattern: "#", valid: false}
      ]

      Enum.each(test_cases, fn test_case ->
        %TestSchema{}
        |> Ecto.Changeset.cast(%{some_string: test_case.pattern}, [:some_string])
        |> validate_hex_color(:some_string)
        |> valid_cs.(test_case.valid)
      end)
    end
  end

  describe "validate_date_after/3" do
    test "validate representative dates" do
      valid_cs = fn cs, expected -> assert cs.valid? == expected end

      test_cases = [
        %{date_field: ~D[2022-06-01], ref_date: ~D[2022-06-01], valid: true},
        %{date_field: ~D[2022-06-01], ref_date: ~D[2022-05-01], valid: true},
        %{date_field: ~D[2022-06-01], ref_date: ~D[2022-07-01], valid: false},
        %{date_field: "not a date", ref_date: ~D[2022-01-01], valid: false}
      ]

      Enum.each(test_cases, fn test_case ->
        %TestSchema{}
        |> Ecto.Changeset.cast(%{from: test_case.date_field}, [:from])
        |> validate_date_after(:from, test_case.ref_date)
        |> valid_cs.(test_case.valid)
      end)
    end
  end

  describe "validate_money/3 when currency" do
    test "returns a valid changeset" do
      %TestSchema{}
      |> change(%{money: @one_euro})
      |> validate_money(:money, currency: :EUR)
      |> assert_changeset_valid()
    end

    test "returns an invalid changeset when invalid currency" do
      %TestSchema{}
      |> change(%{money: @one_euro})
      |> validate_money(:money, currency: :USD)
      |> assert_error_on(:money, :currency)
      |> refute_changeset_valid()
    end
  end

  describe "validate_money/3 when more_than_or_equal_to" do
    test "returns a valid changeset when equal" do
      %TestSchema{}
      |> change(%{money: @two_euros})
      |> validate_money(:money, more_than_or_equal_to: @two_euros)
      |> assert_changeset_valid()
    end

    test "returns a valid changeset when more" do
      %TestSchema{}
      |> change(%{money: @three_euros})
      |> validate_money(:money, more_than_or_equal_to: @two_euros)
      |> assert_changeset_valid()
    end

    test "returns an invalid changeset when less" do
      %TestSchema{}
      |> change(%{money: @one_euro})
      |> validate_money(:money, more_than_or_equal_to: @two_euros)
      |> refute_changeset_valid()
      |> assert_error_on(:money, :more_than_or_equal_to)
    end
  end

  describe "validate_money/3 when less_than_or_equal_to" do
    test "returns a valid changeset when equal" do
      %TestSchema{}
      |> change(%{money: @two_euros})
      |> validate_money(:money, less_than_or_equal_to: @two_euros)
      |> assert_changeset_valid()
    end

    test "returns a valid changeset when less" do
      %TestSchema{}
      |> change(%{money: @one_euro})
      |> validate_money(:money, less_than_or_equal_to: @two_euros)
      |> assert_changeset_valid()
    end

    test "returns an invalid changeset when more" do
      %TestSchema{}
      |> change(%{money: @three_euros})
      |> validate_money(:money, less_than_or_equal_to: @two_euros)
      |> refute_changeset_valid()
      |> assert_error_on(:money, :less_than_or_equal_to)
    end
  end

  describe "validate_money/3 when more_than" do
    test "returns a valid changeset when more" do
      %TestSchema{}
      |> change(%{money: @three_euros})
      |> validate_money(:money, more_than: @two_euros)
      |> assert_changeset_valid()
    end

    test "returns an invalid changeset when equal" do
      %TestSchema{}
      |> change(%{money: @two_euros})
      |> validate_money(:money, more_than: @two_euros)
      |> refute_changeset_valid()
      |> assert_error_on(:money, :more_than)
    end

    test "returns an invalid changeset when less" do
      %TestSchema{}
      |> change(%{money: @one_euro})
      |> validate_money(:money, more_than: @two_euros)
      |> refute_changeset_valid()
      |> assert_error_on(:money, :more_than)
    end
  end

  describe "validate_money/3 when less_than" do
    test "returns a valid changeset when less" do
      %TestSchema{}
      |> change(%{money: @two_euros})
      |> validate_money(:money, less_than: @three_euros)
      |> assert_changeset_valid()
    end

    test "returns an invalid changeset when equal" do
      %TestSchema{}
      |> change(%{money: @two_euros})
      |> validate_money(:money, less_than: @two_euros)
      |> refute_changeset_valid()
      |> assert_error_on(:money, :less_than)
    end

    test "returns an invalid changeset when more" do
      %TestSchema{}
      |> change(%{money: @three_euros})
      |> validate_money(:money, less_than: @two_euros)
      |> refute_changeset_valid()
      |> assert_error_on(:money, :less_than)
    end
  end

  describe "validate_money/3 when equal_to" do
    test "returns a valid changeset when equal" do
      %TestSchema{}
      |> change(%{money: @two_euros})
      |> validate_money(:money, equal_to: @two_euros)
      |> assert_changeset_valid()
    end

    test "returns an invalid changeset when less" do
      %TestSchema{}
      |> change(%{money: @two_euros})
      |> validate_money(:money, equal_to: @three_euros)
      |> refute_changeset_valid()
      |> assert_error_on(:money, :equal_to)
    end

    test "returns an invalid changeset when more" do
      %TestSchema{}
      |> change(%{money: @three_euros})
      |> validate_money(:money, equal_to: @two_euros)
      |> refute_changeset_valid()
      |> assert_error_on(:money, :equal_to)
    end
  end

  describe "validate_money/3 when unknown validator" do
    test "raises an error" do
      assert_raise RuntimeError, ~r/Unknown money validator 'almost_equal_to'/, fn ->
        %TestSchema{}
        |> change(%{money: @three_euros})
        |> validate_money(:money, almost_equal_to: @two_euros)
      end
    end
  end

  describe "validate_money/3 when given not Money field" do
    test "raises an error" do
      assert_raise RuntimeError, ~r/given field must be Money/, fn ->
        %TestSchema{}
        |> change(%{some_integer: 1})
        |> validate_money(:some_integer, more_than: @two_euros)
      end
    end
  end
end
