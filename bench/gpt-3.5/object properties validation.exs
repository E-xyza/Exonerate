defmodule :"object properties validation-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, "bar") and is_binary(Map.get(object, "bar")) and
           Map.has_key?(
             object,
             "foo"
           ) and
           is_integer(
             Map.get(
               object,
               "foo"
             )
           ) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end
