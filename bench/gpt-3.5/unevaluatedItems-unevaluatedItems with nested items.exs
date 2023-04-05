defmodule :"unevaluatedItems-unevaluatedItems with nested items-gpt-3.5" do
  def validate(json) when is_list(json) do
    case json do
      [] ->
        :ok

      _ ->
        case Enum.all?(json, &is_binary/1) do
          true -> :ok
          false -> :error
        end
    end
  end

  def validate(_) do
    :error
  end
end
