Redmine::Plugin.register :custom_rules do
  name 'Custom Rules plugin'
  author 'Ding jianxiong'
  description 'This is a plugin for our custom rules about workflow'
  version '0.0.3'
  url 'https://github.com/daniel-djx/redmine_custom_rules'
  author_url 'http://redmine.socialworks.mobi/users/3'
end


module CustomRules
  class Hooks < Redmine::Hook::ViewListener
    def controller_issues_edit_before_save(context={})
      # Auto incrase 'Verify Count' when the issue verify faild.
      # Also can see the detail via http://redmine.socialworks.mobi/issues/3709
      if context[:issue].status_id_changed? && context[:issue].status_was.name == 'Resolved' && context[:issue].status.name == 'Verify Failed'
        context[:issue].custom_field_values.each do |custom_value|
          custom_value.value = (custom_value.value.to_i + 1).to_s if custom_value.custom_field.name == 'Verify Count'
        end
      end

      # Set Regression field value automated.
      set_regression_field_value(context)

      # Update watcher list.
      update_current_issue_watcher_list(context)
    end

    def controller_issues_new_before_save(context={})
      # Set Regression field value automated.
      set_regression_field_value(context)
    end

    private

    # Set to true automatically when 'Caused by' issue's tracker is Bug.
    # Default value is false.
    # The detail can be seen via http://redmine.socialworks.mobi/issues/3710
    def set_regression_field_value(context={})
      lissue = context[:issue]

      # Make sure current issue custom fields include 'Caused by' and 'Regression'.
      # And 'Caused by' should be a number and 'Regression's value should be false.
      # Note: 'true' is '1' and 'false' is '0' in redmine custom field, default maybe nil.
      field_caused_by = field_regression = nil
      lissue.custom_field_values.each do |custom_value|
        field_caused_by = custom_value if custom_value.custom_field.name == 'Caused by' &&
                                          custom_value.value =~ /\d+/
        field_regression = custom_value if custom_value.custom_field.name == 'Regression' &&
                                           (custom_value.value == '0' || !custom_value.value)
                                           # See above Note.
        break if field_caused_by and field_regression
      end

      if field_caused_by && field_regression
        begin
          caused_by_issue = Issue.find(field_caused_by.value)
        rescue ActiveRecord::RecordNotFound
          caused_by_issue = nil
        end
        # See above note.
        # Sometime the default is 'nil', then the front will display black not no,
        # so we should set the value is '0' when the bug is not a regression bug.
        field_regression.value = (caused_by_issue && caused_by_issue.tracker.name == 'Bug') ? '1' : '0'
      end
    end

    # Add operator into watcher list when a Feature changed from 'Designed' to Reviewed'
    # The detail can be see http://redmine.socialworks.mobi/issues/3645
    def update_current_issue_watcher_list(context={})
      unless context[:issue].status_id_changed? &&
             context[:issue].status_was.name == 'Designed' &&
             context[:issue].status.name == 'Reviewed' &&
             context[:issue].tracker.name == 'Feature'
        return
      end

      # Add the current user to watcher list.
      unless context[:issue].watched_by?(User.current)
        context[:issue].set_watcher(User.current, true)
      end
    end
  end
end
