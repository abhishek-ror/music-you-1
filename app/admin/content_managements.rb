module BxBlockContentManagement
end

ActiveAdmin.register BxBlockContentManagement::ContentManagement, as: 'Content Management' do
	menu false

	permit_params :title, :description, :status, :price, :quantity, :user_type, images: []

	index do
		selectable_column
		id_column
		column :title
		column :price
		column :user_type
		column :quantity
		column :image
		column :description
		column :status
		actions
	end

	show do
		attributes_table do
			row :title
			row :description
			row :price
			row :quantity
			row :user_type
			row :status
			row :images do |s|
				s.images.map do |img|
					span do
						image_tag(img, height: '100', width: '100') rescue nil
					end
					""
				end
			end
		end
	end

	form do |f|
		f.semantic_errors(*f.object.errors.keys)
		f.inputs do
			f.input :title
			f.input :description
			f.input :price
			f.input :quantity
			f.input :user_type
			f.input :status
			f.input :images, as: :file, input_html: { multiple: true }
		end
		f.actions
	end
end
