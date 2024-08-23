ActiveAdmin.register BxBlockCommunityforum::Post, as: "Community Forum Posts" do

  actions :all, :except => [:new]

  permit_params :name, :description, :category, :approved

  member_action :approve, method: :put do
    resource.update(approved: true)
    redirect_to admin_community_forum_posts_path, notice: "Post Approved Successfully."
  end

  member_action :unapprove, method: :put do
    resource.update(approved: false)
    redirect_to admin_community_forum_posts_path, notice: "Post Disapproved Successfully."
  end

  index do
    selectable_column
    id_column
    column :name
    column :description
    column :category
    column :created_by do |obj|
    	obj.account.email
    end
    column :approved

    column "Actions" do |post|
      if !post.approved
        link_to 'Approve', "/admin/community_forum_posts/#{post.id}/approve", method: :put, class: 'approve-button'
      else
        link_to 'Disapprove', "/admin/community_forum_posts/#{post.id}/unapprove", method: :put, class: 'unapprove-button'
      end
    end

    actions
  end

  show do |post|
    attributes_table do
      row :id
      row :account
      row :name
      row :description
      row :category
      row :approved
      row :created_at
    end

    panel 'Songs' do
      if post.post_songs.present?
        table_for post.post_songs do
          column :image do |post_song|
            image_tag post_song.image_url, height: '60px', style: 'border-radius: 5px;'
          end
          column :song_name
          column :artist_name
          column :song_play do |post_song|
            audio_tag post_song.song_url, controls: true, style: 'border-radius: 5px;'
          end
        end
      else
        "No songs added."
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :description, as: :text
      f.input :approved
    end
    f.actions
  end

  filter :name
  filter :description
  filter :description
  filter :approved
end
