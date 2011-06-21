
# This is a helper module that makes it quite easy to define the
# Hash -> reified object mapping.
module HashObject
  # Adds the class methods that are implemented on the included class.
  def self.included(base)
    base.instance_variable_set("@_elements", {})
    base.instance_variable_set("@_strict", true)
    base.extend ClassMethods
  end

  # We need to convert strange elements into boolean values.
  # This is a convenience class for that purpose.
  class BooleanConverter
    # Parses the current element into a boolean value.
    #
    # @param [Object] element The element to parse.
    # @return [Boolean] The parsed element
    def self.parse(element)
      if element == 'false' || element == 0
        false
      else
        !!element
      end
    end
  end

  # An error thrown if a mapping is somehow incorrect.
  class ConfigurationError < Exception; end

  # An internal object that records the state of the mapping between
  # individual keys in a hash object and the actual methods that need
  # to be created.
  class Element
    # @return [Symbol] sym The name of the method
    attr_reader :sym
    # @return [Symbol] sym The name that is to be parsed from the Hash, if it is not the symbol name.
    attr_reader :name

    # Creates an element mapping.
    #
    # @param [Symbol] sym The symbol that defines the method name (and possibly the element string)
    # @param [Hash] options The initialization options
    # @option options [Boolean] :required Whether this element is required. Default is true.
    # @option options [Object, Proc] :default The default value for the element, if not seen.
    # @option options [Class] :type The type of the element to parse it into.
    # @option options [Object] :builder If this is a complex object that needs to be constructed, you can pass in a builder object
    #     to do the object initialization, circumventing the standard policy.
    # @option options [String] :name If you want to map a regular hash key string into a symbol.
    def initialize(sym, options)
      @sym = sym
      @required = options[:required] != false
      @default = options[:default]
      @type = options[:type]
      @single = options[:single]
      @builder = options[:builder]
      @name = options[:name]

      if @type 
        raise ConfigurationError, "'#{sym}' requires a type: #{@type}" unless @type.is_a?(Class)
        if !@type.respond_to?(:parse)
          raise ConfigurationError, "'#{sym}' attribute requires type '#{@type.name}' to implement 'parse'"
        end
      end
    end

    # Sets the value of the newly created element, either parsing the value,
    # setting the default, or using the builder.
    #
    # @param [Object] obj The object being altered.
    # @param [Object] value The value being set on the object.
    # @return [Object] The value that is set on the object being created.
    def set(obj, value)
      if @type
        if @single
          value = @type.parse(value)
        else
          value = value.map{|e| @type.parse(e)}
        end
      elsif @builder
        if @single
          value = @builder.call(value)
        else
          value = value.map{|e| @builder.call(e)}
        end
      end
      obj.send("#{@sym}=".to_sym, value)
    end

    # Sets the default value of the object.
    #
    # @param [Object] obj The object being altered.
    # @return [nil]
    # @raise [ConfigurationError] If the element is required.
    def set_default(obj)
      if @required
        raise ConfigurationError, "The '#{@sym}' attribute is required for '#{obj.class.name}'"
      else
        obj.send("#{@sym}=".to_sym, default_value)
      end
    end

    # An abstraction around the default value of the object, whether
    # it is a reified object or a Proc that will generate the 
    # default value.
    #
    # @return [Object] The default object
    def default_value
      if @default.is_a?(Proc)
        @default.call
      else
        @default
      end
    end
  end

  # Include the given class methods that will be used to create 
  # associated element mappings.
  module ClassMethods

    # Whether we will strictly enforce the mapping -- i.e., will we 
    # fail if there are elements in the hash that we don't understand.
    # The default is false.
    #
    # @param [Boolean] bool Whether to make this mapping strict.
    # @return [nil]
    def strict(bool)
      @_strict = !!bool
    end

    # Creates a new element mapping with the given name. This mapping
    # can be highly customized by the options passed in. In fact, the
    # other mapping methods on this class (see #boolean #has_many) simply
    # delegate to this method.
    #
    # @param [Symbol] sym The name of the new property for this object.
    # @param [Hash] options The options that alter how the element is mapped.
    # @option options [Boolean] :reader Whether we support only an attr_writer.
    #    This is a bit weird, as it essentially hides the element from outside 
    #    objects, but it can be useful when going for information hiding, since
    #    the '@sym' name is still visible inside the object.
    # @option options [Boolean] :single Whether we map only a single element. 
    #    Otherwise, we map many elements (see #has_many).
    # @option options [Symbol] :qname The "question" type name for the method.
    #    Since all of the method definitions create a 'element?' method in addition
    #    to the standard 'element' methods, to see if the property is set,
    #    you can customize the name of the question mark method here. Leave off
    #    the '?' at the end, though.
    # @option options [Boolean] :required Whether this element is required. Default is true.
    # @option options [Object, Proc] :default The default value for the element, if not seen.
    # @option options [String, Symbol] :name The actual key in the hash that
    #    we are mapping to, if it is not the actual 'sym' that we passed in.
    # @option options [Proc] :builder A builder proc that will do the actual parsing,
    #    circumventing the standard #parse method.
    # @option options [Class] :type The type that will be used to parse this element.
    # @return [nil]
    def element(sym, options={})
      if options[:reader] == false
        attr_writer sym
      else
        attr_accessor sym
      end
      if options[:single].nil?
        options[:single] ||= true
      end
      if options[:single]
        self.class_eval <<EOF, __FILE__, __LINE__
          def #{options[:qname] || sym}?
            !!@#{sym}
          end
EOF
      else
        self.class_eval <<EOF, __FILE__, __LINE__
          def #{options[:qname] || sym}?
            if @#{sym}.nil?
              false
            else
              !@#{sym}.empty?
            end
          end
EOF
      end

      elem = Element.new(sym, options)
      @_elements[sym.to_s] = elem
      if options[:name]
        @_elements[options[:name]] = elem
      end
      nil
    end

    # Maps an element to a boolean value using the BooleanConverter.
    # 
    # @param [Symbol] sym The name of the boolean property
    # @param [Hash] options The configuration options (see #element)
    # @return [nil]
    def boolean(sym, options={})
      element(sym, {:type => BooleanConverter, :single => true, :reader => false}.merge(options))
    end

    # Maps an array of child elements into a property.
    # 
    # @param [Symbol] sym The name of the many property mappings
    # @param [Hash] options The configuration options (see #element)
    def has_many(sym, options={})
      element(sym, {:single => false}.merge(options))
    end

    # The parse method is what actually unpacks the hash object into
    # a reified object. It does require that the object be a hash. If 
    # you have nested mappings, this method will be called when the
    # child hash objects are parsed into reified objects.  The only
    # time that isn't the case is when you have a builder that handles
    # that object construction for you.
    #
    # @param [Hash] The hash that we are going to unpack.
    # @return [Object] The object that got built.
    def parse(hash)
      raise ArgumentError, "Requires a hash to read in" unless hash.is_a?(Hash)
      obj = new

      # Exclude from checking elements we've already matched
      matching_names = []

      hash.each do |key, value|
        if elem = @_elements[key]
          elem.set(obj, value)
          matching_names << elem.sym.to_s if elem.name == key
        elsif @_strict
          raise ConfigurationError, "Unsupported attribute '#{key}: #{value}' for #{self.name}"
        end
      end

      @_elements.each do |key, elem|
        next if hash.has_key?(key)
        next if matching_names.include?(key)
        elem.set_default(obj) 
      end

      obj
    end
  end
end
