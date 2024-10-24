# frozen_string_literal: true
require 'net/http'
require 'json'

module BxBlockCategories
  class CategoriesController < ApplicationController
    before_action :load_category, only: %i[show update destroy]

    def all_info
      category_names = [
        "relationship status", "occupation", "education", "religion", "looking for", "ethnicity", "languages",
        "height", "body type", "smoking", "drinking", "pets", "hobbies"
      ]

      categories = Category.includes(:sub_categories)
                           .where(name: category_names).order(:name)

      data = {
        my_info: [],
        languages: [],
        lifestyles: []
      }

      categories.each do |category|
        sub_categories_with_images = category.sub_categories.map do |subcategory|
          {
            id: subcategory.id,
            name: subcategory.name,
            image_url: active_storage_url_with_host(subcategory.image)
          }
        end

        case category.name.downcase
        when "relationship status", "occupation", "education", "religion", "looking for", "ethnicity"
          data[:my_info] << { id: category.id, name: category.name, sub_categories: sub_categories_with_images }
        when "languages"
          data[:languages] = { id: category.id, name: category.name, sub_categories: sub_categories_with_images }
        when "height", "body type", "smoking", "drinking", "pets", "hobbies"
          data[:lifestyles] << { id: category.id, name: category.name, sub_categories: sub_categories_with_images }
        else
          next
        end
      end

      render json: data, status: :ok
    end

    def spotify_genres_list
      category = Category.find_by(name: "what kind of music do you listen to?")
      subcategories = category.sub_categories
      subcategories = subcategories.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
      subcategories = subcategories.page(params[:page]).per(params[:per_page])
      total_count = subcategories.total_count
      serialized_subcategories = SubCategorySerializer.new(subcategories, serialization_options).serializable_hash[:data]
      render json: {
        data: serialized_subcategories,
        total_count: total_count
      }, status: :ok
    end

    def genres_category
      genres = Category.find_by(name: "what kind of music do you listen to?")
      render json: CategorySerializer.new(genres, serialization_options)
        .serializable_hash, status: :ok
    end

    def looking_for_you
      category_data = find_category_by_name("what are you looking for?")
      return render json: { message: "Category not found" }, status: :not_found unless category_data

      render json: { category: category_data }, status: :ok
    end

    def favourite_artists
      category_data = find_category_by_name("who are some of your favorite artists?")
      return render json: { message: "Favorite artists not found" }, status: :not_found unless category_data

      artists = category_data[:sub_categories].map do |sub_category|
        {
          artist_name: sub_category[:name],
          image_url: sub_category[:image_url]
        }
      end

      artists.sort_by! { |artist| artist[:artist_name] } # sort the artists by name in alphabetical order

      # pagination
      if params[:per_page].present? && params[:page].present?
        per_page = params[:per_page].to_i
        page = params[:page].to_i
        offset = (page - 1) * per_page
        artists = artists.slice(offset, per_page)
      end

      render json: { artists: artists }, status: :ok
    end

    def favorite_love_songs
      category_data = find_category_by_name("what your favorite love song?")
      return render json: { message: "favorite love songs not found" }, status: :not_found unless category_data

      render json: { category: category_data }, status: :ok
    end

    def favorite_gym_songs
      category_data = find_category_by_name("what song do I have on repeat at the gym")
      return render json: { message: "Favorite gym songs not found" }, status: :not_found unless category_data

      render json: { category: category_data }, status: :ok
    end

    def ethnicities
      category = Category.find_by(name: "ethnicity")

      if category.nil?
        render json: { error: "Category not found" }, status: :not_found
      else
        subcategories = category&.sub_categories
        ethnicities = subcategories&.map(&:name)
        render json: { ethnicities: ethnicities }, status: :ok
      end
    end

    def community_forum_categories
      category = Category.find_by(name: "Community Forum")

      if category.nil?
        render json: { error: "Category not found for Community Forum" }, status: :not_found
      else
        subcategories = category&.sub_categories
        community_forum_categories = subcategories&.map(&:name)
        render json: { community_forum_categories: community_forum_categories }, status: :ok
      end
    end

    def create
      err = []

      categories_params.map do |x|
        name_validation = x.permit(:name).to_h
        err << "name can't be blank" unless name_validation[:name].present?
      end

      return render json: {message: err.uniq}, status: :unprocessable_entity unless !err.present?
      @categories = Category.create!(categories_params)

      if @categories
        render json: CategorySerializer.new(@categories, serialization_options)
          .serializable_hash,
          status: :created
      end
    rescue
      categories_params.map do |x|
        name_validation = x.permit(:name).to_h
        if Category.where(name: name_validation[:name]).present?
          err << "name can't be use #{name_validation[:name]}"
        end
      end
      render json: {message: err}, status: :unprocessable_entity
    end

    def show
      return if @category.nil?

      render json: CategorySerializer.new(@category, serialization_options)
        .serializable_hash,
        status: :ok
    end

    def index
      return render json: {message: "No data is present"}, status: :not_found unless Category.all.present?
      serializer = if params[:sub_category_id].present?
        categories = SubCategory.find(params[:sub_category_id])
          .categories
        CategorySerializer.new(categories)
      else
        CategorySerializer.new(Category.all, serialization_options)
      end
      render json: serializer, status: :ok
    end

    def destroy
      return if @category.nil?

      begin
        if @category.destroy
          remove_not_used_subcategories

          render json: {success: true}, status: :ok
        end
      rescue ActiveRecord::InvalidForeignKey
        message = "Record can't be deleted due to reference to a catalogue " \
                  "record"

        render json: {
          error: {message: message}
        }, status: :internal_server_error
      end
    end

    def update
      return if @category.nil?

      update_result = @category.update(update_categories_params)

      if update_result
        render json: CategorySerializer.new(@category).serializable_hash,
          status: :ok
      else
        render json: ErrorSerializer.new(@category).serializable_hash,
          status: :unprocessable_entity
      end
    end

    def update_user_categories
      categories = Category.where(id: params[:categories_ids])
      category_ids = categories.map(&:id)

      return render json: {errors: "Category ID #{(params[:categories_ids].map(&:to_i) - category_ids).join(",")} not found"}, status: :unprocessable_entity unless category_ids.count == params[:categories_ids].count
      if categories.present?
        UserCategory.where(account_id: current_user.id).delete_all
        params[:categories_ids].each do |cat_id|
          UserCategory.create!(account_id: current_user.id, category_id: cat_id)
        end
        categories = Category.joins(:user_categories).where(user_categories: {account_id: current_user.id})
        render json: CategorySerializer.new(categories).serializable_hash,
          status: :ok
      end
    end

    private

    def find_category_by_name(name)
      category = Category.find_by(name: name)
      return nil unless category

      sub_categories_with_images = category.sub_categories.map do |subcategory|
        {
          id: subcategory.id,
          name: subcategory.name,
          image_url: active_storage_url_with_host(subcategory.image)
        }
      end

      {
        id: category.id,
        name: category.name,
        sub_categories: sub_categories_with_images
      }
    end

    def active_storage_url_with_host(attachment)
      attachment.attached? ? Rails.application.routes.url_helpers.rails_blob_url(attachment, host: request.base_url, only_path: false) : nil
    end

    def categories_params
      params.permit(categories: [:name, light_icon: {}, light_icon_active: {}, light_icon_inactive: {}, dark_icon: {}, dark_icon_active: {}, dark_icon_inactive: {}]).require(:categories)
    end

    def update_categories_params
      params.require(:categories).permit(:name, light_icon: {}, light_icon_active: {}, light_icon_inactive: {}, dark_icon: {}, dark_icon_active: {}, dark_icon_inactive: {})
    end

    def load_category
      @category = Category.find_by(id: params[:id])

      if @category.nil?
        render json: {
          message: "Category with id #{params[:id]} doesn't exists"
        }, status: :not_found
      end
    end

    def serialization_options
      options = {}
      options[:params] = {sub_categories: true}
      options
    end

    def remove_not_used_subcategories
      sql = "delete from sub_categories sc where sc.id in (
               select sc.id from sub_categories sc
               left join categories_sub_categories csc on
                 sc.id = csc.sub_category_id
               where csc.sub_category_id is null
             )"
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
