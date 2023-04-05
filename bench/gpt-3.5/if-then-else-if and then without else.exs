defmodule :"if and then without else-gpt-3.5" do
  def validate(object) when is_map(object) do
    if Map.has_key?(object, "exclusiveMaximum") do
      if object["exclusiveMaximum"] > 0 do
        :error
      else
        if Map.has_key?(object, "minimum") do
          if object["minimum"] >= -10 do
            :ok
          else
            :error
          end
        else
          :ok
        end
      end
    else
      :ok
    end
  end

  def validate(_) do
    :error
  end
end