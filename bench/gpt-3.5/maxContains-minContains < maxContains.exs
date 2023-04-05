defmodule :"minContains < maxContains-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.fetch(object, "contains") do
      {:ok, contains} when is_list(contains) ->
        case Map.fetch(object, "maxContains") do
          {:ok, max} when is_integer(max) ->
            case Map.fetch(object, "minContains") do
              {:ok, min} when is_integer(min) ->
                if Enum.count(contains, &(&1 == 1)) >= min &&
                     Enum.count(contains, &(&1 == 1)) <= max do
                  :ok
                else
                  :error
                end

              _, _ ->
                :error
            end

          _, _ ->
            :error
        end

      _, _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end