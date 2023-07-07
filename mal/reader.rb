module Mal
  WHITESPACE = {" " => :SPACE,
                "\n" => :NEWLINE,
                "\r" => :CARRIAGE_RETURN,
                "\t" => :TAB,
                "," => :COMMA
               }
  
  SPECIALS = {"[" => :OPEN_SQUARE,
              "]" => :CLOSE_SQUARE,
              "{" => :OPEN_BRACE,
              "}" => :CLOSE_BRACE,
              "(" => :OPEN_PAREN,
              ")" => :CLOSE_PAREN,
              "'" => :QUOTE,
              "`" => :BACKTICK,
              "~" => :TILDE,
              "^" => :CARET,
              "@" => :AT
             }

  class Reader
    def initialize tokens
      @tokens = tokens
      @position = 0
    end

    def next
      @position += 1
      @tokens[@position - 1]
    end

    def peek
      @tokens[@position]
    end
  end

  #-----
  
  def self.read_str s
    tokens = (tokenize s)
    (read_form (Reader.new tokens)) 
  end
  
  def self.tokenize s
    tokens = []    
    pos = 0

    while pos < s.size
      c = s[pos]
      
      if WHITESPACE[c]
        pos += 1
      elsif (c == "~") &&
            (pos + 1 < s.size) &&
            (s[pos + 1] == "@")
        tokens << :TAT
        pos += 2
      elsif sp = SPECIALS[c]
        tokens << sp
        pos += 1
      elsif c == "\""
        start = pos
        
        pos += 1
        pos += 1 while (pos + 1 < s.size) &&
                       (s[pos] != "\"" || s[pos - 1] == "\\")

        pos += 1
        
        tokens << s[start...pos]
      elsif c == ";"
        start = pos
        pos += 1 while (pos < s.size) &&
                       (s[pos] != "\n")
        tokens << s[start...pos]
      else
        start = pos
        pos += 1 while (pos < s.size) &&
                       !(SPECIALS[s[pos]]) &&
                       !(WHITESPACE[s[pos]]) &&
                       !(";" == s[pos])
        tokens << s[start...pos]
      end
      
    end

    return tokens
  end

  def self.read_form reader
    case reader.peek
    when :QUOTE
      reader.next
      List.new [:quote, (read_form reader)]
    when :BACKTICK
      reader.next
      List.new [:quasiquote, (read_form reader)]
    when :TILDE
      reader.next
      List.new [:unquote, (read_form reader)]
    when :TAT
      reader.next
      List.new [:"splice-unquote", (read_form reader)]
    when :CARET
      reader.next
      meta = read_form reader
      List.new [:"with-meta", (read_form reader), meta]
    when :AT
      reader.next
      List.new [:deref, (read_form reader)]
    when :OPEN_PAREN
      read_list reader, List, :CLOSE_PAREN
    when :OPEN_SQUARE
      read_list reader, Vector, :CLOSE_SQUARE
    when :OPEN_BRACE
      Map[(read_list reader, List, :CLOSE_BRACE).each_slice(2).to_a]
    else
      read_atom reader
    end
  end

  def self.read_list reader, type=List, close=:CLOSE_PAREN
    ast = type.new

    reader.next
    
    while (reader.peek) &&
          (s = read_form reader) &&
          (s != close) do
      
      ast << s
    end

    if s != close
        raise "expected '" + close.to_s + "', got EOF"
    end
    
    ast
  end

  def self.read_atom reader
    a = reader.next

    v = nil

    v ||= :nil if a == "nil"
    v ||= true  if a == "true"
    v ||= false if a == "false"
    
    v ||= Keyword.new a if a.start_with? ":"
    v ||= parse_str a if a.start_with? "\""
    
    v ||= begin Integer(a) rescue nil end    
    

    v ||= a.intern

    v
  end

  def self.parse_str s
    ok = (s.end_with? "\"") && (s.length > 1)
    
    s = s[1...-1]

    suffix = ""
    s.reverse.each_char do |c|
      if c == "\\"
       suffix += c
      else
        break
      end
    end

    ok = ok && suffix.length.even?

    raise "expected '\"', got EOF" unless ok
    
    s.gsub! "\\\"", "\""
    s.gsub! "\\n", "\n"
    s.gsub! "\\t", "\t"
    s.gsub! "\\\\", "\\"
    s
  end
end
