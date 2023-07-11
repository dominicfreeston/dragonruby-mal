# Cases are:
# 1. input
# 2. tokenize output
# 3. read_form output - i.e the ast
# 4. pr_str output

$cases = [
  [
    "(1  2 3 )  ",
    [:OPEN_PAREN, "1", "2", "3", :CLOSE_PAREN],
    (Mal::List.new [1, 2, 3]),
    "(1 2 3)",
  ],

  ["\"hi\"",
   ["\"hi\""],
   "hi",
   "\"hi\"",
  ],

  [
    "(  :hi there \"my \\\"friend\\\"\" )",
    [:OPEN_PAREN, ":hi", "there", "\"my \\\"friend\\\"\"", :CLOSE_PAREN],
    (Mal::List.new
     [(Mal::Keyword.new ":hi"), :there, "my \"friend\""]),
    "(:hi there \"my \\\"friend\\\"\")"
  ],

  [
    "[ok 1 2]",
    [:OPEN_SQUARE, "ok", "1", "2", :CLOSE_SQUARE],
    (Mal::Vector.new [:ok, 1, 2]),
    "[ok 1 2]"
  ],
]

def test_tokenize _, assert
  $cases.each do |c|
      result = Mal.tokenize c[0]
      assert.equal! [:token, result], [:token, c[1]]
  end
end

def test_read_str _, assert
  $cases.each do |c| 
    result = Mal.read_str c[0]
    assert.equal! [:ast, result], [:ast, c[2]]
  end
end

def test_print_str _, assert
  $cases.each do |c| 
    result = Mal.pr_str (Mal.read_str c[0])
    assert.equal! [:print, result], [:print, c[3]]
  end
end
