defmodule :"enum-enum with 1 does not match true-gpt-3.5" do
  def validate({:array, _, enum: enum} = json) when is_list(enum) do
    (fn value ->
       if Enum.member?(enum, value) do
         :ok
       else
         :error
       end
     end).()
  end

  def validate(_) do
    :error
  end
end
