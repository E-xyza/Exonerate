defmodule :"ref-property named $ref that is not a reference-gpt-3.5" do
  @spec validate(term) :: :ok | :error
  def validate(value) when is_map(value) do
    case value["properties"] do
      %{"$ref" => %{"type" => "string"}} -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end