defmodule :"single dependency-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, :bar) do
      true ->
        case Map.has_key?(object, :foo) do
          true -> :ok
          false -> :error
        end

      false ->
        :ok
    end
  end

  def validate(_) do
    :error
  end
end