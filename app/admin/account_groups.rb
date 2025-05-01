module AccountGroups
  class Load
    @@loaded_from_gem = false
    def self.is_loaded_from_gem
      @@loaded_from_gem
    end

    def self.loaded
    end

    @@loaded_from_gem = Load.method(:loaded).source_location.first.include?("bx_block_")
  end
end

unless AccountGroups::Load.is_loaded_from_gem
  ActiveAdmin.register BxBlockAccountGroups::Group, as: "Account Groups" do
    menu false
    permit_params :name, :settings, :account_ids

    index do
      selectable_column
      id_column
      column :name
      column :settings
      column :account_ids
      actions
    end

    filter :name
    filter :created_at

    form do |f|
      f.inputs do
        f.input :name
        f.input :settings
        f.input :account_ids
      end
      f.actions
    end
  end
end
