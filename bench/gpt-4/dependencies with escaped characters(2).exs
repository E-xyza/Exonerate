defmodule :"dependencies with escaped characters" do
  def validate(object) when is_map(object) do
    required_fields = Map.keys(object)
    case {Map.has_key?(object, "foo\nbar"), Map.has_key?(object, "foo\"bar")} do
      {true, true} ->
        case {Map.has_key?(object, "foo\rbar"), Map.has_key?(object, "foo'bar")} do
          {true, true} -> :ok
          _ -> :error
        end
      {true, false} ->
        required_fields -- ["foo\nbar", "foo\rbar"] == [] andalso
        object["foo\nbar"] == object["foo\rbar"] andalso
        :ok
      {false, true} ->
        required_fields -- ["foo\"bar", "foo'bar"] == [] andalso
        object["foo\"bar"] == "foo'bar" andalso
        :ok
      _ -> :error
    end
  end

  def validate(_), do: :error
end
