defmodule :"by small number-gpt-3.5" do
  def validate(input) do
    case input do
      %{"multipleOf" => multiple_of} ->
        %{
          "type" => "number",
          "minimum" => multiple_of - 5.0e-5,
          "maximum" => multiple_of + 5.0e-5
        }
        |> validate_number(input)

      _ ->
        :error
    end
  end

  defp validate_number(input, schema) do
    case input do
      number when is_number(number) ->
        if is_number_valid(number, schema) do
          :ok
        else
          :error
        end

      _ ->
        :error
    end
  end

  defp is_number_valid(number, schema) do
    rem(abs(number), schema["multipleOf"]) == 0
  end
end