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
    return nil if tokens.size == 0
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

        # advance until you find a " not preceded by a \
        # keeping in mind \\ doesn't count
        c = 0
        while pos < s.length
          pos += 1

          if s[pos] == "\"" && (c % 2) == 0
            break
          elsif s[pos] == "\\"
            c = c + 1
          else
            c = 0
          end
        end
        
        pos += 1

        tokens << s[start...pos]
      elsif c == ";"
        start = pos
        pos += 1 while (pos < s.size) &&
                       (s[pos] != "\n")
        # tokenizing it just means we have to deal with it later?
        # and somehow differentiate between it and nil
        # tokens << s[start...pos]
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
    
    while (token = reader.peek) != close
      if not token
        raise "expected '" + close.to_s + "', got EOF"
      end
      ast << read_form(reader)
    end
    
    reader.next
    
    ast
  end

  def self.read_atom reader
    a = reader.next

    return nil if a == "nil"
    return true if a == "true"
    return false if a == "false"
    
    return Keyword.new a if a.start_with? ":"
    return parse_str a if a.start_with? "\""

    
    i = begin Integer(a) rescue nil end
    return i if i
    
    return  a.intern
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

    r = ""
    leading = false
    s.each_char do |c|
      if c == "\\"
        r += "\\" if leading
      elsif !leading
        r += c
        leading = true
      elsif c == "n"
        r += "\n"
      elsif c == "t"
        r += "\t"
      elsif c == "\""
        r += "\""
      end
      leading = !leading
    end
    r
  end
end
