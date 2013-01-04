require 'spec_helper'

describe Mongoid::Quaid do

  context "paranoid classes" do

    before do
      @project = create(:paranoid_project)
    end

    it "should not destroy associated documents when parent is destroyed" do
      @project.destroy
      ParanoidProject::Version.unscoped.count.should eq(1)
    end

  end

end