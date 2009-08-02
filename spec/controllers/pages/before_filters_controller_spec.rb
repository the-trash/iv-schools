require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe PagesController do
    # Проверить наличие before фильтров
    it "18:19 23.07.2009" do
      controller.before_filters.should include(:login_required)
      controller.before_filters.should include(:access_to_controller_action_required)
      controller.before_filters.should include(:page_resourсe_access_required)

      controller.before_filter(:login_required).should                        have_options(:except=>[:index, :show])
      controller.before_filter(:access_to_controller_action_required).should  have_options(:only=>[:index, :new, :create, :manager])
      controller.before_filter(:page_resourсe_access_required).should         have_options(:only=>[:show, :edit, :update, :destroy, :up, :down])
    end
end