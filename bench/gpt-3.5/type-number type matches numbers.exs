defmodule :"type-number type matches numbers-gpt-3.5" do
    def validate(number) when is_number(number) do
      :ok
    end

    def validate(_) do
      :error
    end
end
