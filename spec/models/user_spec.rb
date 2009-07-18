require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do  
  describe 'PersonalResourcePolicy' do
    def create_users
      @admin= Factory.create(:admin)
      @ivanov= Factory.create(:ivanov)
      @petrov= Factory.create(:petrov)
    end

    def admin_has_ivanov_as_resource
      @resource_ivanov=Factory.create(:page_manager_personal_resource_policy, :user_id=>@admin.id)
      @resource_ivanov.resource= @ivanov
      @resource_ivanov.save
    end    

    it '17:23 16.07.2009' do
      create_users
      admin_has_ivanov_as_resource
      
      @resource_ivanov.resource_type.should == @ivanov.class.to_s
      @resource_ivanov.resource_id.should   == @ivanov.id
    end
  end#PersonalResourcePolicy
end
