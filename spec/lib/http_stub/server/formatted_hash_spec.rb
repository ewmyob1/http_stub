describe HttpStub::Server::FormattedHash do

  let(:underlying_hash)     { {} }
  let(:key_value_delimiter) { "=" }

  let(:formatted_hash) { described_class.new(underlying_hash, key_value_delimiter) }

  it "is a Hash" do
    expect(formatted_hash).to be_a(Hash)
  end

  describe "#to_s" do

    subject { formatted_hash.to_s }

    describe "when a hash with multiple entires is provided" do

      let(:underlying_hash) { { "key1" => "value1", "key2" => "value2", "key3" => "value3" } }

      it "returns a string containing keys and values delimited by the provided delimiter" do
        result = subject

        underlying_hash.each { |key, value| expect(result).to match(/#{key}#{key_value_delimiter}#{value}/) }
      end

      it "comma delimits the entries" do
        expect(subject).to match(/key\d.value\d\, key\d.value\d\, key\d.value\d/)
      end

    end

    describe "when an empty hash is provided" do

      let(:underlying_hash) { {} }

      it "returns an empty string" do
        expect(subject).to eql("")
      end

    end

    describe "when a nil hash is provided" do

      let(:underlying_hash) { nil }

      it "returns an empty string" do
        expect(subject).to eql("")
      end

    end

  end

end
