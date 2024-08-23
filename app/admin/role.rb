ActiveAdmin.register BxBlockRolesPermissions::Role, as: "Roles Permissions" do
  permit_params :name

  config.sort_order = 'id_asc'

  index do
    column :name
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :created_at
      row :updated_at
    end
  end
end
