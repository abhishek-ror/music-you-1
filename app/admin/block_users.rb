ActiveAdmin.register BxBlockBlockUsers::BlockUser, as: 'Block User' do
  permit_params :current_user_id, :account_id

  config.sort_order = 'id_asc'

  controller do
    def index
      @page_title = "Block User"
      super
    end
  end

  index do
    selectable_column
    id_column
    column :current_user_id
    column :account_id
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :current_user_id
      row :account_id
      row :created_at
      row :updated_at
    end
  end

  member_action :block, method: :post do
    account_id = params[:account_id]
    block_user = BxBlockBlockUsers::BlockUser.new(account_id: account_id)

    if block_user.save
      redirect_to admin_block_user_path(block_user), notice: "User blocked successfully."
    else
      redirect_to admin_block_users_path, alert: "Failed to block user."
    end
  end

  member_action :unblock, method: :put do
    block_user = BxBlockBlockUsers::BlockUser.find(params[:id])
    if block_user.destroy
      redirect_to admin_block_users_path, notice: "User unblocked successfully."
    else
      redirect_to admin_block_users_path, alert: "Failed to unblock user."
    end
  end

  form do |f|
    f.inputs do
      f.input :account_id, as: :select, collection: AccountBlock::Account.pluck(:email, :id)
    end
    f.actions
  end
end
