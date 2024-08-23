ActiveAdmin.register BxBlockAdmin::Safety, as: 'Safety' do
  permit_params :title, :description, :created_at, :updated_at

  config.batch_actions = false
  config.filters = false
  before_action :set_old_description, only: [:edit, :update]

  actions :all
  config.action_items.delete_if { |item| item.display_on?(:index) }

  action_item :new, only: :index do
    link_to 'New Safety', new_admin_safety_path unless BxBlockAdmin::Safety.any?
  end

  form do |f|
    f.inputs 'Safeties' do
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
        return redirect_to admin_safeties_path, notice: "Safety Created!" if @safety.errors.empty?
      end
    end

    def update
      super do
        @safety.update(updated_at: Time.now) if @old_desc != @safety.description
        return redirect_to admin_safety_path, notice: "Safety Updated!" if @safety.errors.empty?
      end
    end

    private

    def set_old_description
      @old_desc = BxBlockAdmin::Safety.find_by(id: params[:id].to_i).description
    end
  end
end
