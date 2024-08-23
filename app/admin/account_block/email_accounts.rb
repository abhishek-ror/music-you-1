ActiveAdmin.register AccountBlock::EmailAccount, as: "EmailAccount" do
  permit_params :email, :password, :accept_terms_and_conditions, :activated
  config.sort_order = 'id_asc'

  form do |f|
    f.inputs "Email Account Details" do
      f.input :email
      f.input :password
      f.input :accept_terms_and_conditions, as: :boolean
      f.input :activated, as: :boolean
    end
    f.actions
  end

  index do
    selectable_column
    id_column
    column :email
    column :accept_terms_and_conditions
    column :activated
    actions
  end

  filter :email
  filter :accept_terms_and_conditions
  filter :activated

  show do
    attributes_table do
      row :id
      row :email
      row :fcm_device_token
      row :accept_terms_and_conditions
      row :activated
    end
  end
end
