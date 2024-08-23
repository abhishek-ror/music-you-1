ActiveAdmin.register AccountBlock::Account, as: "User Management" do
  permit_params :user_name, :email, :date_of_birth, :status, :gender, :activated, :created_at, :fcm_device_token, profiles_attributes: [:id, :first_name, :last_name, :gender, :dob, :looking_for, :concerts_festivals, :indoor_or_outdoor, :city, :bio, :relationship_status, :occupation, :education, :religion, :ethnicity, :height, :body_type, :smoking, :drinking, :pets, :languages => [], :hobbies => [], :favorite_artists => [], :favorite_genres => [], :for_you => []]
  config.sort_order = 'id_asc'

  controller do
    def index
      @page_title = "User Management"
      super
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Account Details" do

      f.input :email

      f.input :status

      f.input :activated

    end

    f.inputs "Profile Details" do
      f.has_many :profiles, new_record: false do |pf|
        pf.input :first_name
        pf.input :last_name
        pf.input :dob, as: :date_select, start_year: Date.today.year - 100, end_year: Date.today.year, order: [:day, :month, :year], include_blank: false
        pf.input :city
        pf.input :bio
        pf.input :height
        pf.input :body_type
        pf.input :smoking
        pf.input :drinking
        pf.input :occupation
        pf.input :gender, as: :select, input_html: { multiple: false }, collection: ["male", "female", "other"]

        pf.input :looking_for, as: :select, input_html: { multiple: false }, collection: ["male", "female", "everyone"]

        pf.input :relationship_status, as: :select, input_html: { multiple: false }, collection: ["single", "in a relationship", "married", "prefer not to say"]

        pf.input :education, as: :select, input_html: { multiple: false }, collection: ["Bechlor's", "in college", "high school", "phd", "grad school", "masters", "trade school"]

        pf.input :religion, as: :select, input_html: { multiple: false }, collection: ["Spiritual", "Chirstianity", "Islam", "Judaism", "other"]

        pf.input :pets, as: :select, input_html: { multiple: false }, collection: ["dog person", "cat person", "pet free", "want a pet", "other"]

        pf.input :ethnicity, as: :select, collection: [["Select a ethnicity", nil]] + BxBlockCategories::Category.find_by(name: 'ethnicity').sub_categories.all.map { |eth| [eth.name, eth.name] }, input_html: { multiple: false }

        pf.input :languages, as: :check_boxes, input_html: { multiple: true, required: true }, collection: ["English", "Spanish", "Arabic", "Hindi", "Bengali", "Protuguese", "Russian", "Madarian Chinese", "others"]

        pf.input :hobbies, as: :check_boxes, collection: ["listen to music", "reading", "hiking", "cooking", "photography", "playing music instruments", "traveller"]

        pf.input :favorite_genres, as: :check_boxes, collection: BxBlockCategories::Category.find_by(name: 'what kind of music do you listen to?').sub_categories.all.map { |gen| [gen.name, gen.name] }

        pf.input :favorite_artists, as: :check_boxes, collection: BxBlockCategories::Category.find_by(name: 'who are some of your favorite artists?').sub_categories.all.map { |art| [art.name, art.name] }
      end

      f.actions
    end
  end

  filter :email
  filter :created_at

  index do
    selectable_column
    id_column
    column :user_name do |account|
      account.name
    end
    column :email
    column :status
    column "Date of Registration", :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :status
      row "Date of Registration" do |account|
        account.created_at
      end
      row "Connected Music Service" do |account|
        if account.music_connections.any?
          account.music_connections.first.service_name
        else
          "No Music Service Connected"
        end
      end
      # row :profile do |account|
      #   account.profiles&.last&.name
      # end
      # row :posts do |account|
      #   account.posts.map { |post| post.name }.join(', ')
      # end
      # row :join_request do |account|
      #   account.join_requests.map { |request| request.community.title }.join(', ')
      # end
      # row :photo_libraries do |account|
      #   account.photo_libraries.map { |library| library.title }.join(', ')
      # end
      # row :user_statuses do |account|
      #   account.user_statuses.map { |status| status.status }.join(', ')
      # end
    end

    panel "Profile Details" do
      if resource.profiles&.last
        attributes_table_for resource.profiles.last do
          row "Profile Pictures" do |profile|
            urls = profile.profile_pictures
            if urls.present?
              urls.map do |url|
                image_tag url, height: '100px', width: '100px', style: 'border-radius: 5px; margin-right: 10px;'
              end.join.html_safe
            else
              "No Profile Pictures"
            end
          end
          row :first_name
          row :last_name
          row :gender
          row :dob
          row :looking_for
          row :concerts_festivals
          row :indoor_or_outdoor
          row :city
          row :bio
          row :relationship_status
          row :occupation
          row :education
          row :religion
          row :ethnicity
          row :height
          row :body_type
          row :smoking
          row :drinking
          row :pets
          row :languages
          row :hobbies
          row :favorite_artists
          row :favorite_genres
          row :for_you
        end
      else
        div "No profile details available"
      end
    end
  end

  action_item :suspend, only: :show do
    # link_to "Suspend Account", suspend_admin_account_block_account_path(resource), method: :put if resource.status != 'suspended'
  end

  action_item :delete, only: :show do
    # link_to "Delete Account", delete_admin_account_block_account_path(resource), method: :delete
  end

  member_action :suspend, method: :put do
    resource.update(status: :suspended)
    redirect_to admin_account_block_account_path(resource), notice: "Account suspended successfully."
  end

  member_action :delete, method: :delete do
    resource.destroy
    redirect_to admin_account_block_accounts_path, notice: "Account deleted successfully."
  end
end
