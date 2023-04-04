defmodule :"enums in properties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key(object, "bar") do
      true ->
        case Map.get(object, "bar") do
          "bar" ->
            case Map.has_key(object, "foo") do
              true ->
                case Map.get(object, "foo") do
                  "foo" -> :ok
                  _ -> :error
                end

              false ->
                :error
            end

          _ ->
            :error
        end

      false ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end
