defmodule :"required validation" do
  def validate(object) when is_map(object) do
    if Map.has_key?(object, "foo") do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error
end
