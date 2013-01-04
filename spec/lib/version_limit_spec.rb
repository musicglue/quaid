require 'spec_helper'

describe Mongoid::Quaid do

  before do
    @project = create(:max_versions_project)
  end

  it "should limit the maximum number of versions that can be stored" do
    5.times {
      @project.name = Faker::Name.new
      @project.save
    }
    @project.versions.count.should eq(5)
  end

  it "should retain the most recent versions when limited" do
    5.times {
      @project.name = Faker::Name.new
      @project.save
    }
    @project.reload
    @project.versions.last.version.should eq(2)
  end

end