module BxBlockContentModeration
end

ActiveAdmin.register BxBlockContentModeration::Content, as: 'Content Moderation' do
	menu false

	permit_params :is_image_approved, :is_text_approved
	before_save :update_by
	config.sort_order = 'id_asc'

	filter :created_by
	filter :is_text_approved
	filter :is_image_approved


	index do
		selectable_column
		id_column
		column :text_content
		column :is_text_approved
		column :created_by
		column :updated_by
		column :image do |a|
			image_tag(a.image, size: '70x70') if a.image.present?
		end
		column :is_image_approved
		actions
	end

 	show do |_f|
		attributes_table do
			row :created_by
			row :updated_by
			row :text_content
			row :is_text_approved
			row :profile_picture, interactive: true do |avatar|
				image_tag(avatar.image, size: '100x100') if avatar.image.present?
			end
			row :is_image_approved
			row :is_active
		end
	end

	form do |f|
		f.inputs do
			f.input :is_text_approved
			f.input :is_image_approved
		end
		f.actions
	end

	controller do
		def update_by(o)
			if params[:action] == 'update'
				o.updated_by = 'admin'
			end
		end
	end
end
