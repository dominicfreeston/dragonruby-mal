require "mal/reader.rb"
require "mal/printer.rb"
require "mal/types.rb"

require "mal/step0_repl.rb"

require "mal/test/cases/parse_cases.rb"

def test_mal_cases args, assert
  cases = parse_test_cases "step0_repl"

  cases[:success].each do |input, expected|
    print "test input: " + input + "\n"
    print "  expected: " + expected + "\n"
    result = (REP input)
    print "    output: " + result + "\n"
    print "\n"
    
    assert.equal! result, expected
  end

  cases[:error].each do |input, expected|
    print "    test input: " + input + "\n"
    print "expected error: " + expected.to_s + "\n"

    result = (REP input)
    print "  actual error: " + result + "\n"
    print "\n"

    success = false
    expected.each do |e|
      success = success || (result.include? e)
    end
    assert.true! success
  end
end
