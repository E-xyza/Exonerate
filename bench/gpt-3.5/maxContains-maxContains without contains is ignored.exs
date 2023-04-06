defmodule :"maxContains-maxContains without contains is ignored-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.fetch(object, "contains") do
      {:ok, _} ->
        :error

      :error ->
        case Map.fetch(object, "maxContains") do
          {:ok, max_contains} ->
            if Enum.count(object, fn _, value -> Integer.parse(value) == :error end) >
                 max_contains do
              :error
            else
              :ok
            end

          :error ->
            :ok
        end
    end
  end

  def validate(_) do
    :error
  end
end