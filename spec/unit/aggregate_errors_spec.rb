# frozen_string_literal: true

RSpec.describe TTY::Option::AggregateErrors do
  context "checks presence" do
    it "is empty by default" do
      errors = described_class.new

      expect(errors.empty?).to eq(true)
      expect(errors.any?).to eq(false)
    end

    it "is not empty" do
      errors = described_class.new

      errors.add TTY::Option::InvalidArgument.new("invalid argument")

      expect(errors.empty?).to eq(false)
      expect(errors.any?).to eq(true)
    end
  end

  context "calculates number" do
    it "has no elements by default" do
      errors = described_class.new

      expect(errors.count).to eq(0)
      expect(errors.size).to eq(0)
    end

    it "counts all errors" do
      errors = described_class.new

      errors.add TTY::Option::InvalidArgument.new("invalid argument")

      expect(errors.count).to eq(1)
      expect(errors.size).to eq(1)
    end
  end

  context "messages" do
    it "returns an empty list when no errors" do
      errors = described_class.new

      expect(errors.messages).to eq([])
    end

    it "returns a list of all messages" do
      invalid_argument = TTY::Option::InvalidArgument.new("invalid argument")
      invalid_arity = TTY::Option::InvalidArity.new("invalid arity")

      errors = described_class.new([invalid_argument, invalid_arity])

      expect(errors.messages).to eq(["invalid argument", "invalid arity"])
    end
  end
end
