module BxBlockFavourites
  class FavouritesController < ApplicationController

    def favourites_list
      liked_profiles = BxBlockLike::Like.where(like_by_id: current_user.id, likeable_type: "BxBlockProfile::Profile", disliked: false)
      likes_on_my_profile = BxBlockLike::Like.where(likeable_id: current_user.profiles.last, likeable_type: "BxBlockProfile::Profile", disliked: false)

      render json: {
        send_likes: {
          count: liked_profiles.count,
          profiles: liked_profiles.map { |like| { profile: BxBlockProfile::ProfileSerializer.new(like.likeable).serializable_hash.merge(age: like.likeable.age) } }
        },
        recieved_likes: {
          count: likes_on_my_profile.count,
          profiles: likes_on_my_profile.map { |like| { profile: BxBlockProfile::ProfileSerializer.new(AccountBlock::Account.find(like.like_by_id).profiles.last).serializable_hash.merge(age: AccountBlock::Account.find(like.like_by_id).profiles.last.age) } }
        }
      }, status: :ok
    end

    def index
      favourites = BxBlockFavourites::Favourite.where(user_id: current_user.id)
      if params[:favouriteable_type]
        favourites = favourites.where(favouriteable_type: params[:favouriteable_type])
      end

      if favourites.present?
        serializer = BxBlockFavourites::FavouriteSerializer.new(favourites)
        render json: serializer.serializable_hash,
          status: :ok
      else
        render json: {
          errors: 'Favourites not found'
        }, status: :not_found
      end
    end

    def create
      favourite = BxBlockFavourites::Favourite.new(
        favourites_params.merge({user_id: current_user.id})
      )
      if favourite.save
        serializer = BxBlockFavourites::FavouriteSerializer.new(favourite)
        render json: serializer.serializable_hash,
          status: :ok
      else
        render json: {errors: favourite.errors},
          status: :unprocessable_entity
      end
    rescue => e
      render json: {errors: e.message},
        status: :unprocessable_entity
    end

    def destroy
      favourite =
        BxBlockFavourites::Favourite.find(params[:id])
      if favourite.destroy
        render json: {message: "Destroy successfully"},
          status: :ok
      end
    end

    private

    def favourites_params
      params.require(:data).permit \
        :favouriteable_id, :favouriteable_type
    end
  end
end
