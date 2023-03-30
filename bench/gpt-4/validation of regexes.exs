defmodule :"validation of regexes" do
  def validate(regex) when is_binary(regex) do
    case Regex.compile(regex) do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
  end

  def validate(_), do: :error
end
