require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Page do
  before(:each) do
    zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
    
    @valid_attributes = {
      :user_id=> 1,
      :zip=>zip,
      :author=>Faker::Name.name,
      :keywords=>Faker::Lorem.sentence(2),
      :description=>Faker::Lorem.sentence(2),
      :copyright=>Faker::Name.name,
      :title=>"Test Title",
      :annotation=>Faker::Lorem.sentence(30),
      :content=>Faker::Lorem.paragraphs(50)
    }
  end

  it "Page creating" do
    Page.create!(@valid_attributes)
  end
end
