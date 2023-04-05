defmodule :"nested refs-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_ref_c(object)
  end

  def validate(_) do
    :error
  end

  defp validate_ref_c(object) do
    if is_integer(object) do
      :ok
    else
      validate_ref_b(object)
    end
  end

  defp validate_ref_b(object) do
    if is_integer(object) do
      :ok
    else
      :error
    end
  end
end