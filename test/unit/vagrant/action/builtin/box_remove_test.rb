require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::BoxRemove do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:env) { {
    box_collection: box_collection,
    ui: Vagrant::UI::Silent.new,
  } }

  subject { described_class.new(app, env) }

  let(:box_collection) { double("box_collection") }
  let(:iso_env) { isolated_environment }

  let(:box) do
    box_dir = iso_env.box3("foo", "1.0", :virtualbox)
    Vagrant::Box.new("foo", :virtualbox, "1.0", box_dir)
  end

  it "deletes the box if it is the only option" do
    box_collection.stub(all: [["foo", "1.0", :virtualbox]])

    env[:box_name] = "foo"

    expect(box_collection).to receive(:find).with(
      "foo", :virtualbox, "1.0").and_return(box)
    expect(box).to receive(:destroy!).once
    expect(app).to receive(:call).with(env).once

    subject.call(env)

    expect(env[:box_removed]).to equal(box)
  end

  it "deletes the box with the specified provider if given" do
    box_collection.stub(
      all: [
        ["foo", "1.0", :virtualbox],
        ["foo", "1.0", :vmware],
      ])

    env[:box_name] = "foo"
    env[:box_provider] = "virtualbox"

    expect(box_collection).to receive(:find).with(
      "foo", :virtualbox, "1.0").and_return(box)
    expect(box).to receive(:destroy!).once
    expect(app).to receive(:call).with(env).once

    subject.call(env)

    expect(env[:box_removed]).to equal(box)
  end

  it "deletes the box with the specified version if given" do
    box_collection.stub(
      all: [
        ["foo", "1.0", :virtualbox],
        ["foo", "1.1", :virtualbox],
      ])

    env[:box_name] = "foo"
    env[:box_version] = "1.0"

    expect(box_collection).to receive(:find).with(
      "foo", :virtualbox, "1.0").and_return(box)
    expect(box).to receive(:destroy!).once
    expect(app).to receive(:call).with(env).once

    subject.call(env)

    expect(env[:box_removed]).to equal(box)
  end

  it "errors if the box doesn't exist" do
    box_collection.stub(all: [])

    expect(app).to receive(:call).never

    expect { subject.call(env) }.
      to raise_error(Vagrant::Errors::BoxRemoveNotFound)
  end

  it "errors if the specified provider doesn't exist" do
    env[:box_name] = "foo"
    env[:box_provider] = "bar"

    box_collection.stub(all: [["foo", "1.0", :virtualbox]])

    expect(app).to receive(:call).never

    expect { subject.call(env) }.
      to raise_error(Vagrant::Errors::BoxRemoveProviderNotFound)
  end

  it "errors if there are multiple providers" do
    env[:box_name] = "foo"

    box_collection.stub(
      all: [
        ["foo", "1.0", :virtualbox],
        ["foo", "1.0", :vmware],
      ])

    expect(app).to receive(:call).never

    expect { subject.call(env) }.
      to raise_error(Vagrant::Errors::BoxRemoveMultiProvider)
  end

  it "errors if the specified provider has multiple versions" do
    env[:box_name] = "foo"
    env[:box_provider] = "virtualbox"

    box_collection.stub(
      all: [
        ["foo", "1.0", :virtualbox],
        ["foo", "1.1", :virtualbox],
      ])

    expect(app).to receive(:call).never

    expect { subject.call(env) }.
      to raise_error(Vagrant::Errors::BoxRemoveMultiVersion)
  end

  it "errors if the specified version doesn't exist" do
    env[:box_name] = "foo"
    env[:box_version] = "1.1"

    box_collection.stub(all: [["foo", "1.0", :virtualbox]])

    expect(app).to receive(:call).never

    expect { subject.call(env) }.
      to raise_error(Vagrant::Errors::BoxRemoveVersionNotFound)
  end
end
