ActiveAdmin.register BxBlockTermsAndConditions::TermsAndCondition, as: "Terms And Condition" do
  menu priority: 7
  config.batch_actions = false
  permit_params :title, :slug, :description
  before_action :set_old_description, only: [:edit, :update]

  config.filters = false

  actions :all
  config.action_items.delete_if { |item| item.display_on?(:index) }

  action_item :new_terms_condition, only: :index do
    link_to 'New Terms and Condition', new_admin_terms_and_condition_path unless BxBlockTermsAndConditions::TermsAndCondition.exists?
  end

  index download_links: false do
    column "Description" do |obj|
      obj.description.html_safe
    end
    actions
  end

  form do |f|
    f.inputs 'Terms and Condition' do
       f.input :description, as: :quill_editor
    end
    f.actions
  end

  show do
    attributes_table do
      row "Description" do |obj|
        obj.description.html_safe
      end
      row "Users who Accepted" do |terms_and_condition|
        accepted_users = terms_and_condition.user_terms_and_conditions.where(is_accepted: true).includes(account: :profile)
        user_info = accepted_users.map { |user_term_condition| "<strong>#{user_term_condition.account.email}</strong>&nbsp;&nbsp;<strong>#{user_term_condition.account.full_name}</strong>" }
        user_info.join('<br>').html_safe
      end
      row :created_at
      row :updated_at
    end
  end

  controller do
    def create
      super do
        return redirect_to admin_terms_and_conditions_path, notice: "Terms and Condition Created!" if @terms_and_condition.errors.empty?
      end
    end

    def update
      super do
        @terms_and_condition.update(updated_at: Time.now) if @old_desc != @terms_and_condition.description
        return redirect_to admin_terms_and_condition_path, notice: "Terms and Condition Updated!" if @terms_and_condition.errors.empty?
      end
    end

    private

    def set_old_description
      @old_desc = BxBlockTermsAndConditions::TermsAndCondition.find_by(id: params[:id].to_i).description
    end
  end
end
