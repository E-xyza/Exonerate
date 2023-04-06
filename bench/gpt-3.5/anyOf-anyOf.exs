defmodule :"anyOf-anyOf-gpt-3.5" do
  def validate(object) when is_integer(object) do
    :ok
  end

  def validate(object) when is_map(object) do
    if Map.has_key?(object, "minimum") && object["minimum"] >= 2 do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end