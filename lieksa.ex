
read_file = fn file ->
  case File.read(file) do
    {:ok, contents} ->
      contents
    {:error, :enoent} ->
      IO.puts("The given file: #{file} does not exist in this context.")
      System.stop()
    {:error, reason} ->
      IO.puts("Something went wrong while trying to read #{file}: #{reason}")
      System.stop()
  end
end

generate_html = fn
  nil, _buffer ->
    # return a string instead of nil so everything else like the file writing works fine
    ""
  groups, buffer ->
    functionName = groups["function_name"]
    arguments = groups["arguments"]

    # In the future I might add IDs or classes so the HTML can be styled

    # the buffer might print out as one long string. I'll have to add newlines somehow

    """
    <h2>#{functionName}</h2>

    <h3>Receives: #{arguments}</h3>

    <p>
    #{buffer}
    </p>
    """
end

write_out = fn
  data, file ->
    case File.write(file, data) do
      :ok ->
        true
      {:error, reason} ->
        IO.puts("Failed to write to #{file}. Reason: #{reason}")
    end
end


[fileToRead, fileToCreate] = case System.argv() do
  [fileToRead, fileToCreate] ->
    [fileToRead, fileToCreate]
  _ ->
    IO.puts("Please provide your code and your desired output file name as the first and second arguments.")
    System.stop()
end

read_file.(fileToRead)
|> String.split("\n")
|> Enum.reduce([], fn line, accumulator ->
  cond do
    # comments get added to the buffer
    String.starts_with?(line, "#") ->
      accumulator ++ [line]
    # write the buffer to the output file function declarations
    # the buffer becomes the body and the function name becomes the header.
    # the arguments are important too because those are included in the documentation.
    String.starts_with?(line, "def") ->
      groups = Regex.named_captures(~r/def (?<function_name>.*?)\((?<arguments>.*?)\)/, line)

      cleaned_buffer = accumulator
      |> Enum.map(&String.replace_prefix(&1, "# ", ""))
      |> Enum.join("\n")

      generate_html.(groups, cleaned_buffer)
      |> write_out.(fileToCreate)

    true ->
      accumulator
  end
end)

IO.puts("Successfully generated your HTML in #{fileToCreate}.")
