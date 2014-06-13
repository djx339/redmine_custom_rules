Redmine::Plugin.register :custom_rules do
  name 'Custom Rules plugin'
  author 'Ding jianxiong'
  description 'This is a plugin for our custom rules about workflow'
  version '0.0.1'
  url 'https://github.com/daniel-djx/redmine_custom_rules.git'
  author_url 'http://redmine.socialworks.mobi/users/3'
end


module CustomRules
  class Hooks < Redmine::Hook::ViewListener
    def controller_issues_edit_before_save(context={})
      
      # Auto incrase 'Verify Count' when the issue verify faild.
      # Also can see the detail vai http://redmine.socialworks.mobi/issues/3709
      if context[:issue].status_id_changed? && context[:issue].status_was.name == 'Resolved' && context[:issue].status.name == 'Verify Failed'
        context[:issue].custom_field_values.each do |custom_value|
          custom_value.value = (custom_value.value.to_i + 1).to_s if custom_value.custom_field.name == 'Verify Count'
        end
      end

    end
  end
end
