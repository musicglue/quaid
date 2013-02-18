require 'spec_helper'

describe Mongoid::Quaid do

  context "Make like Rekall and..." do

    before do
      @project = create(:project)
    end

    it "should include Quaid" do
      @project.class.ancestors.should include(Mongoid::Quaid)
    end

    it "should create a Project::Version class" do
      Project.should have_constant(:Version)
    end

    it "should persist versions for projects in the project_versions collection" do
      Project::Version.collection_name.should eq(:project_versions)
    end

    it "should have a version of 1" do
      @project.version.should eq(1)
    end

    it "should have created a saved version", focus: true do
      Project::Version.count.should eq(1)
    end

    it "should have access to its last version through #last_version" do
      @project.versions.first["version"].should eq(1)
    end

    it "should return an arbitrary version" do
      old_name = @project.name
      @project.name = Faker::Name.name
      @project.save
      old_proj = Project.find_with_version(@project.id, 1)
      old_proj["version"].should eq(1)
    end

    it "should create a new version with the current attributes if updated" do
      old_name = @project.name
      @project.name = Faker::Name.name
      @project.save
      @project.reload
      @project.last_version["version"].should eq(1)
      @project.last_version["name"].should    eq(old_name)
    end

    it "should create a new version with each save" do
      n = 10
      lambda {
        n.times {
          @project.name = Faker::Name.name
          @project.save
        }
      }.should change{ Project::Version.count }.from(1).to(n+1)
    end

    it "should order the versions by their creation date descending" do
      5.times {
        @project.name = Faker::Name.name
        @project.save
      }
      Project::Version.last.version.should eq(1)
    end

    it "should destroy associated versions when record is destroy" do
      id = @project.id
      @project.destroy
      Project::Version.where(owner_id: id).count.should eq(0)
    end

  end

end