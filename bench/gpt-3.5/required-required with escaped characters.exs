defmodule :"required-required with escaped characters-gpt-3.5" do
  def validate(json) when is_map(json) do
    case Map.has_key?(json, "required") do
      true -> validate_required(json["required"])
      false -> :ok
    end
  end

  def validate(_) do
    :error
  end

  defp validate_required(required) when is_list(required) do
    case Enum.all?(required, &is_foobar/1) do
      true -> :ok
      false -> :error
    end
  end

  defp is_foobar(str) do
    str == "foo\nbar" || str == "foo\"bar" || str == "foo\\bar" || str == "foo\rbar" ||
      str == "foo\tbar" || str == "foo\fbar"
  end
end
