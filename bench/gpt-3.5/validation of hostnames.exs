defmodule :"validation of hostnames-gpt-3.5" do
  def validate(%{"format" => "hostname"} = value) do
    case :inet.gethostname() == value do
      true -> :ok
      false -> :error
    end
  end

  def validate(%{"type" => "object"} = value) do
    case is_map(value) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end
