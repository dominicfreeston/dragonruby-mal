def parse_test_cases step
  path = "mal/test/cases/" + step + ".mal"
  lines = ($gtk.read_file path).split "\n"
  cases = {}
  input = nil
  
  lines.each do |line|
    line = line.trim
    next if line.start_with? ";;"

    if line.start_with? ";=>"
      raise "Invalid file" if input.nil?

      cases[input] = line.delete_prefix ";=>"
      input = nil
    else
      input = line
    end
  end

  cases
end



