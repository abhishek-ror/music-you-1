ActiveAdmin.register BxBlockContentflag::Content, as: "Content Flag" do
  menu false

  permit_params :post_id, :account_id, :flag_category_id, :approved

  # actions :all, except: [:destroy]
  config.sort_order = 'id_asc'

  index do
    selectable_column
    id_column
    column :post
    column :account
    column :flag_category
    column :approved
    column :created_at
    column :updated_at
    actions
  end

  filter :post
  filter :account
  filter :flag_category
  filter :approved
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :post, as: :select, collection: BxBlockPosts::Post.all.map { |post| [post.name, post.id] }
      f.input :account, as: :select, collection: AccountBlock::Account.all.map { |account| [account.name, account.id] }
      f.input :flag_category, as: :select, collection: BxBlockContentflag::FlagCategory.all.map { |flag| [flag.reason, flag.id] }
      f.input :approved
    end
    f.actions
  end

  show do
    attributes_table do
      row :post
      row :account
      row :flag_category
      row :approved
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  controller do
    def destroy
      @content = BxBlockContentflag::Content.find(params[:id])
      @content.destroy
      redirect_to admin_content_flags_path, notice: "Content removed successfully."
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_content_flags_path, alert: "Content not found."
    end
  end
end
