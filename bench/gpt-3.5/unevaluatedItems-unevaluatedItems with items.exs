defmodule :"unevaluatedItems with items-gpt-3.5" do
  def validate(object) when is_list(object) do
    case Enum.all?(object, fn item -> is_binary(item) end) do
      true -> :ok
      false -> :error
    end
  end

  def validate(object) when is_map(object) do
    case Map.has_key?(object, :items) and Map.has_key?(object, :prefixItems) do
      true ->
        case Map.get(object, :type, nil) do
          "array" ->
            case Map.get(object, :unevaluatedItems, false) do
              true ->
                :error

              false ->
                case Enum.all?(Map.get(object, :prefixItems, []), fn item ->
                       Map.get(item, :type, nil) == "string"
                     end) do
                  true -> :ok
                  false -> :error
                end
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