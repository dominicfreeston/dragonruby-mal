module Mal
  def self.pr_str f, print_readably=true
    r = print_readably
    case f
    when List
      "(" + f.map { |f| pr_str f, r }.join(" ")  + ")"
    when Vector
      "[" + f.map { |f| pr_str f, r }.join(" ")  + "]"
    when Map
      ret = []
      f.each{ |k,v| ret.push (pr_str k, r), (pr_str v, r) }
      "{" + ret.join(" ") + "}"
    when Keyword
      f
    when String
      if r
        f.inspect
      else
        f
      end
    else
      f.to_s
    end
  end
end