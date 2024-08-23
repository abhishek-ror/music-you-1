ActiveAdmin.register AccountBlock::SocialAccount, as: "SocialAccount" do
  permit_params :email, :password, :accept_terms_and_conditions, :activated, :unique_auth_id, :platform
  config.sort_order = 'id_asc'

  form do |f|
    f.inputs "Email Account Details" do
      f.input :email
      f.input :password
      f.input :unique_auth_id
      f.input :platform
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
    column :platform
    actions
  end

  filter :email
  filter :accept_terms_and_conditions
  filter :activated
  filter :platform

  show do
    attributes_table do
      row :id
      row :email
      row :accept_terms_and_conditions
      row :activated
      row :platform
      row :unique_auth_id
      row :fcm_device_token
    end
  end
end
