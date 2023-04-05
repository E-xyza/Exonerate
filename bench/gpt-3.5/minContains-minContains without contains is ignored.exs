defmodule :"minContains-minContains without contains is ignored" do
  
defmodule Validator do
  def validate(json) do
    case json do
      %{} -> %{:ok}
      _   -> %{:error}
    end
  end
end

end
