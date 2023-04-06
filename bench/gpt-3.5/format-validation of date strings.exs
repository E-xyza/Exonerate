defmodule :"format-validation of date strings-gpt-3.5" do
  def validate(data) do
    case data do
      %{"format" => "date"} -> :ok
      _ -> :error
    end
  end
end