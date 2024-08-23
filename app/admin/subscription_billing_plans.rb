ActiveAdmin.register BxBlockSubscriptionBilling::Plan, as: 'Subscription Plan' do
	permit_params :name, :short_title, :detailed_title, :monthly_fee, :yearly_fee, :details, :color

  config.sort_order = 'id_asc'

  form do |f|
    f.inputs do
      f.input :name
      f.input :short_title
      f.input :detailed_title
      f.input :monthly_fee
      f.input :yearly_fee
      f.input :details
      f.input :color
    end
    f.actions
  end

  index do
    selectable_column
    id_column
    column :name
    column :short_title
    column :detailed_title
    column :monthly_fee
    column :yearly_fee
    column :details
    column :color
    actions
  end

  show do
    attributes_table do
      row :name
      row :short_title
      row :detailed_title
      row :monthly_fee
      row :yearly_fee
      row :details
      row :color
    end
  end
end
