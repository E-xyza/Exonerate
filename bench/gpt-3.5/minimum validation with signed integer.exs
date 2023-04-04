defmodule :"minimum validation with signed integer-gpt-3.5" do
  defmodule Validator do
    def validate(object) when is_integer(object) and object >= -2 do
      :ok
    end

    def validate(_) do
      :error
    end
  end

  Validator.validate(decoded_json_value)
end
