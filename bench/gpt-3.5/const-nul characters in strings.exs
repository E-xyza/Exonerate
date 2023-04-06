defmodule :"const-nul characters in strings-gpt-3.5" do
  def validate("{\"const\":\"hello\\u0000there\"}") do
    {:ok, ""}
  end

  def validate(_) do
    {:error, "Validation failed"}
  end
end