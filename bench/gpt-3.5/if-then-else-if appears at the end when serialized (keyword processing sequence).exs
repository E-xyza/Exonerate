defmodule :"if appears at the end when serialized (keyword processing sequence)-gpt-3.5" do
  def validate(object) when is_map(object) do
    if_max_length =
      case Map.get(object, "maxLength") do
        nil -> true
        value -> value <= 4
      end

    if_const =
      case Map.get(object, "const") do
        "other" -> false
        _ -> true
      end

    if if_max_length and if_const do
      case Map.get(object, "else") do
        "other" ->
          case Map.get(object, "then") do
            "yes" -> :ok
            _ -> :error
          end

        _ ->
          :error
      end
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end