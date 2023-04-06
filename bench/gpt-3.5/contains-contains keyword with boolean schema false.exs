defmodule :"contains-contains keyword with boolean schema false-gpt-3.5" do
  def validate(object) when is_map(object) do
    :error
  end

  def validate(list) when is_list(list) do
    if Enum.member?(list, false) do
      :ok
    else
      :error
    end
  end
end