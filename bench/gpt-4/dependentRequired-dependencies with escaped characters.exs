defmodule :"dependentRequired-dependencies with escaped characters" do
  def validate(map) when is_map(map) and no_dependency?(map), do: :ok
  def validate(_), do: :error

  defp no_dependency?(%{"foo\nbar" => _, "foo\rbar" => _}), do: false
  defp no_dependency?(%{"foo\"bar" => _, "foo'bar" => _}), do: false
  defp no_dependency?(map) do
    not (Map.has_key?(map, "foo\nbar") or Map.has_key?(map, "foo\"bar"))
  end
end
