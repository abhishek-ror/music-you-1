ActiveAdmin.register BxBlockAdmin::PrivacyPolicy, as: 'Privacy Policy' do
  permit_params :description, :created_at, :updated_at

  menu priority: 3

  config.batch_actions = false
  config.filters = false
  before_action :set_old_description, only: [:edit, :update]

  actions :all
  config.action_items.delete_if { |item| item.display_on?(:index) }

  action_item :new, only: :index do
    link_to 'New Privacy Policy', new_admin_privacy_policy_path unless BxBlockAdmin::PrivacyPolicy.any?
  end

  form do |f|
    f.inputs 'Privacy Policies' do
       f.input :description, as: :quill_editor
    end
    f.actions
  end

  index do
    column "Description" do |obj|
      obj.description.html_safe
    end
    actions
  end

  show do
    attributes_table do
      row :created_at
        row :updated_at
      row "Description" do |obj|
        obj.description.html_safe
      end
    end
  end

  controller do
    def create
      super do
        return redirect_to admin_privacy_policies_path, notice: "Privacy Policy Created!" if @privacy_policy.errors.empty?
      end
    end

    def update
      super do
        @privacy_policy.update(updated_at: Time.now) if @old_desc != @privacy_policy.description
        return redirect_to admin_privacy_policy_path, notice: "Privacy Policy Updated!" if @privacy_policy.errors.empty?
      end
    end

    private

    def set_old_description
      @old_desc = BxBlockAdmin::PrivacyPolicy.find_by(id: params[:id].to_i).description
    end
  end
end
