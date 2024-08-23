ActiveAdmin.register BxBlockAudiomusic2::Song, as: 'Songs' do
  permit_params :song_name, :artist_name, :audio, :image

  index do
    selectable_column
    id_column
    column :song_name
    column :artist_name
    column :image do |song|
        if song.image.attached?
          image_tag url_for(song.image), size: "50x50"
        end
      end

    actions
  end

  show do
    attributes_table do
      row :song_name
      row :artist_name
      row :image do |song|
          if song.image.attached?
            image_tag url_for(song.image), size: "50x50"
          end
      end
      row :audio do |song|
        if song.audio.attached?
          audio_tag url_for(song.audio), controls: true
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :song_name
      f.input :artist_name
      f.input :image, as: :file
      f.input :audio, as: :file
    end
    f.actions
  end

  filter :song_name
  filter :artist_name
end
