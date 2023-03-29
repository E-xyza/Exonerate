defmodule :"non-interference across combined schemas-gpt-3.5" do
  def validate(object) when is_map(object) do
    if Map.has_key?(object, "exclusiveMaximum") and object["exclusiveMaximum"] == 0 do
      if Map.has_key?(object, "minimum") and object["minimum"] < -10 do
        :error
      else
        :ok
      end
    else
      if Map.has_key?(object, "multipleOf") and rem(object, 2) != 0 do
        :error
      else
        :ok
      end
    end
  end

  def validate(_) do
    :error
  end
end
