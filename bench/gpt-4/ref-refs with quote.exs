defmodule :"ref-refs with quote" do
  def validate(value) when is_map(value) and validate_foo_bar(value), do: :ok
  def validate(_), do: :error

  defp validate_foo_bar(%{"foo\"bar" => foo_bar}) when is_number(foo_bar), do: true
  defp validate_foo_bar(_), do: false
end
