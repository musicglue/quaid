require 'spec_helper'

describe Mongoid::Quaid do

  before do
    @list = create(:list)
    @list.items << build(:item)
    @list.save
    @list.reload
  end

  it "should save a version on adding an item" do
    @list.versions.size.should eq(2)
  end

  it "should correctly instantiate embedded docs in saved versions" do
    @list.name = Faker::Name.name
    @list.save
    @list.reload
    @list.last_version["items"].first["name"].should eq(@list.items.first.name)
  end

end