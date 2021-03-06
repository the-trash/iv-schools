require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe '15:13 18.07.2009' do
    before(:each) do
      # ����� � �������� ������� ����
      @page_manager_role= Factory.create(:page_manager_role)
      @admin= Factory.create(:admin, :role_id=>@page_manager_role.id)
    end
    
    def create_personal_policies
      # ������� 2 ������������ �������� ��� ������� ������������
      @page_manager_policy= Factory.create(:page_manager_personal_policy_unlimited, :user_id=>@admin.id)
      @page_tree_policy=    Factory.create(:page_tree_personal_policy_unlimited,    :user_id=>@admin.id)
      # ������� �� ������� - ����������
      @page_tree_policy.update_attribute(:value, false)
      @page_manager_policy.update_attribute(:value, false)
    end
    
    # 2 ������������ ���������� ��� ���������� �����������
    it '9:17 15.07.2009' do
      create_personal_policies
      
      @admin.has_personal_block?(:pages, :tree).should     be_true
      @admin.has_personal_block?(:pages, :manager).should  be_true
      
      @admin.has_personal_block?('pages', :tree).should      be_true
      @admin.has_personal_block?('pages', 'manager').should  be_true
      
      @admin.has_personal_block?(:pages0, :tree).should    be_false
      @admin.has_personal_block?(:pages, :duck).should     be_false
    end#9:17 15.07.2009

    # � ������������ ��� �� ����� ������������ ��������
    it '14:29 16.07.2009' do
      # ������� �������� ����
      @admin.role_policies_hash.should  be_instance_of(Hash)
      @admin.role_policies_hash.should  have(2).items
      
      # ������������ ���������� ���
      @admin.create_personal_policies_hash.should  be_instance_of(Hash)
      @admin.create_personal_policies_hash.should  be_empty
      
      # ����� ���������� �� ���������� - ������� false
      @admin.has_personal_block?('pages', 'tree').should   be_false
      @admin.has_personal_block?(:pages, :manager).should  be_false
      @admin.has_personal_block?(:pages, 'manager').should be_false
      @admin.has_personal_block?(:pages0, :tree).should    be_false
      @admin.has_personal_block?(:pages, :duck).should     be_false
    end#14:29 16.07.2009

    # �������
    
    # ����������� ����������� ����������� �� ���-�� ��� �������
    it '11:48 15.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes(:counter=>15, :max_count=>14)
      @admin.has_personal_block?(:pages, :manager).should be_false
    end
    
    # ������� �� ����������
    it '12:38 19.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes(:counter=>nil, :max_count=>14)
      @admin.has_personal_block?(:pages, :manager).should be_true
    end
    
    # �������� �������� �� ����������
    it '12:39 19.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes(:counter=>10, :max_count=>nil)
      @admin.has_personal_block?(:pages, :manager).should be_true
    end

    # ������� �������
    it '12:40 19.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes(:counter=>10, :max_count=>10)
      @admin.has_personal_block?(:pages, :manager).should be_true
    end
    
    # �����
    
    # ��������� �����
    it '11:48 15.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes(:start_at=>DateTime.now-2.seconds, :finish_at=>DateTime.now-1.second)
      @admin.has_personal_block?(:pages, :manager).should be_false
    end
    
    # ����� �� �����������
    it '12:38 19.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes(:start_at=>nil, :finish_at=>nil)
      @admin.has_personal_block?(:pages, :manager).should be_true
    end
    
    # �������� ������� �� ����������
    it '12:39 19.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes(:start_at=>DateTime.now-1.second, :finish_at=>nil)
      @admin.has_personal_block?(:pages, :manager).should be_true
    end

    # ������� ����� �������
    it '12:40 19.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes(:start_at=>DateTime.now-1.second, :finish_at=>DateTime.now+10.second)
      @admin.has_personal_block?(:pages, :manager).should be_true
    end
    
    # �������� ���� �������
    
    it '12:49 19.07.2009' do
      create_personal_policies
      @admin.has_personal_block?(:pages, :manager).should  be_true
      @admin.has_personal_block?(:pages, :tree).should     be_true
      
      # ��� ���������� ���������
      @page_tree_policy.update_attribute(:value, true)
      @page_manager_policy.update_attribute(:value, true)
      
      # ��� �� ����������
      @admin.has_personal_block?(:pages, :manager).should  be_true
      @admin.has_personal_block?(:pages, :tree).should     be_true
      
      # ��� ����������
      @admin.has_personal_block?(:pages, :tree, :recalculate=> true).should  be_false
      @admin.has_personal_block?(:pages, :manager).should  be_false
    end
end
