require "mal/reader.rb"
require "mal/printer.rb"
require "mal/types.rb"
require "mal/env.rb"
require "mal/core.rb"

require "mal/<step>.rb"

require "mal/test/cases/parse_cases.rb"

def test_mal_cases args, assert
  repl = Mal::Repl.new
  
  cases = parse_test_cases "<step>"

  cases[:success].each do |(input, expected)|
    print "test input: " + input.to_s + "\n"
    print "  expected: " + expected + "\n"
    result = nil
    input.each do |i|
      result = repl.REP i
    end
    print "    output: " + result + "\n"
    print "\n"
    
    assert.equal! result, expected
  end

  cases[:error].each do |(input, expected)|
    print "    test input: " + input.to_s + "\n"
    print "expected error: " + expected.to_s + "\n"
    result = nil
    input.each do |i|
      result = repl.REP i
    end
    print "  actual error: " + result + "\n"
    print "\n"

    # Since no regex we just assert it looks like a MAL error
    assert.true! result.start_with? "* Mal Error:"
  end
end
