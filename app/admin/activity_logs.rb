USER_ACTIVITY_CLASS = "user-activity"
TABLE_FORMAT = "table-format"

ActiveAdmin.register_page "Activity Logs" do
  menu priority: 10

  content title: "Activity Logs" do
    columns do
      column do
        panel "User Login/Logout Timestamps", class: USER_ACTIVITY_CLASS do
          paginated_collection(AccountBlock::Account.order(created_at: :desc).page(params[:page]).per(10), download_links: false) do
            table_for collection do
              column :email, class: TABLE_FORMAT
              column "Login Timestamp", class: TABLE_FORMAT do |account|
                account.last_login_at.present? ? account.last_login_at : '-'
              end

              column "Logout Timestamp", class: TABLE_FORMAT do |account|
                account.last_logout_at.present? ? account.last_logout_at : '-'
              end

              column "Activity (Hours)", class: TABLE_FORMAT do |log|
                if log.activity_duration_in_hours.present?
                  log.activity_duration_in_hours
                else
                  '-'
                end
              end
            end
          end
        end
      end
    end
  end
end
