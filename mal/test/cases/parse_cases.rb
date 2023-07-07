def parse_test_cases step
  path = "mal/test/cases/" + step + ".mal"
  lines = ($gtk.read_file path).split "\n"
  cases = {}
  error_cases = {}
  input = nil
  
  lines.each do |line|
    line = line.trim
    next if line.start_with? ";;"

    if line.start_with? ";=>"
      raise "Invalid file" if input.nil?

      cases[input] = line.delete_prefix ";=>"
      input = nil

    ## This is far from complete but captures a few error cases
    ## Without regexes it's quite tricky though!
    elsif line.start_with? ";/.*"
      raise "Invalid file" if input.nil?

      error_cases[input] = line.delete_prefix(";/.*(")
                             .delete_suffix(").*")
                             .split "|"
      input = nil
    else
      input = line
    end
  end

  {success: cases, error: error_cases}
end



