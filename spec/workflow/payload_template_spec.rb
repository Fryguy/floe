RSpec.describe Floe::Workflow::PayloadTemplate do
  let(:subject) { described_class.new(payload) }

  describe "#value" do
    context "with static array" do
      let(:payload) { ["a", 2] }
      let(:context) { {} }

      it "returns the original value" do
        expect(subject.value(context)).to eq(["a", 2])
      end
    end

    context "with static values" do
      let(:payload) { {"foo" => "bar", "bar" => "$.baz", "baz" => 3} }
      let(:context) { {} }

      it "returns the original value" do
        expect(subject.value(context)).to eq({"foo" => "bar", "bar" => "$.baz", "baz" => 3})
      end
    end

    context "with dynamic values" do
      let(:payload) { {"foo.$" => "$.foo", "bar.$" => "$$.bar"} }
      let(:context) { {"bar" => "baz"} }
      let(:inputs)  { {"foo" => "bar"} }

      it "returns the value from the inputs" do
        expect(subject.value(context, inputs)).to eq({"foo" => "bar", "bar" => "baz"})
      end

      context "with an invalid payload" do
        let(:payload) { {"foo.$" => "$.foo", "foo" => "bar"} }

        it "raises an exception" do
          expect { subject }.to raise_error(Floe::InvalidWorkflowError, "both foo.$ and foo present")
        end
      end
    end

    context "with nested dynamic values" do
      let(:payload) { {"foo.$" => ["$.foo", "$$.bar"], "bar.$" => {"hello.$" => "$.greeting"}} }
      let(:context) { {"bar" => "baz"} }
      let(:inputs)  { {"foo" => "bar", "greeting" => "world"} }

      it "returns the value from the inputs" do
        expect(subject.value(context, inputs)).to eq({"foo" => ["bar", "baz"], "bar" => {"hello" => "world"}})
      end
    end
  end
end
