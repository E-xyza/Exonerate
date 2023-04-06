defmodule :"uniqueItems-uniqueItems=false validation-gpt-3.5" do
  @moduledoc "Validates a JSON object against the 'uniqueItems=false' schema.\n"
  @doc "Validates the given JSON object against the schema.\n"
  @spec validate(Map.t()) :: :ok | :error
  def validate(%{uniqueItems: false} = object) when is_list(object) do
    if Enum.uniq(object) == object do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end