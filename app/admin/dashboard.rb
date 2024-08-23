module Dashboard
  class Load
    @@loaded_from_gem = false

    def self.is_loaded_from_gem
      @@loaded_from_gem
    end

    def self.loaded
    end

    # Check if this file is loaded from gem directory or not
    @@loaded_from_gem = Load.method('loaded').source_location.first.include?('bx_block_')
  end
end

PANELS_WRAPPER_CLASS = "panels-wrapper panel_container_main"

unless Dashboard::Load.is_loaded_from_gem
  ActiveAdmin.register_page "Dashboard" do
    menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

    content title: proc { I18n.t("active_admin.dashboard") } do
      panel "Key Metrics", class: "key-metrics-heading" do
      end

      div class: PANELS_WRAPPER_CLASS do
        panel "Total Registered Users", class: "key-metrics" do
          div class: "data_inside_metrics_panel" do
            strong AccountBlock::Account.count.to_s
          end
        end

        panel "Active Users (Last 30 Days)", class: "key-metrics-2" do
          div class: "data_inside_metrics_panel" do
            strong AccountBlock::Account.where("updated_at > ?", 30.days.ago).count.to_s
          end
        end

        panel "New User Registrations (Last 30 Days)", class: "key-metrics-3" do
          div class: "data_inside_metrics_panel" do
            strong AccountBlock::Account.where("created_at > ?", 30.days.ago).count.to_s
          end
        end

        panel "Total Forum Posts", class: "key-metrics-4" do
          div class: "data_inside_metrics_panel" do
            strong BxBlockCommunityforum::Post.count.to_s
          end
        end
      end

      panel "Forum Activity Metrics", class: "forum-activity-heading" do
      end

      div class: PANELS_WRAPPER_CLASS do
        panel "Most Active Forum Topics", class: "activity-metrics" do
          div class: "data_inside_metrics_panel" do
            BxBlockCommunityforum::Post.count.to_s
          end
        end

        panel "Number of Forum Posts", class: "activity-metrics-2" do
          div class: "data_inside_metrics_panel" do
            strong BxBlockCommunityforum::Post.count.to_s
          end
        end

        panel "Number of Forum Comments", class: "activity-metrics-3" do
          div class: "data_inside_metrics_panel" do
            strong BxBlockComments::Comment.count.to_s
          end
        end
      end

      panel "User Demographics", class: "user-demographics-heading" do
      end

      div class: PANELS_WRAPPER_CLASS do
        panel "Male", class: "user-demographics" do
          male_count = BxBlockProfile::Profile.where(gender: 'male').count

          ul class: "data_inside_metrics_panel_small"  do
            if male_count.positive?
              li  "#{male_count}"
            else
              li "No male data available."
            end
          end
        end

        panel "Female", class: "user-demographics-2" do
          female_count = BxBlockProfile::Profile.where(gender: 'female').count

          ul class: "data_inside_metrics_panel_small"  do
            if female_count.positive?
              li "#{female_count}"
            else
              li "No female data available."
            end
          end
        end

        panel "Other", class: "user-demographics-3" do
          other_count = BxBlockProfile::Profile.where(gender: 'other').count

          ul class: "data_inside_metrics_panel_small"  do
            if other_count.positive?
              li "#{other_count}"
            else
              li "No other data available."
            end
          end
        end
      end

      panel "Age Distribution of Users", class: "user-demographics-heading" do
      end

      div class: 'panels-wrapper' do
        panel "Age", class: "user-demographics-2" do
          age_distribution = AccountBlock::Account.where.not(age: nil).group("ROUND(age / 10.0) * 10").count

          div class: "age-distribution" do
            if age_distribution.present?
              age_distribution.sort_by { |age_group, _| age_group.to_f }.each do |age_group, count|
                div class: "age-group" do
                  span "#{age_group.to_i} to #{age_group.to_i + 10} years old: #{count} users", class: "age-group-text"
                end
              end
            else
              div class: "no-age-data" do
                span "No age data available."
              end
            end
          end
        end
      end

      panel "User Engagement Metrics", class: "user-engagement-metrics-heading" do
      end

      div class: PANELS_WRAPPER_CLASS do
        panel "Daily Active Users", class: "user-engagement-metrics" do
          div class: "data_inside_metrics_panel" do
            strong AccountBlock::Account.active_in_last_day.count.to_s
          end
        end

        panel "Weekly Active Users", class: "user-engagement-metrics-2" do
          div class: "data_inside_metrics_panel" do
            strong AccountBlock::Account.active_in_last_week.count.to_s
          end
        end

        panel "Monthly Active Users", class: "user-engagement-metrics-3" do
          div class: "data_inside_metrics_panel" do
            strong AccountBlock::Account.active_in_last_month.count.to_s
          end
        end
      end
    end
  end
end

#Helper method to calculate age
def age(date_of_birth)
  ((Time.zone.now - date_of_birth.to_time) / 1.year.seconds).floor
end
