defmodule :"anyOf complex types-gpt-3.5" do
  def validate(json) when is_map(json) do
    case %{properties: %{bar: %{type: "integer"}}, required: ["bar"]} in json do
      :ok ->
        :ok

      _ ->
        case %{properties: %{foo: %{type: "string"}}, required: ["foo"]} in json do
          :ok -> :ok
          _ -> :error
        end
    end
  end

  def validate(_) do
    :error
  end
end