defmodule :"validate against correct branch, then vs else-gpt-3.5" do
  def validate(object) when is_map(object) do
    if_valid =
      if Map.has_key?(object, "exclusiveMaximum") && object["exclusiveMaximum"] == 0 do
        true
      else
        false
      end

    then_valid =
      if Map.has_key?(object, "minimum") && object["minimum"] >= -10 do
        true
      else
        false
      end

    else_valid =
      if Map.has_key?(object, "multipleOf") && rem(object["multipleOf"], 2) == 0 do
        true
      else
        false
      end

    if if_valid do
      if then_valid do
        if else_valid do
          :ok
        else
          :error
        end
      else
        :error
      end
    else
      :ok
    end
  end

  def validate(_) do
    :error
  end
end