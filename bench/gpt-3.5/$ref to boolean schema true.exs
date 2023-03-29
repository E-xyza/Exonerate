defmodule :"$ref to boolean schema true-gpt-3.5" do
  defmodule Validator do
    def validate(bool) when bool == true or bool == false do
      :ok
    end

    def validate(_) do
      :error
    end
  end

  defmodule JsonSchema do
    def validate(bool) when bool == true or bool == false do
      :ok
    end

    def validate(map) when map == %{"$defs" => defs, "$ref" => "#/$defs/bool"} do
      Validator.validate(defs["bool"])
    end

    def validate(_) do
      :error
    end
  end
end
