require "mal/reader.rb"
require "mal/step0_repl.rb"
require "mal/test/cases/parse_cases.rb"

def test_mal_cases args, assert
  cases = parse_test_cases "step0_repl"
  cases.each do |input, expected|
    result = (REP input)
    
    print "test input: " + input.to_s + "\n"
    print "    output: " + result.to_s + "\n"
    print "  expected: " + expected.to_s + "\n"
    print "\n"
    assert.equal! result, expected
  end
end

