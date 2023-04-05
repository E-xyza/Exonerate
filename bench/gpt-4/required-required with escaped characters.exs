defmodule :"required with escaped characters" do
  def validate(object) when is_map(object) and has_required_properties(object), do: :ok
  def validate(_), do: :error

  defp has_required_properties(object) do
    required_properties = ["foo\nbar", "foo\"bar", "foo\\bar", "foo\rbar", "foo\tbar", "foo\fbar"]
    Enum.all?(required_properties, &Map.has_key?(object, &1))
  end
end
