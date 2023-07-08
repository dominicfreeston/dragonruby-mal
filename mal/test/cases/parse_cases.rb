def parse_test_cases step
  path = "mal/test/cases/" + step + ".mal"
  lines = ($gtk.read_file path).split "\n"
  cases = []
  error_cases = []
  input = []
  
  lines.each do |line|
    line = line.trim
    if line.start_with? ";;"
      input = []
      next
    end

    if line.start_with? ";=>"
      raise "Invalid file" if input.empty?

      cases << [input, (line.delete_prefix ";=>")]
      input = []

    elsif line.start_with? ";/.*"
      raise "Invalid file" if input.empty?

      error_cases << [input, (line.delete_prefix ";/")]
      input = []
    else
      input << line
    end
  end

  {success: cases, error: error_cases}
end



