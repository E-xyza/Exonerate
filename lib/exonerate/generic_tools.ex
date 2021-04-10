defmodule Exonerate.GenericTools do
  defmacro __using__(tools) do
    if :filter_generic in tools do
      quote do
        def filter_generic(spec) do
          List.wrap(if enum = spec.enum do
            quote do
              defp unquote(spec.path)(value, path) when value not in unquote(Macro.escape(enum)) do
                Exonerate.Builder.mismatch(value, path, subpath: "enum")
              end
            end
          end) ++ List.wrap(if const = spec.const do
            quote do
              defp unquote(spec.path)(value, path) when value !== unquote(Macro.escape(const)) do
                Exonerate.Builder.mismatch(value, path, subpath: "const")
              end
            end
          end)
        end
      end
    end
  end
end
