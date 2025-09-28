class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tag, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /tags or /tags.json
  def index
    @tags = policy_scope(Tag).where(archived: false)
  end

  # GET /tags/1 or /tags/1.json
  def show
    authorize @tag
  end

  # GET /tags/new
  def new
    @tag = Tag.new
    authorize @tag
  end

  # GET /tags/1/edit
  def edit
    authorize @tag
  end

  # POST /tags or /tags.json
  def create
    @tag = Tag.new(tag_params)
    authorize @tag

    respond_to do |format|
      if @tag.save
        format.html do
          redirect_to tag_url(@tag), notice: t('common.flash.created', resource: t('activerecord.models.tag'))
        end
        format.json { render :show, status: :created, location: @tag }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tags/1 or /tags/1.json
  def update
    authorize @tag

    respond_to do |format|
      if @tag.update(tag_params)
        format.html do
          redirect_to tag_url(@tag), notice: t('common.flash.updated', resource: t('activerecord.models.tag'))
        end
        format.json { render :show, status: :ok, location: @tag }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    authorize @tag

    @tag.update(archived: true)
    respond_to do |format|
      format.html { redirect_to tags_url, notice: t('common.flash.deleted', resource: t('activerecord.models.tag')) }
      format.json { head :no_content }
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
