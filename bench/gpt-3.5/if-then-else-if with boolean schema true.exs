defmodule :"if with boolean schema true-gpt-3.5" do
  def validate(:ok) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{"if" => true, "then" => %{"const" => "then"}, "else" => %{"const" => "else"}}) do
    :ok
  end

  def validate(_) do
    :error
  end
end