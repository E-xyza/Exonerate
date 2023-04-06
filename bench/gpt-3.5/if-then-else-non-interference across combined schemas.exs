defmodule :"if-then-else-non-interference across combined schemas-gpt-3.5" do
  def validate(json) when is_map(json) do
    exclusive_maximum =
      Map.get(
        json,
        "exclusiveMaximum"
      )

    minimum =
      Map.get(
        json,
        "minimum"
      )

    multiple_of =
      Map.get(
        json,
        "multipleOf"
      )

    if exclusive_maximum == 0 do
      if minimum == nil or minimum < -10 do
        if multiple_of == nil or rem(0, multiple_of) == 0 do
          :ok
        else
          :error
        end
      else
        :error
      end
    else
      if multiple_of == nil or rem(0, multiple_of) == 0 do
        :ok
      else
        :error
      end
    end
  end

  def validate(_) do
    :error
  end
end