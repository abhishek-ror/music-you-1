ActiveAdmin.register BxBlockCategories::Category, as: "Category" do

  permit_params :name, sub_categories_attributes: [:id, :name, :_destroy, :image]

  index do
    selectable_column
    id_column
    column :name
    column :created_at
    column :updated_at
    actions
  end

  filter :name
  filter :created_at

  form do |f|
    f.inputs do
      f.inputs "Category" do
        f.input :name
      end
      f.inputs "Sub Category" do
        f.has_many :sub_categories, accepts_nested_attributes_for: true, new_record: true do |sc|
          sc.input :name
          sc.input :image, as: :file
          # sc.input :_destroy, :as => :boolean
        end
      end
    end
    f.actions
  end

  show do |category|
    @sub_categories = category.sub_categories
    attributes_table do
      row :id
      row :name
      row :created_at
      row :updated_at
      panel "Sub Categories (Total Count: #{category.sub_categories.count})" do
        if category.sub_categories.any?
          table_for category.sub_categories do
            column :id
            column :name
            column :created_at
            column :updated_at
            column :image do |sub_category|
              if sub_category.image.attached?
                image_tag url_for(sub_category.image), size: "50x50"
              end
            end
            column "Actions" do |sub_category|
              link_to 'Delete', destroy_sub_category_admin_category_path(category, sub_category, sub_category_id: sub_category.id), method: :delete, data: { confirm: 'Are you sure you want to delete this?' }
            end
          end
        end
      end
    end
  end

  member_action :destroy_sub_category, method: :delete do
    sub_category = BxBlockCategories::SubCategory.find(params[:sub_category_id])
    category_id = params[:id]
    sub_category.destroy
    redirect_to admin_category_path(category_id), notice: "Sub category '#{sub_category.name}' has been deleted."
  end
end
