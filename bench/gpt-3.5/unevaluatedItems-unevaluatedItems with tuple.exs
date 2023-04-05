defmodule :"unevaluatedItems-unevaluatedItems with tuple-gpt-3.5" do
  def validate(input)
      when is_list(input) and input != [] and List.first(input) == %{"type" => "array"} and
             Keyword.has_key?(
               List.last(input),
               :type
             ) and List.length(List.last(input)[:prefixItems]) == 1 and
             List.first(List.last(input)[:prefixItems]) == %{"type" => "string"} and
             List.last(input)[:unevaluatedItems] == false do
    :ok
  end

  def validate(_) do
    :error
  end
end
