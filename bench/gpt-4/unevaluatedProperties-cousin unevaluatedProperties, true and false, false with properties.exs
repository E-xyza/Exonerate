defmodule :"cousin unevaluatedProperties, true and false, false with properties" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, "foo") do
      true ->
        foo_value = Map.get(object, "foo")

        if is_binary(foo_value) do
          if Enum.count(object) == 1 do
            :ok
          else
            :error
          end
        else
          :error
        end

      false ->
        if Enum.count(object) == 0 do
          :ok
        else
          :error
        end
    end
  end

  def validate(_), do: :error
end
