require "spec_helper"

RSpec.describe Binxtils::Secure do
  let(:subject) { described_class }

  describe "compare?" do
    let(:expected) { "s3cret-t0ken" }

    context "matching value" do
      it "returns true" do
        expect(subject.compare?(expected.dup, expected)).to eq true
      end
    end

    context "value differing in length" do
      it "returns false" do
        expect(subject.compare?("#{expected}8", expected)).to eq false
      end
    end

    context "value differing in a single character" do
      it "returns false" do
        expect(subject.compare?(expected.sub("s", "S"), expected)).to eq false
      end
    end

    context "non-string value" do
      let(:expected) { "42" }

      it "compares the string representation" do
        expect(subject.compare?(42, expected)).to eq true
        expect(subject.compare?(43, expected)).to eq false
      end
    end

    context "non-string expected" do
      let(:expected) { 42 }

      it "compares the string representation" do
        expect(subject.compare?("42", expected)).to eq true
        expect(subject.compare?(42, expected)).to eq true
        expect(subject.compare?("43", expected)).to eq false
      end
    end

    context "nil value" do
      it "returns false" do
        expect(subject.compare?(nil, expected)).to eq false
      end
    end

    context "blank expected" do
      it "returns false" do
        expect(subject.compare?("", nil)).to eq false
        expect(subject.compare?("", "")).to eq false
        expect(subject.compare?(nil, nil)).to eq false
        expect(subject.compare?(expected, nil)).to eq false
      end
    end
  end
end
