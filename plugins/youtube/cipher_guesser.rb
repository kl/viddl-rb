require 'open-uri'

class CipherGuesser

  class CipherGuessError < StandardError; end

  JS_URL = "http://s.ytimg.com/yts/jsbin/html5player-%s.js"

  def guess(cipher_version)

    js = download_player_javascript(cipher_version)

    decipher_func_name = js[decipher_function_name_pattern, 1]
    decipher_func_pattern = function_pattern(decipher_func_name)
    body_match = decipher_func_pattern.match(js)

    raise(CipherGuessError, "Could not extract the decipher function") unless body_match

    body = body_match[:brace]

    lines = body.split(";")

    # The first line splits the string into an array and the last joins and returns
    lines.delete_at(0)
    lines.delete_at(lines.size - 1)

    lines.map do |line|
      if /\(\w+,(?<index>\d+)\)/ =~ line # calling a two argument function (swap)
        "w#{index}"
      elsif /slice\((?<index>\d+)\)/ =~ line # calling slice
        "s#{index}"
      elsif /reverse\(\)/ =~ line # calling reverse
        "r"
      else
        raise "Cannot parse line: #{line}"
      end
    end
  end

  private

  def download_player_javascript(cipher_version)
    open(JS_URL % cipher_version).read
  end

  def decipher_function_name_pattern
    # Find "C" in this: var A = B.sig || C (B.s)
    /
    \.sig
    \s*
    \|\|
    (\w+)
    \(
    /x
  end

  def function_pattern(function_name)
  # Match the function function_name (that has one argument)
    /
    #{function_name}
    \(
    \w+
    \)
    #{function_body_pattern}
    /x
  end

  def function_body_pattern
  # Match nested braces
    /
    (?<brace>
    {
    (
    [^{}]
    | \g<brace>
    )*
    }
    )
    /x
  end

end
