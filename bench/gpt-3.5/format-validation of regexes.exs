defmodule :"validation of regexes-gpt-3.5" do
  def validate(value) do
    case value do
      %{"format" => "regex"} -> :ok
      _ -> :error
    end
  end
end