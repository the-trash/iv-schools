require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe PagesController do
    # Проверить наличие before фильтров
    it "18:19 23.07.2009" do
      controller.before_filters.should include(:login_required)
      controller.before_filter(:login_required).should have_options(:except=>[:index, :show])

      controller.before_filters.should include(:controller_action_policy_required)
      controller.before_filter(:controller_action_policy_required).should have_options(:except=>[:index, :show])

      controller.before_filters.should include(:navigation_menu_init)
      controller.before_filter(:navigation_menu_init).should have_options(:except=>[:show])
    end
end