defmodule :"validation of time strings-gpt-3.5" do
  def validate(%{"format" => "time"} = object) do
    :ok
  end

  def validate(_) do
    :error
  end
end
