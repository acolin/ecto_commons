defmodule EctoCommons.DateValidatorTest do
  use ExUnit.Case, async: true
  import EctoCommons.DateValidator

  doctest EctoCommons.DateValidator, import: true

  @parameters_before [
    # Happy path
    {~D[2015-05-20], ~D[2015-05-24], []},
    {~D[2015-05-20], :utc_today, []},
    # Equal date does not trigger error, it has to be strictly lower.
    {~D[2016-05-24], ~D[2016-05-24], []},

    # Sad path
    {~D[2015-05-25], ~D[2015-05-24],
     [{:birthdate, {"should be before %{before}.", [validation: :datetime, kind: :before]}}]},
    # Compared to another field in changeset happy path
    {~D[2015-05-24], {:before, ~D[2015-03-24]},
     [{:birthdate, {"should be before %{before}.", [validation: :datetime, kind: :before]}}]}
  ]

  for {input, before, expected_errors} <- @parameters_before do
    test "validate_date with #{input} is before #{inspect(before)}, returns errors as #{
           inspect(expected_errors)
         }" do

       params = case is_tuple(unquote(Macro.escape(before))) do
         true ->
           {k, v} = unquote(Macro.escape(before))
           %{
             types: Map.put(%{birthdate: :date}, k, :date),
             params: Map.put(%{birthdate: unquote(Macro.escape(input))}, k, v),
             before: v
           }
         false ->
           %{
             types: %{birthdate: :date},
             params: %{birthdate: unquote(Macro.escape(input))},
             before: unquote(Macro.escape(before))
           }
       end

      result =
        Ecto.Changeset.cast({%{}, params.types}, params.params, Map.keys(params.types))
        |> validate_date(:birthdate, before: params.before)

      assert unquote(Macro.escape(expected_errors)) == result.errors
    end
  end

  @parameters_after [
    # Happy path
    {~D[2015-05-25], ~D[2015-05-24], []},
    {~D[2999-05-25], :utc_today, []},
    # Equal date does not trigger error, it has to be strictly greatly.
    {~D[2015-05-24], ~D[2015-05-24], []},

    # Sad path
    {~D[2015-05-23], ~D[2015-05-24],
     [{:birthdate, {"should be after %{after}.", [validation: :datetime, kind: :after]}}]}
  ]

  for {input, afterr, expected_errors} <- @parameters_after do
    test "validate_date with #{input} is after #{afterr}, returns errors as #{
           inspect(expected_errors)
         }" do
      types = %{birthdate: :date}
      params = %{birthdate: unquote(Macro.escape(input))}

      result =
        Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
        |> validate_date(:birthdate, after: unquote(Macro.escape(afterr)))

      assert unquote(Macro.escape(expected_errors)) == result.errors
    end
  end

  test "validate_date after and before only returns one of the errors" do
    types = %{birthdate: :date}
    params = %{birthdate: ~D[2015-05-24]}

    result =
      Ecto.Changeset.cast({%{}, types}, params, Map.keys(types))
      |> validate_date(:birthdate, after: ~D[2015-05-25], before: ~D[2015-05-25])

    assert [{:birthdate, {"should be after %{after}.", [validation: :datetime, kind: :after]}}] ==
             result.errors
  end
end
