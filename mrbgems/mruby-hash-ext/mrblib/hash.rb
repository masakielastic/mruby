class Hash

  #  ISO does not define Hash#each_pair, so each_pair is defined in gem.
  alias each_pair each

  ##
  # call-seq:
  # Hash[ key, value, ... ] -> new_hash
  # Hash[ [ [key, value], ... ] ] -> new_hash
  # Hash[ object ] -> new_hash
  #
  # Creates a new hash populated with the given objects.
  #
  # Similar to the literal <code>{ _key_ => _value_, ... }</code>. In the first
  # form, keys and values occur in pairs, so there must be an even number of
  # arguments.
  #
  # The second and third form take a single argument which is either an array
  # of key-value pairs or an object convertible to a hash.
  #
  # Hash["a", 100, "b", 200] #=> {"a"=>100, "b"=>200}
  # Hash[ [ ["a", 100], ["b", 200] ] ] #=> {"a"=>100, "b"=>200}
  # Hash["a" => 100, "b" => 200] #=> {"a"=>100, "b"=>200}
  #

  def self.[](*object)
    length = object.length
    if length == 1
      o = object[0]
      if o.respond_to?(:to_hash)
        h = Hash.new
        object[0].to_hash.each { |k, v| h[k] = v }
        return h
      elsif o.respond_to?(:to_a)
        h = Hash.new
        o.to_a.each do |i|
          raise ArgumentError, "wrong element type #{i.class} (expected array)" unless i.respond_to?(:to_a)
          k, v = nil
          case i.size
          when 2
            k = i[0]
            v = i[1]
          when 1
            k = i[0]
          else
            raise ArgumentError, "invalid number of elements (#{i.size} for 1..2)"
          end
          h[k] = v
        end
        return h
      end
    end
    unless length % 2 == 0
      raise ArgumentError, 'odd number of arguments for Hash'
    end
    h = Hash.new
    0.step(length - 2, 2) do |i|
      h[object[i]] = object[i + 1]
    end
    h
  end

  ##
  # call-seq:
  #     hsh.merge!(other_hash)                                 -> hsh
  #     hsh.merge!(other_hash){|key, oldval, newval| block}    -> hsh
  #
  #  Adds the contents of _other_hash_ to _hsh_.  If no block is specified,
  #  entries with duplicate keys are overwritten with the values from
  #  _other_hash_, otherwise the value of each duplicate key is determined by
  #  calling the block with the key, its value in _hsh_ and its value in
  #  _other_hash_.
  #
  #     h1 = { "a" => 100, "b" => 200 }
  #     h2 = { "b" => 254, "c" => 300 }
  #     h1.merge!(h2)   #=> {"a"=>100, "b"=>254, "c"=>300}
  #
  #     h1 = { "a" => 100, "b" => 200 }
  #     h2 = { "b" => 254, "c" => 300 }
  #     h1.merge!(h2) { |key, v1, v2| v1 }
  #                     #=> {"a"=>100, "b"=>200, "c"=>300}
  #

  def merge!(other, &block)
    raise TypeError, "can't convert argument into Hash" unless other.respond_to?(:to_hash)
    if block
      other.each_key{|k|
        self[k] = (self.has_key?(k))? block.call(k, self[k], other[k]): other[k]
      }
    else
      other.each_key{|k| self[k] = other[k]}
    end
    self
  end

  alias update merge!

  ##
  #  call-seq:
  #     hsh.fetch(key [, default] )       -> obj
  #     hsh.fetch(key) {| key | block }   -> obj
  #
  #  Returns a value from the hash for the given key. If the key can't be
  #  found, there are several options: With no other arguments, it will
  #  raise an <code>KeyError</code> exception; if <i>default</i> is
  #  given, then that will be returned; if the optional code block is
  #  specified, then that will be run and its result returned.
  #
  #     h = { "a" => 100, "b" => 200 }
  #     h.fetch("a")                            #=> 100
  #     h.fetch("z", "go fish")                 #=> "go fish"
  #     h.fetch("z") { |el| "go fish, #{el}"}   #=> "go fish, z"
  #
  #  The following example shows that an exception is raised if the key
  #  is not found and a default value is not supplied.
  #
  #     h = { "a" => 100, "b" => 200 }
  #     h.fetch("z")
  #
  #  <em>produces:</em>
  #
  #     prog.rb:2:in `fetch': key not found (KeyError)
  #      from prog.rb:2
  #

  def fetch(key, none=NONE, &block)
    unless self.key?(key)
      if block
        block.call
      elsif none != NONE
        none
      else
        raise RuntimeError, "Key not found: #{key}"
      end
    else
      self[key]
    end
  end

  ##
  #  call-seq:
  #     hsh.delete_if {| key, value | block }  -> hsh
  #     hsh.delete_if                          -> an_enumerator
  #
  #  Deletes every key-value pair from <i>hsh</i> for which <i>block</i>
  #  evaluates to <code>true</code>.
  #
  #  If no block is given, an enumerator is returned instead.
  #
  #     h = { "a" => 100, "b" => 200, "c" => 300 }
  #     h.delete_if {|key, value| key >= "b" }   #=> {"a"=>100}
  #

  def delete_if(&block)
    return to_enum :delete_if unless block_given?

    self.each do |k, v|
      self.delete(k) if block.call(k, v)
    end 
    self
  end

  ##
  #  call-seq:
  #     hash.flatten -> an_array
  #     hash.flatten(level) -> an_array
  #
  #  Returns a new array that is a one-dimensional flattening of this
  #  hash. That is, for every key or value that is an array, extract
  #  its elements into the new array.  Unlike Array#flatten, this
  #  method does not flatten recursively by default.  The optional
  #  <i>level</i> argument determines the level of recursion to flatten.
  #
  #     a =  {1=> "one", 2 => [2,"two"], 3 => "three"}
  #     a.flatten    # => [1, "one", 2, [2, "two"], 3, "three"]
  #     a.flatten(2) # => [1, "one", 2, 2, "two", 3, "three"]
  #

  def flatten(level=1)
    self.to_a.flatten(level)
  end

  ##
  #  call-seq:
  #     hsh.invert -> new_hash
  #
  #  Returns a new hash created by using <i>hsh</i>'s values as keys, and
  #  the keys as values.
  #
  #     h = { "n" => 100, "m" => 100, "y" => 300, "d" => 200, "a" => 0 }
  #     h.invert   #=> {0=>"a", 100=>"m", 200=>"d", 300=>"y"}
  #

  def invert
    h = Hash.new
    self.each {|k, v| h[v] = k }
    h
  end

  ##
  #  call-seq:
  #     hsh.keep_if {| key, value | block }  -> hsh
  #     hsh.keep_if                          -> an_enumerator
  #
  #  Deletes every key-value pair from <i>hsh</i> for which <i>block</i>
  #  evaluates to false.
  #
  #  If no block is given, an enumerator is returned instead.
  #

  def keep_if(&block)
    return to_enum :keep_if unless block_given?

    keys = []
    self.each do |k, v|
      unless block.call([k, v])
        self.delete(k)
      end
    end
    self
  end

  ##
  #  call-seq:
  #     hsh.key(value)    -> key
  #
  #  Returns the key of an occurrence of a given value. If the value is
  #  not found, returns <code>nil</code>.
  #
  #     h = { "a" => 100, "b" => 200, "c" => 300, "d" => 300 }
  #     h.key(200)   #=> "b"
  #     h.key(300)   #=> "c"
  #     h.key(999)   #=> nil
  #

  def key(val)
    self.each do |k, v|
      return k if v == val
    end
    nil
  end

  ##
  #  call-seq:
  #     hsh.to_h     -> hsh or new_hash
  #
  #  Returns +self+. If called on a subclass of Hash, converts
  #  the receiver to a Hash object.
  #
  def to_h
    self
  end
end
