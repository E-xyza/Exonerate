defmodule :"not-forbidden property-gpt-3.5" do
  def validate(object) when is_map(object) do
    do_validate(object)
  end

  def validate(_) do
    :error
  end

  defp do_validate(object) do
    case object["foo"] do
      nil -> :ok
      _ -> :error
    end
  end
end