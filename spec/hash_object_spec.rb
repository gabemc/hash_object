require 'spec_helpers'
require 'hash_object'

describe HashObject do
  class D
    include HashObject
    element :original_name, :name => 'originalName'
  end

  class C
    include HashObject
    element :name
  end

  class B
    include HashObject
    element :address
    strict false
  end

  class A 
    include HashObject
    element :name
    has_many :aliases, :required => false, :default => lambda(){Array.new}
    boolean :default, :required => false, :default => false
    has_many :b, :required => false, :type => B
    has_many :c, :required => false, :builder => lambda {|x|"_#{x}_"}
  end

  context "for configured objects" do
    before :each do
      @a = A.new
    end

    it "should create new methods for 'once'" do
      @a.should respond_to(:name)
      @a.should respond_to(:name=)
    end

    it "should create new methods for 'has_many'" do
      @a.should respond_to(:aliases)
      @a.should respond_to(:aliases=)
    end

    it "should create new methods for booleans" do
      @a.should respond_to(:default?)
      @a.should respond_to(:default=)
    end

    it "should be able to suppress the creation of the reader" do
      @a.should_not respond_to(:default)
    end

    it "should fail when an object doesn't implement 'parse'" do
      attempting {
        class X
          include HashObject
          element :here, :type => String
        end
      }.should raise_error(HashObject::ConfigurationError, /requires type/)
    end
  end

  context "for parsed objects" do
    it "should fail when an element isn't supported" do
      attempting {
        A.parse({'noattr' => 'foo'})
      }.should raise_error(HashObject::ConfigurationError, /noattr/)
    end
    
    it "should not fail when the object being parsed is not strict" do
      attempting {
        B.parse({'address' => 'this', 'not-an-element' => 'goes here'})
      }.should_not raise_error
    end

    it "should set the required elements" do
      a = A.parse({'name' => 'bob'})
      a.name.should eql('bob')
    end

    it "should set the default values if not set" do
      a = A.parse({'name' => 'bob'})
      a.aliases.should eql([])
    end

    it "should fail when the name isn't there" do
      attempting {
        A.parse({})
      }.should raise_error(HashObject::ConfigurationError, /'name' attribute is required for/)
    end

    it "should set collection values" do
      a = A.parse({'name' => 'bob', 'aliases' => ['this', 'that']})
      a.aliases.should eql(['this', 'that'])
    end

    it "should handle nested types" do
      a = A.parse({'name' => 'bob', 'b' => [{'address' => 'someplace'}]})
      a.b[0].address.should eql('someplace')
    end

    it "should return false when querried about empty sublists" do
      a = A.parse({'name' => 'bob'})
      a.aliases?.should be_false
    end

    it "should create objects using builders, when necessary" do
      a = A.parse({'name' => 'bob', 'c' => ['x', 'y']})
      a.c.should eql(['_x_', '_y_'])
    end

    it "should be able to map an original name to a new name" do
      d = D.parse({'originalName' => 'orin'})
      d.original_name.should eql('orin')
    end
  end
end
