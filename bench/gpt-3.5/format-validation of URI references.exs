defmodule :"validation of URI references-gpt-3.5" do
  def validate(object) when is_binary(object) do
    case Poison.decode(object) do
      {:ok, decoded} -> validate(decoded)
      _ -> :error
    end
  end

  def validate(object)
      when is_map(object) and map_size(object) == 1 and Map.keys(object) == [:format] and
             String.match?(
               Map.get(
                 object,
                 :format
               ),
               ~r/^[\w\+\.\/-]+:\S+$/i
             ) do
    :ok
  end

  def validate(_) do
    :error
  end
end
