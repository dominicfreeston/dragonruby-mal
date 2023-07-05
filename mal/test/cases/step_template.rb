require "mal/reader.rb"
require "mal/printer.rb"
require "mal/types.rb"

require "mal/<step>.rb"

require "mal/test/cases/parse_cases.rb"

def test_mal_cases args, assert
  cases = parse_test_cases "<step>"
  cases.each do |input, expected|
    result = (REP input)
    
    print "test input: " + input + "\n"
    print "    output: " + result + "\n"
    print "  expected: " + expected + "\n"
    print "\n"
    assert.equal! result, expected
  end
end

