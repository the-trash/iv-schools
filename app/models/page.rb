class Page < ActiveRecord::Base  
  # �������� ��� ������, ����������� � ��������� (������������)
  acts_as_nested_set :scope=>:user
  belongs_to :user
end
