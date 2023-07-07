require "mal/reader.rb"
require "mal/printer.rb"
require "mal/types.rb"

require "mal/step2_eval.rb"

require "mal/test/cases/parse_cases.rb"

def test_mal_cases args, assert
  repl = Mal::Repl.new
  
  cases = parse_test_cases "step2_eval"

  cases[:success].each do |input, expected|
    print "test input: " + input + "\n"
    print "  expected: " + expected + "\n"
    result = (repl.REP input)
    print "    output: " + result + "\n"
    print "\n"
    
    assert.equal! result, expected
  end

  cases[:error].each do |input, expected|
    print "    test input: " + input + "\n"
    print "expected error: " + expected.to_s + "\n"

    result = (repl.REP input)
    print "  actual error: " + result + "\n"
    print "\n"

    success = false
    expected.each do |e|
      success = success || (result.include? e)
    end
    assert.true! success
  end
end
