defmodule :"format-validation of hostnames-gpt-3.5" do
  def validate(hostname) when is_binary(hostname) and :inet.gethostname() == hostname do
    :ok
  end

  def validate(_) do
    :error
  end
end