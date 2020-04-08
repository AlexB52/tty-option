# frozen_string_literal: true

RSpec.describe TTY::Option::ParamPermitted do
  it "skips check when no permit setting" do
    param = TTY::Option::Parameter::Option.create(:foo)

    expect(described_class[param, "a"]).to eq("a")
  end

  it "permits an option argument" do
    param = TTY::Option::Parameter::Option.create(:foo, permit: %w[a b c])

    expect(described_class[param, "a"]).to eq("a")
  end

  it "doesn't permit an option arguemnt" do
    param = TTY::Option::Parameter::Option.create(:foo, permit: %w[a b c])

    expect {
      described_class[param, "d"]
    }.to raise_error(TTY::Option::UnpermittedArgument,
                    "unpermitted argument d for :foo parameter")
  end
end