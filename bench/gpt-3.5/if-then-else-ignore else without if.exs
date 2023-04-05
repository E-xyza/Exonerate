defmodule :"ignore else without if" do
  
defmodule :"if-then-else-ignore else without if" do
  
  def validate(schema) do
    case schema do
      %{"else" => %{"const" => 0}} ->
        fn(_) -> :ok end

      %{"type" => "object"} ->
        fn(object) when is_map(object) -> :ok
        fn(_) -> :error end

      _ ->
        fn(_) -> :error end
    end
  end

end

end
