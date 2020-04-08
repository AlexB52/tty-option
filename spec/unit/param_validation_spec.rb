# frozen_string_literal: true

RSpec.describe TTY::Option::ParamValidation do
  it "skips validation when no validate setting" do
    param = TTY::Option::Parameter::Option.create(:foo)

    expect(described_class[param, "12"]).to eq("12")
  end

  it "accepts an option parameter as valid" do
    param = TTY::Option::Parameter::Option.create(:foo, validate: /\d+/)

    expect(described_class[param, "12"]).to eq("12")
  end

  it "accepts multiple values in an option parameter as valid" do
    param = TTY::Option::Parameter::Option.create(:foo, validate: /\d+/)

    expect(described_class[param, %w[12 13 14]]).to eq(%w[12 13 14])
  end

  it "fails to accept an option parameter as valid" do
    param = TTY::Option::Parameter::Option.create(:foo, validate: /\d+/)

    expect {
      described_class[param, "bar"]
    }.to raise_error(TTY::Option::InvalidArgument,
                    "value of `bar` fails validation rule for :foo parameter")
  end
end