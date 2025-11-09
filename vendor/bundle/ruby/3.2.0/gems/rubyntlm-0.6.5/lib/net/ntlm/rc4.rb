require 'openssl'

module Net
module NTLM

  begin
    OpenSSL::Cipher.new("rc4")
  rescue
    # libssl-3.0+ doesn't support legacy Rc4 -> use our own implementation

    class Rc4
      def initialize(str)
        raise ArgumentError, "RC4: Key supplied is blank"  if str.eql?('')
        initialize_state(str)
        @q1, @q2 = 0, 0
      end

      def encrypt(text)
        text.each_byte.map do |b|
          @q1 = (@q1 + 1) % 256
          @q2 = (@q2 + @state[@q1]) % 256
          @state[@q1], @state[@q2] = @state[@q2], @state[@q1]
          b ^ @state[(@state[@q1] + @state[@q2]) % 256]
        end.pack("C*")
      end

      private

      # The initial state which is then modified by the key-scheduling algorithm
      INITIAL_STATE = (0..255).to_a

      # Performs the key-scheduling algorithm to initialize the state.
      def initialize_state(key)
        i = j = 0
        @state = INITIAL_STATE.dup
        key_length = key.length
        while i < 256
          j = (j + @state[i] + key.getbyte(i % key_length)) % 256
          @state[i], @state[j] = @state[j], @state[i]
          i += 1
        end
      end
    end

  else
    # Openssl/libssl provides RC4, so we can use it.
    class Rc4
      def initialize(str)
        @ci = OpenSSL::Cipher.new("rc4")
        @ci.key = str
      end

      def encrypt(text)
        @ci.update(text) + @ci.final
      end
    end
  end
end
end
