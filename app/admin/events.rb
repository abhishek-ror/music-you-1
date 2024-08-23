ActiveAdmin.register BxBlockEvents::Event, as: "Event" do
  permit_params :title, :date, :time, :latitude, :longitude, :email_account_id, :event_type, :notify, :repeat, :notes, :visibility, :address, :custom_repeat_in_number, :custom_repeat_every, :image

  index do
    selectable_column
    id_column
    column :title
    column :date
    column :time
    column :latitude
    column :longitude
    column :notify
    column :repeat
    column :custom_repeat_every
    column :assign_to
    column :visibility
    column :email_account
    column :event_type
    column :address
    column :image do |event|
      image_tag(event.image, size: '70x70') if event.image.present?
    end
    actions
  end

  filter :title
  filter :date
  filter :time
  filter :notify
  filter :repeat
  filter :email_account
  filter :event_type

  form do |f|
    f.inputs do
      f.input :title
      f.input :date, as: :datepicker
      f.input :time, as: :time_picker
      f.input :latitude
      f.input :longitude
      f.input :notify, as: :select, collection: BxBlockEvents::Event.notifies.keys
      f.input :repeat, as: :select, collection: BxBlockEvents::Event.repeats.keys
      f.input :custom_repeat_every, as: :select, collection: BxBlockEvents::Event.custom_repeat_everies.keys
      f.input :email_account, as: :select, collection: AccountBlock::EmailAccount.all.map { |acc| [acc.email, acc.id] }
      f.input :event_type
      f.input :address
      f.input :notes
      f.input :custom_repeat_in_number
      f.input :image, as: :file
    end
    f.actions
  end

  show do
    attributes_table do
      row :title
      row :date
      row :time
      row :latitude
      row :longitude
      row :notify
      row :repeat
      row :custom_repeat_every
      row :email_account
      row :event_type
      row :address
      row :notes
      row :custom_repeat_in_number
      row :image do |event|
        image_tag(event.image, size: '100x100') if event.image.present?
      end
    end
    active_admin_comments
  end
end
