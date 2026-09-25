
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

write_out = fn
  data, file ->
    case File.write(file, data, [:append]) do
      :ok ->
        true
      {:error, reason} ->
        IO.puts("Failed to write to #{file}. Reason: #{reason}")
    end
end

generate_html = fn
  nil, _buffer ->
    # return a string instead of nil so everything else like the file writing works fine
    ""

  groups, buffer ->
    functionName = groups["function_name"]
    arguments = groups["arguments"]

    """
    <h2 class="lieksa-function-name">#{functionName}</h2>

    <h3 class="lieksa-function-arguments">Receives: #{arguments}</h3>

    <p class="lieksa-function-description">
    #{buffer}
    </p>

    """
end


[fileToRead, fileToCreate | flags] = case System.argv() do
  [fileToRead, fileToCreate | flags] ->
    [fileToRead, fileToCreate | flags]
  _ ->
    IO.puts("Please provide your code and your desired output file name as the first and second arguments.")
    System.stop()
end



generate_stylesheet = Enum.member?(flags, "style-it")

link_element = case generate_stylesheet do
  true ->
    """
    body {
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    """ |> write_out.("lieksa.css")

    "<link rel='stylesheet' href='lieksa.css'>"
  false ->
    ""
end

"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Lieksa Documentation</title>
  #{link_element}
</head>
<body>

<!--Generated with Lieksa-->

""" |> write_out.(fileToCreate)

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
      groups = Regex.named_captures(~r/(def|function) (?<function_name>.*?)\((?<arguments>.*?)\)/, line)

      cleaned_buffer = accumulator
      |> Enum.map(&String.replace_prefix(&1, "# ", "")) # remove the comment hashtags
      |> Enum.join("\n")

      generate_html.(groups, cleaned_buffer)
      |> write_out.(fileToCreate)

      []
    true ->
      accumulator
  end
end)

# close the opened HTML tags
"""
</body>
</html>
""" |> write_out.(fileToCreate)

IO.puts("Successfully generated your HTML in #{fileToCreate}.")
