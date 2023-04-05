defmodule :"ignore then without if-gpt-3.5" do
  def validate(object) when is_map(object) do
    cond do
      Map.has_key?(object, "then") and object["then"] == %{"const" => 0} -> :ok
      true -> :error
    end
  end

  def validate(_) do
    :error
  end
end