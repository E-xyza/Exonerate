defmodule :"items-nested items-gpt-3.5" do
  def validate(value)
      when is_list(value) and length(value) > 0 and Enum.all?(value, &is_list/1) and
             Enum.all?(value, fn sub_value ->
               is_list(sub_value) and length(sub_value) > 0 and Enum.all?(sub_value, &is_list/1) and
                 Enum.all?(sub_value, fn item ->
                   is_list(item) and length(item) > 0 and Enum.all?(item, &is_number/1)
                 end)
             end) do
    :ok
  end

  def validate(_) do
    :error
  end
end