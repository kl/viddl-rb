
class DecipherCoordinator

  def initialize(decipherer, cipher_guesser)
    @decipherer = decipherer
    @cipher_guesser = cipher_guesser
  end

  #
  # Returns a two element array. The first element is the deciphered signature and
  # the second is whether the signature was guessed (true) or not (false).
  #
  def decipher(signature, html5_player_version)
    sig = @decipherer.decipher_with_version(signature, html5_player_version)
    [sig, false]

    rescue Decipherer::UnknownCipherVersionError => e
      guess_and_decipher(signature, e.cipher_version)
  end

  def guess_and_decipher(signature, cipher_version)
    operations = @cipher_guesser.guess(cipher_version)
    sig = @decipherer.decipher_with_operations(signature, operations)
    [sig, true]

    rescue Decipherer::UnknownCipherOperationError => e
      Youtube.notify "Failed to parse the cipher from the Youtube player version #{cipher_version}\n" +
                   "Please submit a bug report at https://github.com/rb2k/viddl-rb"
      raise e
  end
  
end
