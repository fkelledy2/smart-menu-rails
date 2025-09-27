class TagsController < ApplicationController
  before_action :set_tag, only: %i[ show edit update destroy ]

  # GET /tags or /tags.json
  def index
    if current_user
        @tags = Tag.where(archived: false).all
    else
        redirect_to root_url
    end
  end

  # GET /tags/1 or /tags/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /tags/new
  def new
    if current_user
        @tag = Tag.new
    else
        redirect_to root_url
    end
  end

  # GET /tags/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /tags or /tags.json
  def create
    if current_user
        @tag = Tag.new(tag_params)
        respond_to do |format|
          if @tag.save
            format.html { redirect_to tag_url(@tag), notice: t('common.flash.created', resource: t('activerecord.models.tag')) }
            format.json { render :show, status: :created, location: @tag }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @tag.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /tags/1 or /tags/1.json
  def update
    if current_user
        respond_to do |format|
          if @tag.update(tag_params)
            format.html { redirect_to tag_url(@tag), notice: t('common.flash.updated', resource: t('activerecord.models.tag')) }
            format.json { render :show, status: :ok, location: @tag }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @tag.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    if current_user
        @tag.update( archived: true )
        respond_to do |format|
          format.html { redirect_to tags_url, notice: t('common.flash.deleted', resource: t('activerecord.models.tag')) }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tag
      @tag = Tag.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tag_params
      params.require(:tag).permit(:name, :description, :menuitem_id)
    end
end
